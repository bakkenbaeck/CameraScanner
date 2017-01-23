import UIKit
import AVFoundation
import QReader

class ViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    lazy var scannBarItem: UIBarButtonItem = {
        let view = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(ViewController.presentScannerController))

        return view
    }()

    lazy var toolbar: UIToolbar = {
        let view = UIToolbar()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.barTintColor = .blue
        view.tintColor = .white
        view.delegate = self

        view.items = [self.scannBarItem]

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white

        self.view.addSubview(self.toolbar)
        
        self.toolbar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.toolbar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.toolbar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }

    func presentScannerController() {
        let scanner = CameraScanner(metadataObjectTypes: [AVMetadataObjectTypeQRCode])
        let scannerController = ScannerViewController(prompt: "Scan a profile code or QR code", scanner: scanner)
        scannerController.delegate = self
        self.present(scannerController, animated: true) {
            let deadline: DispatchTime = DispatchTime.now() + Double(Int64(2.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: deadline) {
                Theme.current = Theme(overlayBackgroundColor: .red, overlayBackgroundOpacity: 0.8, promptLabelTextColor: .magenta)
            }
        }
    }
}

extension ViewController: ScannerViewControllerDelegate {
    func scannerDidCancel(_ controller: ScannerViewController) {
        self.dismiss(animated: true)
    }

    func scanner(_ controller: ScannerViewController, didScanResult result: String) {
        print(result)
    }
}

extension ViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

