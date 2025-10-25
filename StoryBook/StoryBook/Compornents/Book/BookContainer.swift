import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - UIPageViewController(.pageCurl) ラッパー

#if canImport(UIKit)
// UIPageViewController(.pageCurl) を用いた本格的なページカール（iOS）
public struct BookPageCurl<Content: View>: UIViewControllerRepresentable {
    public typealias UIViewControllerType = UIPageViewController
    let pages: [Content]
    @Binding var currentIndex: Int
    public init(pages: [Content], currentIndex: Binding<Int>) {
        self.pages = pages
        self._currentIndex = currentIndex
    }

    public func makeCoordinator() -> Coordinator { Coordinator(self) }

    public func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(transitionStyle: .pageCurl,
                                       navigationOrientation: .horizontal,
                                       options: nil)
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator
        pvc.view.backgroundColor = .clear

        context.coordinator.controllers = pages.map {
            let host = UIHostingController(rootView: $0)
            host.view.backgroundColor = .clear
            return host
        }
        let initialIndex = max(0, min(currentIndex, context.coordinator.controllers.count - 1))
        if context.coordinator.controllers.indices.contains(initialIndex) {
            pvc.setViewControllers([context.coordinator.controllers[initialIndex]], direction: .forward, animated: false)
        }
        pvc.isDoubleSided = false
        return pvc
    }

    public func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        let controllers = context.coordinator.controllers
        let safeIndex = max(0, min(currentIndex, controllers.count - 1))
        if let visible = uiViewController.viewControllers?.first,
           let visibleIndex = controllers.firstIndex(of: visible),
           visibleIndex != safeIndex,
           controllers.indices.contains(safeIndex) {
            uiViewController.setViewControllers([controllers[safeIndex]], direction: safeIndex > visibleIndex ? .forward : .reverse, animated: false)
        }
    }

    public final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: BookPageCurl
        var controllers: [UIViewController] = []
        init(_ parent: BookPageCurl) { self.parent = parent }

        public func pageViewController(_ p: UIPageViewController,
                                       viewControllerBefore vc: UIViewController) -> UIViewController? {
            guard let i = controllers.firstIndex(of: vc), i > 0 else { return nil }
            return controllers[i - 1]
        }
        public func pageViewController(_ p: UIPageViewController,
                                       viewControllerAfter vc: UIViewController) -> UIViewController? {
            guard let i = controllers.firstIndex(of: vc), i + 1 < controllers.count else { return nil }
            return controllers[i + 1]
        }
        public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            guard completed, let current = pageViewController.viewControllers?.first,
                  let idx = controllers.firstIndex(of: current) else { return }
            parent.currentIndex = idx
        }
    }
}
#else
// 非UIKit環境のフォールバック（TabViewページング）
public struct BookPageCurl<Content: View>: View {
    let pages: [Content]
    @Binding var current: Int
    public init(pages: [Content], currentIndex: Binding<Int>) {
        self.pages = pages
        self._current = currentIndex
    }
    public var body: some View {
        TabView(selection: $current) {
            ForEach(0..<pages.count, id: \.self) { i in
                pages[i].tag(i)
            }
        }
        #if os(iOS)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        #endif
    }
}
#endif

// MARK: - Book コンテナ（紙・角丸・影・クリップ）

/// 本コンテナの汎用コンポーネント
/// - セーフエリア考慮で可視領域の中央に配置
/// - 高さ割合とアスペクト比でサイズを決定
/// - 表紙（角丸・影・紙色）で中身をクリップ
/// - 任意でタイトル表示
public struct Book<Content: View>: View {
    public let pages: [Content]
    public let title: String?
    public let showTitle: Bool
    public let heightRatio: CGFloat      // 可視領域に対する高さ割合（例: 0.9）
    public let aspectRatio: CGFloat      // 幅:高さ（例: 10:16）
    public let cornerRadius: CGFloat
    public let paperColor: Color
    public let showProgressDots: Bool
    @State private var currentIndex: Int = 0
    @State private var dotPulse: Bool = false
    public let onPageChange: ((Int) -> Void)?

    public init(
        pages: [Content],
        title: String? = nil,
        showTitle: Bool = true,
        heightRatio: CGFloat = 0.9,
        aspectRatio: CGFloat = 10.0/16.0,
        cornerRadius: CGFloat = 16,
        paperColor: Color = Color(red: 252/255, green: 252/255, blue: 252/255),
        showProgressDots: Bool = true,
        onPageChange: ((Int) -> Void)? = nil
    ) {
        self.pages = pages
        self.title = title
        self.showTitle = showTitle
        self.heightRatio = heightRatio
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.paperColor = paperColor
        self.showProgressDots = showProgressDots
        self.onPageChange = onPageChange
    }

    public var body: some View {
        GeometryReader { geo in
            VStack(spacing: 8) {
                let insets = geo.safeAreaInsets
                let availableWidth = max(0, geo.size.width - insets.leading - insets.trailing)
                let availableHeight = max(0, geo.size.height - insets.top - insets.bottom)

                // タイトル表示（任意）
                if showTitle, let title, !title.isEmpty {
                    VStack(spacing: 0) {
                        Text(title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.top, insets.top + 8)
                            .padding(.bottom, 6)
                        Spacer()
                    }
                }

                // 本体サイズ（高さ優先）
                let desiredH = availableHeight * heightRatio
                let bookHeight = desiredH
                let bookWidth = geo.size.width

                ZStack {
                    // 紙（角丸 + 影）
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(paperColor)
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 15)

                    // 中身（ページカール／ページング）
                    BookPageCurl(pages: pages, currentIndex: $currentIndex)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .onChange(of: currentIndex) { newIndex in
                            onPageChange?(newIndex)
                        }
                }
                .frame(width: bookWidth, height: bookHeight)
                .frame(maxWidth: .infinity, alignment: .center)

            }
        }
    }
}
