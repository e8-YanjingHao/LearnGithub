//
//  SwiftLog.swift
//  SwiftLog
//
//  Created by iOS on 2020/4/2.
//  Copyright © 2020 iOS. All rights reserved.
//

import Foundation

private var logFilePath = SLog.getLogFileURL

#if DEBUG
private let shouldLog: Bool = true
#else
private let shouldLog: Bool = false
#endif
 
/// The highest level of log classification ❌
@inlinable public func SLogError(_ message: @autoclosure () -> String,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line) {
    SLog.log(message(), type: .error, file: file, function: function, line: line)
}

/// log level division warning level ⚠️
@inlinable public func SLogWarn(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line) {
    SLog.log(message(), type: .warn, file: file, function: function, line: line)
}

/// log level division information level 🔔
@inlinable public func SLogInfo(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line) {
    SLog.log(message(), type: .info, file: file, function: function, line: line)
}

/// Specially print network logs, which can be turned off separately 🌐
@inlinable public func SLogNet(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line) {
    SLog.log(message(), type: .net, file: file, function: function, line: line)
}

/// The log level is divided into the development level ✅
@inlinable public func SLogDebug(_ message: @autoclosure () -> String,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line) {
    SLog.log(message(), type: .debug, file: file, function: function, line: line)
}
 
/// The lowest level of log level division ⚪ can be ignored
@inlinable public func SLogVerbose(_ message: @autoclosure () -> String,
                         file: StaticString = #file,
                         function: StaticString = #function,
                         line: UInt = #line) {
    SLog.log(message(), type: .verbose, file: file, function: function, line: line)
}

/// log level
public enum LogDegree : Int{
    case verbose = 0
    case debug = 1
    case net = 2
    case info = 3
    case warn = 4
    case error = 5
}

/// log processing
public class SLog {
    
    public static var getLogFileURL: URL {
        
        // Create log file based on date
        let chineseLocaleFormatter = DateFormatter()
        chineseLocaleFormatter.locale = Locale(identifier: "zh_CN")
        chineseLocaleFormatter.dateFormat = "yyyy-MM-dd"
        let date = chineseLocaleFormatter.string(from: Date())
        
        let filePath = (MobileFrameEngine.shared.config.logFilePath as NSString).appendingPathComponent(date + ".txt")
        
        LocalFileManager.createFolder(folderPath: MobileFrameEngine.shared.config.logFilePath)
        LocalFileManager.createFile(filePath: filePath)
                
        return URL(fileURLWithPath: filePath)
    }
    
    /// Log printing level, if it is less than this level, it will be ignored
    public static var defaultLogDegree : LogDegree = .verbose
    
    /// Used to switch network log printing
    public static var showNetLog : Bool = true
    
    ///The cache is kept for the longest time ///If you need to customize the time, it must be before addFileLog
    public static var maxLogAge : TimeInterval? = 60 * 60 * 24 * 7
    
    /// Whether log is written to file
    public static var addFileLog : Bool = MobileFrameEngine.shared.config.addLocalLog {
        didSet{
            if addFileLog {
                deleteOldFiles()
            }
        }
    }
 
    private static func deleteOldFiles() {
        let url = getLogFileURL
        if !FileManager.default.fileExists(atPath: url.path) {
            return
        }
        guard let age : TimeInterval = maxLogAge, age != 0 else {
            return
        }
        let expirationDate = Date(timeIntervalSinceNow: -age)
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .contentModificationDateKey, .totalFileAllocatedSizeKey]
        var resourceValues: URLResourceValues
        
        do {
            resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))
            if let modifucationDate = resourceValues.contentModificationDate {
                if modifucationDate.compare(expirationDate) == .orderedAscending {
                    try? FileManager.default.removeItem(at: url)
                }
            }
        } catch let error {
            debugPrint("SLog error: \(error.localizedDescription)")
        }
        
    }
    
    public static func verbose(_ message: String,
                             file: StaticString = #file,
                             function: StaticString = #function,
                             line: UInt = #line) {
        log(message, type: .verbose, file: file, function: function, line: line)
    }
    
    public static func debug(_ message: String,
                             file: StaticString = #file,
                             function: StaticString = #function,
                             line: UInt = #line) {
        log(message, type: .debug, file: file, function: function, line: line)
    }
    
    public static func net(_ message: String,
                             file: StaticString = #file,
                             function: StaticString = #function,
                             line: UInt = #line) {
        log(message, type: .net, file: file, function: function, line: line)
    }
    
    public static func info(_ message: String,
                             file: StaticString = #file,
                             function: StaticString = #function,
                             line: UInt = #line) {
        log(message, type: .info, file: file, function: function, line: line)
    }
    
    public static func warn(_ message: String,
                             file: StaticString = #file,
                             function: StaticString = #function,
                             line: UInt = #line) {
        log(message, type: .warn, file: file, function: function, line: line)
    }
    
    public static func error(_ message: String,
                             file: StaticString = #file,
                             function: StaticString = #function,
                             line: UInt = #line) {
        log(message, type: .error, file: file, function: function, line: line)
    }
    
    
    /// print log
    /// - Parameters:
    ///   - message: content
    ///   - type: log level
    ///   - file: file
    ///   - function: func
    ///   - line: line
    public static func log(_ message: @autoclosure () -> String,
                           type: LogDegree,
                           file: StaticString,
                           function: StaticString,
                           line: UInt) {
        
        if type.rawValue < defaultLogDegree.rawValue{ return }
        
        if type == .net, !showNetLog{ return }
        
        let fileName = String(describing: file).lastPathComponent
        let formattedMsg = "Class:\(fileName) \n Method:\(String(describing: function)) \n Line:\(line) \n<<<<<<<<<<<<<<<<Message>>>>>>>>>>>>>>>>\n\n \(message()) \n\n<<<<<<<<<<<<<<<<END>>>>>>>>>>>>>>>>\n\n"
        SLogFormatter.log(message: formattedMsg, type: type, addFileLog : addFileLog)
    }
    
    public static var callback: (NSException) -> Void = {_ in }
    
    /**
     signal capture
     */
    static let signalCatch: @convention(c) (Int32) -> Void = { signal in
        
        let stackTrace = Thread.callStackSymbols.joined(separator: "\r\n")
                                
        var userInfo: [AnyHashable: Any] = [:]

        userInfo["UncaughtExceptionHandlerSignalKey"] = signal
        userInfo["UncaughtExceptionHandlerAddressesKey"] = Thread.callStackReturnAddresses
        userInfo["UncaughtExceptionHandlerSymbolsKey"] = Thread.callStackSymbols

        let exception = NSException(name: NSExceptionName(rawValue: "UncaughtExceptionHandlerSignalExceptionName"), reason: "Signal \(signal) was raised.", userInfo: userInfo)

        let semaphore = DispatchSemaphore.init(value: 0)

        NetWorkManager.shared.sendSystemError(title: "UncaughtExceptionHandlerSignalExceptionName", body: stackTrace) { complate in
            semaphore.signal()
        }

        semaphore.wait()

        callback(exception)

        removeSignal()
    }
    
    static let exceptionCatch: @convention(c) (NSException) -> Void = { exception in

        let arr = exception.callStackSymbols
        let reason = exception.reason
        let name = exception.name
        let arrstr = arr.joined(separator: "\n")

        let semaphore = DispatchSemaphore.init(value: 0)

        NetWorkManager.shared.sendSystemError(title: reason ?? "", body: arrstr) { complate in
            semaphore.signal()
        }

        semaphore.wait()
        
        callback(exception)
    }
    
    static func addSignal() {
        signal(SIGINT,  signalCatch);
        signal(SIGSEGV, signalCatch);
        signal(SIGTRAP, signalCatch);
        signal(SIGABRT, signalCatch);
        signal(SIGILL,  signalCatch);
        signal(SIGBUS,  signalCatch);
        signal(SIGFPE,  signalCatch);
        signal(SIGTERM, signalCatch);
        signal(SIGKILL, signalCatch);
        signal(SIGPIPE, signalCatch);
    }
    
    public static func startWatchExecption(call:(@escaping (_ exception: NSException)->())) {
        callback = call
        NSSetUncaughtExceptionHandler(exceptionCatch)
        addSignal()
    }
    
    static func removeSignal() {
        
        NSSetUncaughtExceptionHandler(nil)
        
        signal(SIGINT,  SIG_DFL)
        signal(SIGSEGV, SIG_DFL)
        signal(SIGTRAP, SIG_DFL)
        signal(SIGABRT, SIG_DFL)
        signal(SIGILL,  SIG_DFL)
        signal(SIGBUS,  SIG_DFL)
        signal(SIGFPE,  SIG_DFL)
        signal(SIGTERM, SIG_DFL)
        signal(SIGKILL, SIG_DFL)
        signal(SIGPIPE, SIG_DFL)

        kill(getpid(), SIGKILL)
    }
}

/// log format
class SLogFormatter {

    static var dateFormatter = DateFormatter()

    static func log(message logMessage: String, type: LogDegree, addFileLog : Bool) {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        var logLevelStr: String
        switch type {
        case .error:
            logLevelStr = "❌ Error ❌"
        case .warn:
            logLevelStr = "⚠️ Warning ⚠️"
        case .info:
            logLevelStr = "🔔 Info 🔔"
        case .net:
            logLevelStr = "🌐 Network 🌐"
        case .debug:
            logLevelStr = "✅ Debug ✅"
        case .verbose:
            logLevelStr = "⚪ Verbose ⚪"
        }
        
        let dateStr = dateFormatter.string(from: Date())
        let finalMessage = String(format: "\n%@ | %@ \n %@", logLevelStr, dateStr, logMessage)
        
        
        //Write the content to the file synchronously (under the Caches folder)
        if addFileLog {
            appendText(fileURL: SLog.getLogFileURL, string: "\(finalMessage.replaceUnicode)")
        }
        
        guard shouldLog else { return }
        print(finalMessage.replaceUnicode)
    }
    
    //Append new content to the end of the file
    static func appendText(fileURL: URL, string: String) {
        do {
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            }
             
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            let stringToWrite = "\n" + string
             
            fileHandle.seekToEndOfFile()
            fileHandle.write(stringToWrite.data(using: String.Encoding.utf8)!)
             
        } catch let error as NSError {
            print("failed to append: \(error)")
        }
    }
}

private extension String {

    var fileURL: URL {
        return URL(fileURLWithPath: self)
    }

    var pathExtension: String {
        return fileURL.pathExtension
    }

    var lastPathComponent: String {
        return fileURL.lastPathComponent
    }

    var replaceUnicode: String {
        let tempStr1 = self.replacingOccurrences(of: "\\u", with: "\\U")
        let tempStr2 = tempStr1.replacingOccurrences(of: "\"", with: "\\\"")
        let tempStr3 = "\"".appending(tempStr2).appending("\"")
        guard let tempData = tempStr3.data(using: String.Encoding.utf8) else {
            return "unicode转码失败"
        }
        var returnStr:String = ""
        do {
            returnStr = try PropertyListSerialization.propertyList(from: tempData, options: [.mutableContainers], format: nil) as! String
        } catch {
            return self.replacingOccurrences(of: "\\r\\n", with: "\n")
        }
        return returnStr.replacingOccurrences(of: "\\r\\n", with: "\n")
    }
}

 
