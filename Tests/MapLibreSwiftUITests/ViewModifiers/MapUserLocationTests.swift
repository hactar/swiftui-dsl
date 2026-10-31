import CoreLocation
import MapLibre
import XCTest
@testable import MapLibreSwiftUI

final class MapUserLocationTests: XCTestCase {
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
