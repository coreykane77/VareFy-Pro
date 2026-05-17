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
        ZStack {
            if let image = loadedImage ?? record.localImage {
                ZoomableImageView(image: image)
            } else if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Zoomable image view
//
// UIScrollView as a UIViewRepresentable root has layout issues inside
// TabView(.page) + fullScreenCover: SwiftUI's frame propagation does not
// reliably update scrollView.bounds before fit runs. Fix: use a plain UIView
// container as the representable root. The container receives SwiftUI layout
// cleanly and explicitly sets scrollView.frame = bounds in layoutSubviews,
// guaranteeing the scroll view has real bounds before we fit the image.

private final class ZoomContainer: UIView, UIScrollViewDelegate {
    private let scrollView = UIScrollView()
    private let imageView  = UIImageView()
    private var lastFittedSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator   = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsetAdjustmentBehavior = .never
        addSubview(scrollView)

        imageView.contentMode        = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setImage(_ image: UIImage) {
        guard imageView.image !== image else { return }
        imageView.image = image
        lastFittedSize = .zero
        if bounds.width > 0 { fitImage(size: bounds.size) }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds          // explicit — not left to Auto Layout
        let size = bounds.size
        guard size.width > 0, size.height > 0, size != lastFittedSize else { return }
        lastFittedSize = size
        fitImage(size: size)
    }

    private func fitImage(size: CGSize) {
        guard let img = imageView.image,
              img.size.width > 0, img.size.height > 0 else { return }
        let scale   = min(size.width / img.size.width, size.height / img.size.height)
        let fitSize = CGSize(width: img.size.width * scale, height: img.size.height * scale)
        imageView.frame       = CGRect(origin: .zero, size: fitSize)
        scrollView.contentSize = fitSize
        scrollView.zoomScale  = 1
        centerContent()
    }

    private func centerContent() {
        let b = scrollView.bounds
        imageView.frame.origin = CGPoint(
            x: max((b.width  - imageView.frame.width)  / 2, 0),
            y: max((b.height - imageView.frame.height) / 2, 0)
        )
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerContent() }

    @objc private func handleDoubleTap(_ tap: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.setZoomScale(1, animated: true)
        } else {
            let point  = tap.location(in: imageView)
            let size   = CGSize(width: scrollView.bounds.width / 2.5,
                                height: scrollView.bounds.height / 2.5)
            let origin = CGPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
            scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
        }
    }
}

struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> ZoomContainer {
        let container = ZoomContainer()
        container.setImage(image)
        return container
    }

    func updateUIView(_ container: ZoomContainer, context: Context) {
        container.setImage(image)
    }
}
