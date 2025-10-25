import SwiftUI
import Combine

#if canImport(Auth0)
import Auth0
#endif

// MARK: - Google認証プロバイダー
class GoogleAuthProvider: ObservableObject, AuthProviderProtocol {
    
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
    
    // MARK: - トークン管理
    private let tokenManager = TokenManager()
    
    // MARK: - パブリックメソッド
    
    /// Googleログインを実行
    func login(completion: @escaping (AuthResult) -> Void) {
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
                    self?.handleAuthResult(result, completion: completion)
                }
            }
        #else
        errorMessage = "Auth0モジュールが利用できません"
        completion(AuthResult(success: false, provider: .google, error: NSError(domain: "Auth0", code: -1, userInfo: [NSLocalizedDescriptionKey: "Auth0モジュールが利用できません"])))
        #endif
    }
    
    /// Googleログアウトを実行
    func logout(completion: @escaping (Bool) -> Void) {
        #if canImport(Auth0)
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .clearSession(federated: false) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.clearAuthState()
                        print("✅ Googleログアウト完了")
                        completion(true)
                        
                    case .failure(let error):
                        self?.errorMessage = "Googleログアウトに失敗しました: \(error.localizedDescription)"
                        print("❌ Googleログアウトエラー: \(error)")
                        completion(false)
                    }
                }
            }
        #else
        errorMessage = "Auth0モジュールが利用できません"
        completion(false)
        #endif
    }
    
    /// トークンの有効性を確認
    func verifyToken() -> Bool {
        return tokenManager.isAccessTokenValid()
    }
    
    // MARK: - プライベートメソッド
    
    /// 認証結果を処理
    #if canImport(Auth0)
    private func handleAuthResult(_ result: Auth0.WebAuthResult<Auth0.Credentials>, completion: @escaping (AuthResult) -> Void) {
        isLoading = false
        
        switch result {
        case .success(let credentials):
            isLoggedIn = true
            errorMessage = nil
            
            // トークンを保存
            tokenManager.saveToken(credentials.accessToken, type: .accessToken)
            tokenManager.saveToken(credentials.idToken, type: .idToken)
            
            print("🔍 handleAuthResult: 認証成功")
            
            // IDトークンからユーザー情報を取得
            let userInfo = extractUserInfoFromIdToken(credentials.idToken)
            
            print("✅ Googleログイン成功")
            print("Access Token: \(credentials.accessToken)")
            print("ID Token: \(credentials.idToken)")
            
            // Supabaseにユーザー情報を登録
            if let userInfo = userInfo {
                Task {
                    await registerUserToSupabase(userInfo: userInfo)
                }
            }
            
            completion(AuthResult(
                success: true,
                provider: .google,
                accessToken: credentials.accessToken,
                idToken: credentials.idToken,
                userInfo: userInfo
            ))
            
        case .failure(let error):
            isLoggedIn = false
            errorMessage = "Googleログインに失敗しました: \(error)"
            print("❌ Googleログインエラー詳細: \(error)")
            print("❌ エラータイプ: \(type(of: error))")
            
            completion(AuthResult(
                success: false,
                provider: .google,
                error: error
            ))
        }
    }
    #endif
    
    /// IDトークンからユーザー情報を抽出
    private func extractUserInfoFromIdToken(_ idToken: String) -> UserInfo? {
        print("🔍 extractUserInfoFromIdToken開始")
        
        // JWTのペイロード部分をデコード（簡易実装）
        // 実際の実装では、JWTライブラリを使用することを推奨
        let tokenParts = idToken.components(separatedBy: ".")
        print("🔍 JWTトークン解析: \(tokenParts.count) parts")
        
        if tokenParts.count >= 2 {
            // Base64URLデコード（パディングを追加）
            var payloadString = tokenParts[1]
            let remainder = payloadString.count % 4
            if remainder > 0 {
                payloadString += String(repeating: "=", count: 4 - remainder)
            }
            
            print("🔍 デコード対象: \(payloadString)")
            
            if let data = Data(base64Encoded: payloadString),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("✅ JWTデコード成功")
                
                // Auth0のユーザーID（sub）を取得
                let auth0UserId = json["sub"] as? String
                let userEmail = json["email"] as? String
                let userName = json["name"] as? String
                let userPicture = json["picture"] as? String
                
                print("📧 Googleユーザー情報取得:")
                print("  UserID: \(auth0UserId ?? "なし")")
                print("  Email: \(userEmail ?? "なし")")
                print("  Name: \(userName ?? "なし")")
                print("  Picture: \(userPicture ?? "なし")")
                
                guard let userId = auth0UserId else {
                    print("❌ Auth0ユーザーIDが取得できません")
                    return nil
                }
                
                return UserInfo(
                    id: userId,
                    email: userEmail,
                    name: userName,
                    picture: userPicture
                )
            } else {
                print("❌ JWTデコード失敗")
            }
        } else {
            print("❌ JWTトークン形式エラー: パーツ数不足")
        }
        
        return nil
    }
    
    /// Supabaseにユーザー情報を登録
    private func registerUserToSupabase(userInfo: UserInfo) async {
        let baseURL = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://192.168.3.93:8000"
        
        guard let url = URL(string: "\(baseURL)/users/") else {
            print("❌ Supabaseユーザー登録URLエラー")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // リクエストボディを作成（Auth0のユーザーIDを主キーとして使用）
        let userData: [String: Any] = [
            "id": userInfo.id,  // Auth0のユーザーIDをSupabaseの主キーとして使用
            "user_name": userInfo.name ?? "",
            "email": userInfo.email ?? ""
        ]
        
        // リクエストボディのデバッグ出力
        if let jsonData = try? JSONSerialization.data(withJSONObject: userData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Supabaseユーザー登録リクエスト: \(jsonString)")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: userData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Supabaseユーザー登録レスポンス: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Supabaseユーザー登録レスポンスボディ: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    print("✅ Supabaseユーザー登録成功")
                } else if httpResponse.statusCode == 400 {
                    // 400エラーは「Email already registered」の場合、正常な動作として扱う
                    print("ℹ️ ユーザーは既に登録済み - 正常な動作")
                } else {
                    print("❌ Supabaseユーザー登録エラー: \(httpResponse.statusCode)")
                }
            } else {
                print("❌ 無効なレスポンス")
            }
        } catch {
            print("❌ Supabaseユーザー登録通信エラー: \(error.localizedDescription)")
        }
    }
    
    /// 認証状態をクリア
    private func clearAuthState() {
        isLoggedIn = false
        errorMessage = nil
        tokenManager.clearAllTokens()
    }
}
