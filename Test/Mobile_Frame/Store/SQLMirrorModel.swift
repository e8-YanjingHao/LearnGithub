//
//  SQLMirrorModel.swift
//  
//  Created by ERIC on 2021/11/17.
//

import Foundation

public struct SQLMirrorModel {
    public var tableName: String
    public var props: [SQLitePropModel] = []
    public var primaryKey: String?
    
    public init(_ tableName: String, props: [SQLitePropModel], primaryKey: String?) {
        var name = tableName.trimmingCharacters(in: .whitespacesAndNewlines)
        name = name.replacingOccurrences(of: " ", with: "")
        let pred = NSPredicate(format: "SELF MATCHES %@", "^[a-zA-Z_\\x7f-\\xff][a-zA-Z0-9_\\x7f-\\xff]*$")
        if !pred.evaluate(with: name) {
            assert(true, "Table name verification failed")
        }
        
        self.tableName = tableName
        self.props = props
        self.primaryKey = primaryKey
    }
    
    public static func operateByMirror(object: SQLiteProtocol) -> SQLMirrorModel {
        let mirror = Mirror(reflecting: object)
        var props = [SQLitePropModel]()
        for case let (key?, value) in mirror.children {
            let model = SQLitePropModel(key, value: value, primary: object.primaryKey == key)
            if object.ignoreKeys?.contains(key) == true {
                continue
            }
            props.append(model)
        }
        
        if mirror.displayStyle != .class || mirror.displayStyle != .struct {
            assert(true, "operateByMirror:Not support type")
        }
        return SQLMirrorModel(type(of: object).tableName, props: props, primaryKey: object.primaryKey)
    }
}
