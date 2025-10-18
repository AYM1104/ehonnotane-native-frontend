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
    
    /// フォント名（デフォルトはYuseiMagic-Regular）
    var fontName: String? = "YuseiMagic-Regular"
    
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
            // 共通のボタンスタイルを使用
            CustomButtonStyle(
                title: title,
                width: width,
                fontName: fontName,
                fontSize: fontSize,
                disabled: disabled
            )
        }
        // プレス時の縮小効果
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPressed)
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
