import SwiftUI
import Combine

// MARK: - 認証プロバイダーを管理するメインサービス
class AuthService: ObservableObject {
    
    // MARK: - 認証状態管理
    @Published var authManager = AuthManager()
    
    // MARK: - 認証プロバイダーサービス
    private let googleProvider: GoogleAuthProvider
    private let appleProvider: AppleAuthProvider
    private let emailProvider: EmailAuthProvider
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初期化
    init() {
        self.googleProvider = GoogleAuthProvider()
        self.appleProvider = AppleAuthProvider()
        self.emailProvider = EmailAuthProvider()
        
        bindAuthManager()
        setupProviderBindings()
    }
    
    // MARK: - パブリックメソッド
    
    /// Googleログイン
    func loginWithGoogle() {
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        googleProvider.login { [weak self] result in
            self?.authManager.handleAuthResult(result)
        }
    }
    
    /// Apple Sign In
    func signInWithApple() {
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        appleProvider.login { [weak self] result in
            self?.authManager.handleAuthResult(result)
        }
    }
    
    /// メール/パスワードログイン
    func loginWithEmail() {
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        emailProvider.login { [weak self] result in
            self?.authManager.handleAuthResult(result)
        }
    }
    
    /// ログアウト
    func logout() {
        guard let currentProvider = authManager.currentProvider else {
            authManager.logout()
            return
        }
        
        switch currentProvider {
        case .google:
            googleProvider.logout { [weak self] success in
                self?.authManager.logout()
                print("Googleログアウト完了: \(success)")
            }
        case .apple:
            appleProvider.logout { [weak self] success in
                self?.authManager.logout()
                print("Appleログアウト完了: \(success)")
            }
        case .email:
            emailProvider.logout { [weak self] success in
                self?.authManager.logout()
                print("メールログアウト完了: \(success)")
            }
        }
    }
    
    /// トークンの有効性を確認
    func verifyToken() -> Bool {
        return authManager.verifyAuthState()
    }
    
    /// アクセストークンを取得
    func getAccessToken() -> String? {
        return authManager.getAccessToken()
    }
    
    /// 現在のユーザーIDを取得
    func getCurrentUserId() -> String? {
        return authManager.getCurrentUserId()
    }
    
    // MARK: - プライベートメソッド
    
    /// プロバイダーの状態を監視
    private func setupProviderBindings() {
        // Googleプロバイダーの状態を監視
        googleProvider.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.authManager.isLoading = true
                }
            }
            .store(in: &cancellables)
        
        googleProvider.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.authManager.errorMessage = error
                    self?.authManager.isLoading = false
                }
            }
            .store(in: &cancellables)
        
        // Appleプロバイダーの状態を監視
        appleProvider.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.authManager.isLoading = true
                }
            }
            .store(in: &cancellables)
        
        appleProvider.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.authManager.errorMessage = error
                    self?.authManager.isLoading = false
                }
            }
            .store(in: &cancellables)
        
        // メールプロバイダーの状態を監視
        emailProvider.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.authManager.isLoading = true
                }
            }
            .store(in: &cancellables)
        
        emailProvider.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.authManager.errorMessage = error
                    self?.authManager.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
    
    /// AuthManagerの変更をAuthServiceでも検知できるようにする
    private func bindAuthManager() {
        authManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
