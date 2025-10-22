import SwiftUI

/// サブテキストコンポーネント - YuseiMagicフォントを使用したサブテキスト表示
struct SubText: View {
    // 表示するテキスト
    let text: String
    // フォントサイズ（デフォルト: 16）
    var fontSize: CGFloat = 20
    // テキストカラー（デフォルト: #362D30）
    var color: Color = Color(hex: "362D30")
    // テキストアライメント（デフォルト: center）
    var alignment: TextAlignment = .center
    
    var body: some View {
        Text(text)
            .font(.custom("YuseiMagic-Regular", size: fontSize))
            .foregroundColor(color)
            .multilineTextAlignment(alignment)
    }
}

#Preview {
    ZStack {
        // 背景
        Background {
            BigCharacter()
        }
        
        SubText(text: "これはサブテキストのサンプルです")
    }
}
