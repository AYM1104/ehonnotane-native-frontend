import SwiftUI
import Combine

/// 質問カードビュー - 質問の表示と入力を行う
struct QuestionCardView: View {
    // QuestionServiceを使用
    @StateObject private var questionService = QuestionService.shared
    @State private var currentQuestionIndex = 0
    @State private var answers: [String: String] = [:] // 質問IDと回答のマッピング
    
    // テーマ選択画面への遷移コールバック
    let onNavigateToThemeSelect: () -> Void
    // 呼び出し元から渡される物語設定ID
    let storySettingId: Int
    
    // 送信状態の管理
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // ローディング状態の管理
    @State private var isLoadingQuestions = true
    @State private var loadingError: String?
    
    // フォーカス管理
    @FocusState private var isTextFieldFocused: Bool
    
    // 質問ページのビューを作成（最後に送信ボタンページを追加）
    private var questionPages: [QuestionPage] {
        var pages = questionService.currentQuestions.map { question in
            QuestionPage(
                id: question.field, // 安定したIDを使用
                question: question,
                answer: Binding(
                    get: { answers[question.field] ?? "" },
                    set: { answers[question.field] = $0 }
                ),
                onSubmit: nil,
                isTextFieldFocused: $isTextFieldFocused
            )
        }
        
        // 最後に送信ボタンページを追加
        pages.append(QuestionPage(
            id: "submit", // 安定したIDを使用
            question: Question(
                field: "submit",
                question: "回答を送信しますか？",
                type: "submit",
                placeholder: nil,
                required: false,
                options: nil
            ),
            answer: .constant(""),
            onSubmit: submitAnswers,
            isTextFieldFocused: nil
        ))
        
        return pages
    }
    
    // 質問を取得する関数
    private func loadQuestions() async {
        print("🔄 質問の読み込みを開始します")
        isLoadingQuestions = true
        loadingError = nil
        
        do {
            let response = try await questionService.fetchQuestions(storySettingId: storySettingId)
            await MainActor.run {
                questionService.currentQuestions = response.questions
                questionService.currentQuestionIndex = 0
                isLoadingQuestions = false
                print("✅ 質問の読み込み完了: \(response.questions.count)個の質問")
            }
        } catch {
            print("❌ 質問の取得に失敗しました: \(error)")
            await MainActor.run {
                loadingError = error.localizedDescription
                isLoadingQuestions = false
            }
        }
    }
    
    // 回答を送信する関数
    private func submitAnswers() {
        print("🔄 回答送信処理を開始します")
        isSubmitting = true
        
        Task {
            do {
                // QuestionServiceを使用して回答を送信
                // 送信前に選択肢の回答をvalue（英語コード）に正規化
                var normalized: [String: String] = [:]
                for question in questionService.currentQuestions {
                    let field = question.field
                    if let raw = answers[field], !raw.isEmpty {
                        if let options = question.options, !options.isEmpty {
                            if let matched = options.first(where: { $0.value == raw || $0.label == raw }) {
                                normalized[field] = matched.value
                            } else {
                                normalized[field] = raw
                            }
                        } else {
                            normalized[field] = raw
                        }
                    }
                }
                let response = try await questionService.submitAnswers(
                    storySettingId: storySettingId,
                    answers: normalized
                )
                
                print("✅ 回答送信成功:")
                print("   - Story Setting ID: \(response.story_setting_id)")
                print("   - Updated fields: \(response.updated_fields)")
                print("   - Message: \(response.message)")
                print("   - Processing time: \(response.processing_time_ms ?? 0)ms")

                // 回答送信後にテーマ生成をトリガー
                do {
                    try await questionService.generateThemes(storySettingId: storySettingId)
                    print("🎯 テーマ生成APIを呼び出しました")
                } catch {
                    print("⚠️ テーマ生成API呼び出しに失敗: \(error)")
                }
                
                // メインスレッドでUIを更新
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = "回答を送信しました！"
                    showAlert = true
                    
                    // 成功時はテーマ選択画面に遷移
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onNavigateToThemeSelect()
                    }
                }
                
            } catch {
                print("❌ 回答送信エラー: \(error.localizedDescription)")
                
                // メインスレッドでエラーを表示
                await MainActor.run {
                    isSubmitting = false
                    alertMessage = "回答の送信に失敗しました: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }
            
            // ヘッダー
            Header()
            
            // メインカード（画面下部に配置）
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト
                MainText(text: "どんな おはなしかな？")
                MainText(text: "おしえてね！")
                Spacer()
                
                // ガラス風カードを表示
                mainCard(width: .screen95) {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        // ローディング状態に応じて表示を切り替え
                        if isLoadingQuestions {
                            // 読み込み中の表示
                            VStack(spacing: 20) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                                
                                SubText(text: "質問を読み込み中...", fontSize: 18)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(height: 200)
                        } else if let error = loadingError {
                            // エラー表示
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                
                                SubText(text: "質問の読み込みに失敗しました", fontSize: 18)
                                    .foregroundColor(.white)
                                
                                SubText(text: error, fontSize: 14)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                
                                PrimaryButton(
                                    title: "再試行",
                                    action: {
                                        Task {
                                            await loadQuestions()
                                        }
                                    }
                                )
                            }
                            .frame(height: 300)
                        } else if !questionService.currentQuestions.isEmpty {
                            // 質問が読み込まれている場合はスライド機能付きで表示
                            VStack(spacing: 16) {
                                PagerViewComponent(questionPages, spacing: 20, onPageChanged: { index in
                                    currentQuestionIndex = index
                                    // ページ切り替え時の自動フォーカスを無効化（キーボードの自動表示を防ぐ）
                                    // DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    //     isTextFieldFocused = true
                                    // }
                                }) { page in
                                    QuestionPageComponent(
                                        question: page.question,
                                        answer: page.answer,
                                        onSubmit: page.onSubmit,
                                        isTextFieldFocused: page.isTextFieldFocused
                                    )
                                    .id(page.id) // 安定したIDを使用してビューの再構築を防止
                                }
                                .frame(height: 350)
                                      
                                // ドットプログレスバー
                                ProgressBar(
                                    totalSteps: questionService.currentQuestions.count,
                                    currentStep: currentQuestionIndex,
                                    dotSize: 10,
                                    spacing: 12
                                )
                            
                                .padding(.horizontal, 16)
                            }
                        } else {
                            // 質問がない場合
                            VStack(spacing: 20) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                SubText(text: "質問がありません", fontSize: 18)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(height: 200)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, -10)
            }
        }
        .onAppear {
            // 既に質問が読み込まれている場合は再読み込みしない
            if questionService.currentQuestions.isEmpty {
                Task {
                    await loadQuestions()
                }
            } else {
                isLoadingQuestions = false
                print("✅ 既存の質問を使用: \(questionService.currentQuestions.count)個")
            }
        }
        .alert("お知らせ", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

// 質問ページのデータ構造
struct QuestionPage: Identifiable {
    let id: String // 安定したIDを使用
    let question: Question
    let answer: Binding<String>
    let onSubmit: (() -> Void)?
    let isTextFieldFocused: FocusState<Bool>.Binding?
    
    init(id: String, question: Question, answer: Binding<String>, onSubmit: (() -> Void)?, isTextFieldFocused: FocusState<Bool>.Binding? = nil) {
        self.id = id
        self.question = question
        self.answer = answer
        self.onSubmit = onSubmit
        self.isTextFieldFocused = isTextFieldFocused
    }
}

#Preview {
    QuestionCardView(onNavigateToThemeSelect: {
        print("テーマ選択ページに遷移")
    }, storySettingId: 89)
}
