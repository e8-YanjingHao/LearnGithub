//
//  WKProcessPoolHelper.swift
//  MobileFrame
//
//  Created by Encompass on 2021/11/18.
//

import UIKit
import WebKit

public class WKProcessPoolHelper {
    public static let shared = WKProcessPoolHelper()
    let pool = WKProcessPool()
    var url: URL?
    init() {
    }
    
    public func loadHttpCookie(webviewVC: WebViewController?) {
        
        let cookieStore = webviewVC?.webView?.configuration.websiteDataStore.httpCookieStore
        url = webviewVC?.webView?.url
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                if let wkCookiePro = getCookiePropertys(key: cookie.name, value: cookie.value, expires: cookie.expiresDate) {
                    if let wkCookie = HTTPCookie.init(properties: wkCookiePro) {
                        cookieStore?.setCookie(wkCookie, completionHandler: {
                            print("InsertCookieSuccessfully : name = \(String(describing: wkCookie.name)) , value = \(String(describing: wkCookie.value))")
                        })
                    }
                }
            }
        }
    }
    
    public func getCookiePropertys(key: String, value: String, expires: Date?) -> [HTTPCookiePropertyKey : Any]? {
        var tempCookiePro = Dictionary<HTTPCookiePropertyKey, Any>()
        
        if let domain = url?.host {
            tempCookiePro[.name] = key
            tempCookiePro[.value] = value
            tempCookiePro[.path] = "/"
            tempCookiePro[.domain] = domain
            if let expires = expires {
                tempCookiePro[.expires] = expires
            }
        }
        return tempCookiePro
    }
    
    func getDomain(url: String) -> String? {
        return URL.init(string: url)?.host
    }
    
}
