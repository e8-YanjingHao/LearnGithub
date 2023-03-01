//
//  NavigationViewController.swift
//  ScanCode
//
//  Created by Encompass on 2021/11/11.
//

import UIKit

open class NavigationViewController: UINavigationController {

    open override func viewDidLoad() {
        super.viewDidLoad()

        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        self.navigationItem.leftBarButtonItems = [barButtonItem]
        self.navigationItem.hidesBackButton = true
        
        if #available(iOS 13.0, *) {
             let app = UINavigationBarAppearance()
             app.configureWithOpaqueBackground()
             app.titleTextAttributes = [
                   NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18),
                   NSAttributedString.Key.foregroundColor: UIColor.white
             ]
             app.backgroundColor = UIColor.white
             app.shadowColor = .clear
             app.backgroundEffect = nil
             UINavigationBar.appearance().scrollEdgeAppearance = app
             UINavigationBar.appearance().standardAppearance = app
        }
    }
    
    public func redirectToViewController(_ viewController: UIViewController, animated: Bool) {
        if viewController is WebViewController {
            let viewControllers = self.viewControllers
            var existVC : WebViewController? = nil
            for vc in viewControllers {
                if let vc : WebViewController = vc as? WebViewController {
                    if isExistInStack(vc1: vc, vc2: viewController as! WebViewController) {
                        existVC = vc
                    }
                }
            }
            if existVC == nil {
                self.pushViewController(viewController, animated: animated)
            } else {

                self.popToViewController(existVC!, animated: false)
            }
        } else {
            self.pushViewController(viewController, animated: animated)
        }
    }
    
    func isExistInStack(vc1: WebViewController, vc2: WebViewController) -> Bool {
        if let dashboardid1 = vc1.dashboardId, let dashboardid2 = vc2.dashboardId, dashboardid1 == dashboardid2 {
            return true
        }
        if let urlStr1 = vc1.urlStr, let urlStr2 = vc2.urlStr, urlStr1.elementsEqual(urlStr2) {
            return true
        }
        if let url1 = vc1.url, let url2 = vc2.url, url1.absoluteString.elementsEqual(url2.absoluteString) {
            return true
        }
        if let localPath1 = vc1.localFilePath, let localPath2 = vc2.localFilePath, localPath1.elementsEqual(localPath2) {
            return true
        }
        if let request1 = vc1.request?.url?.absoluteString, let request2 = vc2.request?.url?.absoluteString, request1.elementsEqual(request2) {
            return true
        }
        
        return false
    }
}
