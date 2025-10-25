import SwiftUI
import Combine

// MARK: - 認証状態管理
public class AuthManager: ObservableObject {
    
    // MARK: - 認証状態
    @Published var isLoggedIn = false
    @Published var currentProvider: AuthProvider?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // MARK: - ユーザー情報
    @Published var userInfo: UserInfo?
    
    // MARK: - マネージャー
    private let tokenManager = TokenManager()
    private let userInfoManager = UserInfoManager()
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初期化
    public init() {
        setupBindings()
        loadSavedAuthState()
    }
    
    // MARK: - パブリックメソッド
    
    /// 認証結果を処理
    func handleAuthResult(_ result: AuthResult) {
        isLoading = false
        
        if result.success {
            isLoggedIn = true
            currentProvider = result.provider
            errorMessage = nil
            
            // トークンを保存
            if let accessToken = result.accessToken {
                tokenManager.saveToken(accessToken, type: .accessToken)
            }
            if let idToken = result.idToken {
                tokenManager.saveToken(idToken, type: .idToken)
            }
            
            // ユーザー情報を保存
            if let userInfo = result.userInfo {
                userInfoManager.saveUserInfo(userInfo)
                self.userInfo = userInfo
            }
            
            print("✅ 認証成功: \(result.provider.displayName)")
        } else {
            isLoggedIn = false
            currentProvider = nil
            errorMessage = result.error?.localizedDescription ?? "認証に失敗しました"
            
            print("❌ 認証失敗: \(result.provider.displayName) - \(errorMessage ?? "")")
        }
    }
    
    /// ログアウト
    func logout() {
        isLoggedIn = false
        currentProvider = nil
        errorMessage = nil
        userInfo = nil
        
        // トークンとユーザー情報をクリア
        tokenManager.clearAllTokens()
        userInfoManager.clearUserInfo()
        
        print("✅ ログアウト完了")
    }
    
    /// アクセストークンを設定
    func setAccessToken(_ token: String?) {
        if let token = token {
            tokenManager.saveToken(token, type: .accessToken)
        }
    }
    
    /// アクセストークンを取得
    func getAccessToken() -> String? {
        return tokenManager.getToken(type: .accessToken)
    }
    
    /// 現在のユーザーIDを取得
    func getCurrentUserId() -> String? {
        return userInfo?.id
    }
    
    /// 認証状態を確認
    func verifyAuthState() -> Bool {
        return isLoggedIn && tokenManager.isAccessTokenValid()
    }
    
    /// トークンリフレッシュの必要性をチェック
    func shouldRefreshToken() -> Bool {
        return tokenManager.shouldRefreshToken()
    }
    
    /// リフレッシュトークンが存在するかチェック
    func hasRefreshToken() -> Bool {
        return tokenManager.hasRefreshToken()
    }
    
    /// トークンリフレッシュを試行
    func attemptTokenRefresh() async -> Bool {
        print("🔄 AuthManager: トークンリフレッシュを試行中...")
        
        // リフレッシュトークンが存在しない場合は失敗
        guard hasRefreshToken() else {
            print("❌ AuthManager: リフレッシュトークンが存在しません")
            return false
        }
        
        // 注意: 実際のリフレッシュ処理は認証プロバイダーに依存します
        // 現在はログ出力のみで、実際のリフレッシュAPI呼び出しは実装されていません
        
        print("⚠️ AuthManager: トークンリフレッシュ機能は未実装です")
        print("   実際の実装では、認証プロバイダー（Google/Apple/Auth0）の")
        print("   リフレッシュAPIを呼び出す必要があります")
        
        return false
    }
    
    // MARK: - プライベートメソッド
    
    /// バインディングを設定
    private func setupBindings() {
        // UserInfoManagerの変更を監視
        userInfoManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userInfo in
                self?.userInfo = userInfo
            }
            .store(in: &cancellables)
    }
    
    /// 保存された認証状態を読み込み
    private func loadSavedAuthState() {
        // ユーザー情報を復元
        if let savedUserInfo = userInfoManager.getUserInfo() {
            userInfo = savedUserInfo
            
            // トークンの有効性をチェック
            if tokenManager.isAccessTokenValid() {
                isLoggedIn = true
                // プロバイダーは保存されていないため、デフォルトでGoogleとする
                currentProvider = .google
                print("✅ 保存された認証状態を復元")
            } else {
                // トークンが無効な場合はクリア
                logout()
                print("⚠️ 無効なトークンのため認証状態をクリア")
            }
        }
    }
}

// MARK: - 認証状態の拡張
extension AuthManager {
    /// ユーザー表示名を取得
    var displayName: String {
        return userInfo?.displayName ?? "ゲスト"
    }
    
    /// ログイン状態の文字列表現
    var loginStatusText: String {
        if isLoading {
            return "ログイン中..."
        } else if isLoggedIn {
            let provider = currentProvider?.displayName ?? "認証"
            return "\(provider)ログイン済み (\(displayName))"
        } else {
            return "未ログイン"
        }
    }
    
    /// 現在のプロバイダーのアイコン名
    var currentProviderIcon: String {
        return currentProvider?.iconName ?? "person.circle.fill"
    }
}
