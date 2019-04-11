//
//  ExponentialInsulinModelPreset.swift
//  Loop
//
//  Copyright © 2017 LoopKit Authors. All rights reserved.
//

import LoopKit


public enum ExponentialInsulinModelPreset: String {
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


extension ExponentialInsulinModelPreset: InsulinModel {
    public var effectDuration: TimeInterval {
        return model.effectDuration
    }

    public func percentEffectRemaining(at time: TimeInterval) -> Double {
        return model.percentEffectRemaining(at: time)
    }
}


extension ExponentialInsulinModelPreset: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(self.rawValue)(\(String(reflecting: model))"
    }
}
