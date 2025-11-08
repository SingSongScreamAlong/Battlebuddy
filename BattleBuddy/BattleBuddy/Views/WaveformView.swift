//
//  WaveformView.swift
//  BattleBuddy
//
//  Animated waveform visualization for voice interface
//

import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    let barCount: Int = 30
    let isActive: Bool

    @State private var bars: [CGFloat] = []

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(
                        colors: [.bbAccent, .bbAccent.opacity(0.6)],
                        startPoint: .bottom,
                        endPoint: .top
                    ))
                    .frame(width: 3)
                    .frame(height: barHeight(for: index))
                    .shadow(color: .bbAccent.opacity(isActive ? 0.5 : 0), radius: 4, x: 0, y: 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: bars)
            }
        }
        .frame(height: 60)
        .onAppear {
            initializeBars()
        }
        .onChange(of: audioLevel) { _ in
            if isActive {
                updateBars()
            }
        }
        .onChange(of: isActive) { active in
            if !active {
                resetBars()
            }
        }
    }

    private func initializeBars() {
        bars = Array(repeating: 4.0, count: barCount)
    }

    private func barHeight(for index: Int) -> CGFloat {
        guard index < bars.count else { return 4 }
        return bars[index]
    }

    private func updateBars() {
        let scaledLevel = CGFloat(audioLevel) * 100

        bars = bars.enumerated().map { index, currentHeight in
            // Create wave pattern with some randomness
            let waveOffset = sin(Double(index) * 0.5 + Double(audioLevel) * 10) * 10
            let randomVariation = CGFloat.random(in: 0.8...1.2)

            let targetHeight = max(4, min(60, (scaledLevel + CGFloat(waveOffset)) * randomVariation))

            // Smooth interpolation
            return currentHeight * 0.7 + targetHeight * 0.3
        }
    }

    private func resetBars() {
        withAnimation(.easeOut(duration: 0.3)) {
            bars = Array(repeating: 4.0, count: barCount)
        }
    }
}

// MARK: - Circular Waveform (Alternative Design)
struct CircularWaveformView: View {
    let audioLevel: Float
    let isActive: Bool

    var body: some View {
        ZStack {
            // Outer pulse rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.bbAccent.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                    .frame(width: 100 + CGFloat(index * 10), height: 100 + CGFloat(index * 10))
                    .scaleEffect(isActive ? 1.0 + CGFloat(audioLevel) * 0.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.3 + Double(index) * 0.1)
                            .repeatCount(isActive ? .max : 0, autoreverses: true),
                        value: audioLevel
                    )
            }

            // Animated pulse
            Circle()
                .stroke(Color.bbAccent, lineWidth: 4)
                .frame(width: 100 + CGFloat(audioLevel) * 50, height: 100 + CGFloat(audioLevel) * 50)
                .opacity(Double(1.0 - audioLevel))
                .shadow(color: .bbAccent.opacity(0.5), radius: 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: audioLevel)

            // Inner circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.bbAccent, .bbAccent.opacity(0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 80, height: 80)
                .scaleEffect(isActive ? 1.0 + CGFloat(audioLevel) * 0.3 : 1.0)
                .shadow(color: .bbAccent.opacity(isActive ? 0.6 : 0.2), radius: isActive ? 20 : 10)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: audioLevel)
        }
    }
}

#Preview("Bar Waveform") {
    VStack(spacing: 40) {
        WaveformView(audioLevel: 0.0, isActive: false)
            .padding()
            .background(Color.bbBackground)

        WaveformView(audioLevel: 0.5, isActive: true)
            .padding()
            .background(Color.bbBackground)

        WaveformView(audioLevel: 0.9, isActive: true)
            .padding()
            .background(Color.bbBackground)
    }
}

#Preview("Circular Waveform") {
    CircularWaveformView(audioLevel: 0.5, isActive: true)
        .padding()
        .background(Color.bbBackground)
}
