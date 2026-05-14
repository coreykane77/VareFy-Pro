import SwiftUI

struct VehicleView: View {
    @Environment(ProfileViewModel.self) private var profileVM
    @State private var showPhotoOptions = false
    @State private var vehicleImage: UIImage? = UIImage(named: "Ford")

    var body: some View {
        @Bindable var vm = profileVM

        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    photoCard
                    detailsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Vehicle")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .doneKeyboardToolbar()
        .popButton()
        .confirmationDialog("Vehicle Photo", isPresented: $showPhotoOptions) {
            Button("Add Sample Photo") {
                vehicleImage = UIImage(named: "Ford")
            }
            Button("Remove Photo", role: .destructive) {
                vehicleImage = nil
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - Photo Card

    private var photoCard: some View {
        VStack(spacing: 0) {
            if let img = vehicleImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipped()
                    .overlay(alignment: .bottomTrailing) {
                        Button {
                            Haptics.light()
                            showPhotoOptions = true
                        } label: {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(Color.varefyProCyan)
                                .background(Circle().fill(Color.appBackground).padding(4))
                        }
                        .padding(12)
                    }
            } else {
                ZStack {
                    Color.appCard
                    VStack(spacing: 12) {
                        Image(systemName: "truck.box.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.varefyProCyan.opacity(0.4))
                        Text("No vehicle photo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            Haptics.light()
                            showPhotoOptions = true
                        } label: {
                            Label("Add Photo", systemImage: "camera.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.varefyProCyan)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Details Section

    @ViewBuilder
    private var detailsSection: some View {
        @Bindable var vm = profileVM

        VStack(alignment: .leading, spacing: 0) {
            Text("DETAILS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                fieldRow(label: "Year", text: $vm.profile.vehicleYear, placeholder: "e.g. 2019")
                divider
                fieldRow(label: "Make", text: $vm.profile.vehicleMake, placeholder: "e.g. Ford")
                divider
                fieldRow(label: "Model", text: $vm.profile.vehicleModel, placeholder: "e.g. F-250 SuperDuty")
            }
            .background(Color.appCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }

        // Preview of how it shows on profile
        if !profileVM.profile.vehicleDescription.isEmpty && profileVM.profile.vehicleDescription != "No vehicle on file" {
            VStack(alignment: .leading, spacing: 8) {
                Text("SHOWS ON YOUR PUBLIC PROFILE AS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                    .padding(.horizontal, 4)

                HStack(spacing: 10) {
                    Image(systemName: "car.fill")
                        .foregroundStyle(Color.varefyProCyan.opacity(0.7))
                    Text(profileVM.profile.vehicleDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helpers

    private var divider: some View {
        Divider()
            .background(Color.white.opacity(0.08))
            .padding(.leading, 16)
    }

    @ViewBuilder
    private func fieldRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
            TextField(placeholder, text: text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
