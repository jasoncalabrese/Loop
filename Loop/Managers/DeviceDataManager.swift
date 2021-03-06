//
//  DeviceDataManager.swift
//  Naterade
//
//  Created by Nathan Racklyeft on 8/30/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import HealthKit
import LoopKit
import LoopKitUI


final class DeviceDataManager {

    private let queue = DispatchQueue(label: "com.loopkit.DeviceManagerQueue", qos: .utility)

    var pumpManager: PumpManagerUI? {
        didSet {
            setupPump()

            UserDefaults.appGroup.pumpManager = pumpManager
        }
    }

    let logger = DiagnosticLogger.shared

    private let log = DiagnosticLogger.shared.forCategory("DeviceManager")

    /// Remember the launch date of the app for diagnostic reporting
    private let launchDate = Date()

    /// Manages authentication for remote services
    let remoteDataManager = RemoteDataManager()

    private var nightscoutDataManager: NightscoutDataManager!

    var lastError: (date: Date, error: Error)? {
        return lockedLastError.value
    }
    private func setLastError(error: Error) {
        lockedLastError.value = (date: Date(), error: error)
    }
    private let lockedLastError: Locked<(date: Date, error: Error)?> = Locked(nil)

    // MARK: - CGM

    var cgm: CGM? = UserDefaults.appGroup.cgm {
        didSet {
            if cgm != oldValue {
                setupCGM()
            }

            UserDefaults.appGroup.cgm = cgm
        }
    }

    private(set) var cgmManager: CGMManager?

    /// TODO: Isolate to queue
    private func setupCGM() {
        if case .usePump? = cgm, let pumpManager = pumpManager as? CGMManager {
            cgmManager = pumpManager
        } else {
            cgmManager = cgm?.createManager()
        }

        cgmManager?.cgmManagerDelegate = self
        loopManager.glucoseStore.managedDataInterval = cgmManager?.managedDataInterval

        pumpManager?.updateBLEHeartbeatPreference()
    }

    private func setupPump() {
        pumpManager?.pumpManagerDelegate = self

        // Proliferate PumpModel preferences to DoseStore
        if let pumpRecordsBasalProfileStartEvents = pumpManager?.pumpRecordsBasalProfileStartEvents {
            loopManager?.doseStore.pumpRecordsBasalProfileStartEvents = pumpRecordsBasalProfileStartEvents
        }

        setupCGM()
    }

    var sensorInfo: SensorDisplayable? {
        return cgmManager?.sensorState
    }

    // MARK: - Configuration

    // MARK: - WatchKit

    fileprivate var watchManager: WatchDataManager!

    // MARK: - Status Extension

    fileprivate var statusExtensionManager: StatusExtensionDataManager!

    // MARK: - Initialization

    private(set) var loopManager: LoopDataManager!

    init() {
        pumpManager = UserDefaults.appGroup.pumpManager as? PumpManagerUI

        remoteDataManager.delegate = self
        statusExtensionManager = StatusExtensionDataManager(deviceDataManager: self)
        loopManager = LoopDataManager(
            lastLoopCompleted: statusExtensionManager.context?.lastLoopCompleted,
            lastTempBasal: statusExtensionManager.context?.netBasal?.tempBasal
        )
        watchManager = WatchDataManager(deviceManager: self)
        nightscoutDataManager = NightscoutDataManager(deviceDataManager: self)

        loopManager.delegate = self
        loopManager.carbStore.syncDelegate = remoteDataManager.nightscoutService.uploader
        loopManager.doseStore.delegate = self

        setupPump()
    }
}


extension DeviceDataManager: RemoteDataManagerDelegate {
    func remoteDataManagerDidUpdateServices(_ dataManager: RemoteDataManager) {
        loopManager.carbStore.syncDelegate = dataManager.nightscoutService.uploader
    }
}


extension DeviceDataManager: CGMManagerDelegate {
    func cgmManager(_ manager: CGMManager, didUpdateWith result: CGMResult) {
        /// TODO: Isolate to queue
        switch result {
        case .newData(let values):
            loopManager.addGlucose(values) { result in
                if manager.shouldSyncToRemoteService {
                    switch result {
                    case .success(let values):
                        self.nightscoutDataManager.uploadGlucose(values, sensorState: manager.sensorState)
                    case .failure:
                        break
                    }
                }

                self.pumpManager?.assertCurrentPumpData()
            }
        case .noData:
            pumpManager?.assertCurrentPumpData()
        case .error(let error):
            self.setLastError(error: error)
            pumpManager?.assertCurrentPumpData()
        }

        pumpManager?.updateBLEHeartbeatPreference()
    }

    func startDateToFilterNewData(for manager: CGMManager) -> Date? {
        return loopManager.glucoseStore.latestGlucose?.startDate
    }
}


extension DeviceDataManager: PumpManagerDelegate {
    func pumpManager(_ pumpManager: PumpManager, didAdjustPumpClockBy adjustment: TimeInterval) {
        AnalyticsManager.shared.pumpTimeDidDrift(adjustment)
    }

    func pumpManagerDidUpdatePumpBatteryChargeRemaining(_ pumpManager: PumpManager, oldValue: Double?) {
        if let newValue = pumpManager.pumpBatteryChargeRemaining {
            if newValue == 0 {
                NotificationManager.sendPumpBatteryLowNotification()
            } else {
                NotificationManager.clearPumpBatteryLowNotification()
            }

            if let oldValue = oldValue, newValue - oldValue >= 0.5 {
                AnalyticsManager.shared.pumpBatteryWasReplaced()
            }
        }
    }

    func pumpManagerDidUpdateState(_ pumpManager: PumpManager) {
        UserDefaults.appGroup.pumpManager = pumpManager
    }

    func pumpManagerBLEHeartbeatDidFire(_ pumpManager: PumpManager) {
        cgmManager?.fetchNewDataIfNeeded { (result) in
            if case .newData = result {
                AnalyticsManager.shared.didFetchNewCGMData()
            }

            if let manager = self.cgmManager {
                // TODO: Isolate to queue?
                self.cgmManager(manager, didUpdateWith: result)
            }
        }
    }

    func pumpManagerShouldProvideBLEHeartbeat(_ pumpManager: PumpManager) -> Bool {
        return !(cgmManager?.providesBLEHeartbeat == true)
    }

    func pumpManager(_ pumpManager: PumpManager, didUpdateStatus status: PumpManagerStatus) {
        loopManager.doseStore.device = status.device
        // Update the pump-schedule based settings
        loopManager.setScheduleTimeZone(status.timeZone)
        nightscoutDataManager.upload(pumpStatus: status)
    }

    func pumpManagerWillDeactivate(_ pumpManager: PumpManager) {
        loopManager.doseStore.resetPumpData()
        self.pumpManager = nil
    }

    func pumpManager(_ pumpManager: PumpManager, didUpdatePumpRecordsBasalProfileStartEvents pumpRecordsBasalProfileStartEvents: Bool) {
        loopManager.doseStore.pumpRecordsBasalProfileStartEvents = pumpRecordsBasalProfileStartEvents
    }

    func pumpManager(_ pumpManager: PumpManager, didError error: PumpManagerError) {
        setLastError(error: error)
        nightscoutDataManager.uploadLoopStatus(loopError: error)
    }

    func pumpManager(_ pumpManager: PumpManager, didReadPumpEvents events: [NewPumpEvent], completion: @escaping (_ error: Error?) -> Void) {
        loopManager.addPumpEvents(events) { (error) in
            if let error = error {
                self.log.error("Failed to addPumpEvents to DoseStore: \(error)")
            }

            completion(error)
        }
    }

    func pumpManager(_ pumpManager: PumpManager, didReadReservoirValue units: Double, at date: Date, completion: @escaping (_ result: PumpManagerResult<(newValue: ReservoirValue, lastValue: ReservoirValue?, areStoredValuesContinuous: Bool)>) -> Void) {
        loopManager.addReservoirValue(units, at: date) { (result) in
            switch result {
            case .failure(let error):
                self.logger.addError(error, fromSource: "Bolus")
                completion(.failure(error))
            case .success(let (newValue, lastValue, areStoredValuesContinuous)):
                completion(.success((newValue: newValue, lastValue: lastValue, areStoredValuesContinuous: areStoredValuesContinuous)))

                // Send notifications for low reservoir if necessary
                if let previousVolume = lastValue?.unitVolume {
                    guard newValue.unitVolume > 0 else {
                        NotificationManager.sendPumpReservoirEmptyNotification()
                        return
                    }

                    var didSendLowNotification = false
                    let warningThresholds: [Double] = [10, 20, 30]

                    for threshold in warningThresholds {
                        if newValue.unitVolume <= threshold && previousVolume > threshold {
                            NotificationManager.sendPumpReservoirLowNotificationForAmount(newValue.unitVolume, andTimeRemaining: nil)
                            didSendLowNotification = true
                        }
                    }

                    if !didSendLowNotification {
                        NotificationManager.clearPumpReservoirNotification()
                    }

                    if newValue.unitVolume > previousVolume + 1 {
                        AnalyticsManager.shared.reservoirWasRewound()
                    }
                }
            }
        }
    }

    func pumpManagerRecommendsLoop(_ pumpManager: PumpManager) {
        loopManager.loop()
    }

    func startDateToFilterNewPumpEvents(for manager: PumpManager) -> Date {
        return loopManager.doseStore.pumpEventQueryAfterDate
    }

    func startDateToFilterNewReservoirEvents(for manager: PumpManager) -> Date {
        return loopManager.doseStore.lastReservoirValue?.startDate ?? .distantPast
    }
}


extension DeviceDataManager: DoseStoreDelegate {
    func doseStore(_ doseStore: DoseStore,
        hasEventsNeedingUpload pumpEvents: [PersistedPumpEvent],
        completion completionHandler: @escaping (_ uploadedObjectIDURLs: [URL]) -> Void
    ) {
        /// TODO: Isolate to queue
        guard let uploader = remoteDataManager.nightscoutService.uploader else {
            completionHandler(pumpEvents.map({ $0.objectIDURL }))
            return
        }

        uploader.upload(pumpEvents, fromSource: "loop://\(UIDevice.current.name)") { (result) in
            switch result {
            case .success(let objects):
                completionHandler(objects)
            case .failure(let error):
                let logger = DiagnosticLogger.shared.forCategory("NightscoutUploader")
                logger.error(error)
                completionHandler([])
            }
        }
    }
}

extension DeviceDataManager {
    func enactBolus(units: Double, at startDate: Date = Date(), completion: @escaping (_ error: Error?) -> Void) {
        guard let pumpManager = pumpManager else {
            completion(LoopError.configurationError(.pumpManager))
            return
        }

        pumpManager.enactBolus(units: units, at: startDate, willRequest: { (units, date) in
            self.loopManager.addRequestedBolus(units: units, at: date, completion: nil)
        }) { (error) in
            if let error = error {
                self.log.error(error)
                NotificationManager.sendBolusFailureNotification(for: error, units: units, at: startDate)
                completion(error)
            } else {
                self.loopManager.addConfirmedBolus(units: units, at: Date()) {
                    completion(nil)
                }
            }
        }
    }
}

extension DeviceDataManager: LoopDataManagerDelegate {
    func loopDataManager(
        _ manager: LoopDataManager,
        didRecommendBasalChange basal: (recommendation: TempBasalRecommendation, date: Date),
        completion: @escaping (_ result: Result<DoseEntry>) -> Void
    ) {
        guard let pumpManager = pumpManager else {
            completion(.failure(LoopError.configurationError(.pumpManager)))
            return
        }

        pumpManager.enactTempBasal(
            unitsPerHour: basal.recommendation.unitsPerHour,
            for: basal.recommendation.duration,
            completion: { result in
                switch result {
                case .success(let doseEntry):
                    completion(.success(doseEntry))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
}


extension DeviceDataManager: CustomDebugStringConvertible {
    var debugDescription: String {
        return [
            Bundle.main.localizedNameAndVersion,
            "",
            "## DeviceDataManager",
            "launchDate: \(launchDate)",
            "cgm: \(String(describing: cgm))",
            "lastError: \(String(describing: lastError))",
            "sensorInfo: \(String(reflecting: sensorInfo))",
            "",
            cgmManager != nil ? String(reflecting: cgmManager!) : "cgmManager: nil",
            "",
            pumpManager != nil ? String(reflecting: pumpManager!) : "pumpManager: nil",
            "",
            String(reflecting: statusExtensionManager!),
        ].joined(separator: "\n")
    }
}
