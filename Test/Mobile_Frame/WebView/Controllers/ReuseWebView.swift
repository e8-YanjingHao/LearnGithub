//
//  ReuseWebView.swift
//  MobileFrame
//
//  Created by Encompass on 2022/1/11.
//

import Foundation
import WebKit
import UIKit

typealias OlderClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Any?) -> Void
typealias NewerClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void

public class ReuseWebView: WKWebView, WKNavigationDelegate {
    weak var holdObject: AnyObject?
    var dashboardID: Int?
    
    public var urlStr: String?
    public var request: URLRequest?
    public var localFilePath: String?
    public var html: String?
    public var dashboardQueryString: String?
    public var isDraft = false
    public var isPreWebView = false

    public var didFinish: (() -> ())?
    
    //Task 1093670: DSDLink Mobile: Unable to view email address being entered when attempting to reset password. Page should shift upwards when keyboard is displayed
    /// 这个属性UIWebview有，WKWebView要自己实现
//    var keyboardDisplayRequiresUserAction: Bool? {
//        get {
//            return self.keyboardDisplayRequiresUserAction
//        }
//        set {
//            setKeyboardRequiresUserInteraction(newValue ?? true)
//        }
//    }
    
    override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //Task 1093670: DSDLink Mobile: Unable to view email address being entered when attempting to reset password. Page should shift upwards when keyboard is displayed
//    func setKeyboardRequiresUserInteraction( _ value: Bool) {
//
//        guard
//            let WKContentViewClass: AnyClass = NSClassFromString("WKContentView") else {
//                SLogError("Cannot find the WKContentView class")
//                return
//        }
//
//        let olderSelector: Selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:")
//        let newSelector: Selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
//        let newerSelector: Selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
//        let ios13Selector: Selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:")
//
//        if let method = class_getInstanceMethod(WKContentViewClass, olderSelector) {
//
//            let originalImp: IMP = method_getImplementation(method)
//            let original: OlderClosureType = unsafeBitCast(originalImp, to: OlderClosureType.self)
//            let block : @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Any?) -> Void = { (me, arg0, arg1, arg2, arg3) in
//                original(me, olderSelector, arg0, !value, arg2, arg3)
//            }
//            let imp: IMP = imp_implementationWithBlock(block)
//            method_setImplementation(method, imp)
//        }
//
//        if let method = class_getInstanceMethod(WKContentViewClass, newSelector) {
//            swizzleAutofocusMethod(method, newSelector, value)
//        }
//
//        if let method = class_getInstanceMethod(WKContentViewClass, newerSelector) {
//            swizzleAutofocusMethod(method, newerSelector, value)
//        }
//
//        if let method = class_getInstanceMethod(WKContentViewClass, ios13Selector) {
//            swizzleAutofocusMethod(method, ios13Selector, value)
//        }
//    }
//
//    func swizzleAutofocusMethod(_ method: Method, _ selector: Selector, _ value: Bool) {
//        let originalImp: IMP = method_getImplementation(method)
//        let original: NewerClosureType = unsafeBitCast(originalImp, to: NewerClosureType.self)
//        let block : @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void = { (me, arg0, arg1, arg2, arg3, arg4) in
//            original(me, selector, arg0, !value, arg2, arg3, arg4)
//        }
//        let imp: IMP = imp_implementationWithBlock(block)
//        method_setImplementation(method, imp)
//    }
    
    static func clearAllWebCache() {
        let dataTypes = [WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeIndexedDBDatabases, WKWebsiteDataTypeWebSQLDatabases]
        let websiteDataTypes = Set(dataTypes)
        let dateFrom = Date(timeIntervalSince1970: 0)
        
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom) {
            
        }
    }
    
    //Task 1093670: DSDLink Mobile: Unable to view email address being entered when attempting to reset password. Page should shift upwards when keyboard is displayed
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView != nil {
            var notificationInfo: [String: Any] = [:]
            notificationInfo["point"] = point
            notificationInfo["event"] = event
            NotificationCenter.default.post(name: Notification.Name.TouchWebViewEvent, object: notificationInfo)
        }
        return hitView
    }
    
    deinit {
        //Clear UserScript
        configuration.userContentController.removeAllUserScripts()
        //stop loading
        stopLoading()

        uiDelegate = nil
        navigationDelegate = nil
        // Holder is set to nil
        holdObject = nil
        SLogInfo("WKWebView destroyed！！！")
    }
}

extension ReuseWebView: ReuseWebViewProtocol {
    func willReuse() {
        
    }
    
    func endReuse() {
        holdObject = nil
        scrollView.delegate = nil
        stopLoading()
        navigationDelegate = nil
        uiDelegate = nil
        loadHTMLString("", baseURL: nil)
    }
}
