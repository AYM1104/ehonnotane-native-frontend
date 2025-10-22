import SwiftUI

/// 質問入力コンポーネント - テキスト入力と選択式入力を統合
struct QuestionInputComponent: View {
    let question: Question
    @Binding var answer: String
    let isTextFieldFocused: FocusState<Bool>.Binding?
    
    var body: some View {
        VStack(spacing: 40) {
            SubText(text: "回答", fontSize: 20)
            
            // 質問のタイプに応じて入力方法を切り替え
            if question.type == "select" && question.options != nil && !question.options!.isEmpty {
                // 選択式の質問の場合
                QuestionSelectInput(
                    question: question,
                    answer: $answer
                )
            } else {
                // テキスト入力の質問の場合
                QuestionTextInput(
                    question: question,
                    answer: $answer,
                    isTextFieldFocused: isTextFieldFocused ?? FocusState<Bool>().projectedValue
                )
            }
        }
    }
}

/// 選択式入力コンポーネント
private struct QuestionSelectInput: View {
    let question: Question
    @Binding var answer: String
    
    var body: some View {
        Menu {
            ForEach(question.options!, id: \.value) { option in
                Button(action: {
                    // 保存するのはAPIが期待するvalue（英語コード）
                    answer = option.value
                }) {
                    HStack {
                        Text(option.label)
                            .font(.custom("YuseiMagic-Regular", size: 16))
                            .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        if answer == option.value {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        }
                    }
                }
            }
        } label: {
            HStack {
                // 表示はlabel（日本語）。現在のanswer(value)から対応labelを解決
                Text(displayLabel(for: answer, in: question.options))
                    .font(.custom("YuseiMagic-Regular", size: 18))
                    .foregroundColor(answer.isEmpty ? Color.gray : Color(red: 54/255, green: 45/255, blue: 48/255))
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        answer.isEmpty ? 
                        Color.gray.opacity(0.3) : 
                        Color(red: 54/255, green: 45/255, blue: 48/255).opacity(0.3), 
                        lineWidth: 1
                    )
            )
        }
    }

    /// 現在の選択値(value)に対応するlabelを返す
    private func displayLabel(for value: String, in options: [QuestionOption]?) -> String {
        guard let options, !value.isEmpty else { return "選択してください" }
        return options.first(where: { $0.value == value })?.label ?? "選択してください"
    }
}

/// テキスト入力コンポーネント
private struct QuestionTextInput: View {
    let question: Question
    @Binding var answer: String
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        TextField(question.placeholder ?? "回答を入力してください", text: $answer)
            .font(.custom("YuseiMagic-Regular", size: 18))
            .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
            .focused($isTextFieldFocused)
            .textFieldStyle(PlainTextFieldStyle()) // デフォルトスタイルを無効化
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                ZStack {
                    // ベースの枠線（非フォーカス時は薄い白、フォーカス時はやや強め）
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isTextFieldFocused ? Color.white.opacity(0.9) : Color.white.opacity(0.4),
                            lineWidth: isTextFieldFocused ? 2 : 1
                        )
                    // フォーカス時のみ白いグローを外側に追加
                    if isTextFieldFocused {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            .blur(radius: 6)
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.35), lineWidth: 2)
                            .blur(radius: 12)
                    }
                }
            )
            .onAppear {
                // ビューが表示されたら即座にフォーカスを設定
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
            .onTapGesture {
                // タップ時にフォーカスを確実に設定
                isTextFieldFocused = true
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        // テキスト入力の例
        QuestionInputComponent(
            question: Question(
                field: "text_example",
                question: "テキスト入力の例",
                type: "text",
                placeholder: "ここに入力してください",
                required: true,
                options: nil
            ),
            answer: .constant(""),
            isTextFieldFocused: nil
        )
        
        // 選択式入力の例
        QuestionInputComponent(
            question: Question(
                field: "select_example",
                question: "選択式入力の例",
                type: "select",
                placeholder: nil,
                required: true,
                options: [
                    QuestionOption(value: "option1", label: "選択肢1"),
                    QuestionOption(value: "option2", label: "選択肢2"),
                    QuestionOption(value: "option3", label: "選択肢3")
                ]
            ),
            answer: .constant(""),
            isTextFieldFocused: nil
        )
    }
    .padding()
}
