import Foundation
import AVFoundation

/// The actual scanner. Deals with the lower level capture details. 
/// Since it accesses the cameras, it's necessary to add NSCameraUsageDescription to the Info.plist of your app.
open class CameraScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    /**
     Returns the video orientation for a given interface orientation.

     - parameter interfaceOrientation: The orientation of the user interface.
     */
    public class func videoOrientationFromInterfaceOrientation(_ interfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        switch (interfaceOrientation) {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portrait:
            return .portrait
        default:
            return .portraitUpsideDown
        }
    }

    /**
     Checks if current device supports the given metadata object types.

     - parameter metadataTypes: An array of strings identifying the types of metadata objects to check, such as AVMetadataObjectTypeFace and AVMetadataObjectTypeQRCode.

     - returns: Bool indicating if the device supports the given metadata object types.
     */
    public class func supportsMetadataObjectTypes(_ metadataTypes: [String] = [AVMetadataObjectTypeQRCode]) -> Bool {
        if !self.isAvailable {
            return false
        }

        // Setup components
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return false }

        let output = AVCaptureMetadataOutput()
        let session = AVCaptureSession()

        session.addInput(deviceInput)
        session.addOutput(output)

        for metadataObjectType in metadataTypes {
            return output.availableMetadataObjectTypes.contains { (type: Any) -> Bool in (type as? String) == metadataObjectType }
        }
        
        return false
    }


    /// CALayer that displays the video stream as it is being captured by the input device.
    open lazy var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)

    /// An array of strings identifying the types of metadata objects to process. Conforms to `AVMetadataObjectType` naming convention.
    /// Example: AVMetadataObjectTypeFace, AVMetadataObjectTypeQRCode
    open let metadataObjectTypes: [String]

    /// Block is executing when a QRCode or when the user did stopped the scan.
    open var completionBlock: ((String?) -> ())?

    /**
     Indicates whether the session is currently running.

     Clients can use KVO here to be notified when the session automatically starts or stops running.
     */
    public var running: Bool {
        get {
            return session.isRunning
        }
    }

    /**
     Returns true if device has a font facing camera.

     - returns: Bool indicating fi the device has a fron-facing camera.
     */
    public var hasFrontFacingCamera: Bool {
        return self.frontDevice != nil
    }

    /**
     Returns true if device has a torch/flashlight.

     - returns: Bool indicating if a torch is available.
     */
    public var isTorchAvailable: Bool {
        return self.defaultDevice?.isTorchAvailable == true
    }

    /**
     Checks if the Scanner is available for the current device.

     - returns: Bool that indicates whether the current device has valid input devices.
     */
    open class var isAvailable: Bool {
        // We can just check for the built-in back wide-angle camera, since to that there are no iOS devices with a front-facing camera but no back camera.
        guard let discoverySesssion = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .front) else { return false }

        return discoverySesssion.devices.count > 0
    }

    open var defaultDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)

    open var frontDevice: AVCaptureDevice? = {
        guard let discoverySesssion = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .front) else { return nil }
        for device in discoverySesssion.devices {
            if device.position == .front {
                return device
            }
        }

        return nil
    }()

    open lazy var defaultDeviceInput: AVCaptureDeviceInput? = {
        return try? AVCaptureDeviceInput(device: self.defaultDevice)
    }()

    open lazy var frontDeviceInput: AVCaptureDeviceInput? = {
        if let frontDevice = self.frontDevice {
            return try? AVCaptureDeviceInput(device: frontDevice)
        }

        return nil
    }()

    open var metadataOutput = AVCaptureMetadataOutput()

    open var session = AVCaptureSession()

    public init(metadataObjectTypes types: [String]) {
        self.metadataObjectTypes = types

        super.init()

        self.configure()
    }

    open func configure() {
        self.session.addOutput(self.metadataOutput)

        if let defaultDeviceInput = self.defaultDeviceInput {
            self.session.addInput(defaultDeviceInput)
        }

        self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        self.metadataOutput.metadataObjectTypes = self.metadataObjectTypes
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
    }

    /// Switch between back and front camera.
    public func switchDeviceInput() {
        if let frontDeviceInput = self.frontDeviceInput {
            self.session.beginConfiguration()

            if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
                self.session.removeInput(currentInput)

                let newDeviceInput = (currentInput.device.position == .front) ? defaultDeviceInput : frontDeviceInput
                self.session.addInput(newDeviceInput)
            }

            self.session.commitConfiguration()
        }
    }

    /// Starts scanning the codes.
    public func startScanning() {
        guard !session.isRunning else { return }
        session.startRunning()
    }

    /// Stops scanning the codes.
    public func stopScanning() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    /// Toggles the torch on/off, if avaialable.
    open func toggleTorch() {
        guard let defaultDevice = self.defaultDevice else { return }

        do {
            try defaultDevice.lockForConfiguration()

            let current = defaultDevice.torchMode
            defaultDevice.torchMode = (AVCaptureTorchMode.on == current) ? .off : .on

            defaultDevice.unlockForConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }

    open func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        for metadataObject in metadataObjects {
            guard let readableCodeObject = metadataObject as? AVMetadataMachineReadableCodeObject else { continue }
            if self.metadataObjectTypes.contains(readableCodeObject.type) {
                stopScanning()

                let scannedResult = readableCodeObject.stringValue

                DispatchQueue.main.async { [weak self] in
                    self?.completionBlock?(scannedResult)
                }
            }
        }
    }
}
