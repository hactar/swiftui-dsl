import MapLibre
import UIKit
import XCTest
@testable import MapLibreSwiftUI

final class MapViewControlGestureTests: XCTestCase {
    @MainActor
    func testMapGesturesLeaveControlsAndTheirSubviewsToTheirOwnActions() throws {
        let (map, coordinator, gestures) = try makeMapGestures()
        let button = UIButton(type: .system)
        let label = UILabel()
        button.addSubview(label)
        map.addSubview(button)

        for gesture in gestures {
            XCTAssertFalse(receivesTouch(gesture, on: map.attributionButton))
            XCTAssertFalse(receivesTouch(gesture, on: button))
            XCTAssertFalse(receivesTouch(gesture, on: label))
        }
        withExtendedLifetime(coordinator) {}
    }

    @MainActor
    func testOrdinaryMapContentStillReceivesTapAndLongPress() throws {
        let (map, coordinator, gestures) = try makeMapGestures()
        let content = UIView()
        let label = UILabel()
        content.addSubview(label)
        map.addSubview(content)

        for gesture in gestures {
            XCTAssertTrue(receivesTouch(gesture, on: map))
            XCTAssertTrue(receivesTouch(gesture, on: content))
            XCTAssertTrue(receivesTouch(gesture, on: label))
            XCTAssertTrue(receivesTouch(gesture, on: nil))
            XCTAssertTrue(gesture.cancelsTouchesInView)
        }
        withExtendedLifetime(coordinator) {}
    }

    @MainActor
    func testRestoredMapGesturesKeepControlFilteringWithoutChangingNativeDelegates() throws {
        let (map, coordinator, _) = try makeMapGestures()
        let unmanaged = UIPanGestureRecognizer()
        let nativeDelegate = NativeGestureDelegate()
        unmanaged.delegate = nativeDelegate
        map.addGestureRecognizer(unmanaged)
        coordinator.syncGestures(on: map, gestures: [])
        coordinator.restoreGestures(on: map, gestures: [
            MapGesture(method: .tap(numberOfTaps: 1), onChange: .context { _ in }),
            MapGesture(method: .longPress(minimumDuration: 0.5), onChange: .context { _ in }),
        ])

        XCTAssertTrue(unmanaged.delegate === nativeDelegate)
        XCTAssertTrue(map.gestureRecognizers?.contains(unmanaged) == true)
        XCTAssertEqual(coordinator.managedGestureRecognizers.count, 2)
        for gesture in coordinator.managedGestureRecognizers {
            XCTAssertFalse(receivesTouch(gesture, on: map.attributionButton))
        }
    }

    @MainActor
    private func makeMapGestures() throws -> (
        MLNMapView, MapViewCoordinator<MLNMapViewController>, [UIGestureRecognizer]
    ) {
        let view = try MapView(styleURL: XCTUnwrap(URL(string: "https://maplibre.org")))
        let coordinator = view.makeCoordinator()
        let map = MLNMapView()
        coordinator.syncGestures(on: map, gestures: [
            MapGesture(method: .tap(numberOfTaps: 1), onChange: .context { _ in }),
            MapGesture(method: .longPress(minimumDuration: 0.5), onChange: .context { _ in }),
        ])
        return (map, coordinator, coordinator.managedGestureRecognizers)
    }

    @MainActor
    private func receivesTouch(_ recognizer: UIGestureRecognizer, on view: UIView?) -> Bool {
        recognizer.delegate?.gestureRecognizer?(recognizer, shouldReceive: GestureViewTouch(view: view)) ?? true
    }
}

@MainActor
private final class GestureViewTouch: UITouch {
    private let touchedView: UIView?

    init(view: UIView?) {
        touchedView = view
        super.init()
    }

    override var view: UIView? {
        touchedView
    }
}

@MainActor
private final class NativeGestureDelegate: NSObject, UIGestureRecognizerDelegate {}
