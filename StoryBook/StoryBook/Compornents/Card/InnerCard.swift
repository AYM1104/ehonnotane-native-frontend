//
//  InnerCard.swift
//  StoryBook
//
//  Created by ayu on 2025/10/15.
//

import SwiftUI

// 質問表示用のインナーカードコンポーネント
// React版のAPI(プロパティ)をSwiftUIに合わせて再現

struct InnerCard: View {
    // Reactのpropsに対応
    let questions: [Question]
    let currentIndex: Int
    @Binding var currentAnswer: String
    let onAnswerChange: (String) -> Void
    let onPrev: () -> Void
    let onNext: () -> Void
    let isSubmitting: Bool
    let isCompleted: Bool

    var body: some View {
        ZStack {
            // 背景 (rgba(255,255,255,0.5)相当)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.5))

            content
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private var content: some View {
        if questions.isEmpty {
            // しつもんをよみこみちゅう...
            Text("しつもんをよみこみちゅう...")
                .font(.system(size: 22, weight: .regular))
                .multilineTextAlignment(.center)
        } else {
            VStack(spacing: 24) {
                Spacer(minLength: 0)

                QuestionInputView(
                    question: questions[safe: currentIndex] ?? questions.first!,
                    value: $currentAnswer,
                    onChange: { text in
                        onAnswerChange(text)
                    }
                )

                Spacer(minLength: 0)
            }
        }
    }
}

// 質問入力ビュー (ReactのQuestionInputに対応)
private struct QuestionInputView: View {
    let question: Question
    @Binding var value: String
    let onChange: (String) -> Void

    // テキストフィールドのフォーカス管理
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            // 質問テキスト（中央寄せ・大きめ）
            Text(question.question)
                .font(.custom("YuseiMagic-Regular", size: 32))
                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            inputField
        }
    }

    @ViewBuilder
    private var inputField: some View {
        // 最低限の型分岐。未指定はテキスト入力として扱う
        switch question.type.lowercased() {
        case "select":
            let currentLabel = (question.options ?? []).first(where: { $0.value == value })?.label
            Menu {
                let opts = question.options ?? []
                ForEach(opts, id: \.value) { option in
                    Button(option.label) {
                        value = option.value
                        onChange(option.value)
                    }
                }
            } label: {
                HStack {
                    Text(currentLabel ?? (question.placeholder ?? "えらんでください"))
                        .font(.custom("YuseiMagic-Regular", size: 28))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                    Spacer(minLength: 12)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(Color(red: 54/255, green: 45/255, blue: 48/255), lineWidth: 2)
                )
                .cornerRadius(12)
            }

        case "number":
            TextField(question.placeholder ?? "こたえをいれてね", text: Binding(
                get: { value },
                set: { newValue in
                    // 数字のみを許可 (簡易)
                    let filtered = newValue.filter { $0.isNumber }
                    value = filtered
                    onChange(filtered)
                }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($isFocused)

        default:
            TextField(question.placeholder ?? "こたえをいれてね", text: Binding(
                get: { value },
                set: { newValue in
                    value = newValue
                    onChange(newValue)
                }
            ))
            .font(.custom("YuseiMagic-Regular", size: 22))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 10).stroke(Color(red: 54/255, green: 45/255, blue: 48/255), lineWidth: 1.5)
            )
            .cornerRadius(10)
            .focused($isFocused)
        }
    }
}

// 配列の安全アクセス
private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct InnerCard_Previews: PreviewProvider {
    struct Wrapper: View {
        @State private var answer: String = ""
        var body: some View {
            let sampleQuestions: [Question] = [
                Question(
                    field: "name",
                    question: "なまえはなに？",
                    type: "text",
                    placeholder: "たろう",
                    required: true,
                    options: nil
                )
            ]

            return InnerCard(
                questions: sampleQuestions,
                currentIndex: 0,
                currentAnswer: $answer,
                onAnswerChange: { _ in },
                onPrev: {},
                onNext: {},
                isSubmitting: false,
                isCompleted: false
            )
            .padding()
        }
    }

    static var previews: some View {
        Wrapper()
            .previewLayout(.sizeThatFits)
    }
}
