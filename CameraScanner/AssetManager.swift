import UIKit

open class AssetManager {
    open class var torchImage: UIImage? {
        return UIImage(named: "Torch", in: self.bundle, compatibleWith: nil)
    }

    open class var cameraImage: UIImage? {
        return UIImage(named: "CameraSwitch", in: self.bundle, compatibleWith: nil)
    }

    open class var cornerImage: UIImage? {
        return UIImage(named: "Corner", in: self.bundle, compatibleWith: nil)
    }

    class var bundle: Bundle {
        return Bundle(for: self)
    }
}
