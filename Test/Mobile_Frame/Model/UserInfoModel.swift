//
//  UserInfoModel.swift
//  MobileFrameExampleApp
//
//  Created by ERIC on 2021/11/16.
//

import Foundation

import SwiftyJSON

internal class UserInfoModel: NSObject, SQLiteProtocol {
    public static var tableName: String {
        return "UserInfoModel"
    }
    
    public var primaryKey: String {
        return "UserID"
    }
    
    public var uniqueKeys: [String]? {
        return ["UserID"]
    }
    
    open var SessionExpireTime: String?
    open var EncompassSessionID: String?
    open var UserID: String?
    open var AuthenticationID: String?
    open var Language: String?
    open var RoleID: String?
    open var UserName: String?
    open var FullName: String?
    open var UserType: String?
    open var Phone: String?
    open var Email: String?
    open var UserAvatarURL: String?
    open var UserAvatarThumbnailURL: String?
    open var Permissions: String?
    open var UploadDatabase: String?
    open var HandheldID: String?
    
    open var IsImpersonateUser: String?
    open var DateFormat: String?
    open var TimeFormat: String?
    open var PhoneFormat: String?
    open var CurrencySymbol: String?
    open var CurrencyDecimals: String?
    open var CurrencyGroupDigits: String?
    open var CurrencyUseParForNeg: String?

    public init(jsonData: JSON) {
        SessionExpireTime       = jsonData["SessionExpireTime"].stringValue
        EncompassSessionID      = jsonData["EncompassSessionID"].stringValue
        UserID                  = jsonData["UserID"].stringValue
        AuthenticationID        = jsonData["AuthenticationID"].stringValue
        Language                = jsonData["Language"].stringValue
        RoleID                  = jsonData["RoleID"].stringValue
        UserName                = jsonData["UserName"].stringValue
        FullName                = jsonData["FullName"].stringValue
        UserType                = jsonData["UserType"].stringValue
        Phone                   = jsonData["Phone"].stringValue
        Email                   = jsonData["Email"].stringValue
        UserAvatarURL           = jsonData["UserAvatarURL"].stringValue
        UserAvatarThumbnailURL  = jsonData["UserAvatarThumbnailURL"].stringValue
        Permissions             = jsonData["Permissions"].stringValue
        UploadDatabase          = jsonData["UploadDatabase"].stringValue
        HandheldID              = jsonData["HandheldID"].stringValue

        IsImpersonateUser       = jsonData["IsImpersonateUser"].stringValue
        DateFormat              = jsonData["DateFormat"].stringValue
        TimeFormat              = jsonData["TimeFormat"].stringValue
        PhoneFormat             = jsonData["PhoneFormat"].stringValue
        CurrencySymbol          = jsonData["CurrencySymbol"].stringValue
        CurrencyDecimals        = jsonData["CurrencyDecimals"].stringValue
        CurrencyGroupDigits     = jsonData["CurrencyGroupDigits"].stringValue
        CurrencyUseParForNeg    = jsonData["CurrencyUseParForNeg"].stringValue
    }
    
    public required init(_ dict: [String : Any]) {
        let jsonData = JSON(dict)
        SessionExpireTime       = jsonData["SessionExpireTime"].stringValue
        EncompassSessionID      = jsonData["EncompassSessionID"].stringValue
        UserID                  = jsonData["UserID"].stringValue
        AuthenticationID        = jsonData["AuthenticationID"].stringValue
        Language                = jsonData["Language"].stringValue
        RoleID                  = jsonData["RoleID"].stringValue
        UserName                = jsonData["UserName"].stringValue
        FullName                = jsonData["FullName"].stringValue
        UserType                = jsonData["UserType"].stringValue
        Phone                   = jsonData["Phone"].stringValue
        Email                   = jsonData["Email"].stringValue
        UserAvatarURL           = jsonData["UserAvatarURL"].stringValue
        UserAvatarThumbnailURL  = jsonData["UserAvatarThumbnailURL"].stringValue
        Permissions             = jsonData["Permissions"].stringValue
        UploadDatabase          = jsonData["UploadDatabase"].stringValue
        HandheldID              = jsonData["HandheldID"].stringValue

        IsImpersonateUser       = jsonData["IsImpersonateUser"].stringValue
        DateFormat              = jsonData["DateFormat"].stringValue
        TimeFormat              = jsonData["TimeFormat"].stringValue
        PhoneFormat             = jsonData["PhoneFormat"].stringValue
        CurrencySymbol          = jsonData["CurrencySymbol"].stringValue
        CurrencyDecimals        = jsonData["CurrencyDecimals"].stringValue
        CurrencyGroupDigits     = jsonData["CurrencyGroupDigits"].stringValue
        CurrencyUseParForNeg    = jsonData["CurrencyUseParForNeg"].stringValue
    }
}
