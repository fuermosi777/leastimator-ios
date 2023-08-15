//
//  UIImage+Extensions.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import SwiftUI

extension UIImage {
  func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
    var width: CGFloat
    var height: CGFloat
    var newImage: UIImage
    
    let size = self.size
    let aspectRatio =  size.width/size.height
    
    switch contentMode {
      case .scaleAspectFit:
        if aspectRatio > 1 {                            // Landscape image
          width = dimension
          height = dimension / aspectRatio
        } else {                                        // Portrait image
          height = dimension
          width = dimension * aspectRatio
        }
        
      default:
        fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
    }
    
    if #available(iOS 10.0, *) {
      let renderFormat = UIGraphicsImageRendererFormat.default()
      renderFormat.opaque = opaque
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
      newImage = renderer.image {
        (context) in
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
      }
    } else {
      UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
      self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
      newImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
    }
    
    return newImage
  }
  
  func imageByMakingWhiteBackgroundTransparent() -> UIImage? {
    
    let image = UIImage(data: self.jpegData(compressionQuality: 1.0)!)!
    let rawImageRef: CGImage = image.cgImage!
    
    let colorMasking: [CGFloat] = [255, 255, 255, 255, 255, 255]
    UIGraphicsBeginImageContext(image.size);
    
    let maskedImageRef = rawImageRef.copy(maskingColorComponents: colorMasking)
    UIGraphicsGetCurrentContext()?.translateBy(x: 0.0,y: image.size.height)
    UIGraphicsGetCurrentContext()?.scaleBy(x: 1.0, y: -1.0)
    UIGraphicsGetCurrentContext()?.draw(maskedImageRef!, in: CGRect.init(x: 0, y: 0, width: image.size.width, height: image.size.height))
    let result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result
    
  }
}
