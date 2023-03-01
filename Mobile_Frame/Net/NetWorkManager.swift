//
//  NetWorkManager.swift
//
//  Created by ERIC on 2021/11/12.
//

import Foundation
import UIKit
import SwiftyJSON
import Alamofire
 
public class NetWorkManager: NSObject {
     
    public static var shared = NetWorkManager()

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
        var request = URLRequest.init(url: url!)
        request.httpMethod = "GET"
        request.httpShouldHandleCookies = true
        
        request.addValue(MobileFrameEngine.shared.config.userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue("text/html", forHTTPHeaderField: "Content-Type")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let session = URLSession.shared
        session.configuration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        session.configuration.httpShouldSetCookies = true
        let dataTask = session.dataTask(with: request) { (data, respond, error) in
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
        
        var requestUrl = URL(string: path)
        if let url = URL(string: path) {
            requestUrl = url
        }
        else {
            if let urlStr = path.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed) {
                requestUrl = URL(string: urlStr)
            }
            else {
                let error = NSError(domain: "Bed Request Url", code: -5003, userInfo: nil)
                failure(error)
                return
            }
        }
        var request = URLRequest.init(url: requestUrl!)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = true
        request.httpBody = address.data(using: .utf8)
        
        request.addValue(MobileFrameEngine.shared.config.userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let session = URLSession.shared
        session.configuration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        session.configuration.httpShouldSetCookies = true
        let dataTask = session.dataTask(with: request) { (data, respond, error) in
            DispatchQueue.main.async {
                if let data = data {
                    let log = "URL:\(path) \n\n Params:\(paras?.toJsonString() ?? "") \n\n Result:\(String(data: data, encoding: .utf8) ?? "")"
                    SLogNet(log)

                    if let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                        
                        let data = JSON(result)
                        let errorCode = data["ErrorCode"].intValue
                        if(errorCode == 0) {
                            success(result)
                        } else if errorCode == 1001 {
                            LoginManager.shared.verifySession { [unowned self] VerifySuccess, SocketSessionID, SocketServerURL in
                                if VerifySuccess {
                                    self.postWithPath(path: path, paras: paras, success: success, failure: failure)
                                } else {
                                    let error = NSError(domain: "SocketSessionID expire", code: 1001, userInfo: nil)
                                    failure(error)
                                }
                            }
                            return
                        } else if errorCode == 1002 {
                            LoginManager.shared.autoLogin { [unowned self] isSuccess in
                                if isSuccess {
                                    self.postWithPath(path: path, paras: paras, success: success, failure: failure)
                                } else {
                                    MobileFrameEngine.shared.logOut()
                                }
                            }
                            return
                        } else {
                            let error = NSError(domain: "Unknown Error", code: errorCode, userInfo: nil)
                            failure(error)
                            return
                        }
                    }
                    else {
                        success(data)
                    }
                    
                    if let response : HTTPURLResponse = respond as? HTTPURLResponse {
                        let headers = response.allHeaderFields
                        if headers.keys.contains("Set-Cookie") {
                            let cookie : String = headers["Set-Cookie"] as! String
                            let _ = LoginManager.shared.saveCookies(cookieData: cookie)
                        }
                    }
                }else {
                    if let error = error {
                        let log = "URL:\(path) \n\n Error:\((error as NSError).description)"
                        SLogError(log)
                        failure(error)
                    }
                    else {
                        let error = NSError(domain: "Bad Request Url", code: -5005, userInfo: nil)
                        failure(error)
                    }
                }
            }
        }
        dataTask.resume()
    }
    
    public func fetch(path: String, method: String, httpBody: Data?, httpFormData: [[String: Any]]?, header: [String:String]?, success: @escaping ((_ response: URLResponse?, _ data: Data?) -> ()), failure: @escaping ((_ error: Error) -> ())) {
        
        if path.isBlank {
            return
        }
        let o = path.replacingOccurrences(of: "|", with: "%7C")
        var requestUrl = URL(string: o)
        if let url = URL(string: o) {
            requestUrl = url
        }
        else {
            if let urlStr = path.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed) {
                requestUrl = URL(string: urlStr)
            }
            else {
                let error = NSError(domain: "Bad Request Url", code: -5003, userInfo: nil)
                failure(error)
                return
            }
        }
        var request = URLRequest.init(url: requestUrl!)
        request.httpMethod = method
        request.httpShouldHandleCookies = true
        request.httpBody = httpBody ?? Data()
        if let header = header {
            for (key, value) in header {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
                
        var tempCookiePro = Dictionary<HTTPCookiePropertyKey, Any>()
        tempCookiePro[.name] = "EncompassDistributor"
        tempCookiePro[.value] = MobileFrameEngine.shared.config.encompassID
        tempCookiePro[.domain] = MobileFrameEngine.shared.config.serverHost
        tempCookiePro[.path] = "/"
        HTTPCookieStorage.shared.setCookie(HTTPCookie.init(properties: tempCookiePro)!)
        
        let session = URLSession.shared
        session.configuration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        session.configuration.httpShouldSetCookies = true
        
        if let timeOut = header?["Timeout"] {
            session.configuration.timeoutIntervalForRequest = TimeInterval(timeOut) ?? 60
        }
        
        if let formData = httpFormData {
            if formData.count == 0 {
                let error = NSError(domain: "FormData is None. Please check.", code: -5001)
                failure(error)
                return
            }
            
            AF.upload(multipartFormData: { multipartFormData in
                for data in formData {
                    if let isFile = data["isFile"] as? Bool {
                        if isFile == true {
                            multipartFormData.append(data["value"] as! Data, withName: "file", fileName: data["key"] as? String)
                        }
                        else {
                            multipartFormData.append(data["value"] as! Data, withName: data["key"] as! String)
                        }
                    }
                }
            }, to: path).response { respond in
                
                guard let data = respond.data else {
                    success(respond.response, nil)
                    return
                }
                
                let log = "URL:\(path) \n\n Params: \n\n Result:\(String(data: data, encoding: .utf8) ?? "")"
                SLogNet(log)
                
                if respond.response?.statusCode == 200 {
                    
                    guard let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                        success(respond.response, respond.data)
                        return
                    }
                    
                    let resultJson = JSON(result)
                    
                    if resultJson["errors"][0]["status"].intValue == 401 {
                        LoginManager.shared.autoLogin { isSuccess in
                            if isSuccess == true {
                                self.fetch(path: path, method: method, httpBody: httpBody, httpFormData: formData, header: header) { response, data in
                                    success(respond.response, respond.data)
                                } failure: { error in
                                    failure(error)
                                }
                            }
                            else {
                                MobileFrameEngine.shared.logOut()
                            }
                        }
                    }
                    else {
                        success(respond.response, respond.data)
                    }
                }
                else if respond.response?.statusCode == 401 {
                    
                    LoginManager.shared.autoLogin { isSuccess in
                        if isSuccess == true {
                            self.fetch(path: path, method: method, httpBody: httpBody, httpFormData: formData, header: header) { response, data in
                                success(respond.response, respond.data)
                            } failure: { error in
                                failure(error)
                            }
                        }
                        else {
                            MobileFrameEngine.shared.logOut()
                        }
                    }
                }
                else {
                    let error = NSError(domain: respond.error?.localizedDescription ?? "Bad Request", code: respond.response?.statusCode ?? -5002, userInfo: nil)
                    failure(error)
                }
            }
        }
        else {
            let dataTask = session.dataTask(with: request) { (data, respond, error) in
                DispatchQueue.main.async {

                    var paramsStr = ""
                    var dataStr = ""
                    if let params = httpBody {
                        paramsStr = String(data: params, encoding: .utf8) ?? ""
                    }
                    if let data = data {
                        dataStr = String(data: data, encoding: .utf8) ?? ""
                    }
                    
                    if let e = error {
                        self.log(path: path, params: paramsStr, result: (e as NSError).description)
                        failure(e)
                        return
                    }
                    
                    guard let response = respond as? HTTPURLResponse else {
                        success(respond, data)
                        return
                    }

                    guard let data = data else {
                        success(respond, nil)
                        return
                    }
                    
                    self.log(path: path, params: paramsStr, result: "StatusCode: \(response.statusCode) Data: \(dataStr)")

                    if response.statusCode == 200 {

                        guard let result = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                            success(respond, data)
                            return
                        }

                        let resultJson = JSON(result)

                        if resultJson["errors"][0]["status"].intValue == 401 {
                            LoginManager.shared.autoLogin { isSuccess in
                                if isSuccess == true {
                                    self.fetch(path: path, method: method, httpBody: httpBody, httpFormData: nil, header: header) { response, data in
                                        success(respond, data)
                                    } failure: { error in
                                        failure(error)
                                    }
                                }
                                else {
                                    MobileFrameEngine.shared.logOut()
                                }
                            }
                        }
                        else {
                            success(respond, data)
                        }
                    }
                    else if response.statusCode == 401 {
                        LoginManager.shared.autoLogin { isSuccess in
                            if isSuccess == true {
                                self.fetch(path: path, method: method, httpBody: httpBody, httpFormData: nil, header: header) { response, data in
                                    success(respond, data)
                                } failure: { error in
                                    failure(error)
                                }
                            }
                            else {
                                MobileFrameEngine.shared.logOut()
                            }
                        }
//                        print("直接返回return")
                    }
                    else {
                        let error = NSError(domain: dataStr, code: response.statusCode, userInfo: nil)
                        failure(error)
                    }
                }
            }
            dataTask.resume()
        }
    }
    
    public func download(fileName: String, url: String, success: @escaping ((_ fileName: String, _ path: String) -> ()), fail: @escaping ((_ fileName: String) -> ())) {
        let downloadUrl = (MobileFrameEngine.shared.config.zipFilesPath as NSString).appendingPathComponent(fileName)
        let destination: DownloadRequest.Destination = { _, _ in
            return (URL(fileURLWithPath: downloadUrl), [.removePreviousFile, .createIntermediateDirectories])
        }
        AF.download(url, to: destination).downloadProgress { progress in
            
        }
        .response { response in
            self.log(path: url, params: "", result: response.fileURL?.path ?? "fileUrl fail")
            if response.error == nil, let path = response.fileURL?.path {
                success(fileName, path)
            }
            else {
                fail(fileName)
            }
        }
    }
    
    public func uploadLogs(memo: String) {
        let zipFileName = "\(Int(Date().timeIntervalSince1970))_carshLogs.zip"
        
        let zipPath = (MobileFrameEngine.shared.config.cachesPath as NSString).appendingPathComponent(zipFileName)
        let datebasesPath = (MobileFrameEngine.shared.config.logFilePath as NSString).appendingPathComponent("databases")
        let (copySuccess, _) = LocalFileManager.copyFile(type: .directory, fromeFilePath: MobileFrameEngine.shared.config.globalStaticDatabasePath, toFilePath: datebasesPath)
        if copySuccess == false {
            SLogError("Databases copy fail")
            return
        }
        let success = ZipArchiveManager.share.zip(filePath: zipPath, zipPath: MobileFrameEngine.shared.config.logFilePath)
        if success == true {
            NetWorkManager.shared.uploadFile(path: zipPath, memo: memo) { result in
                LocalFileManager.removefile(filePath: zipPath)
            } failure: { error in
                SLogError((error as NSError).description)
            }
        }
        else {
            SLogError("Log Resource compression failed")
        }
    }
    
    public func uploadFile(path: String, memo: String, success: @escaping ((_ result: String) -> ()), failure: @escaping ((_ error: Error) -> ())) {
        
        let handheldID = UserDefaults.standard.value(forKey: LoginManager.LoginHandleID_Key) ?? ""
        
        let params: [String: String] = [
            "HandheldID": String(describing: handheldID),
            "Type": MobileFrameEngine.shared.config.clientLogType,
            "Memo": memo,
        ]
        
        let url = API.uploadLogs(query: params)
        AF.upload(URL(fileURLWithPath: path), to: url).response { response in
            guard let data = response.data else {
                success("")
                self.log(path: url, params: "", result: "UploadLogs fail")
                return
            }
            let dataStr = String(data: data, encoding: .utf8) ?? ""

            self.log(path: url, params: "", result: dataStr)
            
            if response.response?.statusCode == 200 {
                if dataStr.contains("|") == true {
                    let clientID = dataStr.split(separator: "|").count > 1 ? dataStr.split(separator: "|")[1] : ""
                    success(String(clientID))
                }
                else {
                    success(dataStr)
                }
            }
            else {
                if let error = response.error {
                    failure(error)
                }
                else {
                    let error = NSError(domain: "Bad Request Url", code: -5004, userInfo: nil)
                    failure(error)
                }
            }
        }
    }
    
    private func log(path: String, params: String, result: String) {
        let log = "URL:\(path) \n\n Params: \(params) \n\n Result:\(result)"
        SLogNet(log)
    }
    
    public func sendSystemError(title: String, body: String, success: @escaping ((_ complate: Bool) -> ())) {
        let formmat = "yyyy-MM-dd HH:mm:ss"
        let date = Date()
        let formmat1 = DateFormatter()
        formmat1.dateFormat = formmat
        let string = formmat1.string(from: date)
        
        let userName = UserDefaults.standard.string(forKey: LoginManager.LoginUserName_Key) ?? ""
        
        let majrVersion = OfflineResourcesManager.shared.getLocalGlobalModal()?.MajorVersion ?? ""
        
        let url = API.systemErrorPost(query: [
            "WebRequestID": UUID().uuidString
        ])
        
        let systemError = "EncompassID = \(MobileFrameEngine.shared.config.encompassID)\nMobileFrameAppID = \(MobileFrameEngine.shared.config.mobileFrameAppID)\nUserName = \(userName)\nPlatform = \(device_model_name)\nOS Version = \(device_system_name) \(device_system_version)\nECPVersion = \(majrVersion)\nUserAgent = \(MobileFrameEngine.shared.config.userAgent)\nSystemTime = \(string)\n\n\(title)\n\n<b>Stack Trace：</b>\n\(body)"
        
        let params: [String: Any] = [
            "SystemErrorEncompassID": MobileFrameEngine.shared.config.encompassID,
            "SystemErrorType": "None",
            "SystemErrorTitle": title,
            "SystemError": systemError,
            "SystemTime": string,
            "UserName": userName,
            "ServerName": device_name,
            "Page": "MobileFrame",
            "ECPVersion": majrVersion,
            "Feature": "MobileFrame iOS"
        ]
        
        SLogError("Crash Log:\n \(systemError)")
        
        var i = 0
        var address: String = ""
        for (key,value) in params {
            if i == 0 {
                address += "\(key)=\(value)"
            }else {
                address += "&\(key)=\(value)"
            }
            i += 1
        }
        
        var request = URLRequest.init(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = true
        request.httpBody = address.data(using: .utf8)
        
        request.addValue(MobileFrameEngine.shared.config.userAgent, forHTTPHeaderField: "User-Agent")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        let session = URLSession.shared
        session.configuration.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        session.configuration.httpShouldSetCookies = true
        let dataTask = session.dataTask(with: request) { (data, respond, error) in
            let paramsStr = params.toJsonString() ?? ""
            var dataStr = ""
            if let data = data {
                dataStr = String(data: data, encoding: .utf8) ?? ""
            }
            
            self.log(path: url, params: paramsStr, result: dataStr)
            
            if error == nil {
                success(true)
            }
            else {
                success(false)
            }
        }
        dataTask.resume()
    }
}
