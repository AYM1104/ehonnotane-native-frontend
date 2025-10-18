import SwiftUI
import Combine

#if canImport(Auth0)
import Auth0
#endif

/// 認証プロバイダーの種類
enum AuthProvider: String, CaseIterable {
    case google = "google"
    case apple = "apple"
    case email = "email"
    
    var displayName: String {
        switch self {
        case .google:
            return "Google"
        case .apple:
            return "Apple"
        case .email:
            return "メール"
        }
    }
    
    var iconName: String {
        switch self {
        case .google:
            return "g.circle.fill"
        case .apple:
            return "applelogo"
        case .email:
            return "envelope.circle.fill"
        }
    }
}

/// 認証状態を管理するObservableObject
class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentProvider: AuthProvider?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    // ユーザー情報（統合）
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var userPicture: String?
    @Published var userIdentifier: String?
    @Published var auth0UserId: String?  // Auth0のユーザーID（sub）
}

/// 認証プロバイダーを管理するメインサービス
class AuthService: ObservableObject {
    
    // MARK: - 認証状態管理
    @Published var authManager = AuthManager()
    
    // MARK: - 認証プロバイダーサービス
    // プロジェクトに追加後に有効化
    // @Published var googleService = GoogleOAuthService()
    // @Published var appleService = AppleSignInService()
    
    // MARK: - パブリックメソッド
    
    /// Googleログイン
    func loginWithGoogle() {
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        // googleService.login()
        // observeGoogleService()
        
        // 一時的なモック実装
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.authManager.isLoading = false
            self.authManager.isLoggedIn = true
            self.authManager.currentProvider = .google
            self.authManager.userEmail = "test@google.com"
            self.authManager.userName = "Google User"
            print("✅ Googleログイン（モック）成功")
        }
    }
    
    /// Apple Sign In
    func signInWithApple() {
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        // appleService.signIn()
        // observeAppleService()
        
        // 一時的なモック実装
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.authManager.isLoading = false
            self.authManager.isLoggedIn = true
            self.authManager.currentProvider = .apple
            self.authManager.userEmail = "test@apple.com"
            self.authManager.userName = "Apple User"
            print("✅ Apple Sign In（モック）成功")
        }
    }
    
    /// メール/パスワードログイン（Auth0）
    func loginWithEmail() {
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        // Auth0の通常ログインを実装
        loginWithAuth0()
    }
    
    /// ログアウト
    func logout() {
        guard let currentProvider = authManager.currentProvider else {
            clearAuthState()
            return
        }
        
        switch currentProvider {
        case .google:
            // googleService.logout()
            print("Googleログアウト（モック）")
        case .apple:
            // appleService.signOut()
            print("Appleログアウト（モック）")
        case .email:
            logoutFromAuth0()
        }
        
        clearAuthState()
    }
    
    /// トークンの有効性を確認
    func verifyToken() -> Bool {
        return authManager.isLoggedIn
    }
    
    // MARK: - プライベートメソッド
    
    // GoogleサービスとAppleサービスの監視メソッドは、プロジェクトに追加後に有効化
    /*
    private func observeGoogleService() { ... }
    private func observeAppleService() { ... }
    */
    
    /// Auth0の通常ログイン（メール/パスワード）
    private func loginWithAuth0() {
        #if canImport(Auth0)
        Auth0
            .webAuth(clientId: "b1sTk9gTW2rjddFtvu0w7ZrsFYk2ldfh", domain: "ehonnotane.jp.auth0.com")
            .scope("openid profile email")
            .audience("https://api.ehonnotane")
            .start { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleAuth0Result(result)
                }
            }
        #else
        authManager.errorMessage = "Auth0モジュールが利用できません"
        #endif
    }
    
    /// Auth0のログアウト
    private func logoutFromAuth0() {
        #if canImport(Auth0)
        Auth0
            .webAuth(clientId: "b1sTk9gTW2rjddFtvu0w7ZrsFYk2ldfh", domain: "ehonnotane.jp.auth0.com")
            .clearSession(federated: false) { (result: Auth0.WebAuthResult<Void>) in
                print("Auth0ログアウト完了")
            }
        #endif
    }
    
    /// Auth0認証結果を処理
    #if canImport(Auth0)
    private func handleAuth0Result(_ result: Auth0.WebAuthResult<Auth0.Credentials>) {
        authManager.isLoading = false
        
        switch result {
        case .success(let credentials):
            authManager.isLoggedIn = true
            authManager.currentProvider = .email
            authManager.errorMessage = nil
            
            // ユーザー情報はGoogleOAuthServiceで処理される
            
            print("✅ Auth0ログイン成功")
            
        case .failure(let error):
            authManager.errorMessage = "Auth0ログインに失敗しました: \(error)"
            print("❌ Auth0ログインエラー: \(error)")
        }
    }
    #endif
    
    // extractUserInfoFromIdTokenメソッドはGoogleOAuthServiceに移動済み
    
    /// Supabaseにユーザー情報を登録
    private func registerUserToSupabase(auth0UserId: String, userName: String, email: String) async {
        let baseURL = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://localhost:8000"
        
        guard let url = URL(string: "\(baseURL)/users/") else {
            print("❌ Supabaseユーザー登録URLエラー")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // リクエストボディを作成（Auth0のユーザーIDを主キーとして使用）
        let userData: [String: Any] = [
            "id": auth0UserId,  // Auth0のユーザーIDをSupabaseの主キーとして使用
            "user_name": userName,
            "email": email
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: userData)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Supabaseユーザー登録成功: \(auth0UserId)")
                } else if httpResponse.statusCode == 400 {
                    print("ℹ️ ユーザーは既に登録済み: \(auth0UserId)")
                } else {
                    print("❌ Supabaseユーザー登録エラー: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ Supabaseユーザー登録通信エラー: \(error.localizedDescription)")
        }
    }
    
    /// 認証状態をクリア
    private func clearAuthState() {
        authManager.isLoggedIn = false
        authManager.currentProvider = nil
        authManager.errorMessage = nil
        authManager.userEmail = nil
        authManager.userName = nil
        authManager.userPicture = nil
        authManager.userIdentifier = nil
        authManager.auth0UserId = nil  // Auth0ユーザーIDもクリア
        authManager.isLoading = false
        
        // UserDefaultsからも削除
        UserDefaults.standard.removeObject(forKey: "auth0_user_id")
    }
    
    // MARK: - Combine
    // private var cancellables = Set<AnyCancellable>()
}

// MARK: - 認証状態の拡張
extension AuthManager {
    /// ユーザー表示名を取得
    var displayName: String {
        return userName ?? userEmail ?? "ゲスト"
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
    
    /// 現在のAuth0ユーザーIDを取得
    var currentAuth0UserId: String? {
        return auth0UserId ?? UserDefaults.standard.string(forKey: "auth0_user_id")
    }
}
