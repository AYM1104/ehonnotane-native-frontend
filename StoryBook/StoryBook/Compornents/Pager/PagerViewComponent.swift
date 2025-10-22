import SwiftUI

/// 汎用ページャコンポーネント（指の動きに追従、右→左で次ページ表示）
struct PagerViewComponent<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    // 入力
    let pages: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    var onPageChanged: ((Int) -> Void)? = nil

    // 状態
    @State private var currentIndex: Int = 0
    @GestureState private var dragOffset: CGFloat = 0

    init(_ pages: Data,
         spacing: CGFloat = 0,
         onPageChanged: ((Int) -> Void)? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.pages = pages
        self.spacing = spacing
        self.onPageChanged = onPageChanged
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width + spacing
            // HStackを横に並べて、currentIndexとdragで位置を決める
            HStack(spacing: spacing) {
                ForEach(pages) { page in
                    content(page)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .offset(x: -CGFloat(currentIndex) * width + dragOffset)
            .animation(.interactiveSpring(), value: dragOffset == 0) // 指離し後のスナップ
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .updating($dragOffset) { value, state, _ in
                        // 指の移動に追従（右→左スワイプで value.translation.width はマイナス）
                        // 端での引っ張りすぎを少し抵抗させる
                        let raw = value.translation.width
                        let isAtFirst = (currentIndex == 0 && raw > 0)
                        let isAtLast  = (currentIndex == pages.count - 1 && raw < 0)
                        state = (isAtFirst || isAtLast) ? raw * 0.25 : raw
                    }
                    .onEnded { value in
                        // スナップ判定（距離 or 速度）
                        let raw = value.translation.width
                        let velocity = value.predictedEndTranslation.width - raw
                        let width = geo.size.width

                        var nextIndex = currentIndex
                        let threshold = width * 0.28
                        // 右→左（次ページへ）: raw がマイナス、もしくは左向きに速い
                        if (raw < -threshold) || (velocity < -250) {
                            nextIndex = min(currentIndex + 1, pages.count - 1)
                        }
                        // 左→右（前ページへ）
                        else if (raw > threshold) || (velocity > 250) {
                            nextIndex = max(currentIndex - 1, 0)
                        }

                        if nextIndex != currentIndex {
                            currentIndex = nextIndex
                            onPageChanged?(nextIndex)
                        } else {
                            // 変わらない場合もアニメーションで元位置へスナップ
                            withAnimation(.spring()) { /* no-op: offsetバインドで戻る */ }
                        }
                    }
            )
            .contentShape(Rectangle()) // ヒット領域
            .clipped()
        }
    }
}

#Preview {
    PagerViewPreview()
}

struct PagerViewPreview: View {
    struct PreviewPage: Identifiable {
        let id = UUID()
        let content: String
    }
    
    let pages = [
        PreviewPage(content: "ページ1"),
        PreviewPage(content: "ページ2"),
        PreviewPage(content: "ページ3")
    ]
    
    var body: some View {
        PagerViewComponent(pages, spacing: 20) { page in
            VStack {
                Text(page.content)
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
            .cornerRadius(16)
        }
        .frame(height: 300)
        .padding()
    }
}
