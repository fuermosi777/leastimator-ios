//
//  MileagePicker.swift
//  Leastimator
//
//  Created by Hao Liu on 3/18/23.
//

import SwiftUI

struct MileagePicker: View {
  @Binding var value: String;
  
  private var digitsForSet: [Int] = [0, 0, 0, 0, 0, 0]
  
  init(value: Binding<String>) {
    _value = value
    
    // Add extra 0s to the begin of the digits so that the total count is 6.
    let valueLength = self.value.digits.count
    for (index, d) in self.value.digits.enumerated() {
      digitsForSet[index + 6 - valueLength] = d
    }
  }
  
  var body: some View {
    let digit: Binding<Int> = Binding(
      get: {
        guard self.value.count - 1 >= 0 else {
          return 0
        }
        return self.value.digits[self.value.count - 1]
      },
      set: { d in
        var digits = self.digitsForSet
        digits[5] = d
        self.value = "".join(digits)
      }
    )
    let ten: Binding<Int> = Binding(
      get: {
        guard self.value.count - 2 >= 0 else {
          return 0
        }
        return self.value.digits[self.value.count - 2]
      },
      set: { d in
        var digits = self.digitsForSet
        digits[4] = d
        self.value = "".join(digits)
      }
    )
    let hundred: Binding<Int> = Binding(
      get: {
        guard self.value.count - 3 >= 0 else {
          return 0
        }
        return self.value.digits[self.value.count - 3]
      },
      set: { d in
        var digits = self.digitsForSet
        digits[3] = d
        self.value = "".join(digits)
      }
    )
    let thousand: Binding<Int> = Binding(
      get: {
        guard self.value.count - 4 >= 0 else {
          return 0
        }
        return self.value.digits[self.value.count - 4]
      },
      set: { d in
        var digits = self.digitsForSet
        digits[2] = d
        self.value = "".join(digits)
      }
    )
    let tenThousand: Binding<Int> = Binding(
      get: {
        guard self.value.count - 5 >= 0 else {
          return 0
        }
        return self.value.digits[self.value.count - 5]
      },
      set: { d in
        var digits = self.digitsForSet
        digits[1] = d
        self.value = "".join(digits)
      }
    )
    let hundredThousand: Binding<Int> = Binding(
      get: {
        guard self.value.count - 6 >= 0 else {
          return 0
        }
        return self.value.digits[self.value.count - 6]
      },
      set: { d in
        var digits = self.digitsForSet
        digits[0] = d
        self.value = "".join(digits)
      }
    )
    HStack {
      Picker("", selection: hundredThousand) {
        ForEach(0...9, id: \.self) { number in
          Text("\(number)").font(.system(size: 24, weight: .bold, design: .rounded))
        }
      }.pickerStyle(.wheel)
      Picker("", selection: tenThousand) {
        ForEach(0...9, id: \.self) { number in
          Text("\(number)").font(.system(size: 24, weight: .bold, design: .rounded))
        }
      }.pickerStyle(.wheel)
      Picker("", selection: thousand) {
        ForEach(0...9, id: \.self) { number in
          Text("\(number)").font(.system(size: 24, weight: .bold, design: .rounded))
        }
      }.pickerStyle(.wheel)
      Picker("", selection: hundred) {
        ForEach(0...9, id: \.self) { number in
          Text("\(number)").font(.system(size: 24, weight: .bold, design: .rounded))
        }
      }.pickerStyle(.wheel)
      Picker("", selection: ten) {
        ForEach(0...9, id: \.self) { number in
          Text("\(number)").font(.system(size: 24, weight: .bold, design: .rounded))
        }
      }.pickerStyle(.wheel)
      Picker("", selection: digit) {
        ForEach(0...9, id: \.self) { number in
          Text("\(number)").font(.system(size: 24, weight: .bold, design: .rounded))
        }
      }.pickerStyle(.wheel)
    }
  }
}
