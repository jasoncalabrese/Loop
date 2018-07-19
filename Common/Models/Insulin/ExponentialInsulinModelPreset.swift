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
            return .minutes(300)
        case .humalogNovologChild:
            return .minutes(300)
        case .fiasp:
            return .minutes(300)
        }
    }

    /*
    var peakActivity: TimeInterval {
        switch self {
        case .humalogNovologAdult:
            return .minutes(75)
        case .humalogNovologChild:
            return .minutes(65)
        case .fiasp:
            return .minutes(55)
        }
    }
    */
    
    var peakActivity: TimeInterval {
        switch self {
        case .humalogNovologAdult:
            return .minutes(80)
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
            return NSLocalizedString("Exponential Peak - 80", comment: "Title of insulin model preset")
        case .humalogNovologChild:
            return NSLocalizedString("Exponential 60", comment: "Title of insulin model preset")
        case .fiasp:
            return NSLocalizedString("Exponential 50", comment: "Title of insulin model preset")
        }
    }

    var subtitle: String? {
        switch self {
        case .humalogNovologAdult:
            return NSLocalizedString("A model based on the published absorption of Humalog, Novolog, and Apidra insulin in adults.", comment: "Subtitle of Rapid-Acting – Adult preset")
        case .humalogNovologChild:
            return NSLocalizedString("An adjustment to the adult model based on empirical effects in children.", comment: "Subtitle of Rapid-Acting – Children preset")
        case .fiasp:
            return NSLocalizedString("A model based on the published absorption of Fiasp insulin.", comment: "Subtitle of Fiasp preset")
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
