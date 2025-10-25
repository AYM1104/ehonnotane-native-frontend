import SwiftUI

// MARK: - ログインモーダルコンポーネント

/// ガラス風のログインモーダルコンポーネント
struct LoginModal: View {
    // MARK: - Properties
    
    /// モーダルの表示状態を管理
    @Binding var isPresented: Bool
    
    /// キーボードの表示状態を管理
    @Binding var isKeyboardVisible: Bool
    
    /// 表示中のキーボードの高さ
    let keyboardHeight: CGFloat
    
    /// フォーカス状態（メールアドレス: 0, パスワード: 1）
    @Binding var focusedField: Int
    
    /// ログインアクション
    let onLogin: () -> Void
    
    // MARK: - State
    
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage: String? = nil
    @State private var isFormValid = false
    @State private var showContent = false // コンテンツの表示アニメーション用
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            // フォーカス状態に応じてキーボード上昇率を調整（メールアドレス: 0.5, パスワード: 0.7）
            let keyboardMultiplier = focusedField == 1 ? 0.7 : 0.5
            let keyboardOverlap = max(0, keyboardHeight * keyboardMultiplier)
            
            let modalShape = UnevenRoundedRectangle(
                topLeadingRadius: 50,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 50
            )
            ZStack {
                // ボトムシート用の角丸（上部のみ、より緩やかなカーブ）
                modalShape
                    .fill(
                        // bg-gradient-to-br from-white/15 via-white/5 to-white/10
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.15), location: 0.0),
                                .init(color: Color.white.opacity(0.05), location: 0.5),
                                .init(color: Color.white.opacity(0.10), location: 1.0)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // ガラス風の内側ハイライト
                        // bg-gradient-to-b from-white/8 via-white/2 to-white/5
                        modalShape
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white.opacity(0.08), location: 0.0),
                                        .init(color: Color.white.opacity(0.02), location: 0.5),
                                        .init(color: Color.white.opacity(0.05), location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .blendMode(.plusLighter)
                    )
                    // .overlay(
                    //     // inset シャドウのシミュレーション（上部の内側白ライン）
                    //     // inset_0_1px_0_rgba(255,255,255,0.2)
                    //     VStack {
                    //         Rectangle()
                    //             .fill(Color.white.opacity(0.2))
                    //             .frame(height: 1)
                    //         Spacer()
                    //     }
                    //     .clipShape(
                    //         UnevenRoundedRectangle(
                    //             topLeadingRadius: 50,
                    //             bottomLeadingRadius: 0,
                    //             bottomTrailingRadius: 0,
                    //             topTrailingRadius: 50
                    //         )
                    //     )
                    // )
                     .overlay(
                         // 角丸に沿ったグロー効果
                         UnevenRoundedRectangle(topLeadingRadius: 50, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 50)
                             .stroke(Color.white.opacity(0.8), lineWidth: 2)
                             .shadow(color: Color.white.opacity(0.8), radius: 8, x: 0, y: 0)
                             .shadow(color: Color.white.opacity(0.6), radius: 15, x: 0, y: 0)
                             .shadow(color: Color.white.opacity(0.4), radius: 25, x: 0, y: 0)
                             .shadow(color: Color.blue.opacity(0.3), radius: 35, x: 0, y: 0)
                     )
                    // mainCardと同じ強い輝き効果（複数のシャドウ）
                     .shadow(color: Color.black.opacity(0.2), radius: 50, x: 0, y: 8)
                     .shadow(color: Color.white.opacity(0.3), radius: 50, x: 0, y: 0)
                     .shadow(color: Color(red: 102/255, green: 126/255, blue: 234/255).opacity(0.4), radius: 30, x: 0, y: 0)
                     .shadow(color: Color.white.opacity(0.2), radius: 45, x: 0, y: 0)
                
                // コンテンツ構造
                VStack {
                    // メインコンテンツ
                    VStack {
                        
                        // ログインフォーム
                        VStack(spacing: 20) {
                            // ログインタイトルとキャラクター
                            HStack {
                                Text("ログイン")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                            }
                            .offset(x: showContent ? 0 : -50)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: showContent)
                            .padding(.horizontal, 20)
                            
                            // LoginFormを使用
                            LoginForm(
                                email: $email,
                                password: $password,
                                isPasswordVisible: $isPasswordVisible,
                                errorMessage: $errorMessage,
                                onFormValidChanged: { isValid in
                                    isFormValid = isValid
                                    // フォームが有効になったらエラーメッセージをクリア
                                    if isValid {
                                        errorMessage = nil
                                    }
                                },
                                onKeyboardVisibleChanged: { isVisible in
                                    isKeyboardVisible = isVisible
                                },
                                onFocusChanged: { fieldIndex in
                                    focusedField = fieldIndex
                                }
                            )
                            .offset(y: showContent ? 0 : 30)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
                            .padding(.horizontal, 20)
                            
                            // エラーメッセージ表示
                            if let error = errorMessage, !error.isEmpty {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // Google OAuthエラーメッセージ表示
                            if let googleError = errorMessage, !googleError.isEmpty {
                                Text(googleError)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // ログインボタン
                            Button(action: {
                                if isFormValid {
                                    onLogin()
                                } else {
                                    errorMessage = "メールアドレスとパスワードを正しく入力してください"
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Text("ログイン")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                    Spacer()
                                }
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.teal, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                            }
                            .disabled(!isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                            .padding(.horizontal, 20)
                            
                            // 区切り線
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("または")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            .offset(y: showContent ? 0 : 20)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.5).delay(0.6), value: showContent)
                            
                            // Googleログインボタン
                            Button(action: {
                                onLogin()
                            }) {
                                HStack(spacing: 12) {
                                    // Googleアイコン
                                    Image(systemName: "g.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Googleでログイン")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 25)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .disabled(false)
                            .opacity(1.0)
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: showContent)
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 25)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: geometry.size.height * (2.0/3.0))
            .padding(.horizontal, 0) // 横幅を画面いっぱいに
            .position(x: geometry.size.width / 2, y: geometry.size.height - (geometry.size.height * (2.0/3.0)) / 2) // 画面下に配置
            .ignoresSafeArea(.all, edges: .bottom) // 下部のセーフエリアを完全に無視
            .offset(y: safeAreaBottom - keyboardOverlap) // デフォルトはセーフエリア分を考慮、キーボード表示時は上に移動
            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
        }
        .onAppear {
            // モーダル表示時のアニメーション開始
            withAnimation {
                showContent = true
            }
        }
        .onDisappear {
            // モーダルが閉じる時にフォームをリセット
            email = ""
            password = ""
            isPasswordVisible = false
            errorMessage = nil
            isFormValid = false
            showContent = false
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showModal = false
    
    ZStack {
        // プレビュー用の暗い背景
        Color.black
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            Button("モーダルを表示") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showModal = true
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .offset(y: showModal ? -200 : 0) // モーダル表示時に上に移動
            .animation(.easeInOut(duration: 0.3), value: showModal)
            
            Spacer()
        }
        
        if showModal {
            // 背景タップでモーダルを閉じる
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showModal = false
                    }
                }
            
            LoginModal(
                isPresented: $showModal,
                isKeyboardVisible: .constant(false),
                keyboardHeight: 0,
                focusedField: .constant(0),
                onLogin: {
                    print("ログインボタンが押されました")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showModal = false
                    }
                }
            )
            .transition(.move(edge: .bottom))
            .zIndex(1)
        }
    }
}
