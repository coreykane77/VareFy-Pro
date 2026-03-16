import UIKit

enum PhotoServiceMock {
    static func samplePhoto(color: UIColor = .systemTeal, label: String = "Sample") -> UIImage {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 20)
            ]
            let text = label as NSString
            let textSize = text.size(withAttributes: attrs)
            let point = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            text.draw(at: point, withAttributes: attrs)
        }
    }
}
