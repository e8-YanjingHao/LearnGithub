//
//  StringExtension.swift
//  MobileFrame
//
//  Created by ERIC on 2021/11/16.
//

import Foundation

import CommonCrypto

public extension String {
    
    var md5: String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)

        let hash = NSMutableString()

        for i in 0..<digestLen {
            hash.appendFormat("%02x", result[i])
        }

        result.deallocate()
        return hash as String
    }
    
    var isEmail: Bool {
        let predicateStr = "^[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?\\.)+(?:[A-Za-z]*$)\\b"
        let predicate =  NSPredicate(format: "SELF MATCHES %@" ,predicateStr)
        return predicate.evaluate(with: self)
    }
    
    var isURL: Bool {
        let predicateStr = "(https?|http?)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]"
        let predicate = NSPredicate(format: "SELF MATCHES %@", predicateStr)
        return predicate.evaluate(with: self)
    }
    
    var isBlank: Bool {
        let trimmedStr = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedStr.isEmpty
    }
    
    func toDictionary() -> [String : Any] {
            
        var result = [String : Any]()
        guard !self.isEmpty else { return result }
        
        guard let dataSelf = self.data(using: .utf8) else {
            return result
        }
        
        if let dic = try? JSONSerialization.jsonObject(with: dataSelf,
                           options: .mutableContainers) as? [String : Any] {
            result = dic
        }
        return result
    
    }
    
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)
        return encodeUrlString ?? ""
    }
    
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
    
    func sqlSafe() -> String {
        var keyWord = self.replacingOccurrences(of: "/", with: "//")
        keyWord = keyWord.replacingOccurrences(of: "'", with: "''")
        keyWord = keyWord.replacingOccurrences(of: "[", with: "/[")
        keyWord = keyWord.replacingOccurrences(of: "]", with: "/]")
        keyWord = keyWord.replacingOccurrences(of: "%", with: "/%")
        keyWord = keyWord.replacingOccurrences(of: "&", with: "/&")
        keyWord = keyWord.replacingOccurrences(of: "_", with: "/_")
        keyWord = keyWord.replacingOccurrences(of: "(", with: "/(")
        keyWord = keyWord.replacingOccurrences(of: ")", with: "/)")
        return keyWord
    }
    
    func sqlToN() -> String {
        var keyWord = self.replacingOccurrences(of: "//", with: "/")
        keyWord = keyWord.replacingOccurrences(of: "''", with: "'")
        keyWord = keyWord.replacingOccurrences(of: "/[", with: "[")
        keyWord = keyWord.replacingOccurrences(of: "/]", with: "]")
        keyWord = keyWord.replacingOccurrences(of: "/%", with: "%")
        keyWord = keyWord.replacingOccurrences(of: "/&", with: "&")
        keyWord = keyWord.replacingOccurrences(of: "/_", with: "_")
        keyWord = keyWord.replacingOccurrences(of: "/(", with: "(")
        keyWord = keyWord.replacingOccurrences(of: "/)", with: ")")
        return keyWord
    }
    
    func jsSafe() -> String {
        return self.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "`", with: "\\`")
    }
}
