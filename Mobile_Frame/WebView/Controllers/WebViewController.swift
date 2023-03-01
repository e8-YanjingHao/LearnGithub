
//  WebViewController.swift
//  ScanCode
//
//  Created by Encompass on 2021/11/11.
//

import UIKit
import WebKit
import JavaScriptCore
import Reachability
import SwiftyJSON
import SnapKit

open class WebViewController: UIViewController, WKNavigationDelegate, UIGestureRecognizerDelegate {
    
    public var callBack: (([String : Any]) -> ())?
    public var urlStr: String?
    public var url: URL?
    public var request: URLRequest?
    public var localFilePath: String?
    public var html: String?
    public var dashboardId: Int?
    public var dashboardQueryString: String?
    public var interactivePop = true
    public var isShowNavigation = false
    public var iseChat = false
    public var webViewConfig: WKWebViewConfiguration?
    public var isHiddenDebug = false {
        didSet {
            devTools.isHidden = isHiddenDebug
        }
    }
    
    private var titleLabel: UILabel?
    
    public var webView: ReuseWebView?
    
    public var keyBoardPoint: CGPoint?
    public var touchY : CGFloat = 0.0
    
    var estimatedProgressObservationToken: NSKeyValueObservation?
    
    lazy private var progressView: UIProgressView = {
        self.progressView = UIProgressView.init(frame: CGRect(x: CGFloat(0), y: self.fetchWebViewY(), width: UIScreen.main.bounds.width, height: 2))
        self.progressView.tintColor = UIColor.rgba(red: 22.0, green: 114.0, blue: 193.0)
        self.progressView.trackTintColor = UIColor.clear
        return self.progressView
    }()
    
    lazy var devTools: DevToolsButton = {
        let devTools = DevToolsButton(frame: .zero)
        devTools.devToolsView.delegate = DevToolsHelper(webVC: self)
        devTools.devToolsView.defaultDataSource(dashboardId: dashboardId ?? 0)
        return devTools
    }()
    
    lazy var jsNative: JSNative = {
        let jsNative = JSNative(webVC: self)
        return jsNative
    }()
    
    /* ------- */
    //Task 1093670: DSDLink Mobile: Unable to view email address being entered when attempting to reset password. Page should shift upwards when keyboard is displayed
    @objc func keyboardWillShow(_ showNoti: Notification) {
        let keyboardFrame = (showNoti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardY = keyboardFrame.origin.y
        
        if self.touchY + 80 > keyboardY {
            let offsetY = self.touchY + 80 - keyboardY
            self.webView?.scrollView.contentOffset = CGPoint(x: 0, y: offsetY)
        }
    }
    
    @objc func keyboardWillHide(_ hideNoti: Notification) {
        self.webView?.scrollView.contentOffset = CGPoint(x: 0, y: 0)
    }
    
    @objc func touchWebView(_ notification: Notification) {
        let info = notification.object as! [String : Any]
        let point = info["point"] as! CGPoint
        let event = info["event"] as! UIEvent?
        if let realEvent = event, realEvent.type == .touches {
            self.touchY = point.y
        }
    }
    /* ------ */
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        //Task 1093670: DSDLink Mobile: Unable to view email address being entered when attempting to reset password. Page should shift upwards when keyboard is displayed
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(touchWebView(_:)), name: Notification.Name.TouchWebViewEvent, object: nil)
        
        if let dashboardId = dashboardId {
            if let dashboard = OfflineResourcesManager.shared.getDashboardFromDB(dashboardID: dashboardId) {
                self.view.backgroundColor = UIColor.hexColor(hex: dashboard.DefaultBackgroundColor ?? "#ffffff")
            }
            else {
                self.view.backgroundColor = .white
            }
        }
        else {
            self.view.backgroundColor = .white
        }
        
        initWebView()
        customBackButton()
        customTitleStyle()
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(receivedRotation),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = interactivePop
        self.navigationController?.interactivePopGestureRecognizer!.delegate = interactivePop==true ? self : nil
        
        //Task 1093670: DSDLink Mobile: Unable to view email address being entered when attempting to reset password. Page should shift upwards when keyboard is displayed
        //        let systemVersion = (device_system_version as NSString).floatValue
        //        if (systemVersion >= 12.0) {
        //            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        //        }
        
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        //        registerAllScriptMessage()
        
        self.navigationController?.navigationBar.isHidden = !isShowNavigation
        
        guard let _ = webView?.title else {
            webView?.reload(); return
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        if isShowNavigation {
            self.navigationController?.navigationBar.isHidden = true
        }
        
        //remove webview forward list
        self.webView?.backForwardList.perform(Selector(("_removeAllItems")))
        
        //        removeAllScriptMessage()
    }
    
    func initWebView() {
        webViewConfig = getWKConfig()
        webView = WebViewReusePool.shared.getReusedWebView(dashboardID: self.dashboardId ?? 0, ForHolder: self, configuration: webViewConfig!)!
        webView?.backgroundColor = UIColor.clear
        webView?.isOpaque = false
        webView?.scrollView.bounces = false
        webView?.navigationDelegate = self
        webView?.scrollView.showsHorizontalScrollIndicator = false
        webView?.scrollView.showsVerticalScrollIndicator = false
        webView?.scrollView.contentInsetAdjustmentBehavior = .never
        webView?.scrollView.insetsLayoutMarginsFromSafeArea = false
        webView?.customUserAgent = "MobileFrame_iOS_iPhone_\(MobileFrameEngine.mobileFrameVersion),\(MobileFrameEngine.shared.config.userAgent)"
        //        webView?.keyboardDisplayRequiresUserAction = false //Task 1093670
        
        registerAllScriptMessage()
        
        guard let _ = webView else {
            SLogError("WebView Init Fail.")
            return
        }
        
        self.view.addSubview(self.webView!)
        
        self.view.addSubview(self.progressView)
        self.view.bringSubviewToFront(self.progressView)
        
        self.webView?.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(self.fetchWebViewY())
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottom)
        }
        
        self.view.addSubview(devTools)
        self.devTools.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-FIT_SIZE(w: 50))
            make.right.equalToSuperview().offset(-FIT_SIZE(w: 10))
            make.size.equalTo(CGSize(width: FIT_SIZE(w: 80), height: FIT_SIZE(w: 30)))
        }
        self.isHiddenDebug = !MobileFrameEngine.shared.config.devTools
        
        insertCookies()
        
        startLoadWebview()
    }
    
    @objc func receivedRotation() {
        if UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown {
            self.webView?.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(self.fetchWebViewY())
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.view.snp.bottom)
            }
        } else {
            self.webView?.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(self.fetchWebViewY())
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.view.snp.bottom)
            }
        }
        
        self.devTools.updateLayout()
    }
    
    //Task 1093670
    //    @objc func keyboardWillHide() {
    //        self.webView?.scrollView.contentOffset = CGPoint(x: 0, y: 0)
    //    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == self.navigationController?.interactivePopGestureRecognizer) {
            return self.navigationController!.viewControllers.count > 1
        }
        return true
    }
    
    func updateUIIfNeeded() {
        self.navigationController?.navigationBar.isHidden = !isShowNavigation
        self.webView?.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(self.fetchWebViewY())
            make.left.right.equalToSuperview()
            make.bottom.equalTo(self.view.snp.bottom)
        }
    }
    
    func fetchWebViewY() -> CGFloat {
        if self.iseChat == true {
            return STATUSBAR_HIGH
        }
        
        if self.isShowNavigation == true {
            return NAV_HEIGHT_SAFE
        }
        else {
            return 0
        }
    }
    
    func customBackButton() {
        let backButton = UIButton(frame: CGRect(x: 0, y: 13, width: 18, height: 18))
        backButton.setTitle("Back", for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        backButton.setTitleColor(UIColor.init(red: 47/256, green: 131/256, blue: 248/256, alpha: 1), for: .normal)
        backButton.addTarget(self, action: #selector(clickBackAction), for: .touchUpInside)
        
        let backView = UIBarButtonItem(customView: backButton)
        
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        barButtonItem.width = -5
        
        self.navigationItem.leftBarButtonItems = [barButtonItem, backView]
    }
    
    func spaceBackButton(){
        let backButton = UIButton(frame: CGRect(x: 0, y: 13, width: 18, height: 18))
        backButton.setTitle("", for: .normal)
        let backView = UIBarButtonItem(customView: backButton)
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        self.navigationItem.leftBarButtonItems = [barButtonItem, backView]
    }
    
    func customTitleStyle() {
        let titleView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 30))
        let titleLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 30))
        titleView.addSubview(titleLabel)
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .center
        self.titleLabel = titleLabel
        self.navigationItem.titleView = titleView
    }
    
    @objc func clickBackAction() {
        if webView?.canGoBack != true {
            if self.interactivePop == true && self.navigationController!.viewControllers.count > 0 {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            webView?.goBack()
        }
    }
    
    func setUpObservation() {
        estimatedProgressObservationToken = webView?.observe(\.estimatedProgress) {[weak self] (object, change) in
            guard let self = self else{return}
            self.progressView.alpha = 1.0
            self.progressView.setProgress(Float((self.webView?.estimatedProgress ?? 0) ), animated: true)
            if (self.webView?.estimatedProgress ?? 0)  >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut, animations: {
                    [weak self] in guard let self = self else{return}
                    self.progressView.alpha = 0
                }, completion: {[weak self] (finish) in
                    guard let self = self else{return}
                    self.progressView.setProgress(0.0, animated: false)
                })
            }
        }
    }
    
    //To customize config, overload this method.
    open func getWKConfig() -> WKWebViewConfiguration {
        return getCommenWKConfig()
    }
    
    //To customize Cookies, overload this method.
    open func insertCookies() {
        
    }
    
    open func startLoadWebview() {
        var needShowNav = false
        if let realUrlStr = self.urlStr {
            setUpObservation()
            self.loadUrl(url: realUrlStr)
            needShowNav = true
        }
        else if let realUrl = self.url {
            self.loadUrl(url: realUrl)
            needShowNav = true
        }
        else if let realRequest = self.request {
            self.loadRequest(request: realRequest)
            needShowNav = true
        }
        else if let realDashboardId = self.dashboardId {
            let isOfflineDashboard = OfflineResourcesManager.shared.offLineByDashboardID(dashboardID: realDashboardId)
            if isOfflineDashboard {
                if MobileFrameEngine.shared.config.isGlobalDraft {
                    OfflineResourcesManager.shared.downloadDashboard(dashboardID: realDashboardId) { (isSuccess, filePath) in
                        if isSuccess && !filePath.isBlank {
                            self.loadLoaclFile(path: filePath)
                            self.devTools.devToolsView.switchView.setOn(true, animated: true)
                        }
                        else {
                            MobileFrameEngine.shared.config.isGlobalDraft = false
                            self.devTools.devToolsView.switchView.setOn(false, animated: true)
                        }
                    }
                }
                else {
                    let filePath = OfflineResourcesManager.shared.dashboardFilePathByDashboardID(dashboardID: realDashboardId)
                    if filePath != "" {
                        self.loadLoaclFile(path: filePath)
                    } else {
                        //fail
                        loadErrorPage()
                    }
                }
            } else {
                LoginManager.shared.updateSession() { [unowned self] success in
                    //Task 1157099:The SupplierCRM needs to display the Head and Menu of the navigation bar
                    var destUrl = "Home?EmbededDialog=True&\(self.dashboardQueryString ?? "")".addingPercentEncoding(withAllowedCharacters: .alphanumerics)
                    if let tempDashboardQueryString = self.dashboardQueryString{
                        if(tempDashboardQueryString.contains("EmbededDialog=False")){
                            destUrl = "Home?\(tempDashboardQueryString)".addingPercentEncoding(withAllowedCharacters: .alphanumerics)
                        }
                    }
                    
                    let url = "\(MobileFrameEngine.shared.config.serverHost)/Home?EncompassID=\(MobileFrameEngine.shared.config.encompassID)&EncompassSessionID=\(MobileFrameEngine.shared.userInfo?.EncompassSessionID ?? "")&LogOnType=LogOnByMobile&DestURL=\(destUrl ?? "")"
                    self.urlStr = url
                    
                    self.startLoadWebview()
                    
                    needShowNav = true
                    self.isShowNavigation = needShowNav
                    
                    //Task 1158233
                    var webViewControllerCount = 0
                    for VC in self.navigationController!.viewControllers{
                        if (VC.isMember(of: WebViewController.self)){
                            webViewControllerCount += 1
                        }
                    }
                    if(webViewControllerCount == 1){
                        spaceBackButton()
                    }else{
                        customBackButton()
                    }
                    self.updateUIIfNeeded()
                }
            }
        }
        else if let realPath = self.localFilePath {
            self.loadLoaclFile(path: realPath)
        }
        else if let realHtml = self.html {
            self.loadHtmlString(htmlStr: realHtml)
        }
        
        isShowNavigation = self.iseChat == true ? false :    needShowNav
        
        updateUIIfNeeded()
    }
    
    public func loadUrl(url: String?) {
        if let realUrl = url {
            loadUrl(url: URL.init(string: realUrl))
        }
    }
    
    public func loadUrl(url: URL?) {
        if let realUrl = url {
            loadRequest(request: URLRequest.init(url: realUrl))
        }
    }
    
    public func loadRequest(request: URLRequest?) {
        if let realRequest = request {
            webView?.load(realRequest)
        }
    }
    
    public func loadHtmlString(htmlStr: String?) {
        if let realHtmlStr = htmlStr {
            
            if MobileFrameEngine.shared.config.baseUrl != "" {
                var baseUrl = MobileFrameEngine.shared.config.baseUrl
                baseUrl += "Home?" + (dashboardQueryString ?? "")
                
                //load eruda devTool for debug
                //                if MobileFrameEngine.shared.config.devTools {
                //                    let results = realHtmlStr.components(separatedBy: "<head>")
                //
                //                    let consoleScript = """
                //                        <script src="http://cdn.jsdelivr.net/npm/eruda"></script>
                //                        <script>
                //                          eruda.init();
                //                        </script>
                //                    """
                //                    realHtmlStr = (results.first ?? "") + consoleScript + (results.last ?? "")
                //                }
                
                webView?.loadHTMLString(realHtmlStr, baseURL: URL.init(string: baseUrl))
                
            } else {
                webView?.loadHTMLString(realHtmlStr, baseURL: nil)
            }
        }
    }
    
    public func loadLoaclFile(path: String?) {
        if let realPath = path {
            let filePath = getFilePath(relativePath: realPath)
            if filePath != "" , FileManager.default.fileExists(atPath: filePath) {
                do{
                    let html : String = try String.init(contentsOfFile: filePath, encoding: .utf8)
                    loadHtmlString(htmlStr: evalDefaultJS(html:html))
                }catch {
                    loadErrorPage()
                }
            }
        }
    }
    
    open func loadErrorPage() {
        
        SLogError("WebView Load Error -- DashboardId:\(String(describing: self.dashboardId)), LocalFilePath:\(String(describing: self.localFilePath))")
        
        (dashboardId, localFilePath) = OfflineResourcesManager.shared.exceptionDashboardFilePath()
        if localFilePath?.isBlank == false {
            self.startLoadWebview()
        }
    }
    
    func getFilePath(relativePath: String) -> String {
        let documentPath = MobileFrameEngine.shared.config.isGlobalDraft ? (MobileFrameEngine.shared.config.draftHtmlFilesPath as NSString) : (MobileFrameEngine.shared.config.htmlFilesPath as NSString)
        let baseUrl : String = MobileFrameEngine.shared.config.baseUrl
        if relativePath.contains(baseUrl) {
            return documentPath.appendingPathComponent(relativePath.replacingOccurrences(of: baseUrl, with: ""))
        }
        return documentPath.appendingPathComponent(relativePath)
    }
    
    func evalDefaultJS(html: String) -> String {
        
        if html.contains("<head>") == false {
            return html
        }
        
        var temp = self.evalDefaultCss(html: html)
        
        if LoginManager.shared.isLogin() == false {
            return temp
        }
        
        guard let userInfo = MobileFrameEngine.shared.userInfo else {
            return temp
        }
        
        var TableTraverse = ""
        if let permission = userInfo.Permissions {
            if permission.contains("TableTraverse") == true {
                TableTraverse = "true"
            }
            else {
                TableTraverse = "false"
            }
        }
        
        var IsTestDatabase = "false"
        var MajorVersion : String?
        if let globalStaticModel = OfflineResourcesManager.shared.getLocalGlobalModal() {
            IsTestDatabase = globalStaticModel.IsTestDatabase ?? "false"
            MajorVersion = globalStaticModel.MajorVersion
        }
        
        let defaultVal = "<script>const UserName='\(userInfo.UserName ?? "")';const UserAvatar='\(userInfo.UserAvatarURL ?? "")';PageStartMilliseconds=\(Date().timeIntervalSince1970 * 1000);Distributor='\(MobileFrameEngine.shared.config.encompassID)';IsImpersonateUser=\(String(describing: userInfo.IsImpersonateUser ?? ""));UserType='\(String(describing: userInfo.UserType ?? ""))';AuthenticationID=\(String(describing: userInfo.AuthenticationID ?? ""));UserID=\(String(describing: userInfo.UserID ?? ""));ECPVersion='\(MajorVersion ?? "")';ReleasedCode=true;TestDatabase=\(String(describing: IsTestDatabase));HasTableTraversePermission=\(TableTraverse);window.onload=function(){ document.getElementById('UserLanguage').value='\(userInfo.Language ?? "EN")';document.getElementById('UserDateFormat').value='\(userInfo.DateFormat ?? "")';document.getElementById('UserTimeFormat').value='\(userInfo.TimeFormat ?? "")';document.getElementById('UserPhoneFormat').value='\(userInfo.PhoneFormat ?? "")';if(document.getElementById('UserCurrencySymbol')){document.getElementById('UserCurrencySymbol').value='\(userInfo.CurrencySymbol ?? "")';document.getElementById('UserCurrencyDecimals').value='\(userInfo.CurrencyDecimals ?? "")';document.getElementById('UserCurrencyGroupDigits').value='\(userInfo.CurrencyGroupDigits ?? "")';document.getElementById('UserCurrencyUseParForNeg').value='\(userInfo.CurrencyUseParForNeg ?? "")';} }</script>"
        
        let regex = try! NSRegularExpression(pattern: "<script>.*?</script>", options:[])
        
        if let match = regex.firstMatch(in: temp, range: NSRange(temp.startIndex...,in: temp)) {
            let index = match.range.location + match.range.length
            temp.insert(contentsOf: defaultVal, at: temp.index(temp.startIndex, offsetBy: index))
        }
        
        return temp
    }
    
    func evalDefaultCss(html: String) -> String {
        var temp = String(html)
        let defaultVal = "<style>body{--enc-statusbar-height:\(STATUSBAR_HIGH)px}</style>"
        
        let regex = try! NSRegularExpression(pattern: "<style>.*?</style>", options:[])
        
        if let match = regex.firstMatch(in: html, range: NSRange(html.startIndex...,in: html)) {
            let index = match.range.location + match.range.length
            temp.insert(contentsOf: defaultVal, at: html.index(html.startIndex, offsetBy: index))
        }
        
        return temp
    }
    
    func evalJS(js: String) {
        webView?.evaluateJavaScript(js, completionHandler: { obj, error in
            SLogDebug("evaluateJavaScript completionHandler：\n\(js)\n result：\(error?.localizedDescription ?? "js run success")\n")
        })
    }
    
    func evalUserScript(js: String) {
        if let webViewConfig = self.webViewConfig {
            registerMethod(wkConfig: webViewConfig, javaScript: js)
        }
    }
    
    //MARK ------ WKNavigationDelegate ------
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        SLogInfo(" ------------ \(#function) ------------- ")
        let request : URLRequest = navigationAction.request
        let content : String = "JumpURL = \(request.url?.absoluteString ?? ""), Method = \(request.httpMethod ?? ""), body = \(request.httpBody ?? Data.init()), allKey = \(String(describing: request.allHTTPHeaderFields?.keys))"
        print(content)
        
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        SLogInfo(" ------------ \(#function) ------------- ")
        if let response : HTTPURLResponse = navigationResponse.response as? HTTPURLResponse {
            if response.statusCode == 200 {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                loadErrorPage()
            }
        }
        else {
            loadErrorPage()
            decisionHandler(.cancel)
        }
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        SLogInfo(" ------------ \(#function) ------------- ")
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        SLogInfo(" ------------ \(#function) ------------- ")
        
        if isShowNavigation {
            self.titleLabel?.text = webView.title
        }
        
        if MobileFrameEngine.shared.config.devTools {
            devTools.devToolsView.defaultDataSource(dashboardId: self.dashboardId ?? 0)
        }
    }
    
    public func getCookiePropertys(key: String, value: String, expires: Date?) -> [HTTPCookiePropertyKey : Any]? {
        var tempCookiePro = Dictionary<HTTPCookiePropertyKey, Any>()
        
        tempCookiePro[.name] = key
        tempCookiePro[.value] = value
        tempCookiePro[.path] = "/"
        tempCookiePro[.domain] = MobileFrameEngine.shared.config.serverHost
        if let expires = expires {
            tempCookiePro[.expires] = expires
        }
        return tempCookiePro
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        SLogInfo(" ------------ \(#function) ------------- ")
        
        self.loadErrorPage()
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        SLogInfo(" ------------ \(#function) ------------- ")
        SLogInfo(" Call webViewWebContentProcessDidTerminate ")
        
        webView.reload()
    }
    
    //MARK -------- WKConfig --------
    func getCommenWKConfig() -> WKWebViewConfiguration {
        let customSchemeHandler : CustomSchemeHandler = CustomSchemeHandler.init()
        let wkConfig : WKWebViewConfiguration = WKWebViewConfiguration.init()
        wkConfig.preferences.javaScriptEnabled = true
        wkConfig.processPool = WKProcessPoolHelper.shared.pool
        wkConfig.setURLSchemeHandler(customSchemeHandler, forURLScheme: MobileFrameEngine.shared.config.customScheme)
        if #available(iOS 13.0, *) {
            wkConfig.defaultWebpagePreferences.preferredContentMode = .mobile;
        }
        return wkConfig
    }
    
    func registerMethod(wkConfig: WKWebViewConfiguration, javaScript: String?) {
        if javaScript != nil, javaScript != "" {
            let userScript : WKUserScript = WKUserScript.init(source: javaScript!, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            wkConfig.userContentController.addUserScript(userScript)
        }
    }
    
    func registerAllScriptMessage() {
        removeAllScriptMessage()
        
        let scriptMessageHandler = WebViewUserContentController(jsNative: self.jsNative)
        for messageName in MessageName.allCases {
            webView?.configuration.userContentController.add(scriptMessageHandler, name: messageName.rawValue)
        }
    }
    
    func removeAllScriptMessage() {
        for messageName in MessageName.allCases {
            self.webView?.configuration.userContentController.removeScriptMessageHandler(forName: messageName.rawValue)
        }
    }
    
    func downloadMimeType(str: String) -> Bool {
        if str.contains(".csv") {
            return true
        }
        return false
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
        removeAllScriptMessage()
        
        WebViewReusePool.shared.recycleReusedWebView(webView)
        
        if estimatedProgressObservationToken != nil {
            estimatedProgressObservationToken = nil
        }
        self.webView?.uiDelegate = nil
        self.webView?.navigationDelegate = nil
        
        SLogInfo("WebViewController deinit!")
    }
}

extension WebViewController {
    
    static func enterEchat() {
        
        guard let localGlobalStaticModel = OfflineResourcesManager.shared.localGlobalModel else {
            return
        }
        
        guard let dashboardID = localGlobalStaticModel.EChatDashboardID else {
            return
        }
        
        guard let serverUrl = localGlobalStaticModel.EChatServerUrl else {
            return
        }
        
        if let nav = APPDELEGATE?.window??.rootViewController as? NavigationViewController {
            
            LoginManager.shared.updateSession() { success in
                
                let url = "\(MobileFrameEngine.shared.config.serverHost)/Home?EncompassID=\(MobileFrameEngine.shared.config.encompassID)&EncompassSessionID=\(MobileFrameEngine.shared.userInfo?.EncompassSessionID ?? "")&DashboardID=\(dashboardID)"
                
                let newWebVC = WebViewController.init()
                newWebVC.iseChat = true
                newWebVC.urlStr = url
                nav.pushViewController(newWebVC, animated: true)
                
            }
        }
    }
}
