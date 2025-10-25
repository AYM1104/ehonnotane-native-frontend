//
//  LoginForm.swift
//  StoryBook
//
//  Created by ayu on 2025/10/16.
//

import SwiftUI


/// ログインフォームコンポーネント
/// カードコンポーネント内にメールアドレスとパスワードの入力フィールドを配置
struct LoginForm: View {
    // MARK: - バインディングプロパティ
    
    /// メールアドレス
    @Binding var email: String
    
    /// パスワード
    @Binding var password: String
    
    /// パスワード表示/非表示フラグ
    @Binding var isPasswordVisible: Bool
    
    /// エラーメッセージ
    @Binding var errorMessage: String?
    
    /// フォームの有効性変更時のコールバック
    let onFormValidChanged: (Bool) -> Void
    
    /// キーボード表示状態変更時のコールバック
    let onKeyboardVisibleChanged: (Bool) -> Void
    
    /// フォーカス状態変更時のコールバック（メールアドレス: 0, パスワード: 1）
    let onFocusChanged: (Int) -> Void
    
    // MARK: - 計算プロパティ
    
    /// メールアドレスの有効性チェック
    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }
    
    /// パスワードの有効性チェック
    private var isPasswordValid: Bool {
        password.count >= 6
    }
    
    /// フォーム全体の有効性チェック
    private var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }
    
    // MARK: - ボディ
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // メールアドレス入力フィールド
            VStack(alignment: .leading, spacing: 8) {
                Text("メールアドレス")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                
                TextField("example@mail.com", text: $email)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(inputFieldBackground)
                    .overlay(inputFieldOverlay)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputFieldBorderColor, lineWidth: 1.5)
                    )
                    .onTapGesture {
                        onKeyboardVisibleChanged(true)
                        onFocusChanged(0) // メールアドレスフィールド
                    }
            }
            
            // パスワード入力フィールド
            VStack(alignment: .leading, spacing: 8) {
                Text("パスワード")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                
                HStack(spacing: 8) {
                    Group {
                        if isPasswordVisible {
                            TextField("6文字以上", text: $password)
                                .foregroundColor(.white)
                                .onTapGesture {
                                    onKeyboardVisibleChanged(true)
                                    onFocusChanged(1) // パスワードフィールド
                                }
                        } else {
                            SecureField("6文字以上", text: $password)
                                .foregroundColor(.white)
                                .onTapGesture {
                                    onKeyboardVisibleChanged(true)
                                    onFocusChanged(1) // パスワードフィールド
                                }
                        }
                    }
                    
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .accessibilityLabel(isPasswordVisible ? "パスワードを非表示" : "パスワードを表示")
                }
                .padding(12)
                .background(inputFieldBackground)
                .overlay(inputFieldOverlay)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(passwordFieldBorderColor, lineWidth: 1.5)
                )
            }
            
            // エラーメッセージ表示
            if let error = errorMessage, !error.isEmpty {
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .onChange(of: isFormValid) { _, newValue in
            onFormValidChanged(newValue)
        }
    }
    
    // MARK: - プライベートプロパティ
    
    /// 入力フィールドの背景グラデーション
    private var inputFieldBackground: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.white.opacity(0.08), location: 0.0),
                .init(color: Color.white.opacity(0.02), location: 0.5),
                .init(color: Color.white.opacity(0.05), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    /// 入力フィールドのオーバーレイ（内側の白いライン）
    private var inputFieldOverlay: some View {
        VStack {
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
            Spacer()
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    /// メールアドレスフィールドのボーダー色
    private var inputFieldBorderColor: Color {
        (isEmailValid || email.isEmpty) ? Color.white.opacity(0.6) : Color.red
    }
    
    /// パスワードフィールドのボーダー色
    private var passwordFieldBorderColor: Color {
        (isPasswordValid || password.isEmpty) ? Color.white.opacity(0.6) : Color.red
    }
}


// MARK: - プレビュー

#Preview {
    // プレビュー用のシンプルな背景
    ZStack {
        // グラデーション背景
        LinearGradient(
            colors: [
                Color(red: 0.5, green: 0.2, blue: 0.6),  // purple-900
                Color(red: 0.1, green: 0.2, blue: 0.6),  // blue-900
                Color(red: 0.2, green: 0.1, blue: 0.5)   // indigo-900
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 24) {
            // ロゴをカードの上に配置
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .padding(.bottom, 20)
            
            // カードの代替（シンプルなRoundedRectangle）
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .frame(maxWidth: 480)
                .frame(height: 400)
                .overlay(
                    VStack(spacing: 20) {
                        // タイトル
                        Text("ログイン")
                            .font(.custom("YuseiMagic-Regular", size: 32))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // ログインフォーム
                        LoginForm(
                            email: .constant("test@example.com"),
                            password: .constant("password123"),
                            isPasswordVisible: .constant(false),
                            errorMessage: .constant(nil),
                            onFormValidChanged: { _ in },
                            onKeyboardVisibleChanged: { _ in },
                            onFocusChanged: { _ in }
                        )
                        
                        // ログインボタン（プレビュー用）
                        Button("ログイン") {
                            print("ボタンがタップされました")
                        }
                        .padding(.horizontal, 48)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 16/255, green: 185/255, blue: 129/255), // emerald-500
                                    Color(red: 20/255, green: 184/255, blue: 166/255), // teal-500
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                    }
                    .padding()
                )
        }
        .padding()
    }
}
