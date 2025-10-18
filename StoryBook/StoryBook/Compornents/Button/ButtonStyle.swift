import SwiftUI

/// 共通のボタンスタイルコンポーネント
/// PrimaryButtonとPhotoPickerButtonで使用する統一されたスタイル
struct CustomButtonStyle: View {
    // MARK: - Properties
    
    /// ボタンに表示するテキスト
    let title: String
    
    /// ボタンの幅（nilの場合は自動調整）
    var width: CGFloat? = nil
    
    /// フォント名（nilの場合はシステムフォント）
    var fontName: String? = "YuseiMagic-Regular"
    
    /// フォントサイズ
    var fontSize: CGFloat = 20
    
    /// ボタンが無効かどうか
    var disabled: Bool = false
    
    // MARK: - Body
    
    var body: some View {
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
            .shadow(
                color: Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.5),
                radius: 15,
                x: 0,
                y: 5
            )
            .opacity(disabled ? 0.5 : 1.0)
            .allowsHitTesting(!disabled)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        CustomButtonStyle(
            title: "通常のボタン",
            fontName: "YuseiMagic-Regular",
            fontSize: 20
        )
        
        CustomButtonStyle(
            title: "カスタム幅",
            width: 200,
            fontSize: 18
        )
        
        CustomButtonStyle(
            title: "無効なボタン",
            fontSize: 16,
            disabled: true
        )
    }
    .padding()
}
