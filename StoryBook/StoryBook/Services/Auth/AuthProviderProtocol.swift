import Foundation
import Combine

// MARK: - 認証プロバイダープロトコル
protocol AuthProviderProtocol: ObservableObject {
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isLoggedIn: Bool { get }
    
    func login(completion: @escaping (AuthResult) -> Void)
    func logout(completion: @escaping (Bool) -> Void)
    func verifyToken() -> Bool
}
