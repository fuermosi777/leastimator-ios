//
//  appError.swift
//  Leastimator
//
//  Created by Hao Liu on 3/28/21.
//

import Foundation

enum AppError: Error {
  case invalidInput(reason: String)
  case failedContextSave
}

