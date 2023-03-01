//
//  ScanViewController.swift
//  TestProject
//
//  Created by Encompass on 2021/11/9.
//

import UIKit
import AVFoundation

let kScreenHeight = UIScreen.main.bounds.size.height
let kScreenWidth = UIScreen.main.bounds.size.width

let kTop = (kScreenHeight-220)/2 - 30
let kLeft = (kScreenWidth-220)/2

class CodeScannerViewController: UIViewController , AVCaptureMetadataOutputObjectsDelegate{
    
    public var scanResultCallBack: ((String) -> ())?
    
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var outPut: AVCaptureMetadataOutput?
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var line: UIImageView?
    var timer: Timer?
    
    var num: Int?
    var upOrdown: Bool?
    var cropLayer: CAShapeLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        initViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setCropRect(cropRect: CGRect.init(x: kLeft, y: kTop, width: 220, height: 220))
        
        Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(setupCamera), userInfo: nil, repeats: false)
    }
    
    func initViews() {
        let imageView = UIImageView.init(frame: CGRect.init(x: kLeft, y: kTop, width: 220, height: 220))
        imageView.image = ImageUtil().imageWithName(name: "img_bg")
        self.view.addSubview(imageView)
        
        line = UIImageView.init(frame: CGRect.init(x: kLeft, y: kTop + 10, width: 220, height: 2))
        line?.image = ImageUtil().imageWithName(name: "line.png")
        self.view.addSubview(line!)
        
        upOrdown = true;
        num = 0;
        
        timer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(animation1), userInfo: nil, repeats: true)
        
    }
    
    @objc func animation1() {
        if (upOrdown == true) {
            num! += 1
            line?.frame = CGRect.init(x: kLeft, y: kTop+10+CGFloat(2*num!), width: 220, height: 2)
            if (2*num! == 200) {
                upOrdown = false;
            }
        }
        else {
            num! -= 1
            line?.frame = CGRect.init(x: kLeft, y: kTop+10+CGFloat(2*num!), width: 220, height: 2)
            if (num! == 0) {
                upOrdown = true;
            }
        }
    }
    
    func setCropRect(cropRect: CGRect) {
        cropLayer = CAShapeLayer.init()
        let path = CGMutablePath.init()
        path.addRect(cropRect)
        path.addRect(self.view.bounds)
        
        cropLayer?.fillRule = .evenOdd
        cropLayer?.path = path
        cropLayer?.fillColor = UIColor.white.cgColor
        cropLayer?.opacity = 0.6
        
        cropLayer?.setNeedsDisplay()
        
        self.view.layer.addSublayer(cropLayer!)
    }
    
    @objc func setupCamera() {
        let tempDevice = AVCaptureDevice.default(for: .video)
        if tempDevice == nil {
            return
        }
        
        device = AVCaptureDevice.default(for: .video)
        do {
            input = try AVCaptureDeviceInput.init(device: device!)
        } catch {
            
        }
        outPut = AVCaptureMetadataOutput.init()
        outPut?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        // Set the scan area
        let top = kTop/kScreenHeight
        let left = kLeft/kScreenWidth
        let width = 220/kScreenWidth
        let height = 220/kScreenHeight
        
        outPut?.rectOfInterest = CGRect.init(x: top, y: left, width: height, height: width)
        
        session = AVCaptureSession.init()
        session?.sessionPreset = .high
        if (session?.canAddInput(input!)) == true {
            session?.addInput(input!)
        }
        if session?.canAddOutput(outPut!) == true {
            session?.addOutput(outPut!)
        }
        
        outPut?.metadataObjectTypes = [.qr, .upce, .code128, .ean13, .code39, .code93]
        
        previewLayer = AVCaptureVideoPreviewLayer.init(session: session!)
        previewLayer?.frame = self.view.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        self.view.layer.insertSublayer(previewLayer!, at: 0)
        
        session?.startRunning()
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0 {
            
            session?.stopRunning()
            timer?.invalidate()
            
            let object : AVMetadataMachineReadableCodeObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            let result = object.stringValue
            self.dismiss(animated: true, completion: nil)
            if scanResultCallBack != nil {
                scanResultCallBack!(result ?? "")
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
