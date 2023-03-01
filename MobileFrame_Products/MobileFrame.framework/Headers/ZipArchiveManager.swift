//
//  ZipArchiveManager.swift
//  DSDLinkAppFramework
//
//  Created by ERIC on 2021/11/11.
//

import Foundation
import SSZipArchive

public class ZipArchiveManager {
    
    public static let share = ZipArchiveManager()
    
    public func unzip(filePath: String, unzipPath: String) -> Bool {
        
        return SSZipArchive.unzipFile(atPath: filePath, toDestination: unzipPath)
    }
    
    public func zip(filePath: String, zipPath: [String]) -> Bool {
        
        return SSZipArchive.createZipFile(atPath: filePath, withFilesAtPaths: zipPath)
    }
    
}
