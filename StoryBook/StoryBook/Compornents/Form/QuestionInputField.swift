import SwiftUI

// 質問入力フィールドコンポーネント
struct QuestionInputField: View {
    let question: Question
    @Binding var answer: String
    
    var body: some View {
        VStack(spacing: 8) {
            SubText(text: "回答")
            
            if question.type == "text_input" {
                // テキスト入力ボックス
                VStack(spacing: 8) {
                    TextField("回答を入力してください", text: $answer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .onTapGesture {
                            print("テキストフィールドがタップされました")
                        }
                        .onAppear {
                            print("テキストフィールドが表示されました")
                        }
                    
                    // 入力された内容の表示（デバッグ用）
                    if !answer.isEmpty {
                        SubText(text: "入力内容: \(answer)")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            } else if question.type == "select" {
                // ドロップダウン式選択リスト
                VStack(spacing: 8) {
                    // 選択された回答の表示エリア
                    if !answer.isEmpty {
                        VStack(spacing: 4) {
                            SubText(text: "選択した回答:")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(answer)
                                .foregroundColor(.primary)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    
                    // 選択メニュー
                    Menu {
                        if let options = question.options, !options.isEmpty {
                            ForEach(options, id: \.id) { option in
                                Button(action: {
                                    answer = option.label
                                    print("選択された回答: \(option.label) for question: \(question.id)")
                                }) {
                                    HStack {
                                        Text(option.label)
                                        if answer == option.label {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("選択肢がありません")
                                .foregroundColor(.gray)
                        }
                    } label: {
                        HStack {
                            SubText(text: !answer.isEmpty ? "選択を変更" : "選択してください")
                                .foregroundColor(.gray)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // 選択解除ボタン（選択済みの場合のみ表示）
                    if !answer.isEmpty {
                        Button(action: {
                            answer = ""
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                SubText(text: "選択を解除")
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
            } else {
                // デフォルトの入力エリア
                VStack(spacing: 8) {
                    TextField("回答を入力してください", text: $answer)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .onTapGesture {
                            print("デフォルトテキストフィールドがタップされました")
                        }
                        .onAppear {
                            print("デフォルトテキストフィールドが表示されました")
                        }
                    
                    // 入力された内容の表示（デバッグ用）
                    if !answer.isEmpty {
                        SubText(text: "入力内容: \(answer)")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack {
        // テキスト入力の例
        QuestionInputField(
            question: Question(
                field: "test_field_1",
                question: "テスト質問",
                type: "text_input",
                placeholder: "回答を入力してください",
                required: false,
                options: nil
            ),
            answer: .constant("")
        )
        
        // 選択式の例
        QuestionInputField(
            question: Question(
                field: "test_field_2",
                question: "選択質問",
                type: "select",
                placeholder: nil,
                required: true,
                options: [
                    QuestionOption(value: "option1", label: "選択肢1"),
                    QuestionOption(value: "option2", label: "選択肢2")
                ]
            ),
            answer: .constant("選択肢1")
        )
    }
    .padding()
}
