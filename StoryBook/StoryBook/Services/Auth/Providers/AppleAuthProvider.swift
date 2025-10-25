import SwiftUI
import Combine

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Apple認証プロバイダー
class AppleAuthProvider: NSObject, ObservableObject, AuthProviderProtocol {
    
    // MARK: - 認証状態管理
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false
    
    // MARK: - ユーザー情報
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    @Published var userName: String?
    
    // MARK: - トークン管理
    private let tokenManager = TokenManager()
    
    // MARK: - パブリックメソッド
    
    /// Apple Sign Inを実行
    func login(completion: @escaping (AuthResult) -> Void) {
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
        
        // コールバックを保存
        self.loginCompletion = completion
        
        authorizationController.performRequests()
        
        #else
        errorMessage = "AuthenticationServicesモジュールが利用できません"
        completion(AuthResult(success: false, provider: .apple, error: NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "AuthenticationServicesモジュールが利用できません"])))
        #endif
    }
    
    /// Apple Sign Outを実行（実際にはAppleでは完全なログアウトはできない）
    func logout(completion: @escaping (Bool) -> Void) {
        print("🍎 Apple Sign Out（状態をクリア）")
        clearAuthState()
        completion(true)
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
    
    // MARK: - プライベートプロパティ
    private var loginCompletion: ((AuthResult) -> Void)?
    
    // MARK: - プライベートメソッド
    
    /// 認証状態を確認
    private func checkSignInState() {
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
    
    /// 認証状態をクリア
    private func clearAuthState() {
        isLoggedIn = false
        userIdentifier = nil
        userEmail = nil
        userName = nil
        errorMessage = nil
        tokenManager.clearAllTokens()
    }
}

// MARK: - ASAuthorizationControllerDelegate
#if canImport(AuthenticationServices)
extension AppleAuthProvider: ASAuthorizationControllerDelegate {
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
            
            // UserInfoオブジェクトを作成
            let userInfo = UserInfo(
                id: userIdentifier,
                email: email,
                name: displayName,
                picture: nil
            )
            
            // コールバックを実行
            loginCompletion?(AuthResult(
                success: true,
                provider: .apple,
                userInfo: userInfo
            ))
            
        } else {
            errorMessage = "Apple認証情報の取得に失敗しました"
            print("❌ Apple Sign Inエラー: 認証情報の型が不正")
            
            loginCompletion?(AuthResult(
                success: false,
                provider: .apple,
                error: NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Apple認証情報の取得に失敗しました"])
            ))
        }
        
        // コールバックをクリア
        loginCompletion = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        errorMessage = "Apple Sign Inに失敗しました: \(error.localizedDescription)"
        print("❌ Apple Sign Inエラー: \(error)")
        
        loginCompletion?(AuthResult(
            success: false,
            provider: .apple,
            error: error
        ))
        
        // コールバックをクリア
        loginCompletion = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleAuthProvider: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 現在のウィンドウを返す
        #if canImport(UIKit)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("ウィンドウが見つかりません")
        }
        return window
        #else
        fatalError("UIKitが利用できません")
        #endif
    }
}
#endif
