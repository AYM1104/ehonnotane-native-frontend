import SwiftUI

struct TestView: View {
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            accentBubbles

            GlassCard()
                .padding(.horizontal, 24)
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.14, blue: 0.32),
                Color(red: 0.03, green: 0.06, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var accentBubbles: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.80, green: 0.38, blue: 0.96).opacity(0.55))
                .frame(width: 260)
                .blur(radius: 80)
                .offset(x: -140, y: -220)

            Circle()
                .fill(Color(red: 0.32, green: 0.68, blue: 0.94).opacity(0.45))
                .frame(width: 280)
                .blur(radius: 100)
                .offset(x: 140, y: 200)
        }
    }
}

struct GlassCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .blur(radius: 22)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.55),
                                    Color.white.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.6)
                        .blendMode(.screen)
                        .opacity(0.9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                        .blur(radius: 36)
                        .opacity(0.9)
                        .padding(.bottom, 140)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 28, x: 0, y: 18)

            VStack(alignment: .leading, spacing: 18) {
                Text("Glassmorphism Card")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))

                Text("半透明の背景、柔らかな発光、繊細なボーダーで構成されたカードデザインのサンプルです。")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineSpacing(4)

                Divider()
                    .overlay(Color.white.opacity(0.35))

                HStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("使い方のヒント")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.85))

                        Text("背景とのコントラストを意識しつつ、ハイライトやシャドウで立体感を演出すると印象的になります。")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.7))
                            .lineSpacing(3)
                    }
                }
            }
            .padding(30)
        }
        .frame(maxWidth: 360)
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 8)
                .offset(x: 60, y: -60)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 60, height: 60)
                .blur(radius: 6)
                .offset(x: -30, y: 30)
        }
    }
}

#Preview {
    TestView()
}
