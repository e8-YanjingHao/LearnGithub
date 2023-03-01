# MobileFrame

MobileFrame 是一款基于WKWebView深度定制的iOS移动端开发框架，使用此框架可以使前端混合开发变得更加简单易用。

## 框架特性

- JS交互深度定制
- 本地Sqlite数据库，及数据模型映射
- 静态资源本地缓存
- webview离线加载
- 系统登录状态管理
- 基础网络请求

## 开发要求

- 开发语言：Swift5.5版本及以上
- 开发环境：XCode13.0及以上
- 应用环境：iOS10.0及以上
- 

## 框架依赖类库

- ```SSZipArchive``` 文件解压缩库，最低版本要求2.4.2
- ```SwiftyJSON``` Json格式化库，最低版本要求5.0.1
- ```Tiercel``` 异步网络资源下载库，最低版本要求3.2.5
- ```SQLite.swift``` 移动端本地数据库，最低版本要求0.13.0
- ```ReachabilitySwift``` 网路状态监听库，最低版本要求5.0.0

## 功能模块

```
.
├── MobileFrame.h							# OC桥接文件
├── Engine
│   └── MobileFrameEngine.swift				# 框架入口文件
├── Config
│   └── MobileFrameConfig.swift				# 默认配置文件
├── Core
│   └── OfflineResourcesManager.swift		# 离线资源下载文件
├── Auth
│   ├── API.swift							# 框架内部使用API
│   └── LoginManager.swift					# 框架内部登录状态管理
├── Model
│   ├── DashboardModel.swift				# 框架内部数据模型
│   ├── GlobalStaticModel.swift
│   ├── NetCachesModel.swift
│   └── UserInfoModel.swift
├── Net
│   ├── NetWorkManager.swift				# 网络请求类
│   └── NetworkStatus
│       └── NetworkStatusManager.swift		# 网络状态监听类
├── Store
│   ├── SQLiteManager.swift					# sql管理类，数据模型映射类
│   ├── SQLMirrorModel.swift			
│   └── SQLitePropModel.swift
├── Utils									
│   ├── DeviceSupport
│   │   └── DeviceInfoUtil.swift			# 系统环境信息
│   ├── Extensions
│   │   ├── ArrayExtension.swift			# 扩展类
│   │   ├── DictionaryExtension.swift
│   │   ├── NotificationNameExtension.swift
│   │   └── StringExtension.swift
│   ├── ImageUtil
│   │   └── ImageUtil.swift
│   ├── LocalFileManager					
│   │   └── LocalFileManager.swift			# 文件操作类
│   ├── Log
│   │   └── SwiftLog.swift					# 日志管理类
│   ├── PermissionUtil
│   │   └── PermissionUtil.swift			# 权限设置类
│   └── ZipArchive
│       └── ZipArchiveManager.swift			# 解压缩类
├── WebView									# webview封装类 扩展JS交互
│   ├── Controllers
│   │   ├── CodeScannerViewController.swift
│   │   ├── NavigationViewController.swift
│   │   ├── WebViewController.swift
│   │   └── WebViewUserContentController.swift
│   ├── CustomScheme
│   │   └── CustomSchemeHandler.swift
│   ├── JS
│   │   ├── CustomScriptMessageHandler.swift
│   │   └── JSNative.swift
│   ├── ProcessPool
│   │   └── WKProcessPoolHelper.swift
│   └── Views
│       ├── DevToolsHelper.swift
│       └── DevToolsView.swift
├── Resources								# 静态资源类
```

## 推荐使用CocoaPods

```
target 'MobileFrameExampleApp' do
	platform :ios, '10.0'
	
    use_frameworks!
	
    pod 'MobileFrame', :svn => 'https://svn.encompass8.com:8443/svn/MobileFrame/iOS/Dev/MobileFrame/'
end

```

说明：
1. ```https://svn.encompass8.com:8443/svn/MobileFrame/iOS/Dev/MobileFrame/```为开发地址，随后会发布线上地址
2. 使用Pod管理能够更方便的更新框架以及版本控制
3. CocoaPods安装流程请自行查阅，推荐使用版本1.11.2及以上

## 快速使用

### 1. 新建项目工程

1. 打开xcode开发工具，```Command+Shift+N```新建工程
2. 设置工程名，开发语言选择Swift，选择下一步
3. 新建项目至指定目录，选择```Don`t add to any project or workspace```

### 2. 安装MobileFrame库

1. 打开终端，并cd到项目根目录，输入```pod init```
2. 此时根目录会新建```Podfile```，打开此文件
3. 将cocoaPods说明部分的内容粘贴到Podfile中，并修改```MobileFrameExampleApp```为自己的工程名称，保存文件
4. 在终端输入```pod install```，等待依赖类库下载完毕
5. 如果未报任何错误，说明MobileFrame引入成功
6. 点击工程根目录中```xxx.xcworkspace```，打开工程

### 3. 初始化

1. 在```AppDelegate```顶部导入MobileFrame```import MobileFrame```
2. 在```didFinishLaunchingWithOptions```方法中编写初始化方法：

```swift
let config = MobileFrameConfig()
config.mobileFrameAppID = "1"
config.encompassID = "Pioneer2201"
config.serverHost = "https://test.encompass8.com"
config.addLocalLog = true
config.updateOfflineInSeconds = 10 * 60
config.devTools = true
config.sqlLog = true
MobileFrameEngine.shared.initWithConfig(config: config, delegate: self)
MobileFrameEngine.shared.checkUpdateVersion()
```
3. 在```AppDelegate```中实现delegate方法，具体操作如下：

```swift
extension AppDelegate: MobileFrameEngineDelegate {
	// 资源下载任务监听
    func mobileFrameUpdateOfflineResult(complate: Bool, totalCount: Int, updateCount: Int, progress: CGFloat) {
        if totalCount != updateCount {
            self.window?.rootViewController?.view.showLoading("正在下载资源包: \(updateCount) / \(totalCount)")
        }
        else {
            self.window?.rootViewController?.view.hideLoading()
        }
    }
    
	// 框架监听到登出操作，应用层处理后续业务
    func logOut() {
    }
}
```

4. 在```AppDelegate```的```handleEventsForBackgroundURLSession```中实现以下方法，用来实现资源后台下载断点续传功能：

```swift
func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        let downloadManagers = [NetWorkManager.shared.sessionManager]
        for manager in downloadManagers {
            if manager.identifier == identifier {
                manager.completionHandler = completionHandler
                break
            }
        }
    }
```

5. 在```Info.plist```文件中，新增```App Transport Security Settings```并设置```Allow Arbitrary Loads```为YES
6. 初始化首页控制器，并将此控制器继承自```WebViewController```，如果提示未找到WebViewController，则在控制器顶部```import MobileFrame```
7. 在首页控制器中编写以下代码，用来加载入口网页内容

```swift
import MobileFrame

class ViewController: WebViewController {

    override func viewDidLoad() {
        (dashboardId, localFilePath) = MobileFrameEngine.shared.entryDashboardFilePath()

        super.viewDidLoad()
        
        self.changeStateBar()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func insertCookies() {
        WKProcessPoolHelper.shared.loadHttpCookie(webviewVC: self)
    }
    
    func changeStateBar() {
        let stateBarBlockView = UIView(frame: CGRect.init(x: 0, y: 0, width: Int(SCREEN_WIDTH), height: Int(UIApplication.shared.statusBarFrame.height)))
        stateBarBlockView.backgroundColor = UIColor.rgba(red: 22.0, green: 114.0, blue: 193.0)

        KWINDOW??.addSubview(stateBarBlockView)
        KWINDOW??.bringSubviewToFront(stateBarBlockView)
    }
}
```

## 预加载离线资源包

## 日志说明


