//
//  QuickLookViewController.swift
//  MobileFrame
//
//  Created by ERIC on 2022/4/13.
//

import UIKit
import QuickLook

class QuickLookViewController: QLPreviewController {

    var filePath = ""
    var titleLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        
        customBackButton()
        customTitleStyle()
                
        self.titleLabel?.text = (filePath as NSString).lastPathComponent.isBlank ? "文件预览" : (filePath as NSString).lastPathComponent
        delegate = self
        dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        self.navigationController?.isNavigationBarHidden = true
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
        self.navigationController?.popViewController(animated: true)
    }
}

extension QuickLookViewController: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return NSURL(fileURLWithPath: self.filePath) as QLPreviewItem
    }
}
