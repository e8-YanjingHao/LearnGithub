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
- ```Alamofire``` 网络请求库，最低版本要求5.4.4
- ```ReachabilitySwift``` 网络状态监控，最低版本要求5.0.0
- ```SnapKit``` ui布局库，最低版本要求5.0.1
- ```SwiftyJSON``` Json格式化库，最低版本要求5.0.1
- ```SQLite.swift``` 移动端本地数据库，最低版本要求0.13.0

## 功能模块

```
.
├── MobileFrame.h                               # OC桥接文件
├── Engine
│   └── MobileFrameEngine.swift                 # 框架入口文件
├── Config
│   └── MobileFrameConfig.swift                 # 默认配置文件
├── Core
│   └── OfflineResourcesManager.swift           # 离线资源下载文件
├── Auth
│   ├── API.swift                               # 框架内部使用API
│   └── LoginManager.swift                      # 框架内部登录状态管理
├── Model
│   ├── DashboardModel.swift                    # 框架内部数据模型
│   ├── GlobalStaticModel.swift
│   ├── NetCachesModel.swift
│   └── UserInfoModel.swift
├── Net
│   ├── NetWorkManager.swift                    # 网络请求类
│   └── NetworkStatus
│       └── NetworkStatusManager.swift          # 网络状态监听类
├── Store
│   ├── SQLiteManager.swift                     # sql管理类，数据模型映射类
│   ├── SQLMirrorModel.swift            
│   └── SQLitePropModel.swift
├── Utils                                    
│   ├── DeviceSupport
│   │   └── DeviceInfoUtil.swift                # 系统环境信息
│   ├── Extensions
│   │   ├── ArrayExtension.swift                # 扩展类
│   │   ├── DictionaryExtension.swift
│   │   ├── NotificationNameExtension.swift
│   │   └── StringExtension.swift
│   ├── ImageUtil
│   │   └── ImageUtil.swift
│   ├── LocalFileManager                    
│   │   └── LocalFileManager.swift              # 文件操作类
│   ├── Log
│   │   └── SwiftLog.swift                      # 日志管理类
│   ├── PermissionUtil
│   │   └── PermissionUtil.swift                # 权限设置类
│   └── ZipArchive
│       └── ZipArchiveManager.swift             # 解压缩类
├── WebView                                     # webview封装类 扩展JS交互
│   ├── Controllers
│   │   ├── QuickLookViewController.swift
│   │   ├── WebViewReusePool.swift
│   │   ├── ReuseWebView.swift
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
```

## 全局配置字段说明

```
mobileFrameAppID: 平台为应用分配的唯一标识
	
encompassID: 默认使用的encompassID，例如DSDLink2203

serverHost: 默认使用的域名，例如https://dsdlink.com

userAgent: 默认使用的userAgent

sqlLog: 是否输出并记录sql语句，默认为false

devtools: 是否打开调试功能，默认为false
```

## 推荐使用CocoaPods

```
target 'MobileFrameExampleApp' do    
    use_frameworks!
    
    pod 'MobileFrame', :svn => 'https://svn.encompass8.com:8443/svn/EM-Client/MobileFrame/iOS/Dev/MobileFrame/'
end

```

说明：
1. ```https://svn.encompass8.com:8443/svn/EM-Client/MobileFrame/iOS/Dev/MobileFrame/```为开发地址，随后会发布线上地址
2. 使用Pod管理能够更方便的更新框架以及版本控制
3. CocoaPods安装流程请自行查阅，推荐使用版本1.11.2及以上

## 快速集成

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
let systemVersion : String = UIDevice.current.systemVersion
let systemName : String = UIDevice.current.systemName
let model : String = UIDevice.current.model
let infoDictionary = Bundle.main.infoDictionary ?? [:]
let appVersion : String = (infoDictionary["CFBundleShortVersionString"] as? String) ?? ""
let userAgent : String = "DSDLink_"+appVersion+"_"+systemName+"_"+systemVersion+"_"+"Apple"+"_"+model

let config = MobileFrameConfig()
config.mobileFrameAppID = "2"
config.encompassID = "DSDLink"
config.serverHost = "https://dsdlink.com"
config.userAgent = userAgent
config.devTools = false
config.sqlLog = true

MobileFrameEngine.shared.initWithConfig(config: config, delegate: self)

MobileFrameEngine.shared.setAppConfigComplateBlock = {
    APPDELEGATE?.window??.rootViewController = NavigationViewController.init(rootViewController: MiddleViewController())
}

self.window?.rootViewController = NavigationViewController.init(rootViewController: MiddleViewController())
```
3. 在```AppDelegate```中实现delegate方法，具体操作如下：

```swift
extension AppDelegate: MobileFrameEngineDelegate {
        // 资源下载任务监听
    func mobileFrameUpdateOfflineResult(complate: Bool, totalCount: Int, updateCount: Int, progress: CGFloat) {
    }
    
    // 框架监听到登出操作，应用层处理后续业务
    func logOut() {
        let rootVc =  ViewController()
        rootVc.dashboardId = 190577 //登录页面的dashboardID
        rootVc.localFilePath = "190577.html"
        self.window?.rootViewController = NavigationViewController.init(rootViewController: rootVc)
    }
}
```

4. 在```Info.plist```文件中，新增```App Transport Security Settings```并设置```Allow Arbitrary Loads```为YES
5. 初始化首页控制器，并将此控制器继承自```WebViewController```，如果提示未找到WebViewController，则在控制器顶部```import MobileFrame```

## 预加载离线资源包

### 1. 功能介绍

为了能够使项目离线使用更加方便，我们计划在项目中预加载部分页面资源，在应用被初始化的时候同时初始化静态资源文件，保证第一次打开APP```无网络连接```也能够使用项目

### 2. 实现方式

1. 在项目根目录中新建```Resources/Dashboards```目录，作为存放网页静态资源的目录
2. 将静态资源包导入Dashboards目录下，每个资源包以zip格式存放，不支持其他格式
3. 在Dashboards目录下新建```resources.plist```配置文件，用来控制资源包版本，以下是配置文件的相关字段说明
4. 开发人员只需要按照以上步骤将资源包和配置文件初始化完成，剩下的工作MobileFrame会自动判断处理这些资源文件
5. 因为是在项目中打包的静态资源包，所以每次需要更新的时候，app则需要重新发布新版本
6. 新增资源必须要在```resources.plist```新增或修改对应的字段，否则不会生效

- OfflineDashboards: Array类型存放每个页面的静态资源数据
    - DashboardVersionID: dashboard初始版本可以默认为```-1```
    - TimeUpdated: 更新时间，此处功能作为更新记录
    - DashboardID: dashboard文件的id号
- GlobalZipURL: dashboard全局静态资源包CSS,JS等等，对应目录中的文件名称```例如目录中的文件名称为：GlobalStaticFiles.zip 则此处的字段值为GlobalStaticFiles```
- MobileFrameAppZipURL: APP全局资源包，不同的APP可能会有不同的需求配置，在这个资源包内管理
- MajorVersion: 全局静态资源包对应的初始版本可以默认为```-1```
- MobileFrameAppZipTimeUpdated: 更新时间，此处功能作为更新记录
- EncompassID: 项目初始化配置的EncompassID
- EntryDashboardID: 默认入口Dashboard，作为应用一打开之后就会默认展示的dashboard页面，此字段为OfflineDashboards中的任何一个dashboardID

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>OfflineDashboards</key>
    <array>
        <dict>
            <key>DashboardVersionID</key>
            <string>158534</string>
            <key>TimeUpdated</key>
            <string>2021-12-12 00:00:00</string>
            <key>DashboardID</key>
            <string>189683</string>
        </dict>
        <dict>
            <key>DashboardVersionID</key>
            <string>158748</string>
            <key>TimeUpdated</key>
            <string>2021-12-12 00:00:00</string>
            <key>DashboardID</key>
            <string>189785</string>
        </dict>
        <dict>
            <key>DashboardVersionID</key>
            <string>159562</string>
            <key>TimeUpdated</key>
            <string>2021-12-12 00:00:00</string>
            <key>DashboardID</key>
            <string>190156</string>
        </dict>
    </array>
    <key>GlobalZipURL</key>
    <string>GlobalStaticFiles</string>
    <key>MobileFrameAppZipURL</key>
    <string>MobileFrameZipApp</string>
    <key>MajorVersion</key>
    <string>22.01</string>
    <key>MobileFrameAppZipTimeUpdated</key>
    <string>2021-12-12 00:00:00</string>
    <key>EncompassID</key>
    <string>Pioneer2201</string>
    <key>EntryDashboardID</key>
    <string>189683</string>
</dict>
</plist>

```

## 开放api方法

#### 1. EC_App.NavigateTo

页面正向跳转，使用EC_App.NavigateBack可以返回上一页面

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| DashboardID | string | '' | 是 |
| Data | object | {} | 否 |

##### 返回值

无返回值

##### 实例

```
EC_App.NavigateTo("191003", {
	title: encodeURIComponent("测试传参"),
	content: encodeURIComponent("这是上一页传的参数")
});
```

#### 2. EC_App.RedirectTo

页面重定向跳转，使用此方法后，不可以返回上一页面

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| DashboardID | string | '' | 是 |
| Data | object | {} | 否 |

##### 返回值

无返回值

##### 实例

```
EC_App.RedirectTo("190577");
```

#### 3. EC_App.Open

调用此方法打开在线网页，需要传url地址

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Url | string | '' | 是 |

##### 返回值

无返回值

##### 实例

```
EC_App.Open("https://test.encompass8.com/Home?DashboardID=190528&EncompassID=DSDLink2202&release=false");
```

#### 4. EC_App.NavigateBack

返回上一页面，当调用EC_App.NavigateTo方法后，可以调用此方法返回上一页

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Data | object | {} | 否 |

##### 返回值

无返回值

##### 实例

```
EC_App.NavigateBack();
```

#### 5. EC_App.BindNavigateBack

页面逆向传值，当前页面接收返回之前的页面传递过来的参数

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| callback | func | (res) => {} | 是 |

##### 返回值

无返回值

##### 实例

```
// 在A页面，接收逆向传参
EC_App.BindNavigateBack((data) => {
});

// A页面跳转B页面
EC_App.NavigateTo("191003", {});

// 在B页面调用返回逆向传参
EC_App.NavigateBack({
	title: "页面返回传参",
	content: "页面返回上一页传参内容"
});
```

#### 6. EC_App.Login

应用登录方法，登录成功后会返回用户信息等

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Username | string | '' | 是 |
| Password | string | '' | 是 |

##### 返回值

| 属性 | 类型 | 默认值 |
| :---- | :----: | :----: |
| status | string | 'success' or 'fail' |
| message | string | '' |


##### 实例

```
EC_App.Login("Jiajun$", "passworad").then((n) => {
	if (n.status && n.status === "success") {
		ECP.Dialog.Alert("login success!", (e) => {});
	} else {
		ECP.HTML.Snackbar(n.message, "Error");
	}
	ECP.Dialog.HideLoading();
}, (err) => {
	ECP.HTML.Snackbar(err.message, "Error");
});
```

#### 7. EC_App.Logout

应用退出登录方法，调用退出登录成功后，应用会重定向到登录页面，并且清除用户数据

##### 参数

无参数

##### 返回值

无返回值

##### 实例

```
EC_App.Logout();
```

#### 8. EC_App.ScanQRCode

调用扫描二维码、条形码接口，拉起原生扫码界面

##### 参数

无参数

##### 返回值

| 属性 | 类型 | 默认值 |
| :---- | :----: | :----: |
| result | string | 扫码结果，扫码失败返回'null' |
| Status | bool | 扫码成功返回true, 扫码失败返回false |


##### 实例

```
EC_App.ScanQRCode().then((result) => {
	ECP.Dialog.Alert(result, (e) => {});
}, (err) => {
	ECP.HTML.Snackbar(err.message, "Error");
});
```

#### 9. EC_App.Log

日志记录，此方法会将参数记录到本地log文件中

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Content | string | '' | 是 |

##### 返回值

无返回值

##### 实例

```
EC_App.Log("this is a log record.");
```

#### 10. EC_App.GetAppInfo

获取应用详情，包括设备信息，版本信息，应用信息等等

##### 参数

无参数

##### 返回值

| 属性 | 类型 | 默认值 |
| :---- | :----: | :----: |
| DeviceName | string | '' |
| DeviceModel | string | ''  |
| DeviceModelName | string | ''  |
| SystemVersion | string | ''  |
| SystemName | string | ''  |
| AppVersion | string | ''  |
| DeviceSerialNum | string | ''  |
| UserAgent | string | ''  |
| ScreenWidth | float | 0  |
| ScreenHeight | float | 0  |
| StatusBarHeight | float | 0  |
| NavHeight | float | 0  |
| NavSafeHeight | float | 0  |
| EncompassID | string | ''  |
| ServerHost | string | ''  |
| MobileFrameAppID | string | ''  |
| FontScale | float | 0  |

##### 实例

```
EC_App.GetAppInfo().then((result) => {

});

// resutl
"{\"FontScale\":0.93000000000000005,\"DeviceModelName\":\"x86_64\",\"ScreenHeight\":926,\"ServerHost\":\"https:\\/\\/dsdlink.com\",\"SystemName\":\"iOS\",\"DeviceModel\":\"iPhone\",\"SystemVersion\":\"15.4\",\"DeviceName\":\"iPhone 12 Pro Max\",\"MobileFrameAppID\":\"1\",\"ScreenWidth\":428,\"UserAgent\":\"DSDLink_22.01.01_iOS_15.1.1_Apple_iPhone\",\"StatusBarHeight\":44,\"AppVersion\":\"1.0\",\"NavHeight\":44,\"NavSafeHeight\":88,\"EncompassID\":\"DSDLink\",\"DeviceSerialNum\":\"05FDEC14-FBB8-4DD3-B04B-9B34913E67B9\"}"
```

#### 11. EC_App.GetLocation

获取定位权限，并且返回经纬度

##### 参数

无参数

##### 返回值

| 属性 | 类型 | 默认值 |
| :---- | :----: | :----: |
| Latitude | string | '106.328383' |
| Longitude | string | '35.032338'  |
| Status | bool | 经纬度获取成功返回true，获取失败返回false，当返回false的时候，经纬度默认为'null' |

##### 实例

```
EC_App.GetLocation().then((result) => {
}, (err) => {
});
```

#### 12. EC_App.OpenAppSettings

打开手机设置页面

##### 参数

无参数

##### 返回值

无返回值

##### 实例

```
EC_App.OpenAppSettings();
```

#### 13. EC_App.GetAppConfig

获取应用配置可配置信息，应用内部分全局字段允许在应用内可配置修改

##### 参数

无参数

##### 返回值

| 属性 | 类型 | 默认值 |
| :---- | :----: | :----: |
| EncompassID | string | '' |
| ServerHost | string | ''  |
| UserAgent | string | '' |
| DevTools | bool | true |

##### 实例

```
EC_App.GetAppConfig().then(result => {
	console.log(res)
})

// result
{DevTools: true, EncompassID: "DSDLink", ServerHost: "https://dsdlink.com", UserAgent: "DSDLink_22.01.01_iOS_15.1.1_Apple_iPhone"}
```

#### 14. EC_App.SetAppConfig

设置修改全局配置参数，具体参数如下

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| EncompassID | string | '' | 是 |
| ServerHost | string | '' | 是 |
| UserAgent | string | '' | 是 |
| DevTools | bool | false | 否 |

##### 返回值

无返回值

##### 实例

```
EC_App.SetAppConfig({
	EncompassID: "DSDLink",
	ServerHost: "https://api.encompass8.com",
	UserAgent: "DSDLink_22.01.01_iOS_15.1.1_Apple_iPhone_Test",
	DevTools: false
}).then((res) => {
	console.log(res);
}, (err) => {
	console.log(err);
});
```

#### 15. EC_App.UploadLogs

上传设备报错的日志文件，以及本地数据库文件

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Memo | string | '' | 是 |

##### 返回值

无返回值

##### 实例

```
EC_App.UploadLogs("test memo").then((res) => {
	//上传成功
}, (err) => {
	//上传失败
});
```

#### 16. EC_App.DownloadFile

根据url和指定参数下载内容，在应用指定目录下生成文件并保存

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Url | string | '' | 是 |
| PostData | object | {} | 否 PostData为空的时候默认GET请求，不为空默认POST请求 |
| FilePath | string | '' | 否 FilePath为空的时候默认存储到沙盒tmp临时目录，不为空则存储到document目录下指定路径 |

##### 返回值

无返回值

##### 实例

```
EC_App.DownloadFile("https://test.encompass8.com/API?APICommand=Get_PaylinkInvoiceTransSource&WebRequestID=undefined&RequestDashboardID=188864&FileName=Dahlheimer&EDBLSource=Dahlheimer", {
	InvoiceIDArr: 1384459,
	ReportID: 9735136
}, "files/incoude/123.csv").then((res) => {
	console.log(res);
}, (err) => {
	console.log(err);
});
```

#### 17. EC_App.OpenFile

根据FilePath打开预览本地文件

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| FilePath | string | '' | 是 |

##### 返回值

无返回值

##### 实例

```
 EC_App.OpenFile(res).then((res) => {
	console.log(res);
}, (err) => {
	console.log(err);
});
```

#### 18. EC_App.SQLite.ExecuteSQL

执行sql语句

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Sql | string | '' | 是 |

##### 返回值

无返回值

##### 实例

```
 EC_App.SQLite.ExecuteSQL('select * from "cacheModel"').then((res) => {
	console.log(res);
}, (err) => {
	console.log(err);
});
```

#### 19. EC_App.Storage.SetItem

存储内容到本地缓存数据库，支持键值存储

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Key | string | '' | 是 |
| Content | string | '' | 是 |

##### 返回值

无返回值

##### 实例

```
EC_App.Storage.SetItem("key1", "value1").then((res) => {
	console.log(res);
}, (err) => {
	console.log(err);
});
```

#### 20. EC_App.Storage.GetItem

从本地缓存数据库获取缓存数据

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Key | string | '' | 是 |

##### 返回值

无返回值

##### 实例

```
EC_App.Storage.GetItem("key1").then((res) => {
	console.log(res);
}, (err) => {
	console.log(err);
});
```

#### 21. EC_App.Storage.RemoveItem

从本地缓存数据库删除指定数据内容

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Key | string | '' | 是 |

##### 返回值

无返回值

##### 实例

```
EC_App.Storage.RemoveItem("key1").then((res) => {
	console.log(res);
}, (err) => {
	console.log(err);
});
```

#### 22. EC_App.Storage.Keys

从本地缓存数据库删除指定数据内容

##### 参数

| 属性 | 类型 | 默认值 | 必填 |
| :---- | :----: | :----: | :----: |
| Prefix | string | '' | 否 |

##### 返回值

无返回值

##### 实例

```
EC_App.Storage.Keys("substring").then((res) => {
	console.log(res);
}, (err) => {
	console.log(err);
});
```

## 日志说明

日志记录是框架重要的一项功能，我们将日志记录以txt文件的形式存放在APP的Caches目录下，具体目录为```Caches/Logs/```，日志文件以2021-12-31类似这样的日期划分文件。

1. 如果需要在项目中使用日志记录操作，只需要使用对应的log方法就可以，比如：

- ```SLogError```记录日志严重等级由上到下
- ```SLogWarn```记录一些警告日志
- ```SLogInfo```记录一些正常操作日志
- ```SLogNet```记录一些网络报文
- ```SLogDebug```记录调试日志记录
- ```SLogVerbose```记录一些输入日志

2. 日志文件获取方法
    1. 模拟器查看沙盒路径
    2. 真机使用```xcode Windows-Devices/Simulators```获取日志记录
    
3. 崩溃日志记录
    1. delegate文件，didFinishLaunchingWithOptions方法中实现崩溃日志的监听方法
    ```
    SLog.startWatchExecption { exception in
    }
    ```
    2. 当程序异常导致崩溃，会自动向systemError上报异常数据
