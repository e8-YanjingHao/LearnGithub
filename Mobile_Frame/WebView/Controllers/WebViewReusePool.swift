//
//  ReuseWebView.swift
//  MobileFrame
//
//  Created by Encompass on 2022/1/11.
//


import Foundation
import WebKit

protocol ReuseWebViewProtocol {
    func willReuse()
    func endReuse()
}

public class WebViewReusePool: NSObject {
    public static let shared = WebViewReusePool()
    public var defaultConfigeration: WKWebViewConfiguration?
    
    var visiableWebViewSet = Set<ReuseWebView>()
    var reusableWebViewSet = Set<ReuseWebView>()
    
    var lock = DispatchSemaphore(value: 1)
    
    public static func swiftyLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishLaunchingNotification), name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    @objc static func didFinishLaunchingNotification() {
        for _ in 0..<4 {
            WebViewReusePool.shared.prepareWebView()
        }
    }
    
    @objc func didReceiveMemoryWarningNotification() {
        SLogError("DidReceiveMemoryWarningNotification")
        
        //clearReusableWebViews()
    }
    
    public func prepareWebView() {
        let customSchemeHandler : CustomSchemeHandler = CustomSchemeHandler.init()
        let wkConfig : WKWebViewConfiguration = WKWebViewConfiguration.init()
        wkConfig.preferences.javaScriptEnabled = true
        wkConfig.processPool = WKProcessPoolHelper.shared.pool
        wkConfig.setURLSchemeHandler(customSchemeHandler, forURLScheme: MobileFrameEngine.shared.config.customScheme)
        if #available(iOS 13.0, *) {
            wkConfig.defaultWebpagePreferences.preferredContentMode = .mobile;
        }
        let webView = ReuseWebView(frame: CGRect.zero, configuration: wkConfig)
        self.reusableWebViewSet.insert(webView)
    }
    
    func tryCompactWeakHolders() {
        lock.wait()
        var shouldreusedWebViewSet = Set<ReuseWebView>()
        for webView in visiableWebViewSet {
            guard let _ = webView.holdObject else {
                shouldreusedWebViewSet.insert(webView)
                continue
            }
        }
        
        for webView in shouldreusedWebViewSet {
            webView.endReuse()
            visiableWebViewSet.remove(webView)
            reusableWebViewSet.insert(webView)
        }
        
        lock.signal()
    }
}

// MARK: - Reuse pool operation
extension WebViewReusePool {
    public func getReusedWebView(dashboardID: Int, ForHolder holder: AnyObject?, configuration: WKWebViewConfiguration) -> ReuseWebView? {
        guard let holder = holder else { return nil }
        
        self.defaultConfigeration = configuration

        var webView: ReuseWebView
        lock.wait()
        
        if reusableWebViewSet.count > 0 {
            webView = reusableWebViewSet.randomElement()!
            visiableWebViewSet.insert(webView)
            reusableWebViewSet.remove(webView)
            webView.willReuse()
            
            webView.holdObject = holder
            webView.dashboardID = dashboardID
        }
        else {
            webView = ReuseWebView(frame: CGRect.zero, configuration: configuration)
            webView.holdObject = holder
            webView.dashboardID = dashboardID
            reusableWebViewSet.insert(webView)
        }
        
        lock.signal()
                
        return webView
    }
    
    func recycleReusedWebView(_ webView: ReuseWebView?) {
        guard let webView = webView else { return }

        lock.wait()
        if visiableWebViewSet.contains(webView) {
            webView.endReuse()
            visiableWebViewSet.remove(webView)
            reusableWebViewSet.insert(webView)
        }

        lock.signal()
    }
    
    func clearReusableWebViews() {
        lock.wait()
        reusableWebViewSet.removeAll()
        visiableWebViewSet.removeAll()
        lock.signal()
        ReuseWebView.clearAllWebCache()
    }
}
