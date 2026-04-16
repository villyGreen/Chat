//
//  Created by Alex.M on 02.10.2023.
//

import Foundation
import Combine
import UIKit
import SwiftUI

public final class KeyboardState: ObservableObject {
    @Published private(set) public var isShown: Bool = false
    @Published private(set) public var keyboardFrame: CGRect = .zero
    
    private var subscriptions = Set<AnyCancellable>()

    init() {
        subscribeKeyboardNotifications()
    }

    /// Requests the dismissal of the current / active keyboard
    public func resignFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private extension KeyboardState {
    func subscribeKeyboardNotifications() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self,
                      let userInfo = notification.userInfo,
                      let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
                let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
                let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt) ?? 7
                let curve = UIView.AnimationCurve(rawValue: Int(curveRaw)) ?? .easeInOut
                withAnimation(.interpolatingSpring(duration: duration, bounce: curve == .easeInOut ? 0 : 0.05)) {
                    self.keyboardFrame = frame
                    self.isShown = true
                }
            }
            .store(in: &subscriptions)

        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let self else { return }
                let duration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
                withAnimation(.interpolatingSpring(duration: duration, bounce: 0)) {
                    self.keyboardFrame = .zero
                    self.isShown = false
                }
            }
            .store(in: &subscriptions)
    }
}
