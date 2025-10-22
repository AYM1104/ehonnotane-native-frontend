import SwiftUI

// シンプルなインナーカードコンポーネント
// サイズ設定はコンポーネント内で管理し、View側ではシンプルに使用
struct InnerCard: View {
    struct Section {
        let fixedHeight: CGFloat?
        let fillsRemainingSpace: Bool
        let alignment: Alignment
        let showDivider: Bool  // このセクションの後に区切り線を表示するかどうか
        private let contentView: AnyView
        
        init(
            fixedHeight: CGFloat? = nil,
            fillsRemainingSpace: Bool = true,
            alignment: Alignment = .center,
            showDivider: Bool = true,  // デフォルトで区切り線を表示
            @ViewBuilder content: @escaping () -> some View
        ) {
            self.fixedHeight = fixedHeight
            self.fillsRemainingSpace = fillsRemainingSpace
            self.alignment = alignment
            self.showDivider = showDivider
            self.contentView = AnyView(content())
        }
        
        func configuredView() -> AnyView {
            var view = AnyView(
                contentView
                    .frame(maxWidth: .infinity, alignment: alignment)
            )
            
            if let fixedHeight = fixedHeight {
                view = AnyView(
                    view.frame(height: fixedHeight, alignment: alignment)
                )
            }
            
            if fillsRemainingSpace {
                view = AnyView(
                    view.frame(minHeight: 0, maxHeight: .infinity, alignment: alignment)
                )
            }
            
            return view
        }
    }
    
    let sections: [Section]
    let backgroundColor: Color
    let showDividers: Bool
    let dividerColor: Color
    
    // mainCardのサイズに基づく固定サイズ（90%）
    private let widthRatio: CGFloat = 1.0
    private let heightRatio: CGFloat = 1.0
    
    // シンプルなイニシャライザ（サイズパラメータを削除）
    init(
        backgroundColor: Color = Color.white.opacity(0.5),
        showDividers: Bool = true,
        dividerColor: Color = Color.gray.opacity(0.3),
        sections: [Section]
    ) {
        self.sections = sections
        // self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        // self.horizontalPadding = horizontalPadding
        // self.verticalPadding = verticalPadding
        self.showDividers = showDividers
        self.dividerColor = dividerColor
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<sections.count, id: \.self) { index in
                sections[index]
                    .configuredView()
                    .padding(.horizontal, 30)
                    .padding(.top, 16)
                
                // 区切り線（最後のセクション以外、かつセクションで区切り線が有効な場合）
                if index < sections.count - 1 && showDividers && sections[index].showDivider {
                    Rectangle()
                        .fill(dividerColor)
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .fill(backgroundColor)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InnerCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }
            
            // ヘッダー
            Header()
            
            // メインカード（画面下部に配置）
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト
                MainText(text: "どんな え でえほんを")
                MainText(text: "つくろうかな？")
                Spacer()
                
                // ガラス風カードを表示
                mainCard(width: .screen95) {
                    VStack(spacing: 16) {
                        
                        
                        InnerCard(
                            sections: [
                                .init(showDivider: false) {
                                    // 上部領域：質問（中央配置）
                                    VStack(spacing: 8) {
                                        SubText(text: "質問", fontSize: 18)
                                        SubText(text: "ここに質問内容が表示されますここに質問内容が表示されますここに質問内容が表示されますここに質問内容が表示されますここに質問内容が表示されますここに質問内容が表示されます", fontSize: 18)
                                    }
                                },
                                .init {
                                    // 下部領域：入力エリア
                                    VStack(spacing: 8) {
                                        SubText(text: "入力", fontSize: 18)
                                        
                                        SubText(text: "ここに入力エリアが表示されます", fontSize: 18)
                                    }
                                }
                            ]
                        )
                        .padding(.top, 4) // インナーカード上部の余白
                        .padding(.horizontal,4) // インナーカード左右の余白
                        .padding(.bottom,16) // インナーカード下部の余白
                        
                    }
                }
                .padding(.horizontal, 16) // パディングを減らしてカードを広く表示
                .padding(.bottom, 16) // 画面下部からの余白
            }
        }
    }
}
