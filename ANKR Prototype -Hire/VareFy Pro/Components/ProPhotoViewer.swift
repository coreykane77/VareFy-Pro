import SwiftUI
import UIKit

struct ProPhotoViewer: View {
    let records: [PhotoRecord]
    @State var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(records.enumerated()), id: \.offset) { i, record in
                    ZoomablePhotoRecord(record: record)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: records.count > 1 ? .always : .never))
            .ignoresSafeArea()

            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .padding(20)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Per-record view

private struct ZoomablePhotoRecord: View {
    let record: PhotoRecord
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        GeometryReader { geo in
            if let image = loadedImage ?? record.localImage {
                ZoomableImageView(image: image, size: geo.size)
            } else if isLoading {
                ProgressView()
                    .tint(.white)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .task {
            guard record.localImage == nil, loadedImage == nil, let url = record.signedURL else { return }
            isLoading = true
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let img = UIImage(data: data) {
                loadedImage = img
            }
            isLoading = false
        }
    }
}

// MARK: - UIScrollView zoom wrapper

// Fires onBoundsChanged whenever UIKit commits a new non-zero bounds size.
// This is the authoritative re-fit trigger: GeometryReader and UIKit layout
// are independent, and scrollView.bounds can still be .zero when updateUIView
// first fires (e.g. during fullScreenCover open animation). layoutSubviews
// runs after UIKit has committed real bounds, making it the correct place to
// re-fit the image.
private final class ZoomScrollView: UIScrollView {
    var onBoundsChanged: (() -> Void)?
    private var lastBoundsSize: CGSize = .zero

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastBoundsSize else { return }
        lastBoundsSize = bounds.size
        guard bounds.width > 0, bounds.height > 0 else { return }
        onBoundsChanged?()
    }
}

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let size: CGSize

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = ZoomScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        context.coordinator.scrollView = scrollView

        let coordinator = context.coordinator
        scrollView.onBoundsChanged = { [weak coordinator, weak scrollView] in
            guard let coord = coordinator, let sv = scrollView else { return }
            coord.refitFromBounds(in: sv)
        }

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = context.coordinator.imageView else { return }
        imageView.image = image
        context.coordinator.fitIfNeeded(in: scrollView, image: image, size: size)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        weak var scrollView: UIScrollView?
        weak var imageView: UIImageView?
        private var fittedImage: UIImage?
        private var fittedSize: CGSize = .zero

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent(in: scrollView)
        }

        func fitIfNeeded(in scrollView: UIScrollView, image: UIImage, size: CGSize) {
            guard size.width > 0, size.height > 0 else { return }
            guard image !== fittedImage || size != fittedSize else { return }
            fittedImage = image
            fittedSize = size
            fit(in: scrollView, size: size)
        }

        // Called by ZoomScrollView.layoutSubviews when UIKit commits real bounds.
        // Uses scrollView.bounds.size (authoritative UIKit measurement) rather than
        // the GeometryReader size, which may have been stale at first updateUIView.
        func refitFromBounds(in scrollView: UIScrollView) {
            let boundsSize = scrollView.bounds.size
            guard boundsSize.width > 0, boundsSize.height > 0 else { return }
            fittedSize = .zero  // invalidate so fit() runs even if image is unchanged
            fit(in: scrollView, size: boundsSize)
        }

        private func fit(in scrollView: UIScrollView, size: CGSize) {
            guard let imageView, let img = imageView.image,
                  img.size.width > 0, img.size.height > 0 else { return }
            let scale = min(size.width / img.size.width, size.height / img.size.height)
            imageView.frame = CGRect(origin: .zero, size: CGSize(
                width:  img.size.width  * scale,
                height: img.size.height * scale
            ))
            scrollView.contentSize = imageView.frame.size
            scrollView.zoomScale = 1
            centerContent(in: scrollView)
        }

        func centerContent(in scrollView: UIScrollView) {
            guard let imageView else { return }
            let b = scrollView.bounds
            let offsetX = max((b.width  - imageView.frame.width)  / 2, 0)
            let offsetY = max((b.height - imageView.frame.height) / 2, 0)
            imageView.frame.origin = CGPoint(x: offsetX, y: offsetY)
        }

        @objc func handleDoubleTap(_ tap: UITapGestureRecognizer) {
            guard let scrollView else { return }
            if scrollView.zoomScale > 1 {
                scrollView.setZoomScale(1, animated: true)
            } else {
                let point  = tap.location(in: imageView)
                let size   = CGSize(
                    width:  scrollView.bounds.width  / 2.5,
                    height: scrollView.bounds.height / 2.5
                )
                let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
                scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
            }
        }
    }
}
