//
//  SQLiteManager.swift
//
//  Created by ERIC on 2021/11/17.
//

import SQLite

internal class SQLiteManager {
    public lazy var databasePath: String = {
        return MobileFrameEngine.shared.config.globalStaticDatabase
    }()
    public private(set) var db: Connection!
    public var enableLog = true
    
    public static let `default` = SQLiteManager()
    
    private init() {
        db = try! Connection(databasePath)
        printLog(databasePath)
    }
    
    public func userDB() -> SQLiteManager {
        var database = ""
        if let authId = UserDefaults.standard.string(forKey: LoginManager.LoginAuthID_Key) {
            database = "\(MobileFrameEngine.shared.config.globalStaticDatabasePath)/\(authId)_db.sqlite3"
        }
        else {
            database = databasePath
        }
        let (isSuccess, _) = LocalFileManager.createFile(filePath: database)
        if isSuccess == true {
            db = try! Connection(database)
        }
        return self
    }
    
    public func resourceDB() -> SQLiteManager {
        db = try! Connection(MobileFrameEngine.shared.config.globalStaticDatabase)
        return self
    }
    
    public func exists(tableName : String) -> Bool {
        return exists(tableName)
    }
    
    public func create<E>(_ model: E) throws where E : SQLiteProtocol {
        let mirrorModel = SQLMirrorModel.operateByMirror(object: model)
        create(mirrorModel)
    }
    
    /// insert row
    /// - Parameter model: row model
    public func insert<E>(_ model: E) throws where E : SQLiteProtocol {
        let mirrorModel = SQLMirrorModel.operateByMirror(object: model)
        create(mirrorModel)
        
        let (isExists, filter) = exists(model)
        let tableName = E.tableName
        
        var updates = [String]()
        var inserts = [String: String]()
        for prop in mirrorModel.props {
            if isExists {
                addColumn(tableName, prop: prop)
                updates.append("\(prop.key) = '\(String(describing: prop.value).sqlSafe())'")
            }else {
                addColumn(tableName, prop: prop)
                inserts[prop.key] = "'\(String(describing: prop.value).sqlSafe())'"
            }
        }
        var sql: String
        if isExists {
            sql = "UPDATE \(tableName) SET \(updates.joined(separator: ", "))\(filter)"
        }else {
            sql = "INSERT INTO \(tableName) (\(inserts.keys.joined(separator: ", "))) VALUES (\(inserts.values.joined(separator: ", ")))"
        }
        
        printLog(sql)
        do {
            let _ = try self.prepare(sql)
        }
        catch {
            throw error
        }
    }
    
    /// update row
    /// - Parameter model: model data
    public func update<E>(_ model: E) where E : SQLiteProtocol {
        try? insert(model)
    }
    
    /// select row
    /// - Parameter filter: params
    /// - Returns: select result
    public func select<E>(_ filter: [String: Any] = [:]) throws -> [E] where E : SQLiteProtocol {
        do {
            let rows = try select(E.tableName, filter: filter)
            return rows.map({ E($0) })
        }
        catch {
            throw error
        }
    }
    
    /// select row, return directly
    /// - Parameters:
    ///   - tableName: tablename
    ///   - filter: parmas
    /// - Returns: select result
    public func select(_ tableName: String, filter: [String: Any] = [:]) throws -> [[String: Any]] {
        if !exists(tableName) {
            return []
        }
        var wheres = [String]()
        for (key, value) in filter {
            wheres.append("\(key) = '\(value)'")
        }
        let str = wheres.joined(separator: " AND ")
        let filter = str.count > 0 ? " WHERE \(str)" : str
        let sql = "SELECT * FROM \(tableName)\(filter)"
        
        printLog(sql)
        do {
            let rows = try self.prepare(sql)
            return rows
        }
        catch {
            throw error
        }
    }
    
    /// Delete row data in a model way
    /// - Parameter model: model to delete
    public func delete<E>(_ model: E) where E : SQLiteProtocol {
        let sql = "DELETE FROM \(E.tableName)\(exists(model))"
        let _ = try? prepare(sql)
    }
    
    /// Delete row data directly
    /// - Parameters:
    ///   - tableName: tablename
    ///   - filter: params
    public func delete(_ tableName: String, filter: [String: Any]) throws {
        if !exists(tableName) {
            return
        }
        var wheres = [String]()
        for (key, value) in filter {
            wheres.append("\(key) = '\(value)'")
        }
        let str = wheres.joined(separator: " AND ")
        let filter = str.count > 0 ? " WHERE \(str)" : str
        let sql = "DELETE FROM \(tableName)\(filter)"
        
        printLog(sql)
        do {
            let _ = try prepare(sql)
        }
        catch {
            throw error
        }
    }
    
    /// delete data table
    /// - Parameter tableName: tablename
    public func drop(_ tableName: String) {
        let sql = "DROP TABLE \(tableName)"
        printLog(sql)
        let _ = try? prepare(sql)
    }
    
//    /// 执行数据库语句
//    @discardableResult
//    public func prepare(_ sql: String) -> (Bool, [[String: Any]]) {
//        var elements: [[String: Any]] = []
//        do {
//            let result = try db.prepare(sql)
//            for row in result {
//                var record: [String: Any] = [:]
//                for (idx, column) in result.columnNames.enumerated() {
//                    record[column] = row[idx]
//                }
//                elements.append(record)
//            }
//            return (true, elements)
//        } catch {
//            printLog(error)
//            return (false, [])
//        }
//    }
    
    public func prepare(_ sql: String) throws -> [[String: Any]] {
        var elements: [[String: Any]] = []
        do {
            let result = try db.prepare(sql)
            for row in result {
                var record: [String: Any] = [:]
                for (idx, column) in result.columnNames.enumerated() {
                    record[column] = row[idx]
                }
                elements.append(record)
            }
            return elements
        } catch {
            printLog(error)
            throw error
        }
    }
}

private extension SQLiteManager {
    func printLog(_ items: Any..., file: String = #file, method: String = #function, line: Int = #line) {
        
        if enableLog {
            print("\((file as NSString).lastPathComponent)[\(line)], \(method): \(items)")
        }
    }
    /// create data table
    /// - Parameter model: reflection model
    @discardableResult
    private func create(_ model: SQLMirrorModel) -> Bool {
        if exists(model.tableName) {
            return true
        }
        
        var sql = "CREATE TABLE IF NOT EXISTS \(model.tableName) "
        let columns = model.props.map({ $0.column }).joined(separator: ", ")
        sql += "(\(columns))"
        
        do {
            try db.run(sql)
        } catch {
            printLog(error)
            return false
        }
        return true
    }
    
    /// Is there a datasheet
    /// - Parameter tableName: params
    /// - Returns: true or false
    private func exists(_ tableName: String) -> Bool {
        let exists = try? db.scalar(Table(tableName).exists)
        let isExist = exists != nil
        printLog("数据库表: \(isExist ? "存在" : "不存在")")
        return isExist
    }
    
    /// Whether the row of data exists
    /// - Parameter object: model row
    /// - Returns: true or false
    private func exists<E: SQLiteProtocol>(_ object: E) -> (exists: Bool, filter: String) {
        let mirrorModel = SQLMirrorModel.operateByMirror(object: object)
        var wheres = [String]()
        if let prop = mirrorModel.props.filter({ $0.primary }).first {
            wheres.append("\(prop.key) = '\(prop.value)'")
        }else if let keys = object.uniqueKeys, keys.count > 0 {
            for key in keys {
                for prop in mirrorModel.props {
                    if prop.key != key {
                        continue
                    }
                    wheres.append("\(prop.key) = '\(prop.value)'")
                }
            }
        }else {
            for prop in mirrorModel.props {
                wheres.append("\(prop.key) = '\(prop.value)'")
            }
        }
        let str = wheres.joined(separator: " AND ")
        let filter = str.count > 0 ? " WHERE \(str)" : str
        let sql = "SELECT * FROM \(E.tableName)\(filter)"
        if let rows = try? prepare(sql) {
            return (rows.count == 1, filter)
        }
        else {
            return (false, filter)
        }
    }
    
    /// If the field does not exist, create
    /// - Parameters:
    ///   - tableName: field name
    ///   - prop: field property
    private func addColumn(_ tableName: String, prop: SQLitePropModel) {
        if let result = try? prepare("PRAGMA table_info(\(tableName))") {
            let columns = result.map({ $0["name"] as! String })
            let exist = columns.contains(prop.key)
            if !exist {
                let _ = try? prepare("ALTER TABLE \(tableName) ADD \(prop.column)")
            }
        }
        
    }
}
