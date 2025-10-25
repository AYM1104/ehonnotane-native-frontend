import SwiftUI
import Combine

/// AuthServiceのプレビュー用テストビュー
struct AuthServicePreviewView: View {
    // @StateObject private var authService = AuthService()
    
    // 一時的なモックデータ（AuthServiceが認識されるまでの代替）
    @State private var isLoggedIn = false
    @State private var isLoading = false
    @State private var userEmail: String?
    @State private var userName: String?
    @State private var errorMessage: String?
    @State private var accessToken: String?
    @State private var idToken: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // ヘッダー
                Text("AuthService テスト")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 認証状態表示
                VStack(alignment: .leading, spacing: 10) {
                    Text("認証状態")
                        .font(.headline)
                    
                    Text("ログイン状態: \(isLoggedIn ? "ログイン済み" : "未ログイン")")
                        .foregroundColor(isLoggedIn ? .green : .red)
                    
                    Text("読み込み中: \(isLoading ? "はい" : "いいえ")")
                        .foregroundColor(isLoading ? .orange : .blue)
                    
                    if let email = userEmail {
                        Text("メール: \(email)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let name = userName {
                        Text("名前: \(name)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let error = errorMessage {
                        Text("エラー: \(error)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // アクションボタン
                VStack(spacing: 15) {
                    Button("Auth0ログイン") {
                        // authService.loginWithAuth0()
                        print("Auth0ログインボタンがタップされました")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    Button("Googleログイン") {
                        // authService.loginWithGoogle()
                        print("Googleログインボタンがタップされました")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)
                    
                    if isLoggedIn {
                        Button("ログアウト") {
                            // authService.logout()
                            print("ログアウトボタンがタップされました")
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    
                    Button("トークン検証") {
                        // let isValid = authService.verifyToken()
                        print("トークン検証ボタンがタップされました")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isLoggedIn)
                }
                
                // トークン情報（デバッグ用）
                if isLoggedIn {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("トークン情報（デバッグ用）")
                            .font(.headline)
                        
                        if let accessToken = accessToken {
                            Text("Access Token: \(String(accessToken.prefix(50)))...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let idToken = idToken {
                            Text("ID Token: \(String(idToken.prefix(50)))...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("AuthService テスト")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

/*
#Preview {
    AuthServicePreviewView()
}
*/
