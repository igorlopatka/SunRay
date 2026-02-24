//
//  ShimmerEffect.swift
//  SunRay
//
//  Shimmer and animated gradient effects for liquid glass
//

import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    var duration: Double = 2.0
    var bounce: Bool = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.3), location: 0.5),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: geometry.size.width * (phase - 0.5) * 2)
                    .onAppear {
                        withAnimation(
                            .linear(duration: duration)
                            .repeatForever(autoreverses: bounce)
                        ) {
                            phase = 1.0
                        }
                    }
                }
            }
            .clipped()
    }
}

extension View {
    func shimmer(duration: Double = 2.0, bounce: Bool = false) -> some View {
        self.modifier(ShimmerEffect(duration: duration, bounce: bounce))
    }
}

struct AnimatedMeshGradient: View {
    let colors: [Color]
    @State private var phase: CGFloat = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    .init(0 + sin(time * 0.5) * 0.1, 0 + cos(time * 0.3) * 0.1),
                    .init(0.5 + sin(time * 0.7) * 0.1, 0 + cos(time * 0.4) * 0.1),
                    .init(1 + sin(time * 0.6) * 0.1, 0 + cos(time * 0.5) * 0.1),

                    .init(0 + sin(time * 0.4) * 0.1, 0.5 + cos(time * 0.6) * 0.1),
                    .init(0.5 + sin(time * 0.8) * 0.1, 0.5 + cos(time * 0.7) * 0.1),
                    .init(1 + sin(time * 0.5) * 0.1, 0.5 + cos(time * 0.8) * 0.1),

                    .init(0 + sin(time * 0.3) * 0.1, 1 + cos(time * 0.9) * 0.1),
                    .init(0.5 + sin(time * 0.9) * 0.1, 1 + cos(time * 1.0) * 0.1),
                    .init(1 + sin(time * 0.4) * 0.1, 1 + cos(time * 0.6) * 0.1)
                ],
                colors: colors
            )
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    @State private var isPressed = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(GlassCardBackground())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onTapGesture {}
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

private struct GlassCardBackground: ViewModifier {
    private let cornerRadius: Double = 24

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // Native Liquid Glass — blurs, refracts, and adapts to the content behind the card.
            content
                .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            // Fallback: hand-crafted material card for iOS 17–25.
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThickMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(
                                    .linearGradient(
                                        colors: [.white.opacity(0.5), .white.opacity(0.1), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                }
        }
    }
}

struct FloatingParticles: View {
    @State private var particles: [Particle] = []
    @State private var startTime: Date = .now

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var initialY: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: Double
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)

            GeometryReader { geometry in
                Canvas { context, size in
                    for particle in particles {
                        let totalTravel = size.height + 40
                        let offset = (particle.speed * elapsed).truncatingRemainder(dividingBy: totalTravel)
                        var y = particle.initialY - offset
                        if y < -20 {
                            y += totalTravel
                        }

                        let rect = CGRect(
                            x: particle.x - particle.size / 2,
                            y: y - particle.size / 2,
                            width: particle.size,
                            height: particle.size
                        )
                        context.opacity = particle.opacity
                        context.addFilter(.blur(radius: 2))
                        context.fill(Circle().path(in: rect), with: .color(.white))
                    }
                }
                .onAppear {
                    if particles.isEmpty {
                        createParticles(in: geometry.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<15).map { _ in
            Particle(
                x: CGFloat.random(in: 0...size.width),
                initialY: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.1...0.4),
                speed: Double.random(in: 20...40)
            )
        }
    }
}
