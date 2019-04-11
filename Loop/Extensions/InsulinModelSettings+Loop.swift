//
//  InsulinModelSettings+Loop.swift
//  Loop
//
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import LoopCore
import LoopKit


extension InsulinModelSettings {
    var title: String {
        switch self {
        case .exponentialPreset(let model):
            return model.title
        case .walsh(let model):
            return model.title
        }
    }
}


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
            return NSLocalizedString("Duration: 4h, Peak: 60", comment: "Subtitle of Exponential Novolog Long preset")
        case .humalogNovologChild:
            return NSLocalizedString("Duration: 3.5h, Peak: 60", comment: "Subtitle of Exponential Novolog Normal preset")
        case .fiasp:
            return NSLocalizedString("Duration: 4h, Peak: 55", comment: "Subtitle of Exponential Fiasp preset")
        }
    }
}


extension WalshInsulinModel {
    var title: String {
        return NSLocalizedString("Walsh", comment: "Title of insulin model setting")
    }

    var subtitle: String {
        return NSLocalizedString("The legacy model used by Loop, allowing customization of action duration.", comment: "Subtitle description of Walsh insulin model setting")
    }
}
