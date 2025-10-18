#if canImport(UIKit)
import UIKit

#if canImport(Auth0)
import Auth0

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Auth0のURL処理（最新のSDKではWebAuth.startの結果を処理）
        // 注意: 最新のAuth0 Swift SDKでは、URL処理はWebAuth.startメソッド内で自動的に処理されます
        // このメソッドは主に他のURLスキームの処理用として残しています
        return false
    }
}
#else
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Auth0モジュールが利用できない場合
        return false
    }
}
#endif
#endif