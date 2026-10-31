import MapLibre
import SwiftUI

struct MapUserLocationConfiguration: Equatable, Sendable {
    let isVisible: Bool
    let showsHeading: Bool
    let requestsAuthorization: Bool

    @MainActor func apply(to mapView: MLNMapView) {
        // Set the permission policy before enabling location presentation, which
        // may start the installed location manager immediately.
        mapView.shouldRequestAuthorizationToUseLocationServices = requestsAuthorization
        mapView.showsUserLocation = isVisible
        // Native's heading setter also enables location display. Hidden location
        // therefore takes precedence, even when heading display was requested.
        let effectiveHeading = isVisible && showsHeading
        if mapView.showsUserHeadingIndicator != effectiveHeading {
            mapView.showsUserHeadingIndicator = effectiveHeading
        }
    }
}

private struct MapUserLocationConfigurationKey: EnvironmentKey {
    static let defaultValue: MapUserLocationConfiguration? = nil
}

extension EnvironmentValues {
    var mapUserLocationConfiguration: MapUserLocationConfiguration? {
        get { self[MapUserLocationConfigurationKey.self] }
        set { self[MapUserLocationConfigurationKey.self] = newValue }
    }
}

private struct MapUserLocationViewModifier: ViewModifier {
    let configuration: MapUserLocationConfiguration

    func body(content: Content) -> some View {
        content.environment(\.mapUserLocationConfiguration, configuration)
    }
}

public extension View {
    /// Controls the map's user-location annotation independently of camera tracking.
    ///
    /// The configured location manager is installed before this modifier is applied.
    /// Set `requestsAuthorization` to `false` when the application manages permission
    /// requests itself, including when injecting a shared or simulated location manager.
    /// This modifier does not grant location permission or choose a camera position.
    /// Hiding location also hides its heading indicator. As in MapLibre Native,
    /// hiding location ends native user tracking; a camera tracking mode can enable
    /// location display again.
    ///
    /// - Parameters:
    ///   - isVisible: Whether to display the user's location.
    ///   - showsHeading: Whether to display the heading indicator.
    ///   - requestsAuthorization: Whether MapLibre may request location authorization.
    func mapUserLocationVisible(
        _ isVisible: Bool,
        showsHeading: Bool = false,
        requestsAuthorization: Bool = true
    ) -> some View {
        modifier(MapUserLocationViewModifier(configuration: MapUserLocationConfiguration(
            isVisible: isVisible,
            showsHeading: showsHeading,
            requestsAuthorization: requestsAuthorization
        )))
    }
}
