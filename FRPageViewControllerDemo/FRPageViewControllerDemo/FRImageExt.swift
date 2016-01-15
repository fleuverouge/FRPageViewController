//
//  FRImageExt.swift
//  FRPageViewControllerDemo
//
//  Created by Do Thi Hong Ha on 1/14/16.
//  Copyright © 2016 Yotel. All rights reserved.
//

import ImageIO
import UIKit

extension UIImage {
    func imageByResizeToSize(newSize: CGSize) -> UIImage? {
        if let data = UIImagePNGRepresentation(self),
            let dataPtr = CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(data.bytes), data.length),
            let imageSource = CGImageSourceCreateWithData(dataPtr, nil) {
                let options: [NSString: NSObject] = [
                    kCGImageSourceThumbnailMaxPixelSize: max(newSize.width, newSize.height),
                    kCGImageSourceCreateThumbnailFromImageAlways: true
                ]
                let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options).flatMap { UIImage(CGImage: $0) }
                return scaledImage
        }

        return nil
    }
    
    func imageByResizeToHeight(height: CGFloat) -> UIImage? {
        let ratio = size.width / size.height
        return imageByResizeToSize(CGSize(width: height * ratio, height: height))
    }
    
    func imageByResizeToWidth(width: CGFloat) -> UIImage? {
        let ratio = size.width / size.height
        return imageByResizeToSize(CGSize(width: width, height: width / ratio))
    }
}
