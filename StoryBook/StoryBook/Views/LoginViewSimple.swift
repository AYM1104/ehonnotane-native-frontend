import SwiftUI

#if canImport(Auth0)
import Auth0
#endif

#if canImport(UIKit)
import UIKit
#endif

struct LoginViewSimple: View {
    // 認証サービス
    @StateObject private var authService = AuthService()
    @State private var navigateToUploadImage = false
    
    // 入力状態
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isFormValid: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // ロゴ
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .padding(.bottom, 20)
                    
                    // タイトル
                    Text("えほんのたね")
                        .font(.custom("YuseiMagic-Regular", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // ログインフォーム
                    VStack(spacing: 20) {
                        Text("ログイン")
                            .font(.custom("YuseiMagic-Regular", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // メールアドレス入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メールアドレス")
                                .font(.custom("YuseiMagic-Regular", size: 16))
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextField("メールアドレスを入力", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if canImport(UIKit)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                #endif
                                .onChange(of: email) {
                                    validateForm()
                                }
                        }
                        
                        // パスワード入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("パスワード")
                                .font(.custom("YuseiMagic-Regular", size: 16))
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack {
                                if isPasswordVisible {
                                    TextField("パスワードを入力", text: $password)
                                        .onChange(of: password) {
                                            validateForm()
                                        }
                                } else {
                                    SecureField("パスワードを入力", text: $password)
                                        .onChange(of: password) {
                                            validateForm()
                                        }
                                }
                                
                                Button(action: {
                                    isPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // エラーメッセージ
                        if let errorMessage = authService.authManager.errorMessage {
                            Text(errorMessage)
                                .font(.custom("YuseiMagic-Regular", size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        // ログインボタン
                        Button(action: {
                            authService.loginWithEmail()
                        }) {
                            if authService.authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("メールでログイン")
                                    .font(.custom("YuseiMagic-Regular", size: 20))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 16/255, green: 185/255, blue: 129/255),
                                    Color(red: 20/255, green: 184/255, blue: 166/255),
                                    Color(red: 6/255, green: 182/255, blue: 212/255)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .disabled(!isFormValid || authService.authManager.isLoading)
                        .opacity((isFormValid && !authService.authManager.isLoading) ? 1.0 : 0.6)
                        
                        // 区切り線
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("または")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 16)
                            
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        
                        // Googleログインボタン
                        Button(action: {
                            authService.loginWithGoogle()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "g.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Text("Googleでログイン")
                                    .font(.custom("YuseiMagic-Regular", size: 16))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.85, green: 0.85, blue: 0.85).opacity(0.2),
                                        Color(red: 0.75, green: 0.75, blue: 0.75).opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(authService.authManager.isLoading)
                        .opacity(authService.authManager.isLoading ? 0.6 : 1.0)
                        
                        // Apple Sign Inボタン
                        Button(action: {
                            authService.signInWithApple()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "applelogo")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .semibold))
                                
                                Text("Appleでサインイン")
                                    .font(.custom("YuseiMagic-Regular", size: 16))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.8),
                                        Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(authService.authManager.isLoading)
                        .opacity(authService.authManager.isLoading ? 0.6 : 1.0)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .background(
                // 非表示のNavigationLink（プレビュー用に簡易化）
                NavigationLink(value: navigateToUploadImage) {
                    EmptyView()
                }
                .navigationDestination(isPresented: $navigateToUploadImage) {
                    Text("アップロード画面（プレビュー）")
                }
            )
            .onChange(of: authService.authManager.isLoggedIn) {
                if authService.authManager.isLoggedIn {
                    navigateToUploadImage = true
                }
            }
        }
    }
    
    // MARK: - ヘルパーメソッド
    
    private func validateForm() {
        isFormValid = !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
}


#Preview {
    LoginViewSimple()
}
