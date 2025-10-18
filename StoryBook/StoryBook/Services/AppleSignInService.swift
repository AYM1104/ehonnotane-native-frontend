import SwiftUI
import Combine

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

/// Apple Sign In認証サービス
class AppleSignInService: NSObject, ObservableObject {
    
    // MARK: - 認証状態管理
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    @Published var userName: String?
    
    // MARK: - パブリックメソッド
    
    /// Apple Sign Inを実行
    func signIn() {
        #if canImport(AuthenticationServices)
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("🍎 Apple Sign In開始")
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
        
        #else
        errorMessage = "AuthenticationServicesモジュールが利用できません"
        #endif
    }
    
    /// Apple Sign Outを実行（実際にはAppleでは完全なログアウトはできない）
    func signOut() {
        print("🍎 Apple Sign Out（状態をクリア）")
        clearAuthState()
    }
    
    /// 認証状態を確認
    func checkSignInState() {
        #if canImport(AuthenticationServices)
        guard let userIdentifier = userIdentifier else {
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userIdentifier) { [weak self] credentialState, error in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
                    print("🍎 Apple認証状態: 認証済み")
                    self?.isLoggedIn = true
                case .revoked:
                    print("🍎 Apple認証状態: 取り消し済み")
                    self?.clearAuthState()
                case .notFound:
                    print("🍎 Apple認証状態: 見つからない")
                    self?.clearAuthState()
                default:
                    print("🍎 Apple認証状態: 不明")
                    self?.clearAuthState()
                }
            }
        }
        #endif
    }
    
    /// トークンの有効性を確認
    func verifyToken() -> Bool {
        guard let userIdentifier = userIdentifier, !userIdentifier.isEmpty else {
            return false
        }
        
        // Appleの認証状態をチェック
        checkSignInState()
        return isLoggedIn
    }
    
    // MARK: - プライベートメソッド
    
    /// 認証状態をクリア
    private func clearAuthState() {
        isLoggedIn = false
        userIdentifier = nil
        userEmail = nil
        userName = nil
        errorMessage = nil
    }
}

// MARK: - ASAuthorizationControllerDelegate
#if canImport(AuthenticationServices)
extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        isLoading = false
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // ユーザー情報を取得
            let userIdentifier = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            
            // 名前を組み立て
            var displayName: String?
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                displayName = "\(familyName) \(givenName)"
            } else if let givenName = fullName?.givenName {
                displayName = givenName
            } else if let familyName = fullName?.familyName {
                displayName = familyName
            }
            
            // 状態を更新
            self.userIdentifier = userIdentifier
            self.userEmail = email
            self.userName = displayName
            self.isLoggedIn = true
            self.errorMessage = nil
            
            print("✅ Apple Sign In成功")
            print("  User ID: \(userIdentifier)")
            print("  Email: \(email ?? "なし")")
            print("  Name: \(displayName ?? "なし")")
            
        } else {
            errorMessage = "Apple認証情報の取得に失敗しました"
            print("❌ Apple Sign Inエラー: 認証情報の型が不正")
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        errorMessage = "Apple Sign Inに失敗しました: \(error.localizedDescription)"
        print("❌ Apple Sign Inエラー: \(error)")
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 現在のウィンドウを返す
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("ウィンドウが見つかりません")
        }
        return window
    }
}
#endif

// MARK: - AppleSignInServiceの拡張
extension AppleSignInService {
    /// ユーザー表示名を取得
    var displayName: String {
        return userName ?? userEmail ?? "Appleユーザー"
    }
    
    /// ログイン状態の文字列表現
    var loginStatusText: String {
        if isLoading {
            return "Apple Sign In中..."
        } else if isLoggedIn {
            return "Apple Sign In済み (\(displayName))"
        } else {
            return "Apple未ログイン"
        }
    }
}
