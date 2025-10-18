//
//  mainCard.swift
//  StoryBook
//
//  Created by ayu on 2025/10/13.
//

import SwiftUI

// MARK: - カードサイズ定義

/// カードの横幅サイズ
enum CardWidth {
    case small
    case medium
    case large
    case full
    
    /// サイズに応じた最大幅
    var maxWidth: CGFloat {
        switch self {
        case .small:
            return 320
        case .medium:
            return 480
        case .large:
            return 640
        case .full:
            return .infinity
        }
    }
}

/// ラベルの文字色
enum LabelColor {
    case white
    case black
    
    var color: Color {
        switch self {
        case .white:
            return .white
        case .black:
            return .black
        }
    }
}


// MARK: - メインカードコンポーネント

/// ガラス風のメインカードコンポーネント
/// Card.tsx を完全再現した SwiftUI バージョン
struct mainCard<Content: View>: View {
    // MARK: - Properties
    
    /// カード内に表示するコンテンツ
    let content: () -> Content
    
    /// カード全体を縦方向にずらす量
    let offsetY: CGFloat
    
    /// ラベルの文字色
    let labelColor: LabelColor
    
    /// カードの横幅サイズ
    let widthSize: CardWidth
    
    /// カードの高さ（nilの場合はデフォルト）
    let height: CGFloat?
    
    /// カードの最大幅
    let maxWidth: CGFloat?
    
    // MARK: - Initializer
    
    init(
        offsetY: CGFloat = 0,
        labelColor: LabelColor = .white,
        width: CardWidth = .medium,
        height: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.offsetY = offsetY
        self.labelColor = labelColor
        self.widthSize = width
        self.height = height
        self.maxWidth = maxWidth
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // ガラス風の透明効果（Reactの元の値に合わせて修正）
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    // bg-gradient-to-br from-white/15 via-white/5 to-white/10
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.15), location: 0.0),
                            .init(color: Color.white.opacity(0.05), location: 0.5),
                            .init(color: Color.white.opacity(0.10), location: 1.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // ガラス風の内側ハイライト
                    // bg-gradient-to-b from-white/8 via-white/2 to-white/5
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.08), location: 0.0),
                            .init(color: Color.white.opacity(0.02), location: 0.5),
                            .init(color: Color.white.opacity(0.05), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // inset シャドウのシミュレーション（上部の内側白ライン）
                    // inset_0_1px_0_rgba(255,255,255,0.2)
                    VStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 1)
                        Spacer()
                    }
                )
                .overlay(
                    // 白い枠線（border border-white/30）
                    // より光らせるために不透明度を上げてグロー効果を追加
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                        .shadow(color: Color.white.opacity(0.5), radius: 3, x: 0, y: 0)
                        .shadow(color: Color.white.opacity(0.3), radius: 6, x: 0, y: 0)
                )
            
            // ガラス風のコンテンツエリア
            // relative z-10 h-full flex flex-col items-center justify-start
            VStack {
                content()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .multilineTextAlignment(.center)  // text-center
            // パディング
            .padding(.top, 32)      // pt-8
            .padding(.horizontal, 16)  // px-4
            .padding(.bottom, 16)   // pb-4
            // フォントサイズと文字色
            .font(.system(size: 18, weight: .medium))  // text-lg font-medium
            .foregroundColor(labelColor.color)
            // ボタン等が発光しないようにシャドウは付けない
        }
        // 動的なレスポンシブ最大幅
        .frame(
            height: height ?? 400  // h-[19rem] = 304px
        )
        .frame(maxWidth: maxWidth ?? widthSize.maxWidth)  // 最大幅の制限
        .clipShape(RoundedRectangle(cornerRadius: 16))  // overflow-hidden, rounded-2xl
        // 強い輝き効果（複数のシャドウ）
        // shadow-[0_8px_40px_rgba(0,0,0,0.2),inset_0_1px_0_rgba(255,255,255,0.2),0_0_30px_rgba(255,255,255,0.3),0_0_60px_rgba(102,126,234,0.4),0_0_90px_rgba(255,255,255,0.2)]
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 8)
        .shadow(color: Color.white.opacity(0.3), radius: 15, x: 0, y: 0)
        .shadow(color: Color(red: 102/255, green: 126/255, blue: 234/255).opacity(0.4), radius: 30, x: 0, y: 0)
        .shadow(color: Color.white.opacity(0.2), radius: 45, x: 0, y: 0)
        .offset(y: offsetY)
    }
    
}


// MARK: - Preview

#Preview {
    Background {
        // キャラクターを背景として配置
        BigCharacter()
        ZStack {
            
            
            
            // 基本的なガラス風カード
            mainCard(width: .medium) {
                VStack(spacing: 16) {
                                    
                    Text("えほんのたね")
                        .font(.custom("YuseiMagic-Regular", size: 32))
                    
                    Text("ガラス風のカードコンポーネント")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }
}
