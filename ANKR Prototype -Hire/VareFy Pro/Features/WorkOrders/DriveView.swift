import SwiftUI
import MapKit
import CoreLocation

struct DriveView: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(AppSettingsViewModel.self) private var settingsVM
    @Environment(\.dismiss) private var dismiss

    // Map state
    @State private var destinationCoord: CLLocationCoordinate2D?
    @State private var startCoord: CLLocationCoordinate2D?
    @State private var currentCoord: CLLocationCoordinate2D?
    @State private var camera: MapCameraPosition = .automatic

    // Drive state
    @State private var isDriving = false
    @State private var etaSeconds: Int = 20
    @State private var driveTask: Task<Void, Never>?

    // Arrival popup
    @State private var showArrivalPopup = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var showReportIssue = false
    @State private var clientNotified = false

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer

            // Dim behind popup
            if showArrivalPopup {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Swap bottom sheet ↔ arrival popup
            if showArrivalPopup {
                arrivalPopup
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(10)
            } else {
                bottomSheet
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.78), value: showArrivalPopup)
        .ignoresSafeArea(edges: .top)
        .navigationTitle("Drive to Job")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black.opacity(0.6), for: .navigationBar)
        .sheet(isPresented: $showReportIssue) {
            ReportIssueSheet(orderId: orderId)
                .environment(workOrderVM)
        }
        .closeButton()
        .task { await setupMap() }
        .onDisappear { driveTask?.cancel() }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $camera) {
            if let dest = destinationCoord {
                Marker(order?.serviceTitle ?? "Job Site",
                       systemImage: "briefcase.fill",
                       coordinate: dest)
                    .tint(Color.varefyProCyan)
            }

            if let start = startCoord, let dest = destinationCoord {
                MapPolyline(coordinates: [start, dest])
                    .stroke(Color.blue.opacity(0.6), lineWidth: 5)
            }

            if let pos = currentCoord {
                Annotation("", coordinate: pos, anchor: .center) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.25))
                            .frame(width: 28, height: 28)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Bottom Sheet (driving info, no arrival button)

    private var bottomSheet: some View {
        VStack(spacing: 16) {
            if let order = order {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundStyle(Color.varefyProCyan)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.address)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Text(isDriving
                             ? (etaSeconds > 0 ? "ETA: \(formattedETA(etaSeconds))" : "Almost there…")
                             : (order.status == .enRoute ? "En Route" : "Ready to navigate"))
                            .font(.caption)
                            .foregroundStyle(isDriving ? Color.varefyProGold : .gray)
                    }
                    Spacer()
                    StatusPillView(status: order.status)
                }

                if isDriving {
                    ProgressView(value: simulationProgress)
                        .progressViewStyle(.linear)
                        .tint(Color.varefyProCyan)
                } else if order.status == .readyToNavigate {
                    Divider().background(Color.white.opacity(0.1))

                    // Open in preferred external nav app
                    if let coord = destinationCoord,
                       let url = settingsVM.preferredNavApp.directionsURL(lat: coord.latitude, lon: coord.longitude) {
                        Button {
                            UIApplication.shared.open(url)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.turn.up.right.circle")
                                    .font(.subheadline)
                                Text("Open in \(settingsVM.preferredNavApp.rawValue)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(Color.varefyProCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.varefyProCyan.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    PrimaryButton(title: "Start Drive") {
                        Task { await workOrderVM.startDrive(for: orderId) }
                        startSimulation()
                    }
                }

                Button {
                    Haptics.medium()
                    showReportIssue = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                        Text("Report an Issue")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appBackground)
                .shadow(color: .black.opacity(0.4), radius: 20, y: -4)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, Constants.bottomBarHeight + 24)
    }

    // MARK: - Arrival Popup

    private var arrivalPopup: some View {
        VStack(spacing: 24) {
            // Pulsing location icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseScale)
                Circle()
                    .fill(Color.green.opacity(0.25))
                    .frame(width: 64, height: 64)
                Image(systemName: "location.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.green)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    pulseScale = 1.18
                }
            }

            VStack(spacing: 6) {
                Text("You're at the job site")
                    .font(.title2)
                    .fontWeight(.heavy)
                    .foregroundStyle(.primary)
                Text(order?.address ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if clientNotified {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                    Text("Client notified of your arrival")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(14)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .transition(.opacity)
            } else {
                Button {
                    driveTask?.cancel()
                    Task { await workOrderVM.simulateArrival(for: orderId) }
                    withAnimation { clientNotified = true }
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        dismiss()
                    }
                } label: {
                    Text("Confirm Arrival")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.appBackground)
                .shadow(color: .black.opacity(0.6), radius: 30, y: -8)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, Constants.bottomBarHeight + 32)
    }

    // MARK: - Simulation

    private var simulationProgress: Double {
        1.0 - (Double(max(0, etaSeconds)) / 20.0)
    }

    private func startSimulation() {
        guard let start = startCoord, let dest = destinationCoord else { return }
        isDriving = true
        etaSeconds = 20
        let totalSteps = 10
        let arrivalTriggerStep = 7   // popup appears after ~7 seconds

        driveTask?.cancel()
        driveTask = Task { @MainActor in
            for step in 1...totalSteps {
                guard !Task.isCancelled else { break }
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }

                let progress = Double(step) / Double(totalSteps)
                let lat = start.latitude  + (dest.latitude  - start.latitude)  * progress
                let lon = start.longitude + (dest.longitude - start.longitude) * progress
                currentCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                etaSeconds   = max(0, Int(20.0 * (1.0 - progress)))

                withAnimation(.easeInOut(duration: 0.9)) {
                    camera = .camera(MapCamera(
                        centerCoordinate: currentCoord!,
                        distance: 900,
                        heading: bearing(from: start, to: dest),
                        pitch: 50
                    ))
                }

                // Trigger arrival popup at 45 seconds
                if step == arrivalTriggerStep {
                    withAnimation { showArrivalPopup = true }
                    break  // stop the simulation loop — user confirms manually
                }
            }
        }
    }

    // MARK: - Geocoding

    private func setupMap() async {
        guard let order = order else { return }

        var dest: CLLocationCoordinate2D
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = order.address
        let search = MKLocalSearch(request: request)
        if let response = try? await search.start(),
           let item = response.mapItems.first {
            dest = item.placemark.location?.coordinate ?? item.placemark.coordinate
        } else {
            dest = CLLocationCoordinate2D(latitude: 32.900, longitude: -97.060)
        }

        destinationCoord = dest
        let start = CLLocationCoordinate2D(latitude: dest.latitude + 0.027, longitude: dest.longitude - 0.027)
        startCoord   = start
        currentCoord = start

        camera = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude:  (dest.latitude  + start.latitude)  / 2,
                longitude: (dest.longitude + start.longitude) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        ))

        if order.status == .enRoute {
            startSimulation()
        }
    }

    // MARK: - Helpers

    private func formattedETA(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func bearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let dLon = to.longitude - from.longitude
        let y = sin(dLon) * cos(to.latitude)
        let x = cos(from.latitude) * sin(to.latitude)
              - sin(from.latitude) * cos(to.latitude) * cos(dLon)
        return (atan2(y, x) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }
}
