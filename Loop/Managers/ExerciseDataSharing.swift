//
//  ExerciseDataSharing.swift
//  Loop
//
//  Copyright © 2026 LoopKit Authors. All rights reserved.
//

import HealthKit
import LoopKit
import Observation
import os.log

@Observable
final class ExerciseDataSharing {
    /// The health sample kinds Loop reads and uploads (custom: only what Nightscout uses, not all
    /// of LoopKit's kinds)
    static let healthSampleKinds: [StoredHealthSample.Kind] = [.stepCount, .physicalEffort]

    private(set) var isEnabled: Bool

    @ObservationIgnored private let exerciseStore: ExerciseStore
    @ObservationIgnored private let healthStore: HKHealthStore
    @ObservationIgnored private weak var remoteDataServicesManager: RemoteDataServicesManager?
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let log = OSLog(category: "ExerciseDataSharing")

    init(exerciseStore: ExerciseStore, healthStore: HKHealthStore, remoteDataServicesManager: RemoteDataServicesManager, userDefaults: UserDefaults = .standard) {
        self.exerciseStore = exerciseStore
        self.healthStore = healthStore
        self.remoteDataServicesManager = remoteDataServicesManager
        self.userDefaults = userDefaults
        self.isEnabled = userDefaults.sharesExerciseData
        if isEnabled {
            startObserving()
        }
    }

    var serviceDescriptions: [String] {
        remoteDataServicesManager?.exerciseDataDescriptions ?? []
    }

    @MainActor
    func setEnabled(_ enabled: Bool) async {
        if enabled {
            do {
                try await healthStore.requestAuthorization(toShare: [], read: ExerciseStore.readTypes(for: Self.healthSampleKinds))
            } catch {
                log.error("Exercise data authorization failed: %{public}@", String(describing: error))
                return
            }
        }
        userDefaults.sharesExerciseData = enabled
        isEnabled = enabled
        if enabled {
            startObserving()
        } else {
            exerciseStore.stopObserving()
        }
    }

    private func startObserving() {
        exerciseStore.observe(
            kinds: Self.healthSampleKinds,
            workoutsChanged: { [weak self] in
                Task { @MainActor in self?.remoteDataServicesManager?.triggerUpload(for: .exercise) }
            },
            samplesChanged: { [weak self] in
                Task { @MainActor in self?.remoteDataServicesManager?.triggerUpload(for: .healthSamples) }
            }
        )
    }
}
