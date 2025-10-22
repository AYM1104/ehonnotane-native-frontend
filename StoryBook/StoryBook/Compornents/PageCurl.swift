import SwiftUI
import UIKit

// ページカール効果を提供する汎用コンポーネント
struct PageCurl<Content: View>: UIViewControllerRepresentable {
    var pages: [Content]
    @Binding var currentIndex: Int

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(transitionStyle: .pageCurl,
                                       navigationOrientation: .horizontal,
                                       options: nil)
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator
        pvc.view.backgroundColor = .clear // 背景を透明に
        
        context.coordinator.controllers = pages.map {
            let host = UIHostingController(rootView: $0)
            host.view.backgroundColor = .clear
            // 角丸の背景を設定
            host.view.layer.cornerRadius = 35
            host.view.layer.masksToBounds = false // masksToBoundsをfalseに変更
            
            // TextFieldとMenuが正しく動作するように設定
            host.view.isUserInteractionEnabled = true
            host.view.isMultipleTouchEnabled = true
            
            return host
        }
        
        let initialIndex = max(0, min(currentIndex, context.coordinator.controllers.count - 1))
        if context.coordinator.controllers.indices.contains(initialIndex) {
            pvc.setViewControllers([context.coordinator.controllers[initialIndex]], 
                                   direction: .forward, animated: false)
        }
        pvc.isDoubleSided = false // 片面のみ表示
        
        // ページカールの背景を透明に設定
        DispatchQueue.main.async {
            // UIPageViewControllerの内部ビューを透明に
            for subview in pvc.view.subviews {
                if subview.isKind(of: UIScrollView.self) {
                    subview.backgroundColor = .clear
                }
                // さらに深い階層も透明に
                for subSubview in subview.subviews {
                    subSubview.backgroundColor = .clear
                }
            }
        }
        
        return pvc
    }

    func updateUIViewController(_ pvc: UIPageViewController, context: Context) {
        let controllers = context.coordinator.controllers
        let safeIndex = max(0, min(currentIndex, controllers.count - 1))
        if let visible = pvc.viewControllers?.first,
           let visibleIndex = controllers.firstIndex(of: visible),
           visibleIndex != safeIndex,
           controllers.indices.contains(safeIndex) {
            pvc.setViewControllers([controllers[safeIndex]], 
                                   direction: safeIndex > visibleIndex ? .forward : .reverse, 
                                   animated: true)
        }
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageCurl
        var controllers: [UIViewController] = []
        init(_ parent: PageCurl) { self.parent = parent }

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
        
        func pageViewController(_ pageViewController: UIPageViewController, 
                                didFinishAnimating finished: Bool, 
                                previousViewControllers: [UIViewController], 
                                transitionCompleted completed: Bool) {
            guard completed, let current = pageViewController.viewControllers?.first,
                  let idx = controllers.firstIndex(of: current) else { return }
            parent.currentIndex = idx
        }
    }
}
