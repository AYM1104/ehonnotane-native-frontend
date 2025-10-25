import Foundation

// MARK: - 認証プロバイダーの種類
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

// MARK: - 認証結果
struct AuthResult {
    let success: Bool
    let provider: AuthProvider
    let accessToken: String?
    let idToken: String?
    let userInfo: UserInfo?
    let error: Error?
    
    init(success: Bool, provider: AuthProvider, accessToken: String? = nil, idToken: String? = nil, userInfo: UserInfo? = nil, error: Error? = nil) {
        self.success = success
        self.provider = provider
        self.accessToken = accessToken
        self.idToken = idToken
        self.userInfo = userInfo
        self.error = error
    }
}

// MARK: - ユーザー情報
struct UserInfo {
    let id: String
    let email: String?
    let name: String?
    let picture: String?
    
    var displayName: String {
        return name ?? email ?? "ユーザー"
    }
}

// MARK: - トークンの種類
enum TokenType: String, CaseIterable {
    case accessToken = "access_token"
    case idToken = "id_token"
    case refreshToken = "refresh_token"
    
    var key: String {
        return "auth0_\(self.rawValue)"
    }
}
