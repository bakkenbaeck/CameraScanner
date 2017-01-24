import UIKit
import CameraScanner

// You can easily subclass the ScannerViewController to tweak the UI, simpler than re-implementing it hole.
class ScannerSubclassViewController: ScannerViewController {
    override func setupToolbarItems() {
        self.toolbar.setItems( [self.cancelItem], animated: true)
    }
}
