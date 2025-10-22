import SwiftUI

#if canImport(Auth0)
import Auth0
#endif

enum AppView: Equatable {
    case login
    case uploadImage
    case questions(Int)
}

struct LoginView: View {
    // 認証サービス
    // @StateObject private var authService = AuthService()
    @State private var currentView: AppView = .login
    
    // 一時的な認証状態（後でAuthServiceに移行）
    @State private var isLoggedIn = false
    @State private var accessToken: String?
    @State private var idToken: String?
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    // 入力状態
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isFormValid: Bool = false
    
    var body: some View {
        NavigationStack {
            switch currentView {
            case .login:
                loginContent
            case .uploadImage:
                UploadImageView(onNavigateToQuestions: { storySettingId in
                    print("🔄 UploadImageViewから遷移要求: QuestionViewへ")
                    currentView = .questions(storySettingId)
                })
            case .questions(let storySettingId):
                QuestionCardView(onNavigateToThemeSelect: {
                    print("テーマ選択画面への遷移")
                }, storySettingId: storySettingId)
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onChange(of: currentView) { _, newView in
            print("🔄 currentView変更: \(newView)")
        }
    }
    
    // MARK: - View Components
    
    private var loginContent: some View {
        Background {
            mainContent
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            Spacer()
            
            logoSection
            titleSection
            loginFormSection
            
            Spacer()
        }
        .padding()
        .onChange(of: isLoggedIn) { _, loggedIn in
            if loggedIn {
                print("🔄 ログイン成功: UploadImageViewへ遷移")
                currentView = .uploadImage
            }
        }
    }
    
    private var logoSection: some View {
        Image("logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)
            .padding(.bottom, 20)
    }
    
    private var titleSection: some View {
        Text("えほんのたね")
            .font(.custom("YuseiMagic-Regular", size: 32))
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
    
    private var loginFormSection: some View {
        mainCard(width: .screen95) {
            VStack(spacing: 20) {
                loginTitle
                LoginForm(
                    email: $email,
                    password: $password,
                    isPasswordVisible: $isPasswordVisible,
                    errorMessage: $errorMessage,
                    onFormValidChanged: { isValid in
                        isFormValid = isValid
                    }
                )
                loginButton
                orDivider
                googleLoginButton
            }
        }
    }
    
    private var loginTitle: some View {
        Text("ログイン")
            .font(.custom("YuseiMagic-Regular", size: 28))
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
    
    
    
    private var loginButton: some View {
        Button(action: loginWithAuth0) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                Text("ログイン")
                    .font(.custom("YuseiMagic-Regular", size: 20))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 48)
        .padding(.vertical, 12)
        .background(loginButtonBackground)
        .clipShape(RoundedRectangle(cornerRadius: 50))
        .shadow(
            color: Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.5),
            radius: 15,
            x: 0,
            y: 5
        )
        .disabled(!isFormValid || isLoading)
        .opacity((isFormValid && !isLoading) ? 1.0 : 0.6)
    }
    
    private var loginButtonBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 16/255, green: 185/255, blue: 129/255),
                Color(red: 20/255, green: 184/255, blue: 166/255),
                Color(red: 6/255, green: 182/255, blue: 212/255)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    
    private var orDivider: some View {
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
    }
    
    private var googleLoginButton: some View {
        Button(action: loginWithGoogle) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Googleでログイン")
                    .font(.custom("YuseiMagic-Regular", size: 16))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(googleButtonBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.6 : 1.0)
    }
    
    private var googleButtonBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.85, green: 0.85, blue: 0.85).opacity(0.2),
                Color(red: 0.75, green: 0.75, blue: 0.75).opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Auth0認証メソッド
    
    private func loginWithAuth0() {
        #if canImport(Auth0)
        isLoading = true
        errorMessage = nil
        
        Auth0
            .webAuth(clientId: "b1sTk9gTW2rjddFtvu0w7ZrsFYk2ldfh", domain: "ehonnotane.jp.auth0.com")
            .scope("openid profile email")
            .audience("https://api.ehonnotane")
            .start { result in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    switch result {
                    case .success(let credentials):
                        isLoggedIn = true
                        accessToken = credentials.accessToken
                        idToken = credentials.idToken
                        errorMessage = nil
                        print("✅ Auth0ログイン成功")
                        
                        // ユーザー情報はGoogleOAuthServiceで処理される
                        
                    case .failure(let error):
                        isLoggedIn = false
                        accessToken = nil
                        idToken = nil
                        errorMessage = "ログインに失敗しました: \(error.localizedDescription)"
                        print("❌ Auth0ログインエラー: \(error)")
                    }
                }
            }
        #else
        errorMessage = "Auth0モジュールが利用できません"
        #endif
    }
    
    // extractUserInfoFromIdTokenメソッドはGoogleOAuthServiceに移動済み
    
    // registerUserToSupabaseメソッドはGoogleOAuthServiceに移動済み
    
    private func loginWithGoogle() {
        #if canImport(Auth0)
        isLoading = true
        errorMessage = nil
        
        print("🔍 Googleログイン開始")
        
        // 既存のセッションをクリアしてGoogleアカウント選択画面を表示
        Auth0.webAuth().clearSession { _ in
            print("🧹 Auth0セッションクリア完了")
        }
        
        // Auth0のUniversal LoginでGoogleプロバイダーを指定
        Auth0
            .webAuth(clientId: "b1sTk9gTW2rjddFtvu0w7ZrsFYk2ldfh", domain: "ehonnotane.jp.auth0.com")
            .scope("openid profile email")
            .audience("https://api.ehonnotane")
            .parameters(["connection": "google-oauth2"]) // Googleプロバイダーを指定
            .start { result in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    switch result {
                    case .success(let credentials):
                        isLoggedIn = true
                        accessToken = credentials.accessToken
                        idToken = credentials.idToken
                        errorMessage = nil
                        print("✅ Googleログイン成功")
                        print("Access Token: \(credentials.accessToken)")
                        print("ID Token: \(credentials.idToken)")
                        
                        // ユーザー情報はGoogleOAuthServiceで処理される
                        
                    case .failure(let error):
                        isLoggedIn = false
                        accessToken = nil
                        idToken = nil
                        errorMessage = "Googleログインに失敗しました: \(error)"
                        print("❌ Googleログインエラー詳細: \(error)")
                        print("❌ エラータイプ: \(type(of: error))")
                    }
                }
            }
        #else
        errorMessage = "Auth0モジュールが利用できません"
        #endif
    }
    
}

#Preview {
    LoginView()
}
