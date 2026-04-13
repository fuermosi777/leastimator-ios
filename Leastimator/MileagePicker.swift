//
//  MileagePicker.swift
//  Leastimator
//
//  Created by Hao Liu on 3/18/23.
//

import SwiftUI

struct MileagePicker: View {
  @Binding var value: String
  
  var body: some View {
    HStack(spacing: 0) {
      ForEach(0..<6, id: \.self) { index in
        DigitPicker(index: index, value: $value)
      }
    }
    .padding(.vertical, 8)
  }
}

private struct DigitPicker: View {
  let index: Int
  @Binding var value: String
  
  // Large multiplier to simulate infinite scrolling (e.g., 1000 items)
  @State private var selection: Int = 0
  private let rangeMultiplier = 10
  
  private var currentDigits: [Int] {
    let d = value.digits
    var result = [0, 0, 0, 0, 0, 0]
    for i in 0..<6 {
      let sourceIndex = d.count - 1 - i
      if sourceIndex >= 0 {
        result[5 - i] = d[sourceIndex]
      }
    }
    return result
  }
  
  var body: some View {
    Picker("", selection: $selection) {
      ForEach(0..<(rangeMultiplier * 10), id: \.self) { i in
        Text("\(i % 10)")
          .font(.system(size: 26, weight: .bold, design: .monospaced))
          .tag(i)
      }
    }
    .pickerStyle(.wheel)
    .clipped()
    .onAppear {
      // Initialize to the middle range
      selection = (rangeMultiplier / 2) * 10 + currentDigits[index]
    }
    .onChange(of: selection) { newValue in
      let newDigit = newValue % 10
      var d = currentDigits
      if d[index] != newDigit {
        d[index] = newDigit
        value = "".join(d)
      }
    }
    .onChange(of: value) { newValue in
      // When value changes from outside, sync selection without jumping to the middle
      let newDigit = currentDigits[index]
      if selection % 10 != newDigit {
        // Keep the current "cycle" but update the digit
        selection = (selection / 10) * 10 + newDigit
      }
    }
  }
}
