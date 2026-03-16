import SwiftUI
import Observation

enum NavAppPreference: String, CaseIterable {
    case appleMaps  = "Apple Maps"
    case waze       = "Waze"
    case googleMaps = "Google Maps"

    var urlScheme: String {
        switch self {
        case .appleMaps:  return "maps://"
        case .waze:       return "waze://"
        case .googleMaps: return "comgooglemaps://"
        }
    }

    func directionsURL(lat: Double, lon: Double) -> URL? {
        switch self {
        case .appleMaps:
            return URL(string: "maps://?daddr=\(lat),\(lon)&dirflg=d")
        case .waze:
            return URL(string: "waze://?ll=\(lat),\(lon)&navigate=yes")
        case .googleMaps:
            return URL(string: "comgooglemaps://?daddr=\(lat),\(lon)&directionsmode=driving")
        }
    }

    // canOpenURL requires LSApplicationQueriesSchemes in Info.plist.
    // For this prototype, treat all options as available.
    var isInstalled: Bool { true }
}

@Observable
class AppSettingsViewModel {
    var isDarkMode: Bool = true
    var preferredNavApp: NavAppPreference = .appleMaps

    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
}
