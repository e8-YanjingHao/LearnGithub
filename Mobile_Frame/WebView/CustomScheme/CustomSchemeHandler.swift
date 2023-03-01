//
//  CustomSchemeHandler.swift
//  TestProject
//
//  Created by Encompass on 2021/11/5.
//

import UIKit
import WebKit

internal class CustomSchemeHandler: NSObject, WKURLSchemeHandler {
        
    var holdUrlSchemeTasks:[String:Bool] = [:]
        
    override init() {
        
    }
    
    //Custom Scheme call back
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let request : URLRequest = urlSchemeTask.request
        let headers = urlSchemeTask.request.allHTTPHeaderFields
        guard let accept = headers?["Accept"] else { return }
        let url : String = request.url?.path ?? ""
        let content : String = String.init(format: "URL = \(url), Method = \(request.httpMethod ?? ""), body = \(request.httpBody ?? Data.init()), allKey = \(String(describing: request.allHTTPHeaderFields?.keys)), accept = \(accept)")
        print(content + "\n")
            
        if url != "" {
            if url.uppercased() == "API" || url.uppercased() == "/API" {
                requestData(request: request) { [weak urlSchemeTask] response, data in
                    if let response = response, let data = data {
                        urlSchemeTask?.didReceive(response)
                        urlSchemeTask?.didReceive(data)
                        urlSchemeTask?.didFinish()
                    } else {
                        SLogError("Response is null")

                        let error : NSError = NSError.init(domain: "Response is null", code: -4003, userInfo: nil)
                        urlSchemeTask?.didFailWithError(error)
                    }
                } failure: { [weak urlSchemeTask] error in
                    SLogError("Custom Scheme Handler Fetch Request Error \n\n \(error.localizedDescription)")

                    urlSchemeTask?.didFailWithError(error)
                }
            } else {
                var urlMimeType : String?
                if let urlExt : String = request.url?.pathExtension {
                    urlMimeType = getMimeType(pathExtension: urlExt)
                }
                
                let filePath : String = getFilePath(url: url)
                
                if LocalFileManager.judgeFileOrFolderExists(filePath: filePath) == false {
                    SLogError("File not be found: \n\n \(filePath)")
                    
                    let error : NSError = NSError.init(domain: "Response is null", code: -4004, userInfo: nil)
                    urlSchemeTask.didFailWithError(error)
                }
                else {
                    do{
                        let data1 : Data = try Data.init(contentsOf: URL.init(fileURLWithPath: filePath))
                        let response : URLResponse = URLResponse.init(url: request.url!, mimeType: urlMimeType, expectedContentLength: data1.count, textEncodingName: nil)
                        urlSchemeTask.didReceive(response)
                        urlSchemeTask.didReceive(data1)
                        urlSchemeTask.didFinish()
                    } catch {
                        SLogError("Local file parsing error \n\n \(error.localizedDescription)")

                        urlSchemeTask.didFailWithError(error)
                    }
                }
            }
        } else {
            SLogError("Url is empty and cannot be parsed")

            let error : NSError = NSError.init(domain: "Url is empty and cannot be parsed", code: -4005, userInfo: nil);
            urlSchemeTask.didFailWithError(error)
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        SLogError(" --- webView stop -----")
    }
    
    func getMimeType(pathExtension: String!) -> String {
        switch ("." + pathExtension)
        {
            case ".csv":
                return "text/csv";
            case ".htm":
                return "text/html";
            case ".html":
                return "text/html";
            case ".css":
                return "text/css";
            case ".jpeg":
                return "image/jpeg";
            case ".jpg":
                return "image/jpeg";
            case ".png":
                return "image/png";
            case ".bmp":
                return "image/bmp";
            case ".gif":
                return "image/gif";
            case ".svg":
                return "image/svg+xml";
            case ".js":
                return "application/javascript";
            case ".doc":
                return "application/msword";
            case ".docx":
                return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
            case ".ppt":
                return "application/vnd.ms-powerpoint";
            case ".pptx":
                return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
            case ".xls":
                return "application/vnd.ms-excel";
            case ".xlsx":
                return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            default:
                return "application/octet-stream"
        }
    }
    
    func getFilePath(url: String) -> String {
        let documentPath = MobileFrameEngine.shared.config.isGlobalDraft ? (MobileFrameEngine.shared.config.draftHtmlFilesPath as NSString) : (MobileFrameEngine.shared.config.htmlFilesPath as NSString)
        let baseUrl : String = MobileFrameEngine.shared.config.baseUrl
        if url.contains(baseUrl) {
            return documentPath.appendingPathComponent(url.replacingOccurrences(of: baseUrl, with: ""))
        }
        return documentPath.appendingPathComponent(url)
    }
    
    func requestData(request: URLRequest, success: @escaping ((_ response: URLResponse?, _ data: Data?) -> ()), failure: @escaping ((_ error: Error) -> ())) {
        var absoluteUrlString : String?
        let absoluteString = request.url!.absoluteString
        let absoluteStrings = absoluteString.split(separator: String.Element.init("?"))
        if absoluteStrings.count > 1 {
            absoluteUrlString = MobileFrameEngine.shared.config.serverHost + "/API?" + absoluteStrings[1]
        }
        NetWorkManager.shared.fetch(path: absoluteUrlString ?? request.url!.absoluteString , method: request.httpMethod!, httpBody: request.httpBody, httpFormData: nil, header: request.allHTTPHeaderFields) { response, data in
            success(response, data)
        } failure: { error in
            failure(error)
        }
    }
}



