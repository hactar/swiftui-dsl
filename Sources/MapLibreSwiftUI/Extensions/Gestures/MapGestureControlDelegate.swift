import UIKit

/// Map gestures must not cancel a control's own action or turn it into a map tap.
@MainActor
final class MapGestureControlDelegate: NSObject, @preconcurrency UIGestureRecognizerDelegate {
    func gestureRecognizer(_: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let candidate = view {
            if candidate is UIControl {
                return false
            }
            view = candidate.superview
        }
        return true
    }
}
