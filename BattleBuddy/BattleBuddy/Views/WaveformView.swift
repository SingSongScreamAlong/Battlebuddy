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
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(
                        colors: [.bbAccent, .bbAccent.opacity(0.6)],
                        startPoint: .bottom,
                        endPoint: .top
                    ))
                    .frame(width: 3)
                    .frame(height: barHeight(for: index))
                    .animation(.easeInOut(duration: 0.15), value: bars)
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
            // Outer ring
            Circle()
                .stroke(Color.bbAccent.opacity(0.3), lineWidth: 2)
                .frame(width: 100, height: 100)

            // Animated pulse
            Circle()
                .stroke(Color.bbAccent, lineWidth: 3)
                .frame(width: 100 + CGFloat(audioLevel) * 40, height: 100 + CGFloat(audioLevel) * 40)
                .opacity(Double(1.0 - audioLevel))
                .animation(.easeInOut(duration: 0.1), value: audioLevel)

            // Inner circle
            Circle()
                .fill(Color.bbAccent)
                .frame(width: 80, height: 80)
                .scaleEffect(isActive ? 1.0 + CGFloat(audioLevel) * 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: audioLevel)
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
