import SwiftUI
import Combine

#if canImport(Auth0)
import Auth0
#endif

/// Google OAuth認証サービス
class GoogleOAuthService: ObservableObject {
    
    // MARK: - Auth0設定
    #if canImport(Auth0)
    private let domain = "ehonnotane.jp.auth0.com"
    private let clientId = "b1sTk9gTW2rjddFtvu0w7ZrsFYk2ldfh"
    private let audience = "https://api.ehonnotane"
    #endif
    
    // MARK: - 認証状態管理
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    @Published var accessToken: String?
    @Published var idToken: String?
    
    // MARK: - ユーザー情報
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var userPicture: String?
    
    // MARK: - パブリックメソッド
    
    /// Googleログインを実行
    func login() {
        #if canImport(Auth0)
        isLoading = true
        errorMessage = nil
        
        print("🔍 Googleログイン開始")
        print("🔍 Domain: \(domain)")
        print("🔍 Client ID: \(clientId)")
        print("🔍 Audience: \(audience)")
        
        // Auth0のUniversal LoginでGoogleプロバイダーを指定
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .scope("openid profile email")
            .audience(audience)
            .parameters(["connection": "google-oauth2"]) // Googleプロバイダーを指定
            .start { [weak self] result in
                DispatchQueue.main.async {
                    self?.handleAuthResult(result)
                }
            }
        #else
        errorMessage = "Auth0モジュールが利用できません"
        #endif
    }
    
    /// Googleログアウトを実行
    func logout() {
        #if canImport(Auth0)
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .clearSession(federated: false) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.clearAuthState()
                        print("✅ Googleログアウト完了")
                        
                    case .failure(let error):
                        self?.errorMessage = "Googleログアウトに失敗しました: \(error.localizedDescription)"
                        print("❌ Googleログアウトエラー: \(error)")
                    }
                }
            }
        #else
        errorMessage = "Auth0モジュールが利用できません"
        #endif
    }
    
    /// トークンの有効性を確認
    func verifyToken() -> Bool {
        guard let token = accessToken, !token.isEmpty else {
            return false
        }
        
        // 簡単なトークン存在チェック
        // 実際の実装では、JWTの有効期限もチェックすることを推奨
        return true
    }
    
    // MARK: - プライベートメソッド
    
    /// 認証結果を処理
    #if canImport(Auth0)
    private func handleAuthResult(_ result: Auth0.WebAuthResult<Auth0.Credentials>) {
        isLoading = false
        
        switch result {
        case .success(let credentials):
            isLoggedIn = true
            accessToken = credentials.accessToken
            idToken = credentials.idToken
            errorMessage = nil
            
            // IDトークンからユーザー情報を取得
            extractUserInfoFromIdToken(credentials.idToken)
            
            print("✅ Googleログイン成功")
            print("Access Token: \(credentials.accessToken)")
            print("ID Token: \(credentials.idToken)")
            
        case .failure(let error):
            isLoggedIn = false
            accessToken = nil
            idToken = nil
            errorMessage = "Googleログインに失敗しました: \(error)"
            print("❌ Googleログインエラー詳細: \(error)")
            print("❌ エラータイプ: \(type(of: error))")
        }
    }
    #endif
    
    /// IDトークンからユーザー情報を抽出
    private func extractUserInfoFromIdToken(_ idToken: String) {
        // JWTのペイロード部分をデコード（簡易実装）
        // 実際の実装では、JWTライブラリを使用することを推奨
        if let data = Data(base64Encoded: idToken.components(separatedBy: ".")[1]),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            userEmail = json["email"] as? String
            userName = json["name"] as? String
            userPicture = json["picture"] as? String
            
            print("📧 Googleユーザー情報取得:")
            print("  Email: \(userEmail ?? "なし")")
            print("  Name: \(userName ?? "なし")")
            print("  Picture: \(userPicture ?? "なし")")
        }
    }
    
    /// 認証状態をクリア
    private func clearAuthState() {
        isLoggedIn = false
        accessToken = nil
        idToken = nil
        errorMessage = nil
        userEmail = nil
        userName = nil
        userPicture = nil
    }
}

// MARK: - GoogleOAuthServiceの拡張
extension GoogleOAuthService {
    /// ユーザー表示名を取得
    var displayName: String {
        return userName ?? userEmail ?? "Googleユーザー"
    }
    
    /// ログイン状態の文字列表現
    var loginStatusText: String {
        if isLoading {
            return "Googleログイン中..."
        } else if isLoggedIn {
            return "Googleログイン済み (\(displayName))"
        } else {
            return "Google未ログイン"
        }
    }
}
