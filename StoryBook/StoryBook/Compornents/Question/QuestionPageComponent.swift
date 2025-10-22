import SwiftUI

/// 質問ページコンポーネント
struct QuestionPageComponent: View {
    let question: Question
    @Binding var answer: String
    let onSubmit: (() -> Void)?
    let isTextFieldFocused: FocusState<Bool>.Binding?
    
    var body: some View {
        InnerCard(
            sections: [
                .init {
                    // 上部領域：質問（中央配置）
                    VStack(spacing: 24) {
                        SubText(text: "質問", fontSize: 20)
                        SubText(text: question.question, fontSize: 20)
                    }
                },
                .init {
                    // 下部領域：入力エリアまたは送信ボタン
                    Group {
                        if question.type == "submit" {
                            // 送信ボタン
                            VStack(spacing: 40) {
                                PrimaryButton(
                                    title: "この回答を送る",
                                    action: {
                                        onSubmit?()
                                    }
                                )
                            }
                        } else {
                            // 質問入力コンポーネント
                            QuestionInputComponent(
                                question: question,
                                answer: $answer,
                                isTextFieldFocused: isTextFieldFocused
                            )
                        }
                    }
                }
            ]
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        // 通常の質問ページ
        QuestionPageComponent(
            question: Question(
                field: "example",
                question: "これは質問の例です",
                type: "text",
                placeholder: "回答を入力してください",
                required: true,
                options: nil
            ),
            answer: .constant(""),
            onSubmit: nil,
            isTextFieldFocused: nil
        )
        
        // 送信ページ
        QuestionPageComponent(
            question: Question(
                field: "submit",
                question: "回答を送信しますか？",
                type: "submit",
                placeholder: nil,
                required: false,
                options: nil
            ),
            answer: .constant(""),
            onSubmit: {
                print("送信ボタンが押されました")
            },
            isTextFieldFocused: nil
        )
    }
    .padding()
}
