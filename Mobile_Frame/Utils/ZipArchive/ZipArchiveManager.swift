//
//  ZipArchiveManager.swift
//
//  Created by ERIC on 2021/11/11.
//

import Foundation
import SSZipArchive

internal class ZipArchiveManager {
    
    public static let share = ZipArchiveManager()
    
    public func unzip(filePath: String, unzipPath: String) -> Bool {
        
        return SSZipArchive.unzipFile(atPath: filePath, toDestination: unzipPath, overwrite: true, password: nil, progressHandler: nil, completionHandler: nil)
    }
    
    public func zip(filePath: String, zipPath: String) -> Bool {
        
        return SSZipArchive.createZipFile(atPath: filePath, withContentsOfDirectory: zipPath)
    }
    
}
