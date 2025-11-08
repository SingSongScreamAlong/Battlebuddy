//
//  AnimationHelpers.swift
//  BattleBuddy
//
//  Reusable animations and transitions for smooth UI
//

import SwiftUI

// MARK: - Custom Animations
extension Animation {
    // Smooth spring animation for general UI
    static let smoothSpring = Animation.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0.2)

    // Bouncy spring for interactive elements
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.25)

    // Quick easeInOut for fast transitions
    static let quickEase = Animation.easeInOut(duration: 0.2)

    // Smooth easeInOut for regular transitions
    static let smoothEase = Animation.easeInOut(duration: 0.3)

    // Slow easeInOut for emphasized transitions
    static let slowEase = Animation.easeInOut(duration: 0.5)
}

// MARK: - Custom Transitions
extension AnyTransition {
    // Slide and fade transition
    static var slideAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    // Scale and fade transition
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }

    // Slide up transition
    static var slideUp: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    // Slide down transition
    static var slideDown: AnyTransition {
        .move(edge: .top).combined(with: .opacity)
    }
}

// MARK: - View Modifiers for Animations
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius * 1.5, x: 0, y: 0)
    }
}

// MARK: - View Extensions
extension View {
    // Shake animation
    func shake(trigger: Binding<Bool>) -> some View {
        self.modifier(ShakeModifier(shake: trigger))
    }

    // Pulse animation
    func pulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        self.modifier(PulseEffect(minScale: minScale, maxScale: maxScale, duration: duration))
    }

    // Glow effect
    func glow(color: Color = .bbAccent, radius: CGFloat = 8) -> some View {
        self.modifier(GlowEffect(color: color, radius: radius))
    }

    // Animated card style
    func animatedCard() -> some View {
        self
            .background(Color.bbCardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // Press animation
    func pressAnimation() -> some View {
        self.buttonStyle(PressButtonStyle())
    }
}

// MARK: - Shake Modifier
struct ShakeModifier: ViewModifier {
    @Binding var shake: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
            .onChange(of: shake) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shake = false
                    }
                }
            }
    }
}

// MARK: - Press Button Style
struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.quickEase, value: configuration.isPressed)
    }
}

// MARK: - Loading Animations
struct LoadingDots: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.bbAccent)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                        .blendMode(.overlay)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}
