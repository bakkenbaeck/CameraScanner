import UIKit
import AVFoundation

public enum MetadataObjectType: String {
    case face

    case qrCode

    case ean8Code

    case ean13Code

    case upceCode

    case aztecCode

    case itf14Code

    case code39Code

    case code39Mod43Code

    case code93Code

    case code128Code

    case pdf417Code

    case dataMatrixCode

    case interleaved2of5Code

    public init(rawValue: String) {
        switch rawValue {
        case AVMetadataObjectTypeFace:
            self = .face
        case AVMetadataObjectTypeQRCode:
            self = .qrCode
        case AVMetadataObjectTypeEAN8Code:
            self = .ean8Code
        case AVMetadataObjectTypeEAN13Code:
            self = .ean13Code
        case AVMetadataObjectTypeUPCECode:
            self = .upceCode
        case AVMetadataObjectTypeAztecCode:
            self = .aztecCode
        case AVMetadataObjectTypeITF14Code:
            self = .itf14Code
        case AVMetadataObjectTypeCode39Code:
            self = .code39Code
        case AVMetadataObjectTypeCode39Mod43Code:
            self = .code39Mod43Code
        case AVMetadataObjectTypeCode93Code:
            self = .code93Code
        case AVMetadataObjectTypeCode128Code:
            self = .code128Code
        case AVMetadataObjectTypePDF417Code:
            self = .pdf417Code
        case AVMetadataObjectTypeDataMatrixCode: 
            self = .dataMatrixCode
        case AVMetadataObjectTypeInterleaved2of5Code: 
            self = .interleaved2of5Code
        default:
            fatalError("Tried to initialise a MetadataObjectType with an invalid paremeter.")
        }
    }

    public var metadataObjectTypeValue: String {
        switch self {
        case .face:
            return AVMetadataObjectTypeFace
        case .qrCode:
            return AVMetadataObjectTypeQRCode
        case .ean8Code:
            return AVMetadataObjectTypeEAN8Code
        case .ean13Code:
            return AVMetadataObjectTypeEAN13Code
        case .upceCode:
            return AVMetadataObjectTypeUPCECode
        case .aztecCode:
            return AVMetadataObjectTypeAztecCode
        case .itf14Code:
            return AVMetadataObjectTypeITF14Code
        case .code39Code:
            return AVMetadataObjectTypeCode39Code
        case .code39Mod43Code:
            return AVMetadataObjectTypeCode39Mod43Code
        case .code93Code:
            return AVMetadataObjectTypeCode93Code
        case .code128Code:
            return AVMetadataObjectTypeCode128Code
        case .pdf417Code:
            return AVMetadataObjectTypePDF417Code
        case .dataMatrixCode:
            return AVMetadataObjectTypeDataMatrixCode
        case .interleaved2of5Code:
            return AVMetadataObjectTypeInterleaved2of5Code
        }
    }
}

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
    public class func supportsMetadataObjectTypes(_ metadataTypes: [MetadataObjectType] = [.qrCode]) -> Bool {
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

        for type in metadataTypes {
            return output.availableMetadataObjectTypes.contains { (metadataObjectType: Any) -> Bool in (metadataObjectType as? String) == type.metadataObjectTypeValue }
        }
        
        return false
    }


    /// CALayer that displays the video stream as it is being captured by the input device.
    open lazy var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)

    /// An array of strings identifying the types of metadata objects to process. Conforms to `AVMetadataObjectType` naming convention.
    /// Example: AVMetadataObjectTypeFace, AVMetadataObjectTypeQRCode
    open let metadataObjectTypes: [String]

    open var currentMetadataTypes: [MetadataObjectType] {
        return metadataObjectTypes.map { type -> MetadataObjectType in
            return MetadataObjectType(rawValue: type)
        }
    }

    /// Block is executing when a QRCode or when the user did stopped the scan.
    open var completionBlock: ((String?) -> ())?

    /**
     Indicates whether the session is currently running.

     Clients can use KVO here to be notified when the session automatically starts or stops running.
     */
    public var running: Bool {
        get {
            return self.session.isRunning
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
     Returns true if device has a torch/flashlight.

     - returns: Bool indicating if a flashlight is available.
     */
    public var isFlashlightAvailable: Bool {
        return self.isTorchAvailable
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

    public init(types: [MetadataObjectType]) {
        self.metadataObjectTypes = types.map{ (type) -> String in type.metadataObjectTypeValue }

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
    public func start() {
        guard !self.session.isRunning else { return }
        self.session.startRunning()
    }

    /// Stops scanning the codes.
    public func stop() {
        guard self.session.isRunning else { return }
        self.session.stopRunning()
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
                self.stop()

                let scannedResult = readableCodeObject.stringValue

                DispatchQueue.main.async { [weak self] in
                    self?.completionBlock?(scannedResult)
                }
            }
        }
    }
}
