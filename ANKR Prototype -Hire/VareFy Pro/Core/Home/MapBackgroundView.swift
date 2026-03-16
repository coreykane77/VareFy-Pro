import SwiftUI
import MapKit

// Enum kept for the layer-toggle button UI in HireHomeView.
// MapBackgroundView always renders Apple Maps regardless of the selected style.
enum MapLayerStyle: String, CaseIterable {
    case appleMaps = "Apple"
    case waze      = "Waze"
    case google    = "Google"

    var next: MapLayerStyle {
        let all = MapLayerStyle.allCases
        let idx = all.firstIndex(of: self)!
        return all[(idx + 1) % all.count]
    }

    var icon: String {
        switch self {
        case .appleMaps: return "apple.logo"
        case .waze:      return "car.fill"
        case .google:    return "globe.americas.fill"
        }
    }
}

struct MapBackgroundView: View {

    /// Accepted for API compatibility with the toggle button, but ignored —
    /// Apple Maps is always rendered so the Waze/Google static images
    /// never cause the scaling bug.
    var layerStyle: MapLayerStyle = .appleMaps

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 32.900, longitude: -97.060),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        Map(position: $camera)
            .mapStyle(.standard)
            .disabled(true)
            .ignoresSafeArea()
    }
}
