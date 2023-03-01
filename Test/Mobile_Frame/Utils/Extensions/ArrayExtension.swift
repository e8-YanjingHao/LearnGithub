//
//  ArrayExtension.swift
//  MobileFrame
//
//  Created by ERIC on 2021/12/15.
//

import Foundation

extension Array {
    func toJsonString() -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: self,
                                                     options: []) else {
            return "[]"
        }
        guard let str = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return str
     }
}
