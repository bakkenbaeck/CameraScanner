import UIKit
import AVFoundation

/**
 The methods of this protocol allow the delegate to be notified if the reader scans a result or if the user cancels.
 */
public protocol ScannerViewControllerDelegate: class {
    /**
     Tells the delegate that the reader did scan a code.

     - parameter reader: A code reader object informing the delegate about the scan result.
     - parameter result: The result of the scan
     */
    func scannerViewController(_ controller: ScannerViewController, didScanResult result: String)

    /**
     Tells the delegate that the user wants to stop scanning codes.

     - parameter reader: A code reader object informing the delegate about the cancellation.
     */
    func scannerViewControllerDidCancel(_ controller: ScannerViewController)
}


open class ScannerViewController: UIViewController {

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    fileprivate var cameraView: ScannerOverlayView

    fileprivate lazy var cancelItem: UIBarButtonItem = {
        let item = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(ScannerViewController.cancelAction))

        return item
    }()

    fileprivate lazy var torchItem: UIBarButtonItem = {
        let image = AssetManager.torchImage
        let item = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(ScannerViewController.toggleTorchAction))

        return item
    }()

    fileprivate lazy var toolbar: UIToolbar = {
        let view = UIToolbar()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.barStyle = .black
        view.tintColor = .white
        view.delegate = self

        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        view.items = [self.cancelItem, space, self.torchItem]

        return view
    }()

    lazy var instructionsLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .center

        return view
    }()

    let cameraScanner: CameraScanner

    let startScanningAtLoad: Bool

    open weak var delegate: ScannerViewControllerDelegate?

    open var completionBlock: ((String?) -> ())?

    deinit {
        self.cameraScanner.stop()
        NotificationCenter.default.removeObserver(self)
    }

    /**
     Initializes the default scanner view controller. Can be used as a framework to implement your own custom controller.

     - parameter instructions: A string to explain to the user what they should do.
     - parameter coderReader: The code reader object used to scan the bar code.
     - parameter startScanningAtLoad: Flag to know whether the view controller start scanning the codes when the view will appear.
     - parameter showSwitchCameraButton: Flag to display the switch camera button.
     - parameter showTorchButton: Flag to display the toggle torch button. If the value is true and there is no torch the button will not be displayed.
     */
    public required init(instructions: String = "Scan a QR code", scanner: CameraScanner, startScanningAtLoad startsScanning: Bool = true, showSwitchCameraButton showSwitch: Bool = true, showTorchButton showTorch: Bool = false) {
        self.startScanningAtLoad = startsScanning
        self.cameraScanner = scanner

        self.cameraView = ScannerOverlayView(cameraLayer: self.cameraScanner.previewLayer)

        super.init(nibName: nil, bundle: nil)

        self.cameraScanner.completionBlock = { [weak self] (resultAsString) in
            self?.completionBlock?(resultAsString)

            if let resultAsString = resultAsString {
                self?.delegate?.scannerViewController(self!, didScanResult: resultAsString)
            }
        }

        self.instructionsLabel.text = instructions

        NotificationCenter.default.addObserver(self, selector: #selector(ScannerViewController.orientationDidChanged(_:)), name: .UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTheme), name: ThemeDidChangeNotification, object: Theme.self)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.setupViewsAndConstraints()
        self.updateTheme()
        self.view.backgroundColor = .black
    }

    // MARK: - Responding to View Events

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.startScanningAtLoad {
            self.startScanning()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        self.stopScanning()

        super.viewWillDisappear(animated)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.cameraScanner.previewLayer.frame = self.cameraView.bounds
    }

    func updateTheme() {
        self.instructionsLabel.textColor = Theme.instructionsLabelTextColor
        self.instructionsLabel.font = Theme.instructionsLabelTextFont
    }

    // MARK: - Managing the Orientation

    func orientationDidChanged(_ notification: Notification) {
        self.cameraView.setNeedsDisplay()

        if self.cameraScanner.previewLayer.connection != nil {
            let orientation = UIApplication.shared.statusBarOrientation

            self.cameraScanner.previewLayer.connection.videoOrientation = CameraScanner.videoOrientationFromInterfaceOrientation(orientation)
        }
    }

    // MARK: - Initializing the AV Components

    fileprivate func setupViewsAndConstraints() {
        self.view.addSubview(self.cameraView)
        self.view.addSubview(self.instructionsLabel)
        self.view.addSubview(self.toolbar)

        self.cameraScanner.previewLayer.frame = self.view.bounds

        if self.cameraScanner.previewLayer.connection.isVideoOrientationSupported {
            let orientation = UIApplication.shared.statusBarOrientation
            self.cameraScanner.previewLayer.connection.videoOrientation = CameraScanner.videoOrientationFromInterfaceOrientation(orientation)
        }

        self.toolbar.topAnchor.constraint(equalTo: self.topLayoutGuide.bottomAnchor).isActive = true
        self.toolbar.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.toolbar.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        // we want the camera to extend below the toolbar
        self.cameraView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.cameraView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.cameraView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.cameraView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        self.instructionsLabel.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20).isActive = true
        self.instructionsLabel.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20).isActive = true
        self.instructionsLabel.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -80).isActive = true
    }

    // MARK: - Controlling the Reader

    /// Starts scanning the codes.
    open func startScanning() {
        self.cameraScanner.start()
    }

    /// Stops scanning the codes.
    open func stopScanning() {
        self.cameraScanner.stop()
    }

    // MARK: - Catching Button Events

    func cancelAction(_ button: UIButton) {
        self.cameraScanner.stop()

        self.completionBlock?(nil)
        self.delegate?.scannerViewControllerDidCancel(self)
    }

    func switchCameraAction() {
        self.cameraScanner.switchDeviceInput()
    }

    func toggleTorchAction() {
        self.cameraScanner.toggleTorch()
    }
}

extension ScannerViewController: UIToolbarDelegate {
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
