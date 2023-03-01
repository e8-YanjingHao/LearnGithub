//
//  PermissionUtil.swift
//  MobileFrame
//
//  Created by Encompass on 2021/11/19.
//

import UIKit
import AVFoundation
import CoreLocation

public class PermissionUtil: NSObject {
    
    public static func canAccessCamera(vc : UIViewController, callBack : @escaping (Bool) -> ()){
        let authStatus : AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .denied || authStatus == .restricted {
            
//            let alertController = UIAlertController.init(title: "Alert", message: "Please enable your camera to be used by DSDLink: Setting-Privacy-Camera: Turn on DSDLink.", preferredStyle: .alert)
//            alertController.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
//            alertController.addAction(UIAlertAction.init(title: "Settings", style: .default, handler: { action in
//                let settingUrl = NSURL(string: UIApplication.openSettingsURLString)!
//                if UIApplication.shared.canOpenURL(settingUrl as URL){
//                    UIApplication.shared.open(settingUrl as URL, options: [:], completionHandler: nil)
//                }
//            }))
//            if let NVVC = vc.navigationController {
//                NVVC.present(alertController, animated: true, completion: nil)
//            } else {
//                vc.present(alertController, animated: true, completion: nil)
//            }
            callBack(false)
        } else if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    callBack(granted)
                }
            }
        }
        callBack(true)
    }
    
    public static func canLocation(vc : UIViewController, callBack : @escaping (Bool) -> ()) {
        let authStatus : CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if authStatus == .denied || authStatus == .restricted || authStatus == .notDetermined {
            
//           '' let alertController = UIAlertController.init(title: "Alert", message: "Please enable your Location to be used by DSDLink: Setting-Privacy-Location: Turn on DSDLink.", preferredStyle: .alert)
//            alertController.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { action in
//                callBack(false)
//            }))
//            alertController.addAction(UIAlertAction.init(title: "Settings", style: .default, handler: { action in
//                let settingUrl = NSURL(string: UIApplication.openSettingsURLString)!
//                if UIApplication.shared.canOpenURL(settingUrl as URL){
//                    UIApplication.shared.open(settingUrl as URL, options: [:], completionHandler: nil)
//                }
//            }))
//            if let NVVC = vc.navigationController {
//                NVVC.present(alertController, animated: true, completion: nil)
//            } else {
//                vc.present(alertController, animated: true, completion: nil)
//            }''
            callBack(false)
        }
        else {
            callBack(true)
        }
    }
}
