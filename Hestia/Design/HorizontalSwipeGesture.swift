import SwiftUI
import UIKit

/// Waagrechtes Wischen, das nur beginnt, wenn die Bewegung überwiegend waagrecht ist (ab Phase 18.5, Monat wechseln
/// im `MonthCalendar`). Senkrecht bleibt die Bewegung beim Scrollen der Seite. Waagrecht hat es Vorrang vor dem
/// Zurück-Wischen der Navigation, das unter iOS 26 auf der ganzen Seite gilt: dieses wartet, bis das Wischen
/// gescheitert ist. `onEnded` bekommt den waagrechten Weg (negativ = nach links).
struct HorizontalSwipeGesture: UIGestureRecognizerRepresentable {
    let onEnded: (CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        if recognizer.state == .ended {
            onEnded(recognizer.translation(in: recognizer.view).x)
        }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
            guard let pan = recognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        /// Andere Wischgesten außer dem Scrollen (vor allem das Zurück der Navigation) warten auf dieses Wischen.
        func gestureRecognizer(
            _ recognizer: UIGestureRecognizer, shouldBeRequiredToFailBy other: UIGestureRecognizer
        ) -> Bool {
            other is UIPanGestureRecognizer && !(other.view is UIScrollView)
        }
    }
}
