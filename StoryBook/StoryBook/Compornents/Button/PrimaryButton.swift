//
//  PrimaryButton.swift
//  StoryBook
//
//  Created by ayu on 2025/10/12.
//

import SwiftUI

/// プライマリーボタンコンポーネント
/// エメラルドからティールへのグラデーションを持つ、アニメーション付きのボタン
struct PrimaryButton: View {
    // MARK: - Properties
    
    /// ボタンに表示するテキスト
    let title: String
    
    /// ボタンが無効かどうか
    var disabled: Bool = false
    
    /// ボタンの幅（nilの場合は自動調整）
    var width: CGFloat? = nil
    
    /// フォント名（nilの場合はシステムフォント）
    var fontName: String? = nil
    
    /// フォントサイズ
    var fontSize: CGFloat = 20
    
    /// ボタンタップ時のアクション
    var action: () -> Void
    
    // MARK: - State
    
    /// ボタンが押されているかどうか
    @State private var isPressed = false
    
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            if !disabled {
                action()
            }
        }) {
            // ボタンの背景とテキスト
            Text(title)
                .font(fontName != nil ? .custom(fontName!, size: fontSize) : .system(size: fontSize, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 12)
                .frame(width: width)
                .background(
                    ZStack {
                        // グラデーション背景
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 16/255, green: 185/255, blue: 129/255), // emerald-500
                                Color(red: 20/255, green: 184/255, blue: 166/255), // teal-500
                                Color(red: 6/255, green: 182/255, blue: 212/255)   // cyan-500
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // 光るボーダーエフェクト
                        RoundedRectangle(cornerRadius: 50)
                            .strokeBorder(
                                Color(red: 110/255, green: 231/255, blue: 183/255).opacity(0.5),
                                lineWidth: 1
                            )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 50))
        }
        .shadow(
            color: Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.5),
            radius: 15,
            x: 0,
            y: 5
        )
        // プレス時の縮小効果
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
        // 無効状態のスタイル
        .opacity(disabled ? 0.5 : 1.0)
        .allowsHitTesting(!disabled)
        // プレスジェスチャー
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !disabled {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        PrimaryButton(
            title: "ボタン",
            action: {
                print("ボタンがタップされました")
            }
        )
        
        PrimaryButton(
            title: "カスタム幅",
            width: 200,
            action: {
                print("カスタム幅ボタンがタップされました")
            }
        )
        
        PrimaryButton(
            title: "無効なボタン",
            disabled: true,
            action: {
                print("このボタンは無効です")
            }
        )
    }
    .padding()
}
