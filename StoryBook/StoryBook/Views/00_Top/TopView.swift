import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

struct TopView: View {
    // ボタンの表示状態を管理
    @State private var showButton = false
    // ログインモーダルの表示状態を管理
    @State private var showLoginModal = false
    // キーボードの表示状態を管理
    @State private var isKeyboardVisible = false
    // キーボードの高さを保持
    @State private var keyboardHeight: CGFloat = 0
    // フォーカス状態（メールアドレス: 0, パスワード: 1）
    @State private var focusedField: Int = 0
    // AppCoordinatorへの参照
    @EnvironmentObject var coordinator: AppCoordinator
    // AuthServiceへの参照
    @EnvironmentObject var authService: AuthService
    private var modalContentOffset: CGFloat { showLoginModal ? -340 : 0 } // モーダルのオフセット
    private var modalContentScale: CGFloat { showLoginModal ? 0.5 : 1.0 } // モーダルのスケール
    private var keyboardMultiplier: CGFloat { focusedField == 1 ? 0.7 : 0.5 }
    private var modalKeyboardOffset: CGFloat {
        guard showLoginModal, isKeyboardVisible else { return 0 }
        return -max(0, keyboardHeight * keyboardMultiplier)
    }
    
    var body: some View {
        ZStack {
            // 背景としてBackgroundコンポーネントを使用
            Background()
            
            VStack(spacing: showLoginModal ? -60 : nil) {
                Spacer()
                
                // ロゴアニメーションを中央に配置
                LogoAnimation()
                    .offset(y: modalContentOffset)
                    .scaleEffect(modalContentScale)
                    .animation(.easeInOut(duration: 0.3), value: showLoginModal)
                
                
                // タイトルテキストアニメーションをロゴの下に配置
                TitleText()
                    .offset(y: modalContentOffset)
                    .scaleEffect(modalContentScale)
                    .animation(.easeInOut(duration: 0.3), value: showLoginModal)

                // ボタンをフェードインで配置
                PrimaryButton(
                    title: "えほんをつくる",
                    fontName: "YuseiMagic-Regular",
                    fontSize: 24,
                    action: {
                        // ログインモーダルを表示
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showLoginModal = true
                        }
                    }
                )
                .padding(.top, 40)
                .opacity((showButton && !showLoginModal) ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 1.0), value: showButton)
                .animation(.easeInOut(duration: 0.3), value: showLoginModal)

                Spacer()
            }
            .offset(y: modalKeyboardOffset)
            .animation(.easeInOut(duration: 0.3), value: keyboardHeight)
            .animation(.easeInOut(duration: 0.3), value: focusedField)
            
            // ログインモーダルの表示時の動作
            if showLoginModal {
                // 背景タップ処理：キーボード表示時はキーボードを閉じ、非表示時はモーダルを閉じる
                Color.clear
                    .contentShape(Rectangle())

                    .onTapGesture {
                        if isKeyboardVisible {
                            // キーボードが表示されている場合はキーボードのみを閉じる
                            #if canImport(UIKit)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            #endif
                        } else {
                            // キーボードが表示されていない場合はモーダルを閉じる
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showLoginModal = false
                            }
                        }
                    }
                
                // ログインモーダルの表示
                LoginModal(
                    isPresented: $showLoginModal,
                    isKeyboardVisible: $isKeyboardVisible,
                    keyboardHeight: keyboardHeight,
                    focusedField: $focusedField,
                    onLogin: {
                        // Googleログインを実行
                        authService.loginWithGoogle()
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // タイトル表示完了後にボタンをフェードイン（5.5秒後）
            // タイトルテキストのアニメーション完了（3秒 + 1.2秒） + 少しの遅延
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                showButton = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            #if canImport(UIKit)
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            keyboardHeight = frame.height
            isKeyboardVisible = true
            #endif
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
            isKeyboardVisible = false
        }
        .onChange(of: authService.authManager.isLoggedIn) { _, isLoggedIn in
            // OAuthログインが成功した場合
            if isLoggedIn {
                print("✅ OAuthログイン成功 - TopViewで検知")
                
                // モーダルを閉じる
                withAnimation(.easeInOut(duration: 0.3)) {
                    showLoginModal = false
                }
                
                // UploadImageViewに遷移
                print("🔄 UploadImageViewへの遷移を開始します")
                coordinator.navigateToUploadImage()
                print("🔄 遷移完了")
            }
        }
    }
}



#Preview {
    TopView()
        .environmentObject(AppCoordinator())
        .environmentObject(AuthService())
}

