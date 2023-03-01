//
//  ImageUtil.swift
//  MobileFrame
//
//  Created by Encompass on 2021/12/16.
//

import UIKit

public class ImageUtil: NSObject {
    func imageWithName(name : String) -> UIImage? {
        var image : UIImage?
        let mainBundle = Bundle.init(for: self.classForCoder)
        var resourceBundles : Bundle?
        if let path = mainBundle.path(forResource: "MobileFrame", ofType: "bundle") {
            resourceBundles = Bundle.init(path: path)
        } else {
            resourceBundles = mainBundle
        }
        image = UIImage.init(named: name, in: resourceBundles, compatibleWith: nil)
        return image
    }
}
