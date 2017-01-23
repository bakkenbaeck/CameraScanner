import UIKit

/// Implement this on every view that conforms to our Theme, so that it updates its values on changes.
let ThemeDidChangeNotification = NSNotification.Name.init("ThemeDidChangeNotification")

/// Colours
open class Theme {

    public static var current = Theme() {
        didSet {
            NotificationCenter.default.post(name: ThemeDidChangeNotification, object: self)
        }
    }

    public static var overlayBackgroundColor: UIColor {
        return self.current.overlayBackgroundColor
    }

    public static var overlayBackgroundOpacity: Float {
        return self.current.overlayBackgroundOpacity
    }

    public static var instructionsLabelTextColor: UIColor {
        return self.current.instructionsLabelTextColor
    }

    open static var instructionsLabelTextFont: UIFont {
        return self.current.instructionsLabelTextFont
    }

    ///
    open var overlayBackgroundColor: UIColor

    open var overlayBackgroundOpacity: Float

    open var instructionsLabelTextColor: UIColor

    open var instructionsLabelTextFont: UIFont

    public init(overlayBackgroundColor: UIColor = .black, overlayBackgroundOpacity: Float = 0.6, instructionsLabelTextColor: UIColor = .white, instructionsLabelTextFont: UIFont = .systemFont(ofSize: 16)) {
        self.overlayBackgroundColor = overlayBackgroundColor
        self.overlayBackgroundOpacity = overlayBackgroundOpacity
        self.instructionsLabelTextColor = instructionsLabelTextColor
        self.instructionsLabelTextFont = instructionsLabelTextFont
    }
}
