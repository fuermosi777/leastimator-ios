//
//  DangerousZoneGlow.swift
//  Leastimator
//
//  Created by Antigravity on 4/16/26.
//

import SwiftUI

struct DangerousZoneGlow: ViewModifier {
    var progress: Float
    @State private var animate = false

    private var baseColor: Color? {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.9 {
            return .orange
        }
        return nil
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                if let color = baseColor {
                    ZStack {
                        // Very subtle, blurred inward glow that adapts to any corner radius
                        // By using a large blur and no solid edge, misalignment is invisible
                        Rectangle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.6),
                                        color.opacity(0.3),
                                        .purple.opacity(0.2), // Faint rainbow touch
                                        color.opacity(0.3),
                                        color.opacity(0.6)
                                    ],
                                    startPoint: animate ? .topLeading : .bottomTrailing,
                                    endPoint: animate ? .bottomTrailing : .topLeading
                                ),
                                lineWidth: 20
                            )
                            .blur(radius: 20)
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                            animate.toggle()
                        }
                    }
                }
            }
    }
}

extension View {
    func dangerousZoneGlow(progress: Float) -> some View {
        modifier(DangerousZoneGlow(progress: progress))
    }
}
