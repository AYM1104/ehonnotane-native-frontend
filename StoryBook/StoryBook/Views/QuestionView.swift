import SwiftUI

struct QuestionView: View {
    // テーマ選択画面への遷移コールバック
    let onNavigateToThemeSelect: () -> Void
    
    var body: some View {
        // ヘッダーを含む全体レイアウト
        ZStack(alignment: .top) {
            // 星空背景を適用
            Background {
                // メインコンテンツ
                VStack {
                    // ヘッダーの高さ分のスペースを確保
                    Spacer()
                        .frame(height: 120)
                    
                    // メインテキスト（カードコンポーネントと同じ光る効果）
                    VStack(spacing: 8) {
                        MainText(text: "どんな おはなしかな？")
                        MainText(text: "おしえてね！")
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // ガラス風カードを表示（プレビューに合わせて配置）
                    mainCard(width: .screen95) {
                        ZStack {
                            // インナーカードをガラスカード内の中央に配置（サイズはコンポーネント内で管理）
                            InnerCard(
                                sections: [
                                    .init {
                                        // 上部領域：質問（中央配置）
                                        VStack(spacing: 8) {
                                            Text("質問")
                                                .font(.custom("YuseiMagic-Regular", size: 18))
                                                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                            
                                            Text("ここに質問内容が表示されます")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                                .multilineTextAlignment(.center)
                                        }
                                    },
                                    .init {
                                        // 下部領域：入力エリア
                                        VStack(spacing: 8) {
                                            Text("入力")
                                                .font(.custom("YuseiMagic-Regular", size: 18))
                                                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                            
                                            Text("ここに入力エリアが表示されます")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                ]
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 15) // プレビューに合わせて下から15ポイント上に移動
                }
                .previewLayout(.sizeThatFits)
                .previewDisplayName("メインカード + InnerCard")
            
            // キャラクター（Backgroundの制約から外して配置）
            BigCharacter()
        }
    }
}
}


#Preview {
    QuestionView(onNavigateToThemeSelect: {
        print("プレビュー: テーマ選択画面への遷移")
    })
}
