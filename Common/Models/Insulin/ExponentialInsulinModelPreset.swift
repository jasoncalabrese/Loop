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
            return .minutes(250)
        case .humalogNovologChild:
            return .minutes(230)
        case .fiasp:
            return .minutes(210)
        }
    }

    var peakActivity: TimeInterval {
        switch self {
        case .humalogNovologAdult:
            return .minutes(60)
        case .humalogNovologChild:
            return .minutes(60)
        case .fiasp:
            return .minutes(60)
        }
    }

    var initialDelay: TimeInterval {
        switch self {
        case .humalogNovologAdult:
            return .minutes(20)
        case .humalogNovologChild:
            return .minutes(20)
        case .fiasp:
            return .minutes(20)
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
            return NSLocalizedString("Exponential Slow", comment: "Title of insulin model preset")
        case .humalogNovologChild:
            return NSLocalizedString("Exponential Medium", comment: "Title of insulin model preset")
        case .fiasp:
            return NSLocalizedString("Exponential Fast", comment: "Title of insulin model preset")
        }
    }

    var subtitle: String? {
        switch self {
        case .humalogNovologAdult:
            return NSLocalizedString("Duration: 250m, Peak: 60, Delay: 30", comment: "Exponential Slow")
        case .humalogNovologChild:
            return NSLocalizedString("Duration: 230m, Peak: 60, Delay: 20", comment: "Exponential Medium")
        case .fiasp:
            return NSLocalizedString("Duration: 210m, Peak: 60, Delay: 20", comment: "Exponential Fast")
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
