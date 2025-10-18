import SwiftUI

struct TopView: View {
    // ボタンの表示状態を管理
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            // 背景としてBackgroundコンポーネントを使用
            Background()
            
            VStack() {
                // ロゴアニメーションを中央に配置
                LogoAnimation()
                
                // タイトルテキストアニメーションをロゴの下に配置
                TitleText()

                // ボタンをフェードインで配置
                PrimaryButton(
                    title: "えほんをつくる",
                    fontName: "YuseiMagic-Regular",
                    fontSize: 24,
                    action: {
                        print("ログインボタンがタップされました")
                    }
                )
                .padding(.top, 40)
                .opacity(showButton ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0), value: showButton)

                Spacer()
            }
                
        }
        .onAppear {
            // タイトル表示完了後にボタンをフェードイン（5.5秒後）
            // タイトルテキストのアニメーション完了（3秒 + 1.2秒） + 少しの遅延
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                showButton = true
            }
        }
    }
}


#Preview {
    TopView()
}
