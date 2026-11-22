//
//  SetBolusUserInfo.swift
//  Naterade
//
//  Created by Nathan Racklyeft on 3/20/16.
//  Copyright © 2016 Nathan Racklyeft. All rights reserved.
//

import Foundation
import LoopKit


struct SetBolusUserInfo {
    let value: Double
    let startDate: Date
    let contextDate: Date?
    let carbEntry: NewCarbEntry?
    let activationType: BolusActivationType
}


extension SetBolusUserInfo: RawRepresentable {
    typealias RawValue = [String: Any]

    static let version = 1
    static let name = "SetBolusUserInfo"

    init?(rawValue: RawValue) {
        guard rawValue["v"] as? Int == type(of: self).version &&
                rawValue["name"] as? String == SetBolusUserInfo.name,
              let value = rawValue["bv"] as? Double,
              let startDate = rawValue["sd"] as? Date,
              let rawActivationType = rawValue["at"] as? BolusActivationType.RawValue,
              let activationType = BolusActivationType(rawValue: rawActivationType)
        else {
            return nil
        }

        self.value = value
        self.startDate = startDate
        self.contextDate = rawValue["cd"] as? Date
        self.carbEntry = (rawValue["ce"] as? NewCarbEntry.RawValue).flatMap(NewCarbEntry.init(rawValue:))
        self.activationType = activationType
    }

    var rawValue: RawValue {
        var raw: RawValue = [
            "v": type(of: self).version,
            "name": SetBolusUserInfo.name,
            "bv": value,
            "sd": startDate
        ]

        raw["cd"] = contextDate
        raw["ce"] = carbEntry?.rawValue
        raw["at"] = activationType.rawValue

        return raw
    }
}


// MARK: - Inhaled insulin logging (custom)

/// Watch → phone request to LOG an inhaled dose (Afrezza) that was already taken.
///
/// Deliberately a separate message from `SetBolusUserInfo`: its phone-side handler only
/// records a dose in the dose store and has no path to the pump.
struct LogInhaledDoseUserInfo {
    /// The only cartridge size in use. Shown in the UI as "Afrezza 4U".
    static let defaultCartridgeUnits: Double = 4

    let cartridgeUnits: Double
    let startDate: Date
}


extension LogInhaledDoseUserInfo: RawRepresentable {
    typealias RawValue = [String: Any]

    static let version = 1
    static let name = "LogInhaledDoseUserInfo"

    init?(rawValue: RawValue) {
        guard rawValue["v"] as? Int == LogInhaledDoseUserInfo.version &&
                rawValue["name"] as? String == LogInhaledDoseUserInfo.name,
              let cartridgeUnits = rawValue["cu"] as? Double,
              let startDate = rawValue["sd"] as? Date
        else {
            return nil
        }

        self.cartridgeUnits = cartridgeUnits
        self.startDate = startDate
    }

    var rawValue: RawValue {
        return [
            "v": LogInhaledDoseUserInfo.version,
            "name": LogInhaledDoseUserInfo.name,
            "cu": cartridgeUnits,
            "sd": startDate
        ]
    }
}
