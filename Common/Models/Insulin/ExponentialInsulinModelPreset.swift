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
            return .minutes(240)
        case .humalogNovologChild:
            return .minutes(210)
        case .fiasp:
            return .minutes(240)
        }
    }

    var peakActivity: TimeInterval {
        switch self {
        case .humalogNovologAdult:
            return .minutes(60)
        case .humalogNovologChild:
            return .minutes(60)
        case .fiasp:
            return .minutes(50)
        }
    }
    
    var initialDelay: TimeInterval {
        switch self {
        case .humalogNovologAdult:
            return .minutes(20)
        case .humalogNovologChild:
            return .minutes(20)
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
            return NSLocalizedString("Exponential Novolog Long", comment: "Title of insulin model preset")
        case .humalogNovologChild:
            return NSLocalizedString("Exponential Novolog Normal", comment: "Title of insulin model preset")
        case .fiasp:
            return NSLocalizedString("Exponential Fiasp", comment: "Title of insulin model preset")
        }
    }

    var subtitle: String? {
        switch self {
        case .humalogNovologAdult:
            return NSLocalizedString("Duration: 4h, Peak: 60, Delay: 20", comment: "Exponential Novolog Long")
        case .humalogNovologChild:
            return NSLocalizedString("Duration: 3.5h, Peak: 60, Delay: 20", comment: "Exponential Novolog Normal")
        case .fiasp:
            return NSLocalizedString("Duration: 4h, Peak: 55, Delay: 15", comment: "Exponential Fiasp")
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
