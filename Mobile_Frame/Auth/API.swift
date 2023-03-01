//
//  API.swift
//  MobileFrameExampleApp
//
//  Created by ERIC on 2021/11/16.
//

import Foundation

internal class API {
    
    static func login() -> String {
        return API.frt(path: "/API", api: "MobileFrame_Login", token: "37c4cba28cacb95bee6806df4d39db01", query: nil)
    }
    
    static func getMeta(query: [String:String]?) -> String {
        return API.frt(path: "/API", api: "GetMobileFrameMeta", token: "37c4cba28cacb95bee6806df4d39db01", query: query)
    }
    
    static func getDashboard(query: [String:String]?) -> String {
        return API.frt(path: "/API", api: "PackDashboardFiles_Public", token: "37c4cba28cacb95bee6806df4d39db01", query: query)
    }
    
    static func systemErrorPost(query: [String:String]?) -> String {
        return API.frt(path: "/API", api: "MobileFrame_SendSystemError", token: "48e612653d0b1f9d596615c0eaede8b6", query: query)
    }
    
    static func uploadLogs(query: [String:String]?) -> String {
        return API.frt(path: "/API", api: "MobileFrame_UploadLogs", token: "48e612653d0b1f9d596615c0eaede8b6", query: query)
    }
    
    static func updateSession() -> String {
        return API.frt(path: "/API", api: "Update_Session", token: "", query: nil)
    }
        
    static func frt(path: String, api: String, token: String, query: [String: String]?) -> String {
        
        var address: String = ""
        if let query = query {
            for (key,value) in query {
                let allowedCharacterSet = (CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[] \n").inverted)
                if let v = value.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
                    address += "&\(key)=\(v)"
                }
                else{
                    address += "&\(key)=\(value)"
                }
            }
        }
        
        if token.isBlank == false {
            address += "&APIToken=\(token)"
        }
        
        var encompassID = MobileFrameEngine.shared.config.encompassID
        var serverHost = MobileFrameEngine.shared.config.serverHost
        if api == "MobileFrame_SendSystemError" {
            encompassID = "Support"
            serverHost = "https://api.encompass8.com"
        }
        
        return serverHost + path + "?APICommand=" + api + "&EncompassID=" + encompassID + address
    }
}
