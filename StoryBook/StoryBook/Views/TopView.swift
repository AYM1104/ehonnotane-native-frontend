import SwiftUI

struct TopView: View {
    var body: some View {
        ZStack {
            // 背景としてBackgroundコンポーネントを使用
            Background()
            
            // ロゴアニメーションを上に重ねる
            LogoAnimation()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


#Preview {
    TopView()
}
