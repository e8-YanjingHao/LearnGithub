//
//  NetWorkManager.swift
//  ECPCAppFramework
//
//  Created by ERIC on 2021/11/12.
//

import Foundation
import UIKit
import SwiftyJSON
import Tiercel
 
public class NetWorkManager: NSObject {
     
    public static var shared = NetWorkManager()
    
    public lazy var sessionManager: SessionManager = {
        var configuration = SessionConfiguration()
        configuration.allowsCellularAccess = true
        let dashboardRootPath = MobileFrameEngine.shared.config.rootPath
        let downloadFilePath = MobileFrameEngine.shared.config.zipFilesPath
        let cacahe = Cache("MobileFrameEngine", downloadPath: dashboardRootPath, downloadTmpPath: nil, downloadFilePath: downloadFilePath)
        let manager = SessionManager("MobileFrameEngine", configuration: configuration, cache: cacahe, operationQueue: DispatchQueue(label: "com.Tiercel.SessionManager.operationQueue"))
        return manager
    }()
        
    public func getWithPath(path: String, paras: Dictionary<String,Any>?, success: @escaping ((_ result: Any) -> ()), failure: @escaping ((_ error: Error) -> ())) {
        var i = 0
        var address = path
        if let paras = paras {
            for (key,value) in paras {
                if i == 0 {
                    address += "?\(key)=\(value)"
                }else {
                    address += "&\(key)=\(value)"
                }
                i += 1
            }
        }
        let url = URL(string: address.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url!) { (data, respond, error) in
            if let data = data {
                if let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments){
                    success(result)
                }
            }else {
                failure(error!)
            }
        }
        dataTask.resume()
    }
    
    public func postWithPath(path: String, paras: Dictionary<String,Any>?, success: @escaping ((_ result: Any) -> ()), failure: @escaping ((_ error: Error) -> ())) {
        var i = 0
        var address: String = ""
        if let paras = paras {
            for (key,value) in paras {
                if i == 0 {
                    address += "\(key)=\(value)"
                }else {
                    address += "&\(key)=\(value)"
                }
                i += 1
            }
        }
        let url = URL(string: path)
        var request = URLRequest.init(url: url!)
        request.httpMethod = "POST"
        request.httpBody = address.data(using: .utf8)
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data, respond, error) in
            if let data = data {
                if let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                    success(result)
                }
            }else {
                failure(error!)
            }
        }
        dataTask.resume()
    }
}
