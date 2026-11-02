import CoreLocation
import MapLibre
import Mockable
import SwiftUI
import XCTest
@testable import MapLibreSwiftUI

final class MapViewCoordinatorCameraTests: XCTestCase {
    var maplibreMapView: MockMLNMapViewRepresentable!
    var simulatedFrame = CGRect.zero
    var simulatedContentInset = UIEdgeInsets.zero
    var mapView: MapView<MLNMapViewController>!
    var coordinator: MapView<MLNMapViewController>.Coordinator!

    @MainActor
    override func setUp() async throws {
        maplibreMapView = MockMLNMapViewRepresentable()
        given(maplibreMapView).frame.willProduce { [unowned self] in simulatedFrame }
        given(maplibreMapView).contentInset.willProduce { [unowned self] in simulatedContentInset }
        mapView = MapView(styleURL: URL(string: "https://maplibre.org")!)
        coordinator = MapView.Coordinator(
            parent: mapView,
            onGesture: { _, _ in
                // No action
            },
            onViewProxyChanged: { _ in
                // No action
            }, proxyUpdateMode: .onFinish
        )
    }

    @MainActor func testUnchangedCamera() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 45.0, longitude: -127.0)
        let camera: MapViewCamera = .center(coordinate, zoom: 10)

        given(maplibreMapView)
            .setCenter(
                .any,
                zoomLevel: .any,
                direction: .any,
                animated: .any
            )
            .willReturn()

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView, camera: camera, animated: false
            )
        }

        coordinator.applyCameraChangeFromStateUpdate(
            maplibreMapView, camera: camera, animated: false
        )

        // All of the actions only allow 1 count of set even though we've run the action twice.
        // This verifies the comment above.
        verify(maplibreMapView)
            .userTrackingMode(newValue: .value(.none))
            .setCalled(1)

        verify(maplibreMapView)
            .setCenter(
                .value(coordinate),
                zoomLevel: .value(10),
                direction: .value(0),
                animated: .value(false)
            )
            .called(1)

        // Due to the .frame == .zero workaround, min/max pitch setting is called twice, once to set the
        // pitch, and then once to set the actual range.
        verify(maplibreMapView)
            .minimumPitch(newValue: .value(0))
            .setCalled(2)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(0))
            .setCalled(1)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(60))
            .setCalled(1)

        verify(maplibreMapView)
            .setZoomLevel(.any, animated: .any)
            .called(0)
    }

    @MainActor func testCenterCameraUpdate() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 12.3, longitude: 23.4)
        let newCamera: MapViewCamera = .center(coordinate, zoom: 13)

        given(maplibreMapView)
            .setCenter(
                .any,
                zoomLevel: .any,
                direction: .any,
                animated: .any
            )
            .willReturn()

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView, camera: newCamera, animated: false
            )
        }

        verify(maplibreMapView)
            .userTrackingMode(newValue: .value(.none))
            .setCalled(1)

        verify(maplibreMapView)
            .setCenter(
                .value(coordinate),
                zoomLevel: .value(13),
                direction: .value(0),
                animated: .value(false)
            )
            .called(1)

        // Due to the .frame == .zero workaround, min/max pitch setting is called twice, once to set the
        // pitch, and then once to set the actual range.
        verify(maplibreMapView)
            .minimumPitch(newValue: .value(0))
            .setCalled(2)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(0))
            .setCalled(1)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(60))
            .setCalled(1)

        verify(maplibreMapView)
            .setZoomLevel(.any, animated: .any)
            .called(0)
    }

    @MainActor func testUserTrackingCameraUpdate() async throws {
        let newCamera: MapViewCamera = .trackUserLocation()

        given(maplibreMapView)
            .setZoomLevel(.any, animated: .any)
            .willReturn()

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView, camera: newCamera, animated: false
            )
        }

        verify(maplibreMapView)
            .userTrackingMode(newValue: .value(.follow))
            .setCalled(1)

        verify(maplibreMapView)
            .setCenter(
                .any,
                zoomLevel: .any,
                direction: .any,
                animated: .any
            )
            .called(0)

        // Due to the .frame == .zero workaround, min/max pitch setting is called twice, once to set the
        // pitch, and then once to set the actual range.
        verify(maplibreMapView)
            .minimumPitch(newValue: .value(0))
            .setCalled(2)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(0))
            .setCalled(1)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(60))
            .setCalled(1)

        verify(maplibreMapView)
            .zoomLevel(newValue: .value(10))
            .setCalled(1)
    }

    @MainActor func testUserTrackingWithCourseCameraUpdate() async throws {
        let newCamera: MapViewCamera = .trackUserLocationWithCourse()

        given(maplibreMapView)
            .setZoomLevel(.any, animated: .any)
            .willReturn()

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView, camera: newCamera, animated: false
            )
        }

        verify(maplibreMapView)
            .userTrackingMode(newValue: .value(.followWithCourse))
            .setCalled(1)

        verify(maplibreMapView)
            .setCenter(
                .any,
                zoomLevel: .any,
                direction: .any,
                animated: .any
            )
            .called(0)

        // Due to the .frame == .zero workaround, min/max pitch setting is called twice, once to set the
        // pitch, and then once to set the actual range.
        verify(maplibreMapView)
            .minimumPitch(newValue: .value(0))
            .setCalled(2)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(0))
            .setCalled(1)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(60))
            .setCalled(1)

        verify(maplibreMapView)
            .zoomLevel(newValue: .value(10))
            .setCalled(1)
    }

    @MainActor func testUserTrackingWithHeadingUpdate() async throws {
        let newCamera: MapViewCamera = .trackUserLocationWithHeading()

        given(maplibreMapView)
            .setZoomLevel(.any, animated: .any)
            .willReturn()

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView, camera: newCamera, animated: false
            )
        }

        verify(maplibreMapView)
            .userTrackingMode(newValue: .value(.followWithHeading))
            .setCalled(1)

        verify(maplibreMapView)
            .setCenter(
                .any,
                zoomLevel: .any,
                direction: .any,
                animated: .any
            )
            .called(0)

        // Due to the .frame == .zero workaround, min/max pitch setting is called twice, once to set the
        // pitch, and then once to set the actual range.
        verify(maplibreMapView)
            .minimumPitch(newValue: .value(0))
            .setCalled(2)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(0))
            .setCalled(1)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(60))
            .setCalled(1)

        verify(maplibreMapView)
            .zoomLevel(newValue: .value(10))
            .setCalled(1)
    }

    @MainActor func testShowcaseCameraUpdate() async throws {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 45.0, longitude: -127.0),
            CLLocationCoordinate2D(latitude: 45.2, longitude: -127.3),
        ]
        let shapeCollection = MLNShapeCollection(shapes: [MLNPolylineFeature(coordinates: coordinates)])
        let contentInset = UIEdgeInsets(top: 11, left: 22, bottom: 33, right: 44)
        let newCamera: MapViewCamera = .showcase(shapeCollection: shapeCollection, edgePadding: contentInset)
        let fittedCamera = MLNMapCamera()

        given(maplibreMapView)
            .cameraThatFitsShape(
                .any,
                direction: .any,
                edgePadding: .any
            )
            .willReturn(fittedCamera)

        given(maplibreMapView)
            .setCamera(.any, animated: .any)
            .willReturn()

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView, camera: newCamera, animated: false
            )
        }

        verify(maplibreMapView)
            .userTrackingMode(newValue: .value(.none))
            .setCalled(1)

        verify(maplibreMapView)
            .minimumPitch(newValue: .value(0))
            .setCalled(1)

        verify(maplibreMapView)
            .maximumPitch(newValue: .value(0))
            .setCalled(1)

        verify(maplibreMapView)
            .direction(newValue: .value(0))
            .setCalled(1)

        verify(maplibreMapView)
            .cameraThatFitsShape(
                .any,
                direction: .value(0),
                edgePadding: .value(contentInset)
            )
            .called(1)

        verify(maplibreMapView)
            .setCamera(.any, animated: .value(false))
            .called(1)

        verify(maplibreMapView)
            .setVisibleCoordinateBounds(
                .any,
                edgePadding: .any,
                animated: .any,
                completionHandler: .any
            )
            .called(0)
    }

    @MainActor func testShowcaseUnchangedCameraSkipsSecondUpdate() async throws {
        let coordinates = [
            CLLocationCoordinate2D(latitude: 45.0, longitude: -127.0),
            CLLocationCoordinate2D(latitude: 45.2, longitude: -127.3),
        ]
        let shapeCollection = MLNShapeCollection(shapes: [MLNPolylineFeature(coordinates: coordinates)])
        let camera: MapViewCamera = .showcase(shapeCollection: shapeCollection)
        let fittedCamera = MLNMapCamera()

        given(maplibreMapView)
            .cameraThatFitsShape(
                .any,
                direction: .any,
                edgePadding: .any
            )
            .willReturn(fittedCamera)

        given(maplibreMapView)
            .setCamera(.any, animated: .any)
            .willReturn()

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView, camera: camera, animated: false
            )
        }

        coordinator.applyCameraChangeFromStateUpdate(
            maplibreMapView, camera: camera, animated: false
        )

        verify(maplibreMapView)
            .cameraThatFitsShape(.any, direction: .any, edgePadding: .any)
            .called(1)

        verify(maplibreMapView)
            .setCamera(.any, animated: .any)
            .called(1)
    }

    @MainActor func testShowcaseRefitsAfterSizeAndInsetChanges() async throws {
        let shape = MLNShapeCollection(shapes: [MLNPointFeature(coordinate: .init(latitude: 45, longitude: -127))])
        let camera = MapViewCamera.showcase(shapeCollection: shape)
        coordinator.parent = try MapView(
            styleURL: XCTUnwrap(URL(string: "https://maplibre.org")),
            camera: .constant(camera)
        )
        simulatedFrame = CGRect(x: 0, y: 0, width: 320, height: 640)
        given(maplibreMapView).cameraThatFitsShape(.any, direction: .any, edgePadding: .any).willReturn(MLNMapCamera())
        given(maplibreMapView).setCamera(.any, animated: .any).willReturn()
        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(self.maplibreMapView, camera: camera, animated: false)
        }

        simulatedFrame = CGRect(x: 0, y: 0, width: 640, height: 320)
        try await simulateCameraUpdateAndWait { self.coordinator.refitCameraAfterLayout(
            self.maplibreMapView,
            cameraUpdatesEnabled: true
        ) }
        coordinator.refitCameraAfterLayout(maplibreMapView, cameraUpdatesEnabled: true)
        verify(maplibreMapView).setCamera(.any, animated: .any).called(2)

        simulatedContentInset = UIEdgeInsets(top: 20, left: 200, bottom: 10, right: 10)
        try await simulateCameraUpdateAndWait { self.coordinator.refitCameraAfterLayout(
            self.maplibreMapView,
            cameraUpdatesEnabled: true
        ) }
        coordinator.refitCameraAfterLayout(maplibreMapView, cameraUpdatesEnabled: true)
        verify(maplibreMapView).setCamera(.any, animated: .any).called(3)
    }

    @MainActor func testLayoutLeavesCameraAloneWhenUpdatesAreDisabled() async throws {
        let shape = MLNShapeCollection(shapes: [MLNPointFeature(coordinate: .init(latitude: 45, longitude: -127))])
        let camera = MapViewCamera.showcase(shapeCollection: shape)
        coordinator.parent = try MapView(
            styleURL: XCTUnwrap(URL(string: "https://maplibre.org")),
            camera: .constant(camera)
        )
        simulatedFrame = CGRect(x: 0, y: 0, width: 320, height: 640)
        given(maplibreMapView).cameraThatFitsShape(.any, direction: .any, edgePadding: .any).willReturn(MLNMapCamera())
        given(maplibreMapView).setCamera(.any, animated: .any).willReturn()
        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(self.maplibreMapView, camera: camera, animated: false)
        }
        simulatedFrame = CGRect(x: 0, y: 0, width: 640, height: 320)
        coordinator.refitCameraAfterLayout(maplibreMapView, cameraUpdatesEnabled: false)
        verify(maplibreMapView).setCamera(.any, animated: .any).called(1)
    }

    @MainActor func testBoundsRefitsAfterSizeChange() async throws {
        let bounds = MLNCoordinateBounds(
            sw: .init(latitude: 45, longitude: -127),
            ne: .init(latitude: 46, longitude: -126)
        )
        let camera = MapViewCamera.boundingBox(bounds)
        coordinator.parent = try MapView(
            styleURL: XCTUnwrap(URL(string: "https://maplibre.org")),
            camera: .constant(camera)
        )
        simulatedFrame = CGRect(x: 0, y: 0, width: 320, height: 640)
        given(maplibreMapView).setVisibleCoordinateBounds(
            .any,
            edgePadding: .any,
            animated: .any,
            completionHandler: .any
        ).willReturn()
        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(self.maplibreMapView, camera: camera, animated: false)
        }
        simulatedFrame = CGRect(x: 0, y: 0, width: 640, height: 320)
        try await simulateCameraUpdateAndWait { self.coordinator.refitCameraAfterLayout(
            self.maplibreMapView,
            cameraUpdatesEnabled: true
        ) }
        coordinator.refitCameraAfterLayout(maplibreMapView, cameraUpdatesEnabled: true)
        verify(maplibreMapView).setVisibleCoordinateBounds(
            .any,
            edgePadding: .any,
            animated: .any,
            completionHandler: .any
        ).called(2)
    }

    @MainActor func testLayoutDoesNotReapplyFitAfterCameraIntentChanges() async throws {
        let shape = MLNShapeCollection(shapes: [MLNPointFeature(coordinate: .init(latitude: 45, longitude: -127))])
        let camera = MapViewCamera.showcase(shapeCollection: shape)
        coordinator.parent = try MapView(
            styleURL: XCTUnwrap(URL(string: "https://maplibre.org")),
            camera: .constant(camera)
        )
        simulatedFrame = CGRect(x: 0, y: 0, width: 320, height: 640)
        given(maplibreMapView).cameraThatFitsShape(.any, direction: .any, edgePadding: .any).willReturn(MLNMapCamera())
        given(maplibreMapView).setCamera(.any, animated: .any).willReturn()
        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(self.maplibreMapView, camera: camera, animated: false)
        }
        let pannedCamera = MapViewCamera.center(.init(latitude: 44, longitude: -125), zoom: 12, reason: .gesturePan)
        coordinator.parent = try MapView(
            styleURL: XCTUnwrap(URL(string: "https://maplibre.org")),
            camera: .constant(pannedCamera)
        )
        simulatedFrame = CGRect(x: 0, y: 0, width: 640, height: 320)
        coordinator.refitCameraAfterLayout(maplibreMapView, cameraUpdatesEnabled: true)
        verify(maplibreMapView).setCamera(.any, animated: .any).called(1)
    }

    @MainActor func testDisabledTransactionAppliesImmediateCameraUpdate() async throws {
        given(maplibreMapView).setCenter(.any, zoomLevel: .any, direction: .any, animated: .any).willReturn()
        var disabledTransaction = Transaction()
        disabledTransaction.disablesAnimations = true
        let transaction = disabledTransaction

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView,
                camera: .center(.init(latitude: 45, longitude: -127), zoom: 12),
                animated: true,
                transaction: transaction
            )
        }

        verify(maplibreMapView).setCenter(.any, zoomLevel: .any, direction: .any, animated: .value(false)).called(1)
        verify(maplibreMapView).setCenter(.any, zoomLevel: .any, direction: .any, animated: .value(true)).called(0)
    }

    @MainActor func testOrdinaryTransactionRetainsCameraAnimation() async throws {
        given(maplibreMapView).setCenter(.any, zoomLevel: .any, direction: .any, animated: .any).willReturn()

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView,
                camera: .center(.init(latitude: 45, longitude: -127), zoom: 12),
                animated: true,
                transaction: Transaction()
            )
        }

        verify(maplibreMapView).setCenter(.any, zoomLevel: .any, direction: .any, animated: .value(true)).called(1)
        verify(maplibreMapView).setCenter(.any, zoomLevel: .any, direction: .any, animated: .value(false)).called(0)
    }

    @MainActor func testSupersededCameraTaskDoesNotApplyItsOldViewport() async throws {
        given(maplibreMapView).setCenter(.any, zoomLevel: .any, direction: .any, animated: .any).willReturn()
        let obsolete = CLLocationCoordinate2D(latitude: 45, longitude: -127)
        let current = CLLocationCoordinate2D(latitude: 46, longitude: -126)

        // Both binding changes arrive before the main actor executes either
        // native update. Only the still-current request may move the map.
        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView, camera: .center(obsolete, zoom: 12), animated: false
            )
            self.coordinator.applyCameraChangeFromStateUpdate(
                self.maplibreMapView, camera: .center(current, zoom: 13), animated: false
            )
        }

        verify(maplibreMapView).setCenter(.value(obsolete), zoomLevel: .any, direction: .any, animated: .any).called(0)
        verify(maplibreMapView).setCenter(
            .value(current),
            zoomLevel: .value(13),
            direction: .any,
            animated: .value(false)
        ).called(1)
    }

    @MainActor func testSupersededGestureTaskCannotOverwriteANewerBinding() async throws {
        given(maplibreMapView).setCenter(.any, zoomLevel: .any, direction: .any, animated: .any).willReturn()
        given(maplibreMapView).centerCoordinate.willReturn(.init(latitude: 45, longitude: -127))
        given(maplibreMapView).zoomLevel.willReturn(12)
        given(maplibreMapView).direction.willReturn(0)
        given(maplibreMapView).minimumPitch.willReturn(0)
        given(maplibreMapView).maximumPitch.willReturn(60)
        given(maplibreMapView).camera.willReturn(MLNMapCamera())
        var boundCamera = MapViewCamera.default()
        let current = MapViewCamera.center(.init(latitude: 46, longitude: -126), zoom: 13, reason: .programmatic)
        coordinator.parent = try MapView(
            styleURL: XCTUnwrap(URL(string: "https://maplibre.org")),
            camera: Binding(get: { boundCamera }, set: { boundCamera = $0 })
        )

        try await simulateCameraUpdateAndWait {
            self.coordinator.applyCameraChangeFromGesture(self.maplibreMapView, reason: .gesturePan)
            boundCamera = current
            self.coordinator.applyCameraChangeFromStateUpdate(self.maplibreMapView, camera: current, animated: false)
        }

        XCTAssertEqual(boundCamera, current)
    }

    @MainActor
    private func simulateCameraUpdateAndWait(action: @escaping () -> Void) async throws {
        // Stage 1: Execute camera action and wait for continuation wiring.
        action()

        let pollIntervalNs = 100 * NSEC_PER_MSEC
        let continuationTimeoutNs = 500 * NSEC_PER_MSEC
        var waitedNs: UInt64 = 0

        while coordinator.cameraUpdateContinuation == nil && waitedNs < continuationTimeoutNs {
            try await Task.sleep(nanoseconds: pollIntervalNs)
            waitedNs += UInt64(pollIntervalNs)
        }

        guard let continuation = coordinator.cameraUpdateContinuation else {
            XCTFail("Stage 1 timeout: cameraUpdateContinuation was never set")
            return
        }

        // Stage 2: Resume continuation and verify cameraUpdateTask completes.
        continuation.resume(returning: ())
        coordinator.cameraUpdateContinuation = nil

        let taskCompletionExpectation = XCTestExpectation(
            description: "Stage 2: cameraUpdateTask completes after continuation resume"
        )

        Task { @MainActor in
            _ = await coordinator.cameraUpdateTask?.value
            taskCompletionExpectation.fulfill()
        }

        await fulfillment(of: [taskCompletionExpectation], timeout: 1.0)
        coordinator.cameraUpdateTask = nil
    }
}
