import SwiftUI

@main
struct StoryBookApp: App {
    // ← これでAppDelegateを有効化（Auth0の復帰URLを受け取れるようにする）
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // AppCoordinatorを状態オブジェクトとして管理
    @StateObject private var coordinator = AppCoordinator()

    init() {
        // アプリ起動時にカスタムフォントを登録（あなたの既存処理を保持）
        FontRegistration.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            // MainAppViewを使用して画面遷移を管理
            MainAppView()
                .environmentObject(coordinator) // AppCoordinatorを環境オブジェクトとして提供
                .font(.yuseiMagicBody) // アプリ全体のデフォルトフォントを設定
        }
    }
}
