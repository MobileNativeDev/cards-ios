
import AVKit
import UIKit
import Vision

class ViewController: UIViewController {
  let captureSession = AVCaptureSession()

  @IBOutlet var cameraView: UIView!
    @IBOutlet var switchView: UISwitch!
  @IBOutlet var descLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    startingTheCam()
  }

  // MARK: - Starting the camera

  func startingTheCam() {
    captureSession.sessionPreset = .photo
    guard let capturingDevice = AVCaptureDevice.default(for: .video) else { return }
    guard let capturingInput = try? AVCaptureDeviceInput(device: capturingDevice) else { return }
    captureSession.addInput(capturingInput)
    let cameraDataOutput = AVCaptureVideoDataOutput()
    cameraDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "outputVideo"))
    captureSession.addOutput(cameraDataOutput)
    let cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    cameraPreviewLayer.frame = cameraView.bounds
    cameraView.layer.addSublayer(cameraPreviewLayer)
    captureSession.startRunning()
  }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }
    guard let resNetModel = self.switchView.isOn ? try? VNCoreMLModel(for: ImageClassifier2().model) : try? VNCoreMLModel(for: ImageClassifier().model) else { return }
    let requestCoreML = VNCoreMLRequest(model: resNetModel) { vnReq, err in
      DispatchQueue.main.async {
        if err == nil {
          guard let capturedRes = vnReq.results as? [VNClassificationObservation] else { return }

          guard let firstObserved = capturedRes.first else { return }

          print(firstObserved.identifier, firstObserved.confidence)
        
            if firstObserved.confidence > 0.65 {
              self.descLabel.text = String(format: "This may be %.2f%% %@", firstObserved.confidence, firstObserved.identifier)
            }
        }
      }
    }

    try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([requestCoreML])
  }
}
