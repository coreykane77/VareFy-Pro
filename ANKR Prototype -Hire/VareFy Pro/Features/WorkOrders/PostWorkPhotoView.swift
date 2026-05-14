import SwiftUI

struct PostWorkPhotoView: View {
    let orderId: UUID
    @Environment(WorkOrderViewModel.self) private var workOrderVM
    @Environment(AuthManager.self) private var authManager

    @State private var showImagePicker = false
    @State private var navigateToReview = false
    @State private var showReportIssue = false

    private var order: WorkOrder? { workOrderVM.order(id: orderId) }
    private var canComplete: Bool { workOrderVM.canComplete(for: orderId) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if let order = order {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            gateStatusBanner(order)
                            photoSection(order)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }

                    VStack(spacing: 12) {
                        if !canComplete {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                Text("Required post work photos not yet uploaded.")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .padding(12)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        PrimaryButton(title: "Submit Completion", isEnabled: canComplete) {
                            navigateToReview = true
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, Constants.bottomBarHeight + 24)
                    .background(Color.appBackground)
                }
            }
        }
        .navigationTitle("Post Work Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appNavBar, for: .navigationBar)
        .task { await workOrderVM.fetchPhotos(for: orderId) }
        .alert("Photo Upload Failed", isPresented: Binding(
            get: { workOrderVM.photoUploadError != nil },
            set: { if !$0 { workOrderVM.photoUploadError = nil } }
        )) {
            Button("OK") { workOrderVM.photoUploadError = nil }
        } message: {
            Text(workOrderVM.photoUploadError ?? "")
        }
        .sheet(isPresented: $showReportIssue) {
            ReportIssueSheet(orderId: orderId).environment(workOrderVM)
        }
        .closeButton()
        .navigationDestination(isPresented: $navigateToReview) {
            SubmitReviewView(orderId: orderId)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: Binding(
                get: { nil },
                set: { img in
                    if let img, let userId = authManager.currentUserId {
                        Task { await workOrderVM.addPostPhoto(img, for: orderId, uploadedBy: userId) }
                    }
                }
            ))
        }
    }

    @ViewBuilder
    private func gateStatusBanner(_ order: WorkOrder) -> some View {
        HStack(spacing: 10) {
            Image(systemName: canComplete ? "checkmark.circle.fill" : "camera.fill")
                .foregroundStyle(canComplete ? .green : Color.varefyProCyan)
            VStack(alignment: .leading, spacing: 2) {
                Text("Post Work Photos")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("\(order.confirmedPostPhotoCount) of \(Constants.minPhotosRequired) required uploaded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func photoSection(_ order: WorkOrder) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PHOTOS (\(order.postPhotoCount)/\(Constants.maxPhotosPerGate))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(order.postPhotoRecords) { record in
                        photoThumb(record: record) {
                            Task { await workOrderVM.removePostPhoto(record: record, for: orderId) }
                        }
                    }
                    if order.postPhotoCount < Constants.maxPhotosPerGate {
                        addPhotoButton
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func photoThumb(record: PhotoRecord, onDelete: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                if let image = record.localImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if let url = record.signedURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.appCard
                    }
                } else {
                    Color.appCard
                }

                if record.isUploading {
                    Color.black.opacity(0.45)
                    ProgressView().tint(.white)
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if !record.isUploading {
                Button(action: {
                    Haptics.light()
                    onDelete()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.primary)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
        }
    }

    private var addPhotoButton: some View {
        Button {
            showImagePicker = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundStyle(Color.varefyProCyan)
                Text("Add Photo")
                    .font(.caption2)
                    .foregroundStyle(Color.varefyProCyan)
            }
            .frame(width: 90, height: 90)
            .background(Color.varefyProCyan.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.varefyProCyan.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
    }
}
