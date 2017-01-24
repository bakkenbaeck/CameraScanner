import UIKit

open class ScannerOverlayView: UIView {

    func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * M_PI / 180.0
    }

    lazy var overlayLayer: CALayer = CALayer()

    lazy var cornerTopRightImageView: UIImageView = {
        let view = UIImageView(image: AssetManager.cornerImage)
        view.transform = view.transform.rotated(by: CGFloat(270.0 * M_PI / 180.0))

        // We set the restorationIdentifier here to more easily debug and adjust view positioning.
        view.restorationIdentifier = "CornerTopRightImageView"

        view.clipsToBounds = true
        return view
    }()

    lazy var cornerTopLeftImageView: UIImageView = {
        let view = UIImageView(image: AssetManager.cornerImage)
        view.transform = view.transform.rotated(by: CGFloat(180.0 * M_PI / 180.0))

        // We set the restorationIdentifier here to more easily debug and adjust view positioning.
        view.restorationIdentifier = "CornerTopLeftImageView"

        view.clipsToBounds = true
        return view
    }()

    lazy var cornerBottomLeftImageView: UIImageView = {
        let view = UIImageView(image: AssetManager.cornerImage)
        view.transform = view.transform.rotated(by: CGFloat(90.0 * M_PI / 180.0))

        // We set the restorationIdentifier here to more easily debug and adjust view positioning.
        view.restorationIdentifier = "CornerBottomLeftImageView"

        view.clipsToBounds = true
        return view
    }()

    lazy var cornerBottomRightImageView: UIImageView = {
        let view = UIImageView(image: AssetManager.cornerImage)

        // We set the restorationIdentifier here to more easily debug and adjust view positioning.
        view.restorationIdentifier = "CornerBottomRightImageView"

        view.clipsToBounds = true
        return view
    }()

    /// Width should be 80% of the smallest dimension, so that it will always fit the screen.
    open var maskWidth: CGFloat {
        let size = self.bounds.width > self.bounds.height ? self.bounds.height : self.bounds.width
        return (size * 0.8)
    }

    open var maskY: CGFloat  {
        return ((self.bounds.height / 2.0) - (self.maskWidth / 2.0))
    }

    open var maskX: CGFloat {
        return ((self.bounds.width / 2.0) - (self.maskWidth / 2.0))
    }

    open func newMaskLayer() -> CAShapeLayer {
        let fillLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: 0)

        let holePath = UIBezierPath(rect: CGRect(x: self.maskX, y: self.maskY, width: self.maskWidth, height: self.maskWidth))

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

        self.addSubview(self.cornerTopLeftImageView)
        self.addSubview(self.cornerTopRightImageView)
        self.addSubview(self.cornerBottomLeftImageView)
        self.addSubview(self.cornerBottomRightImageView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: ThemeDidChangeNotification, object: Theme.self)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        self.overlayLayer.frame = self.bounds
        let mask = self.newMaskLayer()

        let imageWidth = self.cornerTopLeftImageView.frame.width
        let imageHeight = self.cornerTopLeftImageView.frame.height

        // this is the half-width of the corner lines.
        let offset: CGFloat = 2.0

        self.cornerTopLeftImageView.frame.origin = CGPoint(x: self.maskX - offset, y: self.maskY - offset)
        self.cornerTopRightImageView.frame.origin = CGPoint(x: self.bounds.maxX - imageWidth - self.maskX + offset, y: self.maskY - offset)

        self.cornerBottomLeftImageView.frame.origin = CGPoint(x: self.maskX - offset, y: self.bounds.maxY - self.maskY - imageHeight + offset)
        self.cornerBottomRightImageView.frame.origin = CGPoint(x: self.bounds.maxX - self.maskX - imageWidth + offset, y: self.bounds.maxY - self.maskY - imageHeight + offset)

        self.overlayLayer.mask = mask
    }

    func updateTheme() {
        self.overlayLayer.backgroundColor = Theme.overlayBackgroundColor.cgColor
        self.overlayLayer.opacity = Theme.overlayBackgroundOpacity
    }
}
