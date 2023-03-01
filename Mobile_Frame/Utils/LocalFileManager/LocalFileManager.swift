//
//  LocalFileManager.swift
//  MobileFrame
//
//  Created by ERIC on 2021/11/15.
//

import Foundation
import UIKit
import SwiftyJSON

public class LocalFileManager: FileManager {
    
}


public extension LocalFileManager {
    // MARK: type of file written
    enum FileWriteType {
        case TextType
        case ImageType
        case ArrayType
        case DictionaryType
        case BinaryType
    }
    // MARK: Type of move or copy
    enum MoveOrCopyType {
        case file
        case directory
    }

    static var fileManager: FileManager {
        return FileManager.default
    }

    // MARK: Create folder (blue, folder and file are not the same)
    /// - Parameter folderName: folder name
    /// - Returns: Returns the created create folder path
    @discardableResult
    static func createFolder(folderPath: String) -> (isSuccess: Bool, error: String) {
        if judgeFileOrFolderExists(filePath: folderPath) {
            return (true, "")
        }
        // Paths that do not exist will be created
        do {
            try fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true, attributes: nil)
            return (true, "")
        } catch {
            return (false, "Faild to create: \(error)")
        }
    }

    // MARK: 2.2、delete folder
    /// - Parameter folderPath: folder path
    @discardableResult
    static func removefolder(folderPath: String) -> (isSuccess: Bool, error: String) {
        let filePath = "\(folderPath)"
        guard judgeFileOrFolderExists(filePath: filePath) else {
            // nothing to do
            return (true, "")
       }
        do {
            try fileManager.removeItem(atPath: filePath)
            return (true, "")
        } catch {
            return (false, "Faild to delete: \(error)")
        }
    }

    // MARK: 2.3、create file
    /// 创建文件
    /// - Parameter filePath: file path
    /// - Returns: Returns the created result and path
    @discardableResult
    static func createFile(filePath: String) -> (isSuccess: Bool, error: String) {
        guard judgeFileOrFolderExists(filePath: filePath) else {
            // A file path that does not exist will be created
            // withIntermediateDirectories is ture Indicates that if there is a folder in the middle of the path that does not exist, it will be created
            let createSuccess = fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
            return (createSuccess, "")
        }
        return (true, "")
    }

    // MARK: 2.4、delete file
    /// - Parameter filePath: file path
    @discardableResult
    static func removefile(filePath: String) -> (isSuccess: Bool, error: String) {
        guard judgeFileOrFolderExists(filePath: filePath) else {
            return (true, "")
        }
        do {
            try fileManager.removeItem(atPath: filePath)
            return (true, "")
        } catch {
            return (false, "Faild to move: \(error)")
        }
    }

    // MARK: 2.5、read file content
    /// - Parameter filePath: file path
    /// - Returns: content
    @discardableResult
    static func readfile(filePath: String) -> String? {
        guard judgeFileOrFolderExists(filePath: filePath) else {
            return nil
        }
        let data = fileManager.contents(atPath: filePath)
        return String(data: data!, encoding: String.Encoding.utf8)
    }

    // MARK: 2.6、Write text, images, arrays, and dictionaries to files
    /// - Parameters:
    ///   - writeType: write type
    ///   - content: write content
    ///   - writePath: write path
    /// - Returns: write result
    @discardableResult
    static func writeToFile(writeType: FileWriteType, content: Any, writePath: String) -> (isSuccess: Bool, error: String) {
        guard judgeFileOrFolderExists(filePath: writePath) else {
            return (false, "file path that does not exist")
        }
        switch writeType {
        case .TextType:
            let info = "\(content)"
            do {
                try info.write(toFile: writePath, atomically: true, encoding: String.Encoding.utf8)
                return (true, "")
            } catch {
                return (false, "Failed to write: \(error)")
            }
        case .ImageType, .BinaryType:
            let data = content as! Data
            do {
                try data.write(to: URL(fileURLWithPath: writePath))
                return (true, "")
            } catch {
                return (false, "Failed to write: \(error)")
            }
        case .ArrayType:
            let array = content as! NSArray
            let result = array.write(toFile: writePath, atomically: true)
            if result {
                return (true, "")
            } else {
                return (false, "Failed to write")
            }
        case .DictionaryType:
            let result = (content as! NSDictionary).write(toFile: writePath, atomically: true)
            if result {
                return (true, "")
            } else {
                return (false, "Failed to write")
            }
        }
    }

    // MARK: 2.7、Read text, image, array, dictionary read from file
    /// - Parameters:
    ///   - readType: read type
    ///   - readPath: read path
    /// - Returns: read result
    @discardableResult
    static func readFromFile(readType: FileWriteType, readPath: String) -> (isSuccess: Bool, content: Any?, error: String) {
        guard judgeFileOrFolderExists(filePath: readPath),  let readHandler =  FileHandle(forReadingAtPath: readPath) else {
            return (false, nil, "file path that does not exist")
        }
        let data = readHandler.readDataToEndOfFile()
        switch readType {
        case .TextType:
            let readString = String(data: data, encoding: String.Encoding.utf8)
            return (true, readString, "")
        case .ImageType:
            let image = UIImage(data: data)
            return (true, image, "")
        case .ArrayType:
            guard let readString = String(data: data, encoding: String.Encoding.utf8) else {
                return (false, nil, "Failed to read content")
            }
            return (true, JSON(readString).arrayValue, "")
        case .DictionaryType:
            guard let readString = String(data: data, encoding: String.Encoding.utf8) else {
                return (false, nil, "Failed to read content")
            }
            return (true, JSON(readString).dictionaryValue, "")
        case .BinaryType:
            return (true, data, "")
        }
    }

    // MARK: 2.8、Copy the content of (folder/file) to another (folder/file), if the new (folder/file) exists, delete it first and then copy it
    /**
     A few small notes:
       1. The target path, you must bring the folder name, not just the parent path
       2. If it is an overwrite copy, it means that the target path already exists in this folder, we must delete it first, otherwise it will prompt make directory error (of course, it is best to do a fault-tolerant process here, such as transferring to another path before copying, if it fails, then Take back)
     */
    /// - Parameters:
    ///   - fromeFile: copied (folder/file) path
    ///   - toFile: The copied (folder/file) path
    ///   - isOverwrite: When the path to be copied (folder/file) exists, the copy will fail, and whether to overwrite it is passed in here.
    /// - Returns: result
    @discardableResult
    static func copyFile(type: MoveOrCopyType, fromeFilePath: String, toFilePath: String, isOverwrite: Bool = true) -> (isSuccess: Bool, error: String) {
        // 1. First determine whether the copied path exists
        guard judgeFileOrFolderExists(filePath: fromeFilePath) else {
            return (false, "The copied (folder/file) path does not exist")
        }
        // 2. Check folder exists
        let toFileFolderPath = directoryAtPath(path: toFilePath)
        if !judgeFileOrFolderExists(filePath: toFileFolderPath), type == .file ? !createFile(filePath: toFilePath).isSuccess : !createFolder(folderPath: toFileFolderPath).isSuccess {
            return (false, "The folder before the path does not exist after copying")
        }
        // 3. Delete files
        if isOverwrite, judgeFileOrFolderExists(filePath: toFilePath) {
            do {
                try fileManager.removeItem(atPath: toFilePath)
            } catch {
                return (false, "Failed to copy: \(error)")
            }
        }
        // 4. Copy
        do {
            try fileManager.copyItem(atPath: fromeFilePath, toPath: toFilePath)
        } catch {
            return (false, "Failed to copy: \(error)")
        }
        return (true, "success")
    }

    // MARK: 2.9、Move the content of (folder/file) to another (folder/file), if the new (folder/file) exists, delete it first and then move it
    /// - Parameters:
    ///   - fromeFile:
    ///   - toFile:
    @discardableResult
    static func moveFile(type: MoveOrCopyType, fromeFilePath: String, toFilePath: String, isOverwrite: Bool = true) -> (isSuccess: Bool, error: String) {
        guard judgeFileOrFolderExists(filePath: fromeFilePath) else {
            return (false, "The moved (folder/file) path does not exist")
        }
        let toFileFolderPath = directoryAtPath(path: toFilePath)
        if !judgeFileOrFolderExists(filePath: toFileFolderPath), type == .file ? !createFile(filePath: toFilePath).isSuccess : !createFolder(folderPath: toFileFolderPath).isSuccess {
            return (false, "The folder before the path does not exist after the move")
        }
        if isOverwrite, judgeFileOrFolderExists(filePath: toFilePath) {
            do {
                try fileManager.removeItem(atPath: toFilePath)
            } catch _ {
                return (false, "Failed to move")
            }
        }
        do {
            try fileManager.moveItem(atPath: fromeFilePath, toPath: toFilePath)
        } catch _ {
            return (false, "Failed to move")
        }
        return (true, "success")
    }

    // MARK: 2.10、Determine if (folder/file) exists
    static func judgeFileOrFolderExists(filePath: String) -> Bool {
        let exist = fileManager.fileExists(atPath: filePath)
        guard exist else {
            return false
        }
        return true
    }

    // MARK: 2.11、get the previous path of (folder/file)
    /// - Parameter path: (folder/file) path
    /// - Returns: (folder/file) previous path
    static func directoryAtPath(path: String) -> String {
        return (path as NSString).deletingLastPathComponent
    }

    // MARK: 2.12、Check if a directory is readable
    static func judegeIsReadableFile(path: String) -> Bool {
        return fileManager.isReadableFile(atPath: path)
    }

    // MARK: 2.13、Check if a directory is writable
    static func judegeIsWritableFile(path: String) -> Bool {
        return fileManager.isReadableFile(atPath: path)
    }

    // MARK: 2.14、Get file extension type based on file path
    /// - Parameter path:
    /// - Returns:
    static func fileSuffixAtPath(path: String) -> String {
        return (path as NSString).pathExtension
    }

    // MARK: 2.15、Get the file name based on the file path, whether a suffix is required
    /// - Parameters:
    ///   - path: file path
    ///   - suffix: Whether a suffix is required, the default is required
    /// - Returns: file name
    static func fileName(path: String, suffix: Bool = true) -> String {
        let fileName = (path as NSString).lastPathComponent
        guard suffix else {
            return (fileName as NSString).deletingPathExtension
        }
        return fileName
    }

    // MARK: 2.16、Perform a shallow search on the specified path, and return a list of files, subdirectories, and symbolic links under the specified directory path (seeking only one level)
    /// - Parameter folderPath:
    /// - Returns: List of files, subdirectories, and symbolic links in the specified directory path
    static func shallowSearchAllFiles(folderPath: String) -> Array<String>? {
        do {
            let contentsOfDirectoryArray = try fileManager.contentsOfDirectory(atPath: folderPath)
            return contentsOfDirectoryArray
        } catch _ {
            return nil
        }
    }

    // MARK: 2.17、In-depth traversal, it will recursively traverse subfolders (including symbolic links, so use enumeratorAtPath if performance is required)
    static func getAllFileNames(folderPath: String) -> Array<String>? {
        if (judgeFileOrFolderExists(filePath: folderPath)) {
            guard let subPaths = fileManager.subpaths(atPath: folderPath) else {
                return nil
            }
            return subPaths
        } else {
            return nil
        }
    }

    // MARK: 2.18、Deep traversal, will recursively traverse subfolders (but not recursive symlinks)
    static func deepSearchAllFiles(folderPath: String) -> Array<Any>? {
        if (judgeFileOrFolderExists(filePath: folderPath)) {
            guard let contentsOfPathArray = fileManager.enumerator(atPath: folderPath) else {
                return nil
            }
            return contentsOfPathArray.allObjects
        }else{
            return nil
        }
    }

    // MARK: 2.19、Calculate the size of a single (folder/file) in bytes (without conversion)
    /// - Parameter filePath:
    /// - Returns: The size of a single file or folder
    static func fileOrDirectorySingleSize(filePath: String) -> UInt64 {
        guard judgeFileOrFolderExists(filePath: filePath) else {
            return 0
        }
        do {
            let fileAttributes = try fileManager.attributesOfItem(atPath: filePath)
            guard let fileSizeValue = fileAttributes[FileAttributeKey.size] as? UInt64 else {
                return 0
            }
            return fileSizeValue
        } catch {
            return 0
        }
    }

    //MARK: 2.20、Calculate (folder/file) size (converted)
    /// - Parameter path:
    /// - Returns: (folder/file) size
    static func fileOrDirectorySize(path: String) -> String {
        if path.count == 0, !fileManager.fileExists(atPath: path) {
            return "0MB"
        }
        var fileSize: UInt64 = 0
        do {
            let files = try fileManager.contentsOfDirectory(atPath: path)
            for file in files {
                let path = path + "/\(file)"
                fileSize = fileSize + fileOrDirectorySingleSize(filePath: path)
            }
        } catch {
            fileSize = fileSize + fileOrDirectorySingleSize(filePath: path)
        }
        // converted size ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        return covertUInt64ToString(with: fileSize)
    }

    // MARK: 2.21、Get (folder/file) property collection
    /// - Parameter path:
    /// - Returns:
    @discardableResult
    static func fileAttributes(path: String) -> ([FileAttributeKey : Any]?) {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            return attributes
        } catch _ {
            return nil
        }
        /*
        public static let type:
        public static let size:
        public static let modificationDate:
        public static let referenceCount:
        public static let deviceIdentifier:
        public static let ownerAccountName:
        public static let groupOwnerAccountName:
        public static let posixPermissions:
        public static let systemNumber:
        public static let systemFileNumber:
        public static let extensionHidden:
        public static let hfsCreatorCode:
        public static let hfsTypeCode:
        public static let immutable:
        public static let appendOnly:
        public static let creationDate:
        public static let ownerAccountID:
        public static let groupOwnerAccountID:
        public static let busy:
        @available(iOS 4.0, *)
        public static let protectionKey:
        public static let systemSize:
        public static let systemFreeSize:
        public static let systemNodes:
        public static let systemFreeNodes:
        */
    }
}

// MARK:- fileprivate
extension FileManager {

    // MARK: Calculate file size: UInt64 -> String
    /// UInt64 -> String
    /// - Parameter size: size
    /// - Returns: 
    fileprivate static func covertUInt64ToString(with size: UInt64) -> String {
        var convertedValue: Double = Double(size)
        var multiplyFactor = 0
        let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
        while convertedValue > 1024 {
            convertedValue /= 1024
            multiplyFactor += 1
        }
        return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
    }
}

/*
public extension LocalFileManager {
    static func image(name: String) -> UIImage? {
        let image = UIImage(named: name, in: Bundle.sm_frameworkBundle(), compatibleWith: nil)
        return image
    }
}

extension Bundle {
    static func sm_frameworkBundle() -> Bundle {

        let candidates = [
            Bundle.main.resourceURL,
            Bundle(for: LocalFileManager.self).resourceURL,
            Bundle.main.bundleURL,
        ]

        let bundleNames = [
            "MobileFrame",
        ]

        for bundleName in bundleNames {
            for candidate in candidates {
                let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
                if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                    return bundle
                }
            }
        }

        return Bundle(for: LocalFileManager.self)
    }
}
 */

