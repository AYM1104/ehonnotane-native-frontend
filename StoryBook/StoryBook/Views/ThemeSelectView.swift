import SwiftUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - テーマ選択画面（Next.js版の再現）
struct ThemaSelectView: View {
    // 画像生成サービス
    @StateObject private var imageGenerationService = ImageGenerationService.shared
    
    // テーマデータ
    @State private var storySettingId: Int? = nil
    @State private var latestTitles: [ThemeItem] = []
    @State private var titleSlideIndex: Int = 0
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var error: String? = nil

    // API Base URL（必要に応じて利用）
    private let apiBaseURL = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://localhost:8000"

    var body: some View {
        ZStack(alignment: .top) {
            // 背景コンポーネント
            Background {
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
                        mainCard(width: .screen95) {
                            VStack(spacing: 16) {
                                // ThemeCardコンポーネントを使用
                                if latestTitles.indices.contains(titleSlideIndex) {
                                    ThemeCard(
                                        theme: convertToTheme(from: latestTitles[titleSlideIndex]),
                                        isSelected: false,
                                        onTap: onSelectTheme
                                    )
                                    .padding(.horizontal, 8)
                                } else {
                                    Text("テーマがありません")
                                        .font(.custom("YuseiMagic-Regular", size: 20))
                                        .foregroundColor(.gray)
                                        .padding()
                                }

                                // CTA ボタン（グリーングラデーション、角丸 pill）
                                Button(action: onSelectTheme) {
                                    Text(imageGenerationService.isGenerating ? "せいせいちゅう..." : "このテーマを選択")
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
                                .disabled(imageGenerationService.isGenerating || !latestTitles.indices.contains(titleSlideIndex))
                                .opacity((imageGenerationService.isGenerating || !latestTitles.indices.contains(titleSlideIndex)) ? 0.5 : 1.0)

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
            if imageGenerationService.isGenerating {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                VStack {
                    ImageGenerationProgressView(
                        currentImage: imageGenerationService.progress.current,
                        totalImages: imageGenerationService.progress.total,
                        currentImageDetails: imageGenerationService.progress.currentImageDetails
                    )
                    .padding(.horizontal, 24)
                }
            }
            
            // キャラクター（Backgroundの制約から外して配置）
            BigCharacter()
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

        // 画像生成サービスを使用
        Task {
            do {
                try await imageGenerationService.generateImages(
                    for: storySettingId,
                    themeTitle: latestTitles[titleSlideIndex].title
                )
                
                DispatchQueue.main.async {
                    self.alertMessage = "テーマ『\(self.latestTitles[self.titleSlideIndex].title)』の画像生成が完了しました！\n生成された画像数: \(self.imageGenerationService.progress.total)"
                    self.showAlert = true
                    // 本来は storybook 画面へ遷移を行う
                    print("Push to /storybook/<id> with story_setting_id=\(storySettingId)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "画像生成に失敗しました: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
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
    
    // ThemeItemをThemeモデルに変換する関数
    private func convertToTheme(from themeItem: ThemeItem) -> Theme {
        return Theme(
            id: themeItem.id.uuidString,
            name: themeItem.title,
            description: themeItem.description,
            iconName: "book.fill", // デフォルトアイコン
            imageName: nil
        )
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
