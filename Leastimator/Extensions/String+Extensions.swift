//
//  String+Extensions.swift
//  Leastimator
//
//  Created by Hao Liu on 3/19/23.
//

import SwiftUI

extension StringProtocol  {
  var digits: [Int] { compactMap(\.wholeNumberValue) }
}

extension String {
  func join(_ array:[Int]) -> String {
    var str:String = ""
    for (index, item) in array.enumerated() {
      str += "\(item)"
      if index < array.count-1 {
        str += self
      }
    }
    return str
  }
}

extension LocalizedStringKey {
  public func toString() -> String {
    //use reflection
    let mirror = Mirror(reflecting: self)
    
    //try to find 'key' attribute value
    let attributeLabelAndValue = mirror.children.first { (arg0) -> Bool in
      let (label, _) = arg0
      if(label == "key"){
        return true;
      }
      return false;
    }
    
    if(attributeLabelAndValue != nil) {
      //ask for localization of found key via NSLocalizedString
      return String.localizedStringWithFormat(NSLocalizedString(attributeLabelAndValue!.value as! String, comment: ""));
    }
    else {
      return "Swift LocalizedStringKey signature must have changed. @see Apple documentation."
    }
  }
}
