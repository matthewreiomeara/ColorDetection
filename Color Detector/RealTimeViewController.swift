//
//  ViewController.swift
//  ColorDetector
//
//  Created by Matthew O'Meara on 1/11/21.
//

import UIKit
import AVFoundation
import KDTree

class RealTimeViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    //creates an instance of AVCaptureSession
    private let captureSession = AVCaptureSession()
    
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
        preview.videoGravity = .resizeAspect
        //print(preview.)
        return preview
    }()
    
    private let videoOutput = AVCaptureVideoDataOutput()
    
    @IBAction func moreInfo(_ sender: Any) {
    }
    var buttonColor: UIColor?
    
    @IBOutlet weak var ColorSquare: UILabel!
    
    
    @IBOutlet weak var Color: UILabel!
    
    
    @IBAction func goBack(_ sender: Any){
        performSegue(withIdentifier: "goToMain", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMain" {
            guard let vc = segue.destination as? ViewController else {
                return
            }
            vc.modalPresentationStyle = .fullScreen
            self.captureSession.stopRunning()
            
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        self.addCameraInput()
        self.addPreviewLayer()
        self.createTargetCircle()
        self.createCrossHairs()
        self.addVideoOutput()
        self.captureSession.startRunning()
        // Do any additional setup after loading the view.
    }
    
    //adds back camera as capture input to our capture session
    private func addCameraInput(){
        let device = AVCaptureDevice.default(for: .video)!
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func addPreviewLayer(){
        self.view.layer.addSublayer(self.previewLayer)
    }
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.bounds
    }
    
    private func addVideoOutput() {
        self.videoOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "my.image.handling.queue"))
        self.captureSession.addOutput(self.videoOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        CVPixelBufferLockBaseAddress(frame, CVPixelBufferLockFlags(rawValue: 0))
        let height = CVPixelBufferGetWidth(frame)/2
        let width = CVPixelBufferGetHeight(frame)/2
        let color = pixelFrom(x: height, y: width, frame: frame)
        let red = Double(color.0)
        let green = Double(color.1)
        let blue = Double(color.2)
        let average = red + green + blue
        let similarColor = similar(red: red, green: green, blue: blue)
        print(similarColor.0)

        DispatchQueue.main.async {
            
            if(average > 500) {
                self.Color.textColor = UIColor.black
            } else {
                self.Color.textColor = UIColor.white
            }
            self.Color.text = similarColor.0
            self.Color.backgroundColor = UIColor.init(red: CGFloat(similarColor.1)/255, green: CGFloat(similarColor.2)/255, blue: CGFloat(similarColor.3)/255, alpha: 1)
//            self.ColorSquare.backgroundColor = UIColor.init(red: CGFloat(similarColor.1)/255, green: CGFloat(similarColor.2)/255, blue: CGFloat(similarColor.3)/255, alpha: 1)
//
        }

    }
    
    func pixelFrom(x: Int, y: Int, frame: CVPixelBuffer) -> (UInt8, UInt8, UInt8) {
        let baseAddress = CVPixelBufferGetBaseAddress(frame)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(frame)
        let buffer = baseAddress!.assumingMemoryBound(to: UInt8.self)
        let index = x*4 + y*bytesPerRow
        let b = buffer[index]
        let g = buffer[index+1]
        let r = buffer[index+2]
        return(r,g,b)
    }
    
    private func createTargetCircle(){
        let camPreviewBounds = view.bounds
            let cropRect = CGRect(
                x: camPreviewBounds.minX + (camPreviewBounds.width - 50) * 0.5,
                y: camPreviewBounds.minY + (camPreviewBounds.height - 50) * 0.5,
                width: 50,
                height: 50
            )
            let path = UIBezierPath(roundedRect: camPreviewBounds, cornerRadius: 0)
            path.append(UIBezierPath(ovalIn: cropRect))
            let layer = CAShapeLayer()
            layer.path = path.cgPath
            layer.fillRule = CAShapeLayerFillRule.evenOdd
            layer.fillColor = UIColor.black.cgColor
            layer.opacity = 0.3;
            view.layer.addSublayer(layer)
    }
    
    private func createCrossHairs(){
        let path = UIBezierPath()
        path.move(to: CGPoint(x: view.center.x, y: view.center.y+4))
        path.addLine(to: CGPoint(x: view.center.x, y: view.center.y+25))
        path.move(to: CGPoint(x: view.center.x, y: view.center.y-4))
        path.addLine(to: CGPoint(x: view.center.x, y: view.center.y-25))
        path.move(to: CGPoint(x: view.center.x+4, y: view.center.y))
        path.addLine(to: CGPoint(x: view.center.x+25, y: view.center.y))
        path.move(to: CGPoint(x: view.center.x-4, y: view.center.y))
        path.addLine(to: CGPoint(x: view.center.x-25, y: view.center.y))
    
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 1.2
        shapeLayer.opacity = 0.8
        
        let bounds = CAShapeLayer()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: view.bounds.maxX, y: view.bounds.maxY))
        line.addLine(to: CGPoint(x: view.bounds.minX, y:view.bounds.maxY))
        bounds.path = line.cgPath
        bounds.strokeColor = UIColor.white.cgColor
        bounds.lineWidth = 5
        bounds.opacity = 1
        
        print(view.bounds.maxX)
        
        
        
//        let circleLayer = CAShapeLayer();
//        circleLayer.path = UIBezierPath(ovalIn: CGRect(x: view.center.x-1, y: view.center.y-1, width: 2, height: 2)).cgPath
//        circleLayer.strokeColor = UIColor.black.cgColor
//        circleLayer.lineWidth = 0.5
//        shapeLayer.opacity = 1
        view.layer.addSublayer(shapeLayer)
        //view.layer.addSublayer(bounds)
//        view.layer.addSublayer(circleLayer)
    }
    
    private func similar(red: Double, green: Double, blue: Double) -> (String,Int,Int,Int){
        
        var distance: Double?
        var index: Int?
        var simColor: (Int,Int,Int)?
        let returnColor: (String, Int,Int,Int)?
        let keys = ["Maroon","Dark Red","Brown","Firebrick","Crimson","Red","Tomato","Coral","Indian Red","Light Coral","Dark Salmon","Salmon","Light Salmon","Orange Red","Dark Orange","Orange","Gold","Dark Golden Rod","Golden Rod","Pale Golden Rod","Dark Khaki","Khaki","Olive","Yellow","Yellow Green","Dark Olive Green","Olive Drab","Lawn Green","Chart Reuse","Green Yellow","Dark Green","Green","Forest Green","Lime","Lime Green","Light Green","Pale Green","Dark Sea Green","Medium Spring Green","Spring Green","Sea Green","Medium Aqua Marine","Medium Sea Green","Light Sea Green","Dark Slate Gray","Teal","Dark Cyan","Aqua","Cyan","Light Cyan","Dark Turquoise","Turquoise","Medium Turquoise","Pale Turquoise","Aqua Marine","Powder Blue","Cadet Blue","Steel Blue","Corn Flower Blue","Deep Sky Blue","Dodger Blue","Light Blue","Sky Blue","Light Sky Blue","Midnight Blue","Navy","Dark Blue","Medium Blue","Blue","Royal Blue","Blue Violet","Indigo","Dark Slate Blue","Slate Blue","Medium Slate Blue","Medium Purple","Dark Magenta","Dark Violet","Dark Orchid","Medium Orchid","Purple","Thistle","Plum","Violet","Magenta","Orchid","Medium Violet Red","Pale Violet Red","Deep Pink","Hot Pink","Light Pink","Pink","Antique White","Beige","Bisque","Blanched Almond","Wheat","Corn Silk","Lemon Chiffon","Light Golden Rod Yellow","Light Yellow","Saddle Brown","Sienna","Chocolate","Peru","Sandy Brown","Burly Wood","Tan","Rosy Brown","Moccasin","Navajo White","Peach Puff","Misty Rose","Lavender Blush","Linen","Old Lace","Papaya Whip","Sea Shell","Mint Cream","Slate Gray","Light Slate Gray","Light Steel Blue","Lavender","Floral White","Alice Blue","Ghost White","Honeydew","Ivory","Azure","Snow","Black","Dim Gray","Gray","Dark Gray","Silver","Light Gray","Gainsboro","White Smoke","White"]
        let values = [[128,0,0],[139,0,0],[165,42,42],[178,34,34],[220,20,60],[255,0,0],[255,99,71],[255,127,80],[205,92,92],[240,128,128],[233,150,122],[250,128,114],[255,160,122],[255,69,0],[255,140,0],[255,165,0],[255,215,0],[184,134,11],[218,165,32],[238,232,170],[189,183,107],[240,230,140],[128,128,0],[255,255,0],[154,205,50],[85,107,47],[107,142,35],[124,252,0],[127,255,0],[173,255,47],[0,100,0],[0,128,0],[34,139,34],[0,255,0],[50,205,50],[144,238,144],[152,251,152],[143,188,143],[0,250,154],[0,255,127],[46,139,87],[102,205,170],[60,179,113],[32,178,170],[47,79,79],[0,128,128],[0,139,139],[0,255,255],[0,255,255],[224,255,255],[0,206,209],[64,224,208],[72,209,204],[175,238,238],[127,255,212],[176,224,230],[95,158,160],[70,130,180],[100,149,237],[0,191,255],[30,144,255],[173,216,230],[135,206,235],[135,206,250],[25,25,112],[0,0,128],[0,0,139],[0,0,205],[0,0,255],[65,105,225],[138,43,226],[75,0,130],[72,61,139],[106,90,205],[123,104,238],[147,112,219],[139,0,139],[148,0,211],[153,50,204],[186,85,211],[128,0,128],[216,191,216],[221,160,221],[238,130,238],[255,0,255],[218,112,214],[199,21,133],[219,112,147],[255,20,147],[255,105,180],[255,182,193],[255,192,203],[250,235,215],[245,245,220],[255,228,196],[255,235,205],[245,222,179],[255,248,220],[255,250,205],[250,250,210],[255,255,224],[139,69,19],[160,82,45],[210,105,30],[205,133,63],[244,164,96],[222,184,135],[210,180,140],[188,143,143],[255,228,181],[255,222,173],[255,218,185],[255,228,225],[255,240,245],[250,240,230],[253,245,230],[255,239,213],[255,245,238],[245,255,250],[112,128,144],[119,136,153],[176,196,222],[230,230,250],[255,250,240],[240,248,255],[248,248,255],[240,255,240],[255,255,240],[240,255,255],[255,250,250],[0,0,0],[105,105,105],[128,128,128],[169,169,169],[192,192,192],[211,211,211],[220,220,220],[245,245,245],[255,255,255]]

        let XYZ = RGBtoXYZ(red: red, green: green, blue: blue)
        let LAB = XYZtoLAB(x: XYZ.0, y: XYZ.1, z: XYZ.2)
        for i in 0...138 {
            let XYZ2 = RGBtoXYZ(red: Double(values[i][0]), green: Double(values[i][1]), blue: Double(values[i][2]))
            let LAB2 = XYZtoLAB(x: XYZ2.0, y: XYZ2.1, z: XYZ2.2)
            let L = pow((LAB.0 - LAB2.0),2)
            let A = pow((LAB.1 - LAB2.1),2)
            let B = pow((LAB.2 - LAB2.2),2)
            let average = (L+A+B).squareRoot()
            
            if(distance == nil) {
                distance = average
                simColor = (values[i][0],values[i][1],values[i][2])
                index = i
            } else if (distance! > average){
                distance = average
                simColor = (values[i][0],values[i][1],values[i][2])
                index = i
            }
        }
        returnColor = (keys[index!],simColor!.0,simColor!.1,simColor!.2)
        return returnColor!
        
        
    }
    
    func RGBtoXYZ(red: Double, green: Double, blue: Double) -> (Double,Double,Double){
        var r = (red/255)
        var g = (green/255)
        var b = (blue/255)
        
        if(r > 0.04045){
            r = pow(((r+0.055)/1.055), 2.4)
        } else {
            r = r/12.92
        }
        if(g > 0.04045){
            g = pow(((g+0.055)/1.055), 2.4)
        } else {
            g = g/12.92
        }
        if(b > 0.04045){
            b = pow(((b+0.055)/1.055), 2.4)
        } else {
            b = b/12.92
        }
        r *= 100
        g *= 100
        b *= 100
        let x = (r * 0.4124) + (g * 0.3576) + (b * 0.1805)
        let y = (r * 0.2126) + (g * 0.7152) + (b * 0.0722)
        let z = (r * 0.0193) + (g * 0.1192) + (b * 0.9505)
        return(x,y,z)
    }
    
    func XYZtoLAB(x: Double, y: Double, z: Double) -> (Double,Double,Double){
        var refX = x/95.047
        var refY = y/100.000
        var refZ = z/108.883
        
        if(refX > 0.008856) {
            refX = pow(refX,1/3)
        } else {
            refX = (7.787 * refX) + (16/116)
        }
        if(refY > 0.008856) {
            refY = pow(refY,1/3)
        } else {
            refY = (7.787 * refY) + (16/116)
        }
        if(refZ > 0.008856) {
            refZ = pow(refZ,1/3)
        } else {
            refZ = (7.787 * refZ) + (16/116)
        }
        let L = (116 * refY) - 16
        let A = 500 * (refX-refY)
        let B = 200 * (refY - refZ)
        return (L,A,B)
    }
    
    override open var shouldAutorotate: Bool {
        return  false
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    
}

extension UINavigationController {
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? .portrait
    }
}

