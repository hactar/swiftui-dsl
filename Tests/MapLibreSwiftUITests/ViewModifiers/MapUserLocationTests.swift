import CoreLocation
import MapLibre
import SwiftUI
import XCTest
@testable import MapLibreSwiftUI

final class MapUserLocationTests: XCTestCase {
    @MainActor func testShowingLocationReappliesUnchangedFollowCamera() async throws {
        let camera = MapViewCamera.trackUserLocation()
        let map = MLNMapView()
        map.locationManager = RecordingLocationManager()
        let coordinator = try makeCoordinator(camera: camera)
        map.delegate = coordinator

        coordinator.updateUserLocation(
            on: map,
            configuration: locationConfiguration(true),
            didInstallLocationManager: false
        )
        await applyFollowCamera(camera, on: map, coordinator: coordinator)

        coordinator.updateUserLocation(
            on: map,
            configuration: locationConfiguration(false),
            didInstallLocationManager: false
        )
        coordinator.applyCameraChangeFromStateUpdate(map, camera: camera, animated: false)
        XCTAssertFalse(map.showsUserLocation)
        XCTAssertEqual(map.userTrackingMode, .none)

        coordinator.updateUserLocation(
            on: map,
            configuration: locationConfiguration(true),
            didInstallLocationManager: false
        )
        await applyFollowCamera(camera, on: map, coordinator: coordinator)
        XCTAssertEqual(map.userTrackingMode, .follow)
    }

    @MainActor func testHidingLocationDefersTrackingCallback() async throws {
        let map = MLNMapView()
        map.locationManager = RecordingLocationManager()
        let coordinator = try makeCoordinator()
        map.delegate = coordinator
        coordinator.updateUserLocation(
            on: map,
            configuration: locationConfiguration(true),
            didInstallLocationManager: false
        )
        map.userTrackingMode = .follow
        XCTAssertEqual(map.userTrackingMode, .follow)

        let delivered = expectation(description: "Tracking callback after the visibility update")
        var isUpdating = true
        coordinator.onUserTrackingModeChange = { mode, _ in
            XCTAssertFalse(isUpdating)
            XCTAssertEqual(mode, .none)
            delivered.fulfill()
        }

        coordinator.updateUserLocation(
            on: map,
            configuration: locationConfiguration(false),
            didInstallLocationManager: false
        )
        isUpdating = false
        XCTAssertEqual(map.userTrackingMode, .none)
        await fulfillment(of: [delivered], timeout: 1)
        coordinator.onUserTrackingModeChange = nil
    }

    @MainActor func testInstallingManagerWhileLocationStaysVisibleRestartsItOnce() throws {
        let map = MLNMapView()
        map.locationManager = RecordingLocationManager()
        locationConfiguration(true).apply(to: map)
        let manager = RecordingLocationManager()
        map.locationManager = manager
        map.locationManager = map.locationManager
        let coordinator = try makeCoordinator()

        coordinator.updateUserLocation(
            on: map,
            configuration: locationConfiguration(true),
            didInstallLocationManager: true
        )

        XCTAssertTrue(map.locationManager === manager)
        XCTAssertEqual(manager.locationStarts, 1)
        XCTAssertEqual(manager.authorizationRequests, 0)
        coordinator.updateUserLocation(
            on: map,
            configuration: locationConfiguration(true),
            didInstallLocationManager: false
        )
        XCTAssertEqual(manager.locationStarts, 1)
    }

    @MainActor private func makeCoordinator(camera: MapViewCamera = .default()) throws
        -> MapViewCoordinator<MLNMapViewController>
    {
        try MapViewCoordinator(
            parent: MapView(
                styleURL: XCTUnwrap(URL(string: "https://maplibre.org")),
                camera: .constant(camera)
            ),
            onGesture: { _, _ in },
            onViewProxyChanged: { _ in },
            proxyUpdateMode: .onFinish
        )
    }

    @MainActor private func applyFollowCamera(
        _ camera: MapViewCamera,
        on map: MLNMapView,
        coordinator: MapViewCoordinator<MLNMapViewController>
    ) async {
        let followed = expectation(description: "Native map starts following")
        coordinator.onUserTrackingModeChange = { mode, _ in
            if mode == .follow {
                followed.fulfill()
            }
        }
        coordinator.applyCameraChangeFromStateUpdate(map, camera: camera, animated: false)
        await fulfillment(of: [followed], timeout: 1)
        coordinator.onUserTrackingModeChange = nil
        coordinator.mapViewDidBecomeIdle(map)
    }

    private func locationConfiguration(_ isVisible: Bool) -> MapUserLocationConfiguration {
        MapUserLocationConfiguration(isVisible: isVisible, showsHeading: false, requestsAuthorization: false)
    }

    @MainActor func testLocationPresentationUsesInstalledManagerWithoutRequestingPermission() {
        let manager = RecordingLocationManager()
        let map = MLNMapView()
        map.locationManager = manager

        MapUserLocationConfiguration(isVisible: true, showsHeading: true, requestsAuthorization: false)
            .apply(to: map)

        XCTAssertTrue(map.showsUserLocation)
        XCTAssertTrue(map.showsUserHeadingIndicator)
        XCTAssertFalse(map.shouldRequestAuthorizationToUseLocationServices)
        XCTAssertTrue(map.locationManager === manager)
        XCTAssertGreaterThan(manager.locationStarts, 0)
        XCTAssertEqual(manager.authorizationRequests, 0)
        let starts = manager.locationStarts
        let headingStarts = manager.headingStarts
        MapUserLocationConfiguration(isVisible: true, showsHeading: true, requestsAuthorization: false)
            .apply(to: map)
        XCTAssertEqual(manager.locationStarts, starts, "Unchanged SwiftUI updates must not restart location updates")
        XCTAssertEqual(
            manager.headingStarts,
            headingStarts,
            "Unchanged SwiftUI updates must not restart heading updates"
        )

        MapUserLocationConfiguration(isVisible: false, showsHeading: false, requestsAuthorization: false)
            .apply(to: map)

        XCTAssertFalse(map.showsUserLocation)
        XCTAssertFalse(map.showsUserHeadingIndicator)
        XCTAssertGreaterThan(manager.locationStops, 0)
        XCTAssertEqual(manager.authorizationRequests, 0)
    }

    @MainActor func testHiddenLocationTakesPrecedenceOverHeadingDisplay() {
        let manager = RecordingLocationManager()
        let map = MLNMapView()
        map.locationManager = manager
        MapUserLocationConfiguration(isVisible: false, showsHeading: true, requestsAuthorization: false)
            .apply(to: map)
        XCTAssertFalse(map.showsUserLocation)
        XCTAssertFalse(map.showsUserHeadingIndicator)
        XCTAssertEqual(manager.locationStarts, 0)
        XCTAssertEqual(manager.headingStarts, 0)
    }

    @MainActor func testHostOwnedPermissionDoesNotPromptForAnUndeterminedSource() {
        let manager = RecordingLocationManager()
        manager.authorizationStatus = .notDetermined
        let map = MLNMapView()
        map.locationManager = manager
        MapUserLocationConfiguration(isVisible: true, showsHeading: false, requestsAuthorization: false)
            .apply(to: map)
        XCTAssertEqual(manager.authorizationRequests, 0)
    }

    @MainActor func testEnablingLocationDoesNotChooseCameraTrackingMode() {
        let map = MLNMapView()
        map.locationManager = RecordingLocationManager()
        let initialMode = map.userTrackingMode
        MapUserLocationConfiguration(isVisible: true, showsHeading: false, requestsAuthorization: false)
            .apply(to: map)
        XCTAssertEqual(map.userTrackingMode, initialMode)
    }
}

@MainActor
private final class RecordingLocationManager: NSObject, @preconcurrency MLNLocationManager {
    weak var delegate: MLNLocationManagerDelegate?
    var headingOrientation: CLDeviceOrientation = .portrait
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    var locationStarts = 0
    var locationStops = 0
    var headingStarts = 0
    var authorizationRequests = 0
    func requestAlwaysAuthorization() {
        authorizationRequests += 1
    }

    func requestWhenInUseAuthorization() {
        authorizationRequests += 1
    }

    func startUpdatingLocation() {
        locationStarts += 1
    }

    func stopUpdatingLocation() {
        locationStops += 1
    }

    func startUpdatingHeading() {
        headingStarts += 1
    }

    func stopUpdatingHeading() {}
    func dismissHeadingCalibrationDisplay() {}
}
