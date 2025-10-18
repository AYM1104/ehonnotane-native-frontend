//
//  Background.swift
//  StoryBook
//
//  Created by ayu on 2025/10/12.
//

import SwiftUI

// MARK: - Color Extension（16進数カラーコードをサポート）
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 星の型定義
// 星1つの位置・大きさ・動きなどの情報を定義
struct Star: Identifiable {
    let id = UUID()
    let src: String           // 星の色（yellow, blue, green, purple, red, white）
    let left: CGFloat         // 配置するX座標
    let top: CGFloat          // 配置するY座標
    let size: CGFloat         // 星の大きさ（px）
    let opacity: Double       // 星の透明度（0～1）
    let rotate: Double        // 星の回転角度（°）
    let twinkleDur: Double    // 点滅（twinkle）にかかる時間（秒）
    let twinkleDelay: Double  // 点滅の開始タイミング（秒）
    let floatDur: Double      // 上下に揺れる（floatY）動きの周期（秒）
}

// MARK: - 星の画像パス一覧（色違いの星）
let starImages = [
    "yellow",
    "blue",
    "green",
    "purple",
    "red",
    "white"
]

// MARK: - 画面の広さに対するベース密度
// 例: 1920x1080 ≒ 2,073,600px * 0.0003 ≒ 622個
let BASE_DENSITY: CGFloat = 0.0003

// MARK: - 星を生成する関数
func generateStars(count: Int, width: CGFloat, height: CGFloat) -> [Star] {
    return (0..<count).map { _ in
        Star(
            src: starImages.randomElement()!,
            left: CGFloat.random(in: 0...width),
            top: CGFloat.random(in: 0...height),
            size: CGFloat.random(in: 5...12),
            opacity: Double.random(in: 0.5...1.0),
            rotate: Double.random(in: 0...360),
            twinkleDur: Double.random(in: 1.5...3.5),
            twinkleDelay: Double.random(in: 0...2),
            floatDur: Double.random(in: 3...6)
        )
    }
}

// MARK: - 菱形（Diamond）Shape
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 菱形の4つの頂点を定義
        let top = CGPoint(x: rect.midX, y: rect.minY)
        let right = CGPoint(x: rect.maxX, y: rect.midY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let left = CGPoint(x: rect.minX, y: rect.midY)
        
        // 菱形を描画
        path.move(to: top)
        path.addLine(to: right)
        path.addLine(to: bottom)
        path.addLine(to: left)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - レイヤータイプの定義
enum LayerType {
    case far   // 遠景：薄くてゆったりした動きの星
    case mid   // 中景：標準の明るさと動きの星
    case near  // 近景：強く光り、大きめ＆影付きの星
}

// MARK: - 星のレイヤー（StarLayer）
// 星を配置するレイヤー
struct StarLayer: View {
    let stars: [Star]
    let layerType: LayerType
    
    var body: some View {
        ForEach(stars) { star in
            StarView(star: star, layerType: layerType)
        }
    }
}

// MARK: - 個別の星ビュー（StarView）
struct StarView: View {
    let star: Star
    let layerType: LayerType
    
    @State private var twinkleOpacity: Double = 1.0
    @State private var twinkleScale: CGFloat = 1.0
    @State private var floatY: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 塗りつぶし
            DiamondShape()
                .fill(starColor)
            
            // 黒枠線（opacity: 0.2）
            DiamondShape()
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
            
            // 黒枠線（通常）
            DiamondShape()
                .stroke(Color.black, lineWidth: 1)
        }
        .frame(width: star.size, height: star.size)
        .opacity(layerOpacity)
        .rotationEffect(.degrees(star.rotate))
        .scaleEffect(twinkleScale)
        .blur(radius: blurRadius)
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 0)
        .offset(y: floatY)
        .position(x: star.left, y: star.top)
        .onAppear {
            startAnimations()
        }
    }
    
    // レイヤータイプごとの透明度
    private var layerOpacity: Double {
        switch layerType {
        case .far:
            return star.opacity * 0.8 * twinkleOpacity  // 少し薄めに表示
        case .mid:
            return star.opacity * twinkleOpacity        // そのままの明るさ
        case .near:
            return star.opacity * twinkleOpacity        // はっきり見える
        }
    }
    
    // レイヤータイプごとのブラー効果
    private var blurRadius: CGFloat {
        switch layerType {
        case .far:
            return 0.2  // ほんの少しぼかして遠さを演出
        case .mid:
            return 0
        case .near:
            return 0
        }
    }
    
    // レイヤータイプごとのシャドウ効果（近景だけ光をにじませる）
    private var shadowColor: Color {
        layerType == .near ? Color.white.opacity(0.35) : Color.clear
    }
    
    private var shadowRadius: CGFloat {
        layerType == .near ? 4 : 0
    }
    
    // 星の色を取得（SVGファイルと同じカラーコード）
    private var starColor: Color {
        switch star.src {
        case "yellow":
            return Color(hex: "#FFC31C")  // star-yellow.svg
        case "blue":
            return Color(hex: "#77C7E3")  // star-blue.svg
        case "green":
            return Color(hex: "#00AA9C")  // star-green.svg
        case "purple":
            return Color(hex: "#A481B4")  // star-purple.svg
        case "red":
            return Color(hex: "#E3662A")  // star-red.svg
        case "white":
            return Color(hex: "#F8F8FA")  // star-white.svg
        default:
            return Color(hex: "#F8F8FA")
        }
    }
    
    // アニメーションを開始
    private func startAnimations() {
        // レイヤータイプごとのアニメーション設定
        let (twinkleDuration, floatDuration, floatDelay) = getAnimationParams()
        
        // 点滅アニメーション（twinkle）
        // 0%: opacity: 0.45, scale: 0.95（少し暗く小さめ）
        // 100%: opacity: 1.0, scale: 1.05（明るく大きめ）
        withAnimation(
            .easeInOut(duration: twinkleDuration)
            .repeatForever(autoreverses: true)
            .delay(star.twinkleDelay)
        ) {
            twinkleOpacity = 0.45
            twinkleScale = 0.95
        }
        
        // 上下に揺れるアニメーション（floatY）
        // -2px ⇔ 2px
        withAnimation(
            .easeInOut(duration: floatDuration)
            .repeatForever(autoreverses: true)
            .delay(floatDelay)
        ) {
            floatY = 2
        }
    }
    
    // レイヤータイプごとのアニメーションパラメータ
    private func getAnimationParams() -> (twinkleDuration: Double, floatDuration: Double, floatDelay: Double) {
        switch layerType {
        case .far:
            return (
                twinkleDuration: star.twinkleDur,
                floatDuration: star.floatDur,
                floatDelay: star.twinkleDelay / 2
            )
        case .mid:
            return (
                twinkleDuration: star.twinkleDur,
                floatDuration: star.floatDur * 0.7,
                floatDelay: star.twinkleDelay / 3
            )
        case .near:
            return (
                twinkleDuration: star.twinkleDur * 0.8,
                floatDuration: star.floatDur * 0.5,
                floatDelay: star.twinkleDelay / 4
            )
        }
    }
}

// MARK: - 星空全体のコンポーネント（StarField）
struct StarField: View {
    let far: [Star]   // 遠景の星データ
    let mid: [Star]   // 中景の星データ
    let near: [Star]  // 近景の星データ
    
    var body: some View {
        // 画面いっぱいに広がる星空（クリックなどのイベントは通すため allowsHitTesting(false)）
        ZStack {
            // 遠景：薄くてゆったりした動きの星
            StarLayer(stars: far, layerType: .far)
            
            // 中景：標準の明るさと動きの星
            StarLayer(stars: mid, layerType: .mid)
            
            // 近景：強く光り、大きめ＆影付きの星
            StarLayer(stars: near, layerType: .near)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - メイン背景ビュー（Background）
struct Background<Content: View>: View {
    let content: () -> Content
    
    @State private var mounted = false
    @State private var viewport: CGSize? = nil
    @State private var farStars: [Star] = []
    @State private var midStars: [Star] = []
    @State private var nearStars: [Star] = []
    
    init(@ViewBuilder content: @escaping () -> Content = { EmptyView() }) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // グラデーション背景（fixed inset-0 bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900）
                LinearGradient(
                    colors: [
                        Color(red: 0.5, green: 0.2, blue: 0.6),  // purple-900
                        Color(red: 0.1, green: 0.2, blue: 0.6),  // blue-900
                        Color(red: 0.2, green: 0.1, blue: 0.5)   // indigo-900
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 星空（マウント完了まで描画しない）
                if mounted {
                    StarField(far: farStars, mid: midStars, near: nearStars)
                }
                
                // コンテンツ（relative z-10）
                content()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .zIndex(10)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onChange(of: geometry.size) { oldSize, newSize in
                // サイズ変化時の暗黙アニメーションを無効化
                withAnimation(nil) {
                    updateViewport(size: newSize)
                }
            }
            .onAppear {
                // 初回マウント時の暗黙アニメーションを無効化
                withAnimation(nil) {
                    mounted = true
                    updateViewport(size: geometry.size)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // ビューポートを更新して星を再生成する関数
    private func updateViewport(size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }
        viewport = size
        
        let width = size.width
        let height = size.height
        let area = width * height
        
        // 画面サイズに応じた密度調整
        let densityScale: CGFloat = {
            if width < 600 { return 0.6 }
            if width < 900 { return 0.8 }
            return 1.0
        }()
        
        // 星の数を計算（TypeScriptの実装と同じ）
        let farCount = min(180, Int(area * 0.00004 * densityScale))
        let midCount = min(240, Int(area * 0.00006 * densityScale))
        let nearCount = min(140, Int(area * 0.00003 * densityScale))
        
        // 星を生成
        farStars = generateStars(count: farCount, width: width, height: height)
        midStars = generateStars(count: midCount, width: width, height: height)
        nearStars = generateStars(count: nearCount, width: width, height: height)
    }
}

// MARK: - Preview
#Preview {
    Background {

    }
}
