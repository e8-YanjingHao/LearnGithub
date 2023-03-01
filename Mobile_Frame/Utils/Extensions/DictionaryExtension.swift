//
//  DictionaryExtension.swift
//  MobileFrame
//
//  Created by ERIC on 2021/12/15.
//

import Foundation

extension Dictionary {
    
    func toJsonString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self,
                                                     options: []) else {
            return nil
        }
        guard let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
     }
    
}
