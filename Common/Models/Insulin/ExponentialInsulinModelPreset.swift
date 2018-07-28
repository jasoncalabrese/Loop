//
//  ExponentialInsulinModelPreset.swift
//  Loop
//
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import LoopKit

enum ExponentialInsulinModelPreset: String {
    case humalogNovologAdult
    case humalogNovologChild
    case fiasp
}


// MARK: - Model generation
extension ExponentialInsulinModelPreset {
    var actionDuration: TimeInterval {
        switch self {
        case .humalogNovologAdult:
            return .minutes(210)
        case .humalogNovologChild:
            return .minutes(230)
        case .fiasp:
            return .minutes(230)
        }
    }

    var peakActivity: TimeInterval {
        switch self {
        case .humalogNovologAdult:
            return .minutes(60)
        case .humalogNovologChild:
            return .minutes(50)
        case .fiasp:
            return .minutes(45)
        }
    }

    var initialDelay: TimeInterval {
        switch self {
        case .humalogNovologAdult:
            return .minutes(20)
        case .humalogNovologChild:
            return .minutes(15)
        case .fiasp:
            return .minutes(10)
        }
    }

    var model: InsulinModel {
        return ExponentialInsulinModel(actionDuration: actionDuration, peakActivityTime: peakActivity, initialDelay: initialDelay)
    }
}


// MARK: - Localization
extension ExponentialInsulinModelPreset {
    var title: String {
        switch self {
        case .humalogNovologAdult:
            return NSLocalizedString("Exponential Novolog", comment: "Title of insulin model preset")
        case .humalogNovologChild:
            return NSLocalizedString("Exponential Fiasp Slow", comment: "Title of insulin model preset")
        case .fiasp:
            return NSLocalizedString("Exponential Fiasp Fast", comment: "Title of insulin model preset")
        }
    }

    var subtitle: String? {
        switch self {
        case .humalogNovologAdult:
            return NSLocalizedString("Duration: 210m, Peak: 60, Delay: 20", comment: "Exponential Novolog")
        case .humalogNovologChild:
            return NSLocalizedString("Duration: 230m, Peak: 50, Delay: 15", comment: "Exponential Fiasp Slow")
        case .fiasp:
            return NSLocalizedString("Duration: 230m, Peak: 45, Delay: 10", comment: "Exponential Fiasp Fast")
        }
    }
}


extension ExponentialInsulinModelPreset: InsulinModel {
    var effectDuration: TimeInterval {
        return model.effectDuration
    }

    func percentEffectRemaining(at time: TimeInterval) -> Double {
        return model.percentEffectRemaining(at: time)
    }
}


extension ExponentialInsulinModelPreset: CustomDebugStringConvertible {
    var debugDescription: String {
        return "\(self.rawValue)(\(String(reflecting: model))"
    }
}
