//
//  SQLitePropModel.swift
//
//  Created by ERIC on 2021/11/17.
//

import Foundation

public protocol SQLiteProtocol {
    static var tableName: String { get }
    
    /// primary key field
    var primaryKey: String? { get }
    /// ignored fields, do not save
    var ignoreKeys: [String]? { get }
    /// unique field
    var uniqueKeys: [String]? { get }
    
    init(_ dict: [String: Any])
}

public extension SQLiteProtocol {
    /// primary key field
    var primaryKey: String? { return nil }
    /// ignored fields, do not save
    var ignoreKeys: [String]? { return nil }
    /// unique field
    var uniqueKeys: [String]? { return nil }
}

public struct SQLitePropModel {
    public var key: String
    public var value: Any

    public var primary = false
    
    public init(_ key: String, value: Any, primary: Bool) {
        self.key = key
        self.primary = primary
        
        let mirror = Mirror(reflecting: value)
        self.option = mirror.displayStyle == .optional
        // unwrap optional
        if mirror.displayStyle != .optional {
            self.value = value
        }else if mirror.children.count == 0 { self.value = "" }
        else {
            let (_, some) = mirror.children.first!
            self.value = some
        }
    }
    
    private var option = false
    public var datatype: String {
        let nativeType = type(of: value)
        var datatype = ""
        
        if nativeType is Int.Type || nativeType is Int?.Type {
            datatype = "INTEGER"
        }else if nativeType is Float.Type || nativeType is Double.Type || nativeType is Float?.Type || nativeType is Double?.Type {
            datatype = "REAL"
        }else if nativeType is NSString.Type || nativeType is String.Type || nativeType is Character.Type || nativeType is NSString?.Type || nativeType is String?.Type || nativeType is Character?.Type {
            datatype = "TEXT"
        }else if nativeType is Bool.Type || nativeType is Bool?.Type {
            datatype = "REAL"
        }else{
            assert(true, "sqlType:not support type")
        }
        return datatype
    }
    public var column: String {
        let arr: [String?] = [key, datatype, !primary ? nil : "PRIMARY KEY", option ? nil : "NOT NULL"]
        return arr.compactMap({ $0 }).joined(separator: " ")
    }
}
