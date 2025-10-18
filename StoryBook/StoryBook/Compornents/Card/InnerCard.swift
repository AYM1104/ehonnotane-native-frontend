import SwiftUI

// シンプルなインナーカードコンポーネント
// サイズ設定はコンポーネント内で管理し、View側ではシンプルに使用
struct InnerCard: View {
    let sections: [AnyView]
    let cornerRadius: CGFloat
    let backgroundColor: Color
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let showDividers: Bool
    let dividerColor: Color
    
    // mainCardのサイズに基づく固定サイズ（90%）
    private let widthRatio: CGFloat = 0.9
    private let heightRatio: CGFloat = 0.9
    
    // シンプルなイニシャライザ（サイズパラメータを削除）
    init(
        cornerRadius: CGFloat = 16,
        backgroundColor: Color = Color.white.opacity(0.5),
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 16,
        showDividers: Bool = true,
        dividerColor: Color = Color.gray.opacity(0.3),
        sections: [AnyView]
    ) {
        self.sections = sections
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.showDividers = showDividers
        self.dividerColor = dividerColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach(0..<sections.count, id: \.self) { index in
                    sections[index]
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, verticalPadding)
                    
                    // 区切り線（最後のセクション以外）
                    if index < sections.count - 1 && showDividers {
                        Rectangle()
                            .fill(dividerColor)
                            .frame(height: 1)
                            .padding(.horizontal, horizontalPadding)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            // mainCardの90%サイズに設定
            .frame(
                width: geometry.size.width * widthRatio,
                height: geometry.size.height * heightRatio
            )
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

struct InnerCard_Previews: PreviewProvider {
    static var previews: some View {
        // ヘッダーを含む全体レイアウト
        ZStack(alignment: .top) {
            // 星空背景を適用
            Background {
                // キャラクターを背景として配置
                BigCharacter()
                
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
                                    AnyView(
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
                                    ),
                                    AnyView(
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
                                    )
                                ]
                            )
                        }
                    }
                    .padding()
                    .padding(.bottom, 15) // プレビューに合わせて下から15ポイント上に移動
                }
                .previewLayout(.sizeThatFits)
                .previewDisplayName("メインカード + InnerCard")
            }
        }
    }
}
