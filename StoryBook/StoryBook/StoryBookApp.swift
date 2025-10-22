import SwiftUI

@main
struct StoryBookApp: App {
    // ← これでAppDelegateを有効化（Auth0の復帰URLを受け取れるようにする）
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // アプリ起動時にカスタムフォントを登録（あなたの既存処理を保持）
        FontRegistration.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            // ルートは現状のまま ContentView でOK（LoginViewでも可）
            TopView()
                .font(.yuseiMagicBody) // アプリ全体のデフォルトフォントを設定
        }
    }
}
