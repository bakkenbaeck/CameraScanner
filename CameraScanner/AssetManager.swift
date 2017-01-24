import UIKit

open class AssetManager {
    open class var torchImage: UIImage? {
        let bundle = Bundle(for: self)
        return UIImage(named: "Torch", in: bundle, compatibleWith: nil)
    }
}

