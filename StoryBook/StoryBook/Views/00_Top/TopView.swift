import SwiftUI

struct TopView: View {
    // ボタンの表示状態を管理
    @State private var showButton = false
    // ログインモーダルの表示状態を管理
    @State private var showLoginModal = false
    // UploadImageViewの表示状態を管理
    @State private var showUploadImageView = false
    // QuestionViewの表示状態を管理
    @State private var showQuestionView = false
    // 物語設定IDを保持
    @State private var storySettingId: Int?
    // ThemeSelectViewの表示状態を管理
    @State private var showThemeSelectView = false
    
    var body: some View {
        ZStack {
            if showThemeSelectView {
                // ThemeSelectViewを表示
                ThemeSelectView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else if showQuestionView, let storySettingId {
                // QuestionCardViewを表示
                QuestionCardView(onNavigateToThemeSelect: {
                    // QuestionCardViewからThemeSelectViewへの遷移
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showQuestionView = false
                        showThemeSelectView = true
                    }
                }, storySettingId: storySettingId)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else if showUploadImageView {
                // UploadImageViewを表示
                UploadImageView(onNavigateToQuestions: { newStorySettingId in
                    // UploadImageViewからQuestionViewへの遷移
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showUploadImageView = false
                        storySettingId = newStorySettingId
                        showQuestionView = true
                    }
                })
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                // TopViewのメインコンテンツ
                ZStack {
                    // 背景としてBackgroundコンポーネントを使用
                    Background()
                    
                    VStack() {
                        // ロゴアニメーションを中央に配置
                        LogoAnimation()
                        
                        // タイトルテキストアニメーションをロゴの下に配置
                        TitleText()

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
                        .opacity(showButton ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0), value: showButton)

                        Spacer()
                    }
                    
                    // ログインモーダルの表示
                    if showLoginModal {
                        // 背景タップでモーダルを閉じる
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showLoginModal = false
                                }
                            }
                        
                        LoginModal(
                            isPresented: $showLoginModal,
                            onLogin: {
                                print("ログインが成功しました")
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showLoginModal = false
                                }
                                // UploadImageViewに遷移（アニメーション付き）
                                print("🔄 UploadImageViewへの遷移を開始します")
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showUploadImageView = true
                                }
                                print("🔄 showUploadImageView = \(showUploadImageView)")
                            }
                        )
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // タイトル表示完了後にボタンをフェードイン（5.5秒後）
            // タイトルテキストのアニメーション完了（3秒 + 1.2秒） + 少しの遅延
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                showButton = true
            }
        }
    }
}


#Preview {
    TopView()
}
