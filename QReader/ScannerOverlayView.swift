import UIKit

open class ScannerOverlayView: UIView {

    lazy var overlayLayer: CALayer = CALayer()

    open func newMaskLayer() -> CAShapeLayer {
        let bounds = self.bounds
        let width: CGFloat = 300.0
        let y = (bounds.height / 2.0) - (width / 2.0)
        let x = (bounds.width / 2.0) - (width / 2.0)

        let fillLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 0)
        let holePath = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: width), cornerRadius: 8)

        path.append(holePath)

        fillLayer.path = path.cgPath
        fillLayer.fillRule = kCAFillRuleEvenOdd

        return fillLayer
    }

    public init(cameraLayer: CALayer) {
        super.init(frame: .zero)

        self.translatesAutoresizingMaskIntoConstraints = false

        self.layer.addSublayer(cameraLayer)
        self.layer.addSublayer(self.overlayLayer)

        self.updateTheme()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: ThemeDidChangeNotification, object: Theme.self)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        self.overlayLayer.frame = self.bounds
        self.overlayLayer.mask = self.newMaskLayer()
    }

    func updateTheme() {
        self.overlayLayer.backgroundColor = Theme.overlayBackgroundColor.cgColor
        self.overlayLayer.opacity = Theme.overlayBackgroundOpacity
    }
}
