import UIKit

/// Implement this on every view that conforms to our Theme, so that it updates its values on changes.
let ThemeDidChangeNotification = NSNotification.Name.init("ThemeDidChangeNotification")

/// Colours
open class Theme {
    public static var overlayBackgroundColor: UIColor {
        return self.current.overlayBackgroundColor
    }

    public static var overlayBackgroundOpacity: Float {
        return self.current.overlayBackgroundOpacity
    }

    public static var promptLabelTextColor: UIColor {
        return self.current.promptLabelTextColor
    }

    public static var current = Theme() {
        didSet {
            NotificationCenter.default.post(name: ThemeDidChangeNotification, object: self)
        }
    }

    ///
    open var overlayBackgroundColor: UIColor

    open var overlayBackgroundOpacity: Float

    open var promptLabelTextColor: UIColor

    public init(overlayBackgroundColor: UIColor = .black, overlayBackgroundOpacity: Float = 0.6, promptLabelTextColor: UIColor = .white) {
        self.overlayBackgroundColor = overlayBackgroundColor

        self.overlayBackgroundOpacity = overlayBackgroundOpacity

        self.promptLabelTextColor = promptLabelTextColor
    }
}

/// Fonts
extension Theme {
    open static var promptLabelTextFont: UIFont {
        return .systemFont(ofSize: 16)
    }
}
