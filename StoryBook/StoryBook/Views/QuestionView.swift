import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// 物語設定データ
struct StorySettingData: Codable {
    let protagonist_type: String?
    let protagonist_name: String?
    let setting_place: String?
    let title_suggestion: String?
}

struct QuestionView: View {
    // MARK: - State
    @State private var storySettingId: Int? = nil
    @State private var storySettingData: StorySettingData? = nil
    @State private var questions: [Question] = []
    @State private var currentIndex: Int = 0
    @State private var answers: [String: String] = [:]
    @State private var currentAnswer: String = ""
    @State private var isSubmitting: Bool = false
    @State private var isCompleted: Bool = false
    @State private var showConfirmation: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    // 回答送信完了後にテーマ選択へ遷移するフラグ
    @State private var navigateToThemaSelect: Bool = false
    // キーボード回避用の高さ
    @State private var keyboardHeight: CGFloat = 0
    
    // スワイプジェスチャー用
    @State private var dragOffset: CGFloat = 0
    
    // API Base URL
    private let apiBaseURL = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://localhost:8000"
    
    // レスポンスモデルは Models 側に定義
    
    var body: some View {
        ZStack(alignment: .top) {
            // 画面遷移用の隠しリンク（NavigationStack 配下で有効）
            NavigationLink(destination: ThemaSelectView(), isActive: $navigateToThemaSelect) { EmptyView() }
                .hidden()
            // 星空背景を適用
            Background {
                // キャラクターを背景として配置
                BigCharacter()  

                // メインコンテンツ
                VStack {
                    // ヘッダーの高さ分のスペースを確保
                    Spacer()
                        .frame(height: 120)
                    
                    // メインテキスト（カードコンポーネントと同じ光る効果）
                    VStack(spacing: 8) {
                        MainText(text: "どんな えほんに")
                        MainText(text: "しようかな？")
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // ガラス風カードを表示
                    ZStack {
                        mainCard(width: .medium) {
                            VStack(spacing: 20) {
                                if showConfirmation {
                                    // 確認画面
                                    confirmationView
                                } else {
                                    // 質問カード
                                    questionCardView
                                }
                            }
                        }
                        
                        // ナビゲーションボタンを重ねて配置
                        if !showConfirmation {
                            HStack {
                                // 前へボタン
                                Button(action: handlePrev) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                        .frame(width: 40, height: 40)
                                        .background(Color(red: 255/255, green: 195/255, blue: 28/255))
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4)
                                }
                                .disabled(currentIndex == 0)
                                .opacity(currentIndex == 0 ? 0.3 : 1.0)
                                
                                Spacer()
                                
                                // 次へボタン
                                Button(action: handleNext) {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                        .frame(width: 40, height: 40)
                                        .background(Color(red: 255/255, green: 195/255, blue: 28/255))
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4)
                                }
                                .disabled(isSubmitting || isCompleted)
                                .opacity(isSubmitting || isCompleted ? 0.5 : 1.0)
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding()
                    
                    Spacer()
                        .frame(maxHeight: 30)
                }
                // キーボード表示時のみ下から押し上げる
                .padding(.bottom, keyboardHeight)
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            }
            
            // 画面上部に固定されるヘッダー
            Header(
                title: "えほんのたね",
                logoName: "logo",
                navItems: [
                    HeaderNavItem(label: "ホーム", href: "/home", action: { print("ホームクリック") }),
                    HeaderNavItem(label: "マイページ", href: "/mypage", action: { print("マイページクリック") }),
                    HeaderNavItem(label: "ログアウト", action: { print("ログアウトクリック") })
                ]
            )
            
            // 送信中のオーバーレイ
            if isSubmitting {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    
                    Text("そうしんちゅう・・・")
                        .font(.custom("YuseiMagic-Regular", size: 24))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 2)
                }
            }
        }
        .navigationBarHidden(true)
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            loadStorySettingData()
        }
        // キーボード表示時に高さを更新
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            #if canImport(UIKit)
            if let userInfo = notification.userInfo,
               let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height
            }
            #endif
        }
        // キーボード非表示時にリセット
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        // UploadImageView 側で UserDefaults に story_setting_id / data が保存されたら再読込
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            loadStorySettingData()
        }
        .onChange(of: currentIndex) { _, _ in
            updateCurrentAnswer()
        }
    }
    
    // MARK: - 確認画面
    private var confirmationView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("こたえを おくる？")
                .font(.custom("YuseiMagic-Regular", size: 32))
                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                // もどるボタン
                Button(action: {
                    showConfirmation = false
                }) {
                    Text("もどる")
                        .font(.custom("YuseiMagic-Regular", size: 18))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.gray)
                        .cornerRadius(10)
                }
                
                // おくるボタン
                Button(action: submitAnswers) {
                    Text(isSubmitting ? "おくりちゅう..." : "おくる")
                        .font(.custom("YuseiMagic-Regular", size: 18))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(red: 255/255, green: 195/255, blue: 28/255))
                        .cornerRadius(10)
                }
                .disabled(isSubmitting)
                .opacity(isSubmitting ? 0.5 : 1.0)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 質問カード
    private var questionCardView: some View {
        InnerCard(
            questions: questions,
            currentIndex: currentIndex,
            currentAnswer: $currentAnswer,
            onAnswerChange: { text in
                currentAnswer = text
            },
            onPrev: handlePrev,
            onNext: handleNext,
            isSubmitting: isSubmitting,
            isCompleted: isCompleted
        )
        .gesture(
            DragGesture()
                .onEnded { value in
                    let minSwipeDistance: CGFloat = 50
                    let horizontalDistance = value.translation.width
                    
                    if horizontalDistance < -minSwipeDistance && currentIndex < questions.count - 1 {
                        // 左スワイプ（次の質問へ）
                        handleNext()
                    } else if horizontalDistance > minSwipeDistance && currentIndex > 0 {
                        // 右スワイプ（前の質問へ）
                        handlePrev()
                    }
                }
        )
    }
    
    // MARK: - Functions
    
    /// UserDefaultsから物語設定データを読み込み、未設定時は id=0 を使用する
    private func loadStorySettingData() {
        // id は未設定時に 0 を使用
        let idFromDefaults = UserDefaults.standard.string(forKey: "story_setting_id").flatMap { Int($0) } ?? 0
        storySettingId = idFromDefaults

        // 設定データは存在する場合のみ読み込む（無ければ nil のまま続行）
        if let dataString = UserDefaults.standard.string(forKey: "story_setting_data"),
           let data = dataString.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()
                let settingData = try decoder.decode(StorySettingData.self, from: data)
                storySettingData = settingData
            } catch {
                // 設定データのデコードに失敗しても、id=0（または取得済みの id）で続行
                storySettingData = nil
            }
        } else {
            storySettingData = nil
        }

        // 質問を取得（id は 0 を含めそのまま使用）
        fetchQuestions(id: idFromDefaults)
    }
    
    /// APIから質問を取得
    private func fetchQuestions(id: Int) {
        guard let url = URL(string: "\(apiBaseURL)/story/story_settings/\(id)/questions") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    print("質問取得エラー: \(error)")
                }
                return
            }
            
            guard let http = response as? HTTPURLResponse else { return }
            guard (200...299).contains(http.statusCode), let data = data else {
                DispatchQueue.main.async {
                    print("質問取得エラー: ステータスコード不正 \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(QuestionAPIResponse.self, from: data)
                DispatchQueue.main.async {
                    self.storySettingId = result.story_setting_id
                    self.questions = result.questions
                }
            } catch {
                DispatchQueue.main.async {
                    print("質問デコードエラー: \(error)")
                }
            }
        }.resume()
    }
    
    /// 現在の質問インデックスに合わせて回答を更新
    private func updateCurrentAnswer() {
        if currentIndex < questions.count {
            let field = questions[currentIndex].field
            currentAnswer = answers[field] ?? ""
        } else {
            currentAnswer = ""
        }
    }
    
    /// 前の質問に戻る
    private func handlePrev() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    /// 次の質問に進む
    private func handleNext() {
        guard currentIndex < questions.count else { return }
        
        let question = questions[currentIndex]
        
        // 必須項目チェック
        if question.required == true && currentAnswer.isEmpty {
            alertMessage = "このしつもんにはこたえてね"
            showAlert = true
            return
        }
        
        // 回答を保存
        answers[question.field] = currentAnswer
        
        // 最後の質問なら確認画面へ
        if currentIndex == questions.count - 1 {
            showConfirmation = true
        } else {
            // 次の質問へ
            currentIndex += 1
        }
    }
    
    /// 回答を送信
    private func submitAnswers() {
        guard let id = storySettingId else { return }
        
        isSubmitting = true
        
        let group = DispatchGroup()
        var hasError = false
        
        // 各回答を送信
        for (field, answer) in answers where !answer.isEmpty {
            group.enter()
            
            guard let url = URL(string: "\(apiBaseURL)/story/story_settings/\(id)/answers") else {
                group.leave()
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["field": field, "answer": answer]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("回答送信エラー: \(error)")
                    hasError = true
                }
                group.leave()
            }.resume()
        }
        
        // 全ての回答送信完了後
        group.notify(queue: .main) {
            if hasError {
                isSubmitting = false
                alertMessage = "こたえの保存にしっぱいしました"
                showAlert = true
                return
            }
            
            // ストーリー生成を起動
            triggerStoryGeneration(id: id)
        }
    }
    
    /// ストーリー生成を起動
    private func triggerStoryGeneration(id: Int) {
        guard let url = URL(string: "\(apiBaseURL)/story/story_generator") else {
            isSubmitting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["story_setting_id": id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    print("ストーリー生成エラー: \(error)")
                    alertMessage = "ストーリー生成の開始に失敗しました"
                    showAlert = true
                    return
                }
                
                // 完了
                isCompleted = true
                // 回答送信→生成開始が成功したらテーマ選択へ遷移
                navigateToThemaSelect = true
            }
        }.resume()
    }
}

// ProgressDotsView は ThemaSelectView.swift に移動しました

//#Preview {
//   QuestionView()
//}
