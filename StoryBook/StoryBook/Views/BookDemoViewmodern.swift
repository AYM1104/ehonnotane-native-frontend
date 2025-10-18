import SwiftUI
import UIKit

// 1) 最小の PageCurl ラッパー（背景/ダブルサイドをシンプルに）
struct ModernPageCurlWrapper<Content: View>: UIViewControllerRepresentable {
    var pages: [Content]

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(transitionStyle: .pageCurl,
                                       navigationOrientation: .horizontal,
                                       options: nil)
        pvc.dataSource = context.coordinator
        // コンテナで見せたいので背景は透過
        pvc.view.backgroundColor = .clear
        context.coordinator.controllers = pages.map {
            // 安全領域は無視せず、コンテナのフレームに収める
            let host = UIHostingController(rootView: $0)
            host.view.backgroundColor = .clear
            return host
        }
        pvc.setViewControllers([context.coordinator.controllers.first!],
                               direction: .forward, animated: false)
        pvc.isDoubleSided = false   // まずは単ページで確実に動かす
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {}

    final class Coordinator: NSObject, UIPageViewControllerDataSource {
        var parent: ModernPageCurlWrapper
        var controllers: [UIViewController] = []
        init(_ parent: ModernPageCurlWrapper) { self.parent = parent }

        func pageViewController(_ p: UIPageViewController,
                                viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard let i = controllers.firstIndex(of: vc), i > 0 else { return nil }
            return controllers[i - 1]
        }
        func pageViewController(_ p: UIPageViewController,
                                viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard let i = controllers.firstIndex(of: vc), i + 1 < controllers.count else { return nil }
            return controllers[i + 1]
        }
    }
}

// 2) デモ用の物語ページ
struct ModernDemoPageWrapper: View {
    let number: Int
    
    var body: some View {
        ZStack {
            Color.white
            
            VStack(spacing: 20) {
                // ページ番号
                Text("\(number)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.gray)
                
                // 物語の文章
                Text(storyText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 30)
            }
        }
        .ignoresSafeArea()
    }
    
    // ページ番号に応じた物語の文章
    private var storyText: String {
        switch number {
        case 1: return "むかしむかし、あるところに小さな村がありました。\n\nその村には不思議な力を持つ子どもが住んでいました。"
        case 2: return "ある日、子どもは大きな冒険に出ることを決心しました。\n\n森の奥には誰も見たことのない世界が広がっていると聞いたからです。"
        case 3: return "森の中で、子どもは不思議な生き物に出会いました。\n\nその生き物は優しく、道を教えてくれました。"
        case 4: return "旅の途中、大きな試練が待っていました。\n\nでも、勇気と友情の力で乗り越えることができました。"
        case 5: return "そして子どもは村に帰り、みんなに冒険の話を聞かせました。\n\nめでたし、めでたし。"
        default: return "お話の続きは..."
        }
    }
}

// 3) 実行ビュー：右端/左端をスワイプしてめくる
struct ModernMinimalPageCurlDemoWrapper: View {
    var body: some View {
        ModernPageCurlWrapper(pages: [
            ModernDemoPageWrapper(number: 1),
            ModernDemoPageWrapper(number: 2),
            ModernDemoPageWrapper(number: 3),
            ModernDemoPageWrapper(number: 4),
            ModernDemoPageWrapper(number: 5)
        ])
        .navigationBarBackButtonHidden(true) // 戻るスワイプと競合しないように
    }
}

// 4) 画面中央に本（固定サイズ）を置いて、その中だけが捲れるデモ
struct CenterBookCurlDemoWrapper: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 本のサイズをもっと大きく（アスペクト比 3:5 程度で縦長に）
                let bookWidth = min(geo.size.width * 0.95, 800)  // 85% → 95%に変更、最大幅も800pxに
                let bookHeight = bookWidth * (5.0/3.0)  // 4:3 → 5:3に変更で縦長に

                ZStack {
                    // 本の表紙（コンテナの背景）
                    RoundedRectangle(cornerRadius: 16)  // 角丸も少し大きく
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color(red: 0.985, green: 0.98, blue: 0.965)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 15)  // 影も少し大きく

                    // ページカールはこのフレーム内でのみ表示
                    ModernPageCurlWrapper(pages: [
                        ModernDemoPageWrapper(number: 1),
                        ModernDemoPageWrapper(number: 2),
                        ModernDemoPageWrapper(number: 3),
                        ModernDemoPageWrapper(number: 4),
                        ModernDemoPageWrapper(number: 5)
                    ])
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .frame(width: bookWidth, height: bookHeight)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)  // 画面の中央に配置
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ZStack {
        // 星空のような背景色
        LinearGradient(
            colors: [
                Color(red: 0.5, green: 0.2, blue: 0.6),  // purple-900
                Color(red: 0.1, green: 0.2, blue: 0.6),  // blue-900
                Color(red: 0.2, green: 0.1, blue: 0.5)   // indigo-900
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 24) {
            Text("中央に本だけが捲れる")
                .font(.headline)
                .foregroundColor(.white)
            CenterBookCurlDemoWrapper()
                .frame(height: 800)  // 縦長に合わせて高さも調整
        }
        .padding()
    }
}
