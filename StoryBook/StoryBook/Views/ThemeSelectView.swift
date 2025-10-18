import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - テーマ選択画面（Next.js版の再現）
struct ThemaSelectView: View {
    // 画像生成フロー状態
    @State private var isGeneratingImages: Bool = false
    @State private var storySettingId: Int? = nil
    @State private var latestTitles: [ThemeItem] = []
    @State private var titleSlideIndex: Int = 0
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var error: String? = nil

    // 画像生成の進捗
    @State private var imageProgress = ImageGenerationProgressState()

    // API Base URL（必要に応じて利用）
    private let apiBaseURL = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://localhost:8000"

    var body: some View {
        ZStack(alignment: .top) {
            // 背景コンポーネント + キャラクター
            Background {
                BigCharacter()

                // メインコンテンツ
                VStack {
                    Spacer()
                        .frame(height: 120)

                    // 見出し（光るテキスト風のスタイル）
                    VStack(spacing: 8) {
                        MainText(text: "すきな おはなしを")
                        MainText(text: "えらんでね！")
                    }
                    .padding(.horizontal, 40)

                    Spacer()

                    // カード領域（ガラス風コンポーネント）
                    ZStack {
                        mainCard(width: .medium) {
                            VStack(spacing: 16) {
                                ThemeInnerCardView(
                                    items: latestTitles,
                                    currentIndex: titleSlideIndex,
                                    isGeneratingImages: isGeneratingImages,
                                    onSelectTheme: onSelectTheme
                                )
                                .padding(.horizontal, 8)

                                // 下部プログレスドット
                                if latestTitles.count > 0 {
                                    ProgressDotsView(total: latestTitles.count, currentIndex: titleSlideIndex)
                                        .padding(.bottom, 4)
                                }
                            }
                        }

                        // 前へ/次へ ボタン（カード上に重ねる）
                        HStack {
                                Button(action: prevTitle) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                .frame(width: 40, height: 40)
                                .background((titleSlideIndex == 0 ? Color.yellow.opacity(0.5) : Color.yellow))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4)
                        }
                        .disabled(titleSlideIndex == 0)
                        .opacity(titleSlideIndex == 0 ? 0.5 : 1.0)

                        Spacer()

                        Button(action: nextTitle) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                                .frame(width: 40, height: 40)
                                .background((titleSlideIndex == latestTitles.count - 1 ? Color.yellow.opacity(0.5) : Color.yellow))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4)
                        }
                        .disabled(titleSlideIndex == latestTitles.count - 1)
                        .opacity(titleSlideIndex == latestTitles.count - 1 ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: 560)
                }
                .padding()

                    Spacer().frame(maxHeight: 30)
                }
            }

            // 画像生成プログレス（画面上の簡易オーバーレイ）
            if isGeneratingImages {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                VStack {
                    ImageGenerationProgressView(
                        currentImage: imageProgress.current,
                        totalImages: imageProgress.total,
                        currentImageDetails: imageProgress.currentImageDetails
                    )
                    .padding(.horizontal, 24)
                }
            }
        }
        // ナビゲーションバー非表示（必要であれば呼び出し側で制御）
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            loadInitialData()
        }
    }

    // MARK: - Actions
    private func prevTitle() {
        guard titleSlideIndex > 0 else { return }
        titleSlideIndex -= 1
    }

    private func nextTitle() {
        guard titleSlideIndex < max(0, latestTitles.count - 1) else { return }
        titleSlideIndex += 1
    }

    private func onSelectTheme() {
        guard !latestTitles.isEmpty, titleSlideIndex < latestTitles.count else {
            alertMessage = "テーマが選択されていません"
            showAlert = true
            return
        }
        guard let storySettingId else {
            alertMessage = "ストーリー設定IDが見つかりません"
            showAlert = true
            return
        }

        isGeneratingImages = true
        imageProgress.start(total: 5)

        // 疑似的な生成進行（実際のAPI連携に置き換え可）
        Task {
            for page in 1...imageProgress.total {
                imageProgress.setGenerating(pageNumber: page, message: "ページ \(page) の画像を生成中...")
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                imageProgress.setCompleted(pageNumber: page)
            }
            imageProgress.finish()
            isGeneratingImages = false
            alertMessage = "テーマ『\(latestTitles[titleSlideIndex].title)』の画像生成が完了しました！\n生成された画像数: \(imageProgress.total)"
            showAlert = true
            // 本来は storybook 画面へ遷移を行う
            print("Push to /storybook/<id> with story_setting_id=\(storySettingId)")
        }
    }

    // MARK: - Load
    private func loadInitialData() {
        let idFromDefaults = UserDefaults.standard.string(forKey: "story_setting_id").flatMap { Int($0) }
        storySettingId = idFromDefaults

        // APIからタイトルと概要を取得
        fetchStoryPlots(userId: readUserId(), storySettingId: idFromDefaults, limit: 3) { items in
            DispatchQueue.main.async {
                if items.isEmpty {
                    // フォールバックのダミータイトル
                    self.latestTitles = [
                        ThemeItem(title: "ふしぎな もり の ぼうけん", description: "もりでふしぎなできごとが..."),
                        ThemeItem(title: "そら とぶ ねこ", description: "ねこがそらをとぶひみつは？"),
                        ThemeItem(title: "うみの ひみつ きち", description: "うみのそこには...？")
                    ]
                } else {
                    self.latestTitles = items
                }
                self.titleSlideIndex = 0
            }
        }
    }

    // MARK: - API: /story/story_plots
    private struct StoryPlot: Decodable {
        let title: String
        let description: String?
    }

    private struct StoryPlotsEnvelope: Decodable {
        let story_plots: [StoryPlot]
    }

    private func fetchStoryPlots(userId: Int?, storySettingId: Int?, limit: Int, completion: @escaping ([ThemeItem]) -> Void) {
        guard let userId, let storySettingId else {
            completion([])
            return
        }

        var components = URLComponents(string: "\(apiBaseURL)/story/story_plots")
        components?.queryItems = [
            URLQueryItem(name: "user_id", value: String(userId)),
            URLQueryItem(name: "story_setting_id", value: String(storySettingId)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        guard let url = components?.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                completion([])
                return
            }
            // まずは配列形式を試す -> 包装形式の順でデコード
            if let arr = try? JSONDecoder().decode([StoryPlot].self, from: data) {
                completion(arr.map { ThemeItem(title: $0.title, description: $0.description) })
                return
            }
            if let env = try? JSONDecoder().decode(StoryPlotsEnvelope.self, from: data) {
                completion(env.story_plots.map { ThemeItem(title: $0.title, description: $0.description) })
                return
            }
            completion([])
        }.resume()
    }

    private func readUserId() -> Int? {
        if let s = UserDefaults.standard.string(forKey: "user_id"), let v = Int(s) { return v }
        if let v = UserDefaults.standard.value(forKey: "user_id") as? Int { return v }
        if let s = UserDefaults.standard.string(forKey: "userId"), let v = Int(s) { return v }
        return nil
    }
}

// MARK: - サポート型/ビュー
struct ThemeItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String?
}

// UserDefaults.decode用の軽量型（QuestionView側の StorySettingData と競合させない）
struct StorySettingDataLite: Codable {
    let protagonist_type: String?
    let protagonist_name: String?
    let setting_place: String?
    let title_suggestion: String?
}

struct ImageGenerationProgressState {
    var total: Int = 0
    var current: Int = 0
    var currentImageDetails: String = ""

    mutating func start(total: Int) {
        self.total = total
        self.current = 0
        self.currentImageDetails = "画像生成中... (0/\(total))"
    }

    mutating func setGenerating(pageNumber: Int, message: String) {
        current = min(pageNumber, total)
        currentImageDetails = message
    }

    mutating func setCompleted(pageNumber: Int) {
        current = min(pageNumber, total)
        currentImageDetails = "ページ \(pageNumber) の生成が完了"
    }

    mutating func setFailed(pageNumber: Int, message: String) {
        current = min(pageNumber, total)
        currentImageDetails = message
    }

    mutating func finish() {
        current = total
        currentImageDetails = "すべての画像生成が完了しました"
    }
}

struct ImageGenerationProgressView: View {
    let currentImage: Int
    let totalImages: Int
    let currentImageDetails: String

    var body: some View {
        VStack(spacing: 12) {
            // 疑似プログレスバー
            ProgressView(value: Double(currentImage), total: Double(max(totalImages, 1)))
                .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                .frame(maxWidth: .infinity)

            Text(currentImageDetails)
                .font(.custom("YuseiMagic-Regular", size: 16))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 2)

            // ドット（ページ進捗）
            HStack(spacing: 6) {
                ForEach(0..<max(totalImages, 0), id: \.self) { index in
                    Circle()
                        .fill(index < currentImage ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.4))
        .cornerRadius(16)
    }
}

struct ThemeInnerCardView: View {
    let items: [ThemeItem]
    let currentIndex: Int
    let isGeneratingImages: Bool
    let onSelectTheme: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            if items.indices.contains(currentIndex) {
                // クリーム色の内側カード
                VStack(spacing: 14) {
                    // タイトル（中央・太字・やや大）
                    Text(items[currentIndex].title)
                        .font(.custom("YuseiMagic-Regular", size: 24))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    // 区切り（小さな矢印風）
                    Text("▾")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255).opacity(0.7))

                    // 説明文
                    if let desc = items[currentIndex].description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 1.0, green: 0.96, blue: 0.88)) // クリーム色
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                )
            } else {
                Text("テーマがありません")
                    .font(.custom("YuseiMagic-Regular", size: 20))
                    .foregroundColor(.gray)
            }

            // CTA ボタン（グリーングラデーション、角丸 pill）
            Button(action: onSelectTheme) {
                Text(isGeneratingImages ? "せいせいちゅう..." : "このテーマを選択")
                    .font(.custom("YuseiMagic-Regular", size: 18))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 16/255, green: 185/255, blue: 129/255),
                                Color(red: 6/255, green: 182/255, blue: 212/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 6)
            }
            .disabled(isGeneratingImages || !items.indices.contains(currentIndex))
            .opacity((isGeneratingImages || !items.indices.contains(currentIndex)) ? 0.5 : 1.0)
        }
    }
}

// StorySettingData は他ファイル（QuestionView.swift）に定義済み

#if UNUSED_QUESTION_VIEW
// 既存: 質問画面（このファイルでは未使用のためビルド対象外）
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
    
    // スワイプジェスチャー用
    @State private var dragOffset: CGFloat = 0
    
    // API Base URL
    private let apiBaseURL = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://localhost:8000"
    
    // バックエンドのQuestionResponseに対応したローカルレスポンスモデル
    private struct QuestionAPIResponse: Decodable {
        let questions: [Question]
        let story_setting_id: Int
        let message: String?
        let processing_time_ms: Double?
    }
    
    var body: some View {
        ZStack(alignment: .top) {
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
        // UploadImageView 側で UserDefaults に story_setting_id / data が保存されたら再読込
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            loadStorySettingData()
        }
        .onChange(of: currentIndex) { _ in
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
                // TODO: テーマ選択ページへ遷移
                print("ストーリー生成を開始しました")
            }
        }.resume()
    }
}
#endif

// MARK: - Progress Dots View
struct ProgressDotsView: View {
    let total: Int
    let currentIndex: Int
    
    var body: some View {
        if total > 0 {
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

#Preview {
    ThemaSelectView()
}
