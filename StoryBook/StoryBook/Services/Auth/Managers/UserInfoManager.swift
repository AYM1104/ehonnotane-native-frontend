import Foundation
import Combine

// MARK: - ユーザー情報管理
class UserInfoManager: ObservableObject {
    @Published var currentUser: UserInfo?
    
    private let keychain = KeychainManager()
    private let userDefaultsKey = "auth0_user_id"
    
    /// ユーザー情報を保存
    func saveUserInfo(_ userInfo: UserInfo) {
        currentUser = userInfo
        
        // UserDefaultsにユーザーIDを保存（後方互換性のため）
        UserDefaults.standard.set(userInfo.id, forKey: userDefaultsKey)
        
        print("✅ ユーザー情報保存完了: \(userInfo.displayName)")
    }
    
    /// ユーザー情報を取得
    func getUserInfo() -> UserInfo? {
        return currentUser
    }
    
    /// 現在のユーザーIDを取得
    func getCurrentUserId() -> String? {
        return currentUser?.id ?? UserDefaults.standard.string(forKey: userDefaultsKey)
    }
    
    /// ユーザー情報をクリア
    func clearUserInfo() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("🗑️ ユーザー情報クリア完了")
    }
    
    /// ユーザー表示名を取得
    var displayName: String {
        return currentUser?.displayName ?? "ゲスト"
    }
    
    /// ログイン状態を確認
    var isLoggedIn: Bool {
        return currentUser != nil
    }
}
