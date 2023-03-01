//
//  DevToolsView.swift
//  MobileFrame
//
//  Created by ERIC on 2021/12/13.
//

import UIKit

internal protocol DevToolsViewDelegate {
    func devToolsClose(_ devToolsView: DevToolsView)
    func devToolsReload(_ devToolsView: DevToolsView)
    func devToolsLogout(_ devToolsView: DevToolsView)
    func devToolsClear(_ devToolsView: DevToolsView)
    func devToolsDraft(_ devToolsView: DevToolsView)
    func devToolsNavToTestDashboard(_ devToolsView: DevToolsView)
}

internal class DevToolsButton: UIButton {
    
    lazy var devToolsView: DevToolsView = {
        let view = DevToolsView(frame: .zero)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setTitle("Debug", for: .normal)
        self.setTitleColor(.white, for: .normal)
        self.backgroundColor = UIColor.hexColor(hex: "ff0000")
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
        self.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        
        APPDELEGATE?.window??.addSubview(devToolsView)
        
        devToolsView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(SCREEN_HEIGHT/2)
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func updateLayout() {
        if UIDevice.current.orientation == .portrait {
            self.devToolsView.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalToSuperview().dividedBy(2)
            }
        } else {
            self.devToolsView.snp.remakeConstraints { (make) in
                make.height.equalToSuperview().dividedBy(2)
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview().offset(0)
            }
            
            self.devToolsView.tableView.snp.remakeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview().offset(0)
                make.bottom.equalToSuperview().offset(-FIT_SIZE(w: 60))
                make.top.equalToSuperview()
            }
        }
        
        let itemWidth:CGFloat = SCREEN_WIDTH / CGFloat(4)
        for (index, itemView) in self.devToolsView.toolView.subviews.enumerated() {
            itemView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(CGFloat(index)*itemWidth)
                make.top.equalToSuperview().offset(0)
                make.width.equalToSuperview().dividedBy(4)
                make.height.equalTo(FIT_SIZE(w: 60))
            }
        }
    }
    
    @objc func onClick() {
        devToolsView.isHidden = !devToolsView.isHidden
        
        if devToolsView.isHidden == false {
            if devToolsView.dashboardId != 0 {
                devToolsView.defaultDataSource(dashboardId: devToolsView.dashboardId)
            }
        }
    }
}

public class DevToolsView: UIView {
    
    var delegate: DevToolsViewDelegate?
    var dashboardId: Int = 0
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = UIColor.hexColor(hex: "#f5f5f5")
        tableView.estimatedRowHeight = 50
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44.0
        return tableView
    }()
    
    lazy var toolView: UIView = {
        let toolView = UIView(frame: .zero)
        toolView.backgroundColor = .white
        return toolView
    }()
    
    lazy var switchView: UISwitch = {
        let switchView = UISwitch(frame: .zero)
        switchView.addTarget(self, action: #selector(onSwitchToDraft), for: .valueChanged)
        return switchView
    }()
    
    var dataSource: [[String: String]] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .red
        self.isHidden = true
        
        self.addSubview(tableView)
        self.addSubview(toolView)
        
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-FIT_SIZE(w: 60))
        }
        
        toolView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(FIT_SIZE(w: 60))
        }
        
        makeUI()
    }
    
    func makeUI() {
        let actions = [
            [
                "action": "logout",
                "title": "Logout",
            ],
            [
                "action": "reload",
                "title": "Reload",
            ],
            [
                "action": "clear",
                "title": "Clear",
            ],
            [
                "action": "close",
                "title": "Close",
            ],
        ]
        
        let itemWidth:CGFloat = SCREEN_WIDTH / CGFloat(actions.count)
        for (index, item) in actions.enumerated() {
            let itemView = UIView(frame: .zero)
            
            let btn = UIButton(frame: itemView.bounds)
            btn.setTitle(item["title"], for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.addTarget(self, action: Selector(item["action"]!), for: .touchUpInside)
            
            let line = UIView(frame: CGRect(x: 0, y: 15, width: 1, height: itemView.frame.height-30))
            line.backgroundColor = UIColor.hexColor(hex: "#f5f5f5")
            itemView.addSubview(line)
            
            itemView.addSubview(btn)
            toolView.addSubview(itemView)
            
            btn.snp.makeConstraints { make in
                make.top.left.right.bottom.equalToSuperview()
            }
            
            line.snp.makeConstraints { make in
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 1, height: 30))
            }
            
            itemView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(CGFloat(index)*itemWidth)
                make.top.equalToSuperview().offset(0)
                make.width.equalToSuperview().dividedBy(actions.count)
                make.height.equalTo(FIT_SIZE(w: 60))
            }
        }
    }
    
    func defaultDataSource(dashboardId: Int) {
        self.dashboardId = dashboardId
        
        dataSource.removeAll()
        
        dataSource.append([
            "title": "Switch To Draft:",
            "status": "0",
        ])
        
        dataSource.append([
            "title": "Navigate to Test Dashboard:",
            "action": "onClickNavToTestDashboard"
        ])
        
        dataSource.append([
            "title": "Global Settings",
            "detail": "EncompassID: \(MobileFrameEngine.shared.config.encompassID) \nServerHost: \(MobileFrameEngine.shared.config.serverHost) \nUserAgent: \(MobileFrameEngine.shared.config.userAgent)"
        ])
        
        if let globalModel = OfflineResourcesManager.shared.getLocalGlobalModal() {
            dataSource.append([
                "title": "Global Static Resource:",
                "detail": "EncompassID: \(String(describing: globalModel.EncompassID ?? "")) \nMajorVersion: \(String(describing: globalModel.MajorVersion ?? "")) \nEntryDashboardID: \(String(describing: globalModel.EntryDashboardID ?? 0)) \nMobileFrameAppZipTimeUpdated: \(String(describing: globalModel.MobileFrameAppZipTimeUpdated ?? ""))"
            ])
        }
        
        if let dashboard = OfflineResourcesManager.shared.getDashboardFromDB(dashboardID: dashboardId) {
            dataSource.append([
                "title": "Dashboard Resource:",
                "detail": "Dashboard: \(String(describing: dashboard.DashboardID ?? 0)) \nVersionId: \(String(describing: dashboard.DashboardVersionID ?? 0)) \nTimeUpdated: \(String(describing: dashboard.TimeUpdated ?? ""))"
            ])
        }
        
        if let cookie = LoginManager.shared.getCookieData() {
            dataSource.append([
                "title": "Cookie Data:",
                "detail": cookie
            ])
        }
        else {
            dataSource.append([
                "title": "Cookie Data:",
                "detail": "暂无"
            ])
        }
        
        tableView.reloadData()
    }
    
    @objc func reload() {
        delegate?.devToolsReload(self)
    }
    
    @objc func close() {
        self.isHidden = true
    }
    
    @objc func logout() {
        delegate?.devToolsLogout(self)
    }
    
    @objc func clear() {
        delegate?.devToolsClear(self)
    }
    
    @objc func onSwitchToDraft() {
        delegate?.devToolsDraft(self)
    }
    
    @objc func onClickNavToTestDashboard() {
        delegate?.devToolsNavToTestDashboard(self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}

extension DevToolsView: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
            cell?.selectionStyle = .none
        }
        let row = dataSource[indexPath.row]
        cell?.textLabel?.text = row["title"]
        cell?.textLabel?.textColor = UIColor.hexColor(hex: "#ff0000")
        
        if indexPath.row == 0 {
            cell?.detailTextLabel?.text = ""
            cell?.detailTextLabel?.numberOfLines = 0
            cell?.contentView.addSubview(switchView)
            switchView.setOn(MobileFrameEngine.shared.config.isGlobalDraft, animated: true)

            switchView.snp.makeConstraints { make in
                make.top.equalTo(5)
                make.right.equalToSuperview().offset(0)
                make.size.equalTo(CGSize(width: FIT_SIZE(w: 60), height: FIT_SIZE(w: 40)))
            }
        }
        else if indexPath.row == 1 {
            cell?.detailTextLabel?.text = ""
            cell?.accessoryType = .disclosureIndicator
        }
        else {
            cell?.accessoryType = .none
            cell?.detailTextLabel?.text = row["detail"]
            cell?.detailTextLabel?.numberOfLines = 0
        }
        
        return cell ?? UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = dataSource[indexPath.row]
        if let action = row["action"] {
            self.perform(Selector(action))
        }
    }
}
