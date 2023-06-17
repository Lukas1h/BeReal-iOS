//
//  CustomCameraView.swift
//  BeRealRewrite
//
//  Created by Lukas Hahn on 5/17/23.
//

import SwiftUI
import AVFoundation



enum FilterType : String, CaseIterable {
    case Chrome = "CIPhotoEffectChrome"
    case Fade = "CIPhotoEffectFade"
    case Instant = "CIPhotoEffectInstant"
    case Mono = "CIPhotoEffectMono"
    case Noir = "CIPhotoEffectNoir"
    case Process = "CIPhotoEffectProcess"
    case Tonal = "CIPhotoEffectTonal"
    case Transfer = "CIPhotoEffectTransfer"
    case Bloom = "CIBloom"
    case ComicEffect = "CIComicEffect"
    case Crystallize = "CICrystallize"
    case EdgeWork = "CIEdgeWork"
    case Gloom = "CIGloom"
    case HexagonalPixellate = "CIHexagonalPixellate"
    case Pixellate = "CIPixellate"
    case SepiaTone = "CISepiaTone"
    case Vignette = "CIVignette"
    
    func getNext() -> FilterType {
        guard let currentIndex = Self.allCases.firstIndex(of: self) else {
            return Self.allCases.first!
        }
        let nextIndex = (currentIndex + 1) % Self.allCases.count
        return Self.allCases[nextIndex]
    }
}




struct CustomCameraView: View {
    
    enum SelectedCameraMenu {
        case filters
        case effect
        case none
    }
    @State var selectedCameraMenu = SelectedCameraMenu.none
    @Binding var frontImage: UIImage?
    @Binding var backImage: UIImage?
    @State var didTapCapture: Bool = false
    @State var didTapReverseInt: Int = 0
    @State var filterType = FilterType.Instant
    @State var isFront = true
    
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            CustomCameraRepresentable(frontImage: self.$frontImage, backImage: self.$backImage, didTapCapture: $didTapCapture, didTapReverseInt: self.$didTapReverseInt, filterType: self.$filterType, isFront: self.$isFront)
                .background(
                    VStack{
                        ProgressView()
                            .controlSize(.large)
                        
                    }
                        .frame(maxWidth: .infinity,maxHeight: .infinity)
                        .background(Color(uiColor: UIColor.systemGray6))
                )

            
            VStack{
                ScrollView(.horizontal,showsIndicators: false) {
                    HStack(spacing: 4) {
                        if(selectedCameraMenu == .filters || selectedCameraMenu == .none){
                            Button{
                                withAnimation(.spring()){
                                    if(selectedCameraMenu == .filters){
                                        selectedCameraMenu = .none
                                    }else if(selectedCameraMenu == .none){
                                        selectedCameraMenu = .filters
                                    }
                                }
                            } label: {
                                Image(systemName:"camera.filters")
                                    .font(.system(size:28))
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .padding(4)
                                    .foregroundColor(.white)
                            }
                        }
                        if(selectedCameraMenu == .effect || selectedCameraMenu == .none){
                            Button{
                                withAnimation(.spring()){
                                    if(selectedCameraMenu == .effect){
                                        selectedCameraMenu = .none
                                    }else if(selectedCameraMenu == .none){
                                        selectedCameraMenu = .effect
                                    }
                                }
                            } label: {
                                Image(systemName:"camera")
                                    .font(.system(size:28))
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .padding(4)
                                    .foregroundColor(.white)
                            }
                        }
                        if(self.selectedCameraMenu == .filters){
                            Group{
                                ForEach(FilterType.allCases, id: \.self) { filterType in
                                    Button(action: {
                                        self.filterType = filterType
                                    }) {
                                        Text(filterType.rawValue)
                                            .font(.headline)
                                            .padding(8)
                                            .background(.ultraThinMaterial)
                                            .overlay{
                                                Capsule().stroke(lineWidth:4).foregroundColor(self.filterType == filterType ? Color.gray: Color.clear)
                                            }
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                            .shadow(radius: 8)
                                    }
                                }
                            }
                        }
                        
                    }
                    .padding()
                }
                Spacer()
                HStack{
                    Button{
                        print("setting reverse")
                        self.isFront.toggle()
                        
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 24))
                            .padding(.horizontal,20)
                            .foregroundColor(.white)
                    }
                    
                    CaptureButtonView().onTapGesture {
                        self.didTapCapture = true
                    }
                    
                    ChooseButtonView()
                    
                }
            }
        }
    }
}



struct CustomCameraRepresentable: UIViewControllerRepresentable {
    
    @Binding var frontImage: UIImage?
    @Binding var backImage: UIImage?
    @Binding var didTapCapture: Bool
    @Binding var didTapReverseInt: Int
    @State var oldDidTapReverseIntObject:Dictionary<String,Int> = ["count":0]
    @State var isRotated = false
    @Binding var filterType: FilterType
    @Binding var isFront: Bool
    //For getting around those pesky `Modifying state during view update, this will cause undefined behavior.` errors
    
    
    func makeUIViewController(context: Context) -> CustomCameraController {
        let controller = CustomCameraController()
        controller.filter = CIFilter(name: filterType.rawValue)!
        controller.isFront = isFront
        controller.delegate1 = Coordinator1(self)
        controller.delegate2 = Coordinator2(self)
        return controller
    }
    
    
    
    func updateUIViewController(_ cameraViewController: CustomCameraController, context: Context) {
        
        if(cameraViewController.filter!.name != CIFilter(name: filterType.rawValue)!.name){
            cameraViewController.filter = CIFilter(name: filterType.rawValue)!
        }else{
        }
        
        if(self.didTapCapture) {
            cameraViewController.didTapRecord()
        }
        
        if(isFront != cameraViewController.isFront){
            if(isFront){
                cameraViewController.setFrontCam()
            }else{
                cameraViewController.setBackCam()
            }
            cameraViewController.isFront = isFront
        }
        //cameraViewController.checkRotate()
    }
    
    class Coordinator1: NSObject, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
        let parent: CustomCameraRepresentable
        
        init(_ parent: CustomCameraRepresentable) {
            self.parent = parent
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
          print("Photo output 1")
            parent.didTapCapture = false
            if let imageData = photo.fileDataRepresentation() {
                

                let im = UIImage(data: imageData)
                let ciImage: CIImage = CIImage(cgImage: im!.cgImage!).oriented(forExifOrientation: 6)
                
                let filter = CIFilter(name: parent.filterType.rawValue)
                filter?.setValue(ciImage, forKey: "inputImage")

                
                print("Setting front image")
                parent.frontImage = UIImage.convert(from: filter!.outputImage!)
                
            }
            
        }
    }
    class Coordinator2: NSObject, UINavigationControllerDelegate, AVCapturePhotoCaptureDelegate {
        let parent: CustomCameraRepresentable
        
        init(_ parent: CustomCameraRepresentable) {
            self.parent = parent
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            print("Photo output 2",photo)
            parent.didTapCapture = false
            
            
            if let error = error {
                print("Error capturing photo: \(error)")
                return
            }
            
            if let imageData = photo.fileDataRepresentation() {
                

                let im = UIImage(data: imageData)
                let ciImage: CIImage = CIImage(cgImage: im!.cgImage!).oriented(forExifOrientation: 6)
                
                print("filter name is for 2",parent.filterType.rawValue)
                let filter = CIFilter(name: parent.filterType.rawValue)
                filter?.setValue(ciImage, forKey: "inputImage")
                
                print("Setting back image")
                parent.backImage = UIImage.convert(from: filter!.outputImage!)
                
            }else{
                print("faild to get data from image 2")
            }
        }
    }
}

class CustomCameraController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var image: UIImage?
    
    var filter: CIFilter?
    
    var captureSession = AVCaptureMultiCamSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    var photoOutput1: AVCapturePhotoOutput?
    var photoOutput2: AVCapturePhotoOutput?
    var cameraPreviewLayer: UIImageView?
    
    var frontCameraVideoDataOutput = AVCapturePhotoOutput()
    var backCameraVideoDataOutput = AVCapturePhotoOutput()
    var backPreviewCameraVideoDataOutput = AVCaptureVideoDataOutput()
    var frontPreviewCameraVideoDataOutput = AVCaptureVideoDataOutput()
    
    var captureDeviceInput1Thing: AVCaptureInput? = nil
    
    //DELEGATE
    var delegate1: AVCapturePhotoCaptureDelegate?
    var delegate2: AVCapturePhotoCaptureDelegate?
    
    var isFront = false
    
    
    func setFrontCam(){
        
        backPreviewCameraVideoDataOutput.setSampleBufferDelegate(nil, queue: DispatchQueue(label: "videoQueue"))
        frontPreviewCameraVideoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
    }
    
    func setBackCam(){
        backPreviewCameraVideoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        frontPreviewCameraVideoDataOutput.setSampleBufferDelegate(nil, queue: DispatchQueue(label: "videoQueue"))
        
    }
    
    
    
    
    func didTapRecord() {
        print("record tapped")
        
        
        
        
        
        // Configure photo settings
        let frontPhotoSettings = AVCapturePhotoSettings()
        let backPhotoSettings = AVCapturePhotoSettings()

        
        // Capture photos
        if(isFront){
            frontCameraVideoDataOutput.capturePhoto(with: frontPhotoSettings, delegate: delegate1!)
            backCameraVideoDataOutput.capturePhoto(with: backPhotoSettings, delegate: delegate2!)
        }else{
            backCameraVideoDataOutput.capturePhoto(with: frontPhotoSettings, delegate: delegate1!)
            frontCameraVideoDataOutput.capturePhoto(with: backPhotoSettings, delegate: delegate2!)
        }
        
    }


    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        setupDevice()
        

        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("Multi-camera capture is not supported!")
            return
        }
        
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let rearCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get cameras")
            return
        }
        

        
        // Add inputs for front and rear cameras to the multi-camera session
        let frontCameraDeviceInput = try! AVCaptureDeviceInput(device: frontCamera)
        let backCameraDeviceInput = try! AVCaptureDeviceInput(device: rearCamera)

        captureSession.addInputWithNoConnections(frontCameraDeviceInput)
        captureSession.addInputWithNoConnections(backCameraDeviceInput)

        captureSession.addOutputWithNoConnections(backPreviewCameraVideoDataOutput)
        captureSession.addOutputWithNoConnections(frontPreviewCameraVideoDataOutput)
        captureSession.addOutputWithNoConnections(frontCameraVideoDataOutput)
        captureSession.addOutputWithNoConnections(backCameraVideoDataOutput)
        
        let frontCameraVideoPort =  frontCameraDeviceInput.ports(for: .video,
                                                                 sourceDeviceType: frontCamera.deviceType,
                                                                 sourceDevicePosition: AVCaptureDevice.Position(rawValue: (frontCamera.position).rawValue) ?? AVCaptureDevice.Position.front).first
        
        
        let backCameraVideoPort =  backCameraDeviceInput.ports(for: .video,
                                                              sourceDeviceType: backCamera?.deviceType,
                                                              sourceDevicePosition: AVCaptureDevice.Position(rawValue: (backCamera?.position)!.rawValue) ?? AVCaptureDevice.Position.back).first
        
        
        let backPreviewCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [backCameraVideoPort!], output: backPreviewCameraVideoDataOutput)
        let frontPreviewCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [frontCameraVideoPort!], output: frontPreviewCameraVideoDataOutput)
        let frontCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [frontCameraVideoPort!], output: frontCameraVideoDataOutput)
        let backCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [backCameraVideoPort!], output: backCameraVideoDataOutput)

        captureSession.addConnection(backPreviewCameraVideoDataOutputConnection)
        frontCameraVideoDataOutputConnection.videoOrientation = .portrait
        captureSession.addConnection(frontPreviewCameraVideoDataOutputConnection)
        frontCameraVideoDataOutputConnection.videoOrientation = .portrait
        captureSession.addConnection(frontCameraVideoDataOutputConnection)
        frontCameraVideoDataOutputConnection.videoOrientation = .portrait
        captureSession.addConnection(backCameraVideoDataOutputConnection)
        backCameraVideoDataOutputConnection.videoOrientation = .portrait
        
        
        cameraPreviewLayer = UIImageView(frame:  UIScreen.main.bounds )
        cameraPreviewLayer!.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(cameraPreviewLayer!, at: 0)
        
        cameraPreviewLayer!.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        cameraPreviewLayer!.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        cameraPreviewLayer!.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        cameraPreviewLayer!.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        
        frontPreviewCameraVideoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        
        
        self.captureSession.commitConfiguration()
        
        startRunningCaptureSession()
        
    }
    

    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                                      mediaType: AVMediaType.video,
                                                                      position: AVCaptureDevice.Position.unspecified)
        for device in deviceDiscoverySession.devices {
            
            switch device.position {
            case AVCaptureDevice.Position.front:
                self.frontCamera = device
            case AVCaptureDevice.Position.back:
                self.backCamera = device
            default:
                break
            }
        }
        
        self.currentCamera = self.backCamera
    }
    

    func setupPreviewLayer()
    {
//        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        cameraPreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspect
//        cameraPreviewLayer!.connection?.videoOrientation = .portrait
//        cameraPreviewLayer!.frame = view.frame
//        view.layer.insertSublayer(cameraPreviewLayer!, at: 0)

        
    }
    
    func startRunningCaptureSession(){
        DispatchQueue.init(label: "startRunningCaptureSession").async {
            self.captureSession.startRunning()
        }
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: imageBuffer)
        ciImage = ciImage.oriented(forExifOrientation: 6)
        filter!.setValue(ciImage, forKey: kCIInputImageKey)
        
        if let outputImage = filter!.outputImage {
            let context = CIContext()
            let cgImage = context.createCGImage(outputImage, from: outputImage.extent,format: .RGBA8, colorSpace: nil, deferred: false)!
            DispatchQueue.main.async {

                // Calculate the aspect ratio of the CIImage
                let aspectRatio = ciImage.extent.width / ciImage.extent.height

                // Calculate the width of the view based on its height and the inverse of the aspect ratio
                let newWidth = self.view.frame.height * aspectRatio

                // Create a new CGRect with the same origin and size as the view, but with the new width
                let newFrame = CGRect(x: self.view.frame.origin.x, y: self.view.frame.origin.y, width: newWidth, height: self.view.frame.height)

                // Set the view's frame to the new frame
                self.cameraPreviewLayer!.frame = newFrame
                
                self.cameraPreviewLayer!.image = UIImage(ciImage: outputImage)
            }
        }
    }
    
}


struct CaptureButtonView: View {
    var body: some View {
        ZStack {
           Circle()
               .fill(Color.white)
               .frame(width: 64, height: 64)
           
           Circle()
               .strokeBorder(Color.white, lineWidth: 4)
               .frame(width: 80, height: 80)
       }
        .padding()
    }
}

struct ReverseButtonView: View {
    var body: some View {
        Image(systemName: "arrow.triangle.2.circlepath")
            .font(.system(size: 24))
            .padding(.horizontal,20)
    }
}

struct ChooseButtonView: View {
    var body: some View {
        Image(systemName: "photo.on.rectangle")
            .font(.system(size: 24))
            .padding(.horizontal,20)
    }
}


extension UIImage{
    static func convert(from ciImage: CIImage) -> UIImage{
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}





/* func didTapRecord() {
 
 
 
 let swiftUIView = ProgressView()
 let hostingController = UIHostingController(rootView: swiftUIView)
 addChild(hostingController)
 
 // Set the size of the hosting view controller to match the parent view's bounds
 hostingController.view.frame = view.bounds
 hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
 
 // Add the hosting view controller's view to the parent view
 view.addSubview(hostingController.view)
 
 
 
 
 
 
 hostingController.didMove(toParent: self)

 for input in captureSession.inputs {
     captureSession.removeInput(input);
 }
 for output in captureSession.outputs {
     captureSession.removeOutput(output);
 }
 
 let photoSettings1 = AVCapturePhotoSettings()
 photoSettings1.isHighResolutionPhotoEnabled = true
 photoSettings1.previewPhotoFormat = [
     kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
     kCVPixelBufferWidthKey as String: 160,
     kCVPixelBufferHeightKey as String: 160
 ]
 photoSettings1.flashMode = .auto
 photoSettings1.photoQualityPrioritization =  .quality
 photoSettings1.isHighResolutionPhotoEnabled = true
 photoSettings1.isAutoRedEyeReductionEnabled = true
 
 

 
 let photoOutput = AVCapturePhotoOutput()
 photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)
 photoOutput.maxPhotoQualityPrioritization = .quality
 photoOutput.isHighResolutionCaptureEnabled = true
 

 
 let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)

 
 let frontCameraInput = try! AVCaptureDeviceInput(device: frontCamera!)
 
 captureSession.addInput(frontCameraInput)
 
 
 let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)

 
 
 let backCameraInput = try! AVCaptureDeviceInput(device: backCamera!)
 
 captureSession.addOutput(photoOutput)
 
 print("taking one")
 if(isFront){
     photoOutput.capturePhoto(with: AVCapturePhotoSettings(from: photoSettings1), delegate: self.delegate1!)
     print("front")
 }else{
     photoOutput.capturePhoto(with: AVCapturePhotoSettings(from: photoSettings1), delegate: self.delegate2!)
     print("back")
 }
 
 // Switch to the back camera
 captureSession.removeInput(frontCameraInput)
 captureSession.addInput(backCameraInput)

 print("taking two")
 if(!isFront){
     photoOutput.capturePhoto(with: AVCapturePhotoSettings(from: photoSettings1), delegate: self.delegate1!)
     print("front")
 }else{
     photoOutput.capturePhoto(with: AVCapturePhotoSettings(from: photoSettings1), delegate: self.delegate2!)
     print("back")
 }

 // Switch back to the front camera
 captureSession.removeInput(backCameraInput)
 captureSession.addInput(frontCameraInput)
}*/
