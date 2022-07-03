//
//  BolusConfirmationView.swift
//  WatchApp Extension
//
//  Created by Michael Pangburn on 3/27/20.
//  Copyright © 2020 LoopKit Authors. All rights reserved.
//

import Combine
import SwiftUI


struct BolusConfirmationView: View {
    // Strictly for storage. Use `progress` to access the underlying value.
    @Binding private var progressStorage: Double

    private let completion: () -> Void
    private let resetProgress = PeriodicPublisher(interval: 0.25)

    private var progress: Binding<Double> {
        Binding(
            get: { self.progressStorage.clamped(to: -1...1) },
            set: { newValue in
                // Prevent further state changes after completion.
                guard abs(self.progressStorage) < 1.0 else {
                    return
                }

                withAnimation {
                    self.progressStorage = newValue
                }

                self.resetProgress.acknowledge()
                if abs(newValue) >= 1.0 {
                    WKInterfaceDevice.current().play(.success)
                    self.completion()
                }
            }
        )
    }

    init(progress: Binding<Double>, onConfirmation completion: @escaping () -> Void) {
        self._progressStorage = progress
        self.completion = completion
    }

    var body: some View {
        VStack(spacing: 8) {
            ActionButton(title: Text("Confirm"), color: .red) {
                self.completion()
            }
        }
        .focusable()
    }

    private var isFinished: Bool { abs(progress.wrappedValue) >= 1.0 }

    private var helpText: some View {
        Text("Turn Digital Crown\nto bolus", comment: "Help text for bolus confirmation on Apple Watch")
            .font(.footnote)
            .multilineTextAlignment(.center)
            .foregroundColor(Color(.lightGray))
            .fixedSize(horizontal: false, vertical: true)
            .opacity(isFinished ? 0 : 1)
    }
}
