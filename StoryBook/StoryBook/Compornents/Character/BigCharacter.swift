import SwiftUI

// シンプルなキャラクター画像表示コンポーネント
struct BigCharacter: View {
    var body: some View {
        VStack {
            Spacer()
            
            Image("charactor-smartphone")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: UIScreen.main.bounds.height * 0.8)
                .padding(.bottom, 30)
        }
    }
}

#Preview("デフォルト") {
    ZStack(alignment: .top) {
        // 背景
        Background {
            BigCharacter()
        }
        
        // ヘッダー
        Header()
    }
}

