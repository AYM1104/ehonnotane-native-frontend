import SwiftUI
import UIKit

struct TestView: View {
    @StateObject private var questionService = QuestionService.shared
    @State private var storySettingId = 89 // テスト用のID
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentPageIndex: Int = 0
    @State private var answers: [String: String] = [:] // 質問ID: 回答のマッピング
    @FocusState private var isTextFieldFocused: Bool
    
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
                MainText(text: "どんな え でえほんを")
                MainText(text: "つくろうかな？")
                Spacer()
                
                // ガラス風カードを表示
                mainCard(width: .screen95) {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        // ページカール効果で質問を表示
                        PageCurl(
                            pages: createQuestionPages(),
                            currentIndex: $currentPageIndex
                        )
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 35))
                        .onChange(of: currentPageIndex) { _, newIndex in
                            // ページが変更されたら質問サービスも更新
                            if newIndex != questionService.currentQuestionIndex {
                                questionService.currentQuestionIndex = newIndex
                            }
                        }
                        .onChange(of: questionService.currentQuestionIndex) { _, newIndex in
                            // 質問サービスが変更されたらページも更新
                            if newIndex != currentPageIndex {
                                currentPageIndex = newIndex
                            }
                        }
                        
                        
                        
                        // プログレスバー
                        ProgressBar(
                            totalSteps: max(questionService.currentQuestions.count, 1),
                            currentStep: questionService.currentQuestionIndex
                        )
                        .padding(.top, 8)
                        
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16) // パディングを減らしてカードを広く表示
                .padding(.bottom, -10) // 画面下部からの余白
            }
        }
        .onAppear {
            loadQuestions()
        }
    }
    
    // 質問ページを作成する関数
    private func createQuestionPages() -> [AnyView] {
        if isLoading {
            return [AnyView(
                InnerCard(
                    backgroundColor: Color.white, // 完全に不透明な白背景
                    sections: [
                        .init {
                            VStack(spacing: 8) {
                                SubText(text: "質問")
                                SubText(text: "質問を読み込み中...")
                            }
                        },
                        .init {
                            VStack(spacing: 8) {
                                SubText(text: "回答")
                                TextField("読み込み中...", text: .constant(""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 8)
                                    .disabled(true)
                            }
                        }
                    ]
                )
            )]
        } else if let errorMessage = errorMessage {
            return [AnyView(
                InnerCard(
                    backgroundColor: Color.white, // 完全に不透明な白背景
                    sections: [
                        .init {
                            VStack(spacing: 8) {
                                SubText(text: "エラー")
                                SubText(text: errorMessage)
                                    .foregroundColor(.red)
                            }
                        },
                        .init {
                            VStack(spacing: 8) {
                                SubText(text: "回答")
                                TextField("エラーが発生しました", text: .constant(""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 8)
                                    .disabled(true)
                            }
                        }
                    ]
                )
            )]
        } else if questionService.currentQuestions.isEmpty {
            return [AnyView(
                InnerCard(
                    backgroundColor: Color.white, // 完全に不透明な白背景
                    sections: [
                        .init {
                            VStack(spacing: 8) {
                                SubText(text: "質問")
                                SubText(text: "質問がありません")
                            }
                        },
                        .init {
                            VStack(spacing: 8) {
                                SubText(text: "回答")
                                TextField("質問を読み込んでください", text: .constant(""))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 8)
                                    .disabled(true)
                            }
                        }
                    ]
                )
            )]
        } else {
            return questionService.currentQuestions.map { question in
                AnyView(
                    InnerCard(
                        backgroundColor: Color.white, // 完全に不透明な白背景
                        sections: [
                            .init {
                                VStack(spacing: 8) {
                                    SubText(text: "質問")
                                    SubText(text: question.question)
                                }
                            },
                            .init {
                                QuestionInputField(
                                    question: question,
                                    answer: Binding(
                                        get: { answers[question.id] ?? "" },
                                        set: { answers[question.id] = $0 }
                                    )
                                )
                            }
                        ]
                    )
                )
            }
        }
    }
    
    // 質問を読み込む関数
    private func loadQuestions() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await questionService.fetchQuestions(storySettingId: storySettingId)
                await MainActor.run {
                    questionService.currentQuestions = response.questions
                    questionService.currentQuestionIndex = 0
                    currentPageIndex = 0
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    TestView()
}
