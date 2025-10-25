import SwiftUI
import Combine

struct ThemeSelectView: View {
    // ページの状態管理
    @State private var currentPageIndex = 0
    
    // テーマデータ管理
    @State private var themePages: [ThemePage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // ストーリーブックサービス
    @State private var storybookService: StorybookService?
    
    // ナビゲーション状態
    @State private var isGeneratingImages = false
    @State private var showError = false
    @State private var errorMessageText = ""
    
    // 進捗管理
    @State private var currentStep = 0
    @State private var totalSteps = 4
    @State private var stepMessage = ""
    
    // AppCoordinatorへの参照
    @EnvironmentObject var coordinator: AppCoordinator
    // AuthServiceへの参照
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }
            
            // ヘッダー
            Header()

            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト（カードコンポーネントと同じ光る効果）
                MainText(text: "すきな おはなしを")
                MainText(text: "えらんでね！")
                Spacer()

                // ガラス風カードを表示
                mainCard(width: .screen95) {
                    if isLoading {
                        // ローディング表示（インナーカード内）
                        InnerCard(
                            sections: [
                                .init(
                                    fillsRemainingSpace: true,
                                    alignment: .center
                                ) {
                                    VStack(spacing: 20) {
                                        ProgressView()
                                            .scaleEffect(1.5)
                                        SubText(text: "テーマを読み込み中...", fontSize: 16)
                                    }
                                }
                            ]
                        )
                    } else if let errorMessage = errorMessage, !errorMessage.isEmpty {
                        // エラー表示（インナーカード内）
                        InnerCard(
                            sections: [
                                .init(
                                    fillsRemainingSpace: true,
                                    alignment: .center
                                ) {
                                    VStack(spacing: 20) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 40))
                                            .foregroundColor(.red)
                                        SubText(text: errorMessage, fontSize: 16)
                                        Button("再試行") {
                                            loadThemeDataSync()
                                        }
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                }
                            ]
                        )
                    } else if themePages.isEmpty {
                        // データなし表示（インナーカード内）
                        InnerCard(
                            sections: [
                                .init(
                                    fillsRemainingSpace: true,
                                    alignment: .center
                                ) {
                                    VStack(spacing: 20) {
                                        Image(systemName: "book.closed")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        SubText(text: "テーマが見つかりません", fontSize: 16)
                                    }
                                }
                            ]
                        )
                        } else {
                            // テーマデータがある場合
                            VStack(spacing: 16) {                                
                                // PagerViewComponentでスライド機能を実装
                                PagerViewComponent(themePages, spacing: 20, onPageChanged: { index in
                                    currentPageIndex = index
                                }) { page in
                                    // インナーカードを表示
                                    InnerCard(
                                        sections: [
                                            // おはなしのタイトル
                                            .init(
                                                fixedHeight: 100,
                                                fillsRemainingSpace: false,
                                                alignment: .top
                                            ) {
                                                VStack(spacing: 20) {
                                                    SubText(text: "〈おはなしのタイトル〉")
                                                    SubText(text: page.title)
                                                }
                                            },
                                            // おはなしの概要
                                            .init(
                                                alignment: .top,  // ← 中央揃えではなく上揃えに変更
                                                showDivider: false // 区切り線を表示しない
                                            ) {
                                               ScrollView(showsIndicators: true) {
                                                    SubText(text: page.content)
                                                        .padding(.horizontal, 10) // 左右の余白を追加
                                               }
                                               .frame(maxHeight: .infinity) // 利用可能な高さまで拡張
                                               .padding(.bottom, -10) // 下部の余白を追加
                                            },
                                            // 決定ボタン
                                            .init(
                                                fixedHeight: 80,
                                                fillsRemainingSpace: false,
                                                alignment: .center
                                            ) {
                                                PrimaryButton(
                                                    title: isGeneratingImages ? "画像生成中..." : "これにけってい",
                                                    action: {
                                                        // テーマ選択時のアクション
                                                        Task {
                                                            await selectTheme(page: page)
                                                        }
                                                    }
                                                )
                                                .disabled(isGeneratingImages)
                                            }
                                        ]
                                    )
                                }
                                // プログレスバーを表示
                                if isGeneratingImages {
                                    // 画像生成中の進捗表示
                                    VStack(spacing: 12) {
                                        ProgressBar(
                                            totalSteps: totalSteps,
                                            currentStep: currentStep
                                        )
                                        .padding(.horizontal, 20)
                                        
                                        // 進捗メッセージ
                                        SubText(
                                            text: stepMessage,
                                            fontSize: 14
                                        )
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 20)
                                    }
                                } else {
                                    // 通常のテーマ選択進捗
                                    ProgressBar(
                                        totalSteps: themePages.count,
                                        currentStep: currentPageIndex
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                }
                .padding(.horizontal, 16) // 
                .padding(.bottom, -10) // 画面下部からの余白    
            }

            // テーマ選択後の全画面ローディングオーバーレイ
            if isGeneratingImages {
                // 半透明のフルスクリーンカバー
                Color.black.opacity(0.35)
                    .ignoresSafeArea()

                // 中央のローディングボックス
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.8)
                    Text("えほん作成中")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(Color.black.opacity(0.6))
                .cornerRadius(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear {
            // StorybookServiceを初期化（AuthServiceのAuthManagerを使用）
            storybookService = StorybookService(authManager: authService.authManager)
            
            Task {
                await loadThemeData()
            }
        }
        .alert("エラー", isPresented: $showError) {
            Button("OK") {
                showError = false
                errorMessageText = ""
            }
        } message: {
            Text(errorMessageText)
        }
    }
    
    // MARK: - テーマ選択処理
    @MainActor
    private func selectTheme(page: ThemePage) async {
        isGeneratingImages = true
        errorMessage = nil
        showError = false
        currentStep = 0
        totalSteps = 4
        
        do {
            print("🎨 テーマが選択されました: \(page.title)")
            print("📝 Story Plot ID: \(page.storyPlotId)")
            
            // 認証状態を事前チェック
            print("🔍 ThemeSelectView: テーマ選択前の認証状態チェック")
            
            // 1. 最新のstory_setting_idを取得
            guard let userId = authService.getCurrentUserId() else {
                print("❌ ThemeSelectView: ユーザーIDが取得できません")
                throw StorybookAPIError.serverError(401, "ユーザーIDが取得できません")
            }
            
            // 認証トークンの有効性をチェック
            if !authService.verifyToken() {
                print("❌ ThemeSelectView: 認証トークンが無効です")
                throw StorybookAPIError.serverError(401, "認証トークンが無効です")
            }
            
            print("✅ ThemeSelectView: 認証状態OK - userId: \(userId)")
            
            guard let storybookService = storybookService else {
                throw StorybookAPIError.serverError(401, "StorybookServiceが初期化されていません")
            }
            let storySettingId = try await storybookService.fetchLatestStorySettingId(userId: userId)
            
            // ステップ1: 物語生成
            currentStep = 1
            stepMessage = "おはなしを生成中..."
            print("📝 Step 1: Generating story...")
            let storyResponse = try await storybookService.generateStory(storySettingId: storySettingId, selectedTheme: page.selectedTheme)
            
            // ステップ2: ストーリーブック作成
            currentStep = 2
            stepMessage = "絵本を作成中..."
            print("📖 Step 2: Creating storybook...")
            let storybookResponse = try await storybookService.createStorybook(storyPlotId: storyResponse.storyPlotId, selectedTheme: storyResponse.selectedTheme)
            
            // ステップ3: 画像生成
            currentStep = 3
            stepMessage = "絵を描いています..."
            print("🎨 Step 3: Generating images...")
            _ = try await storybookService.generateStoryImages(storybookId: storybookResponse.storybookId)
            
            // ステップ4: 画像URL更新
            currentStep = 4
            stepMessage = "最終調整中..."
            print("🔄 Step 4: Updating image URLs...")
            _ = try await storybookService.updateImageUrls(storybookId: storybookResponse.storybookId)
            
            print("✅ テーマ選択フローが完了しました: storybookId=\(storybookResponse.storybookId)")
            
            // 完了: StoryBookViewに遷移
            coordinator.navigateToStorybook(storybookId: storybookResponse.storybookId)
            
        } catch {
            print("❌ テーマ選択エラー: \(error)")
            
            // 認証エラーの場合は特別な処理
            if let storybookError = error as? StorybookAPIError,
               case .serverError(let code, _) = storybookError,
               code == 401 {
                print("🚨 ThemeSelectView: テーマ選択時の認証エラー検出 - ログアウト処理を実行")
                
                // 認証エラーの場合は自動的にログアウト
                DispatchQueue.main.async {
                    self.authService.logout()
                    // トップページに戻る
                    self.coordinator.navigateToTop()
                }
                
                errorMessageText = "認証に問題があります。ログインし直してください。"
                showError = true
            } else {
                // エラーメッセージをユーザーフレンドリーに変換
                let userFriendlyMessage = convertToUserFriendlyMessage(error)
                errorMessageText = userFriendlyMessage
                showError = true
            }
            
            // 進捗をリセット
            currentStep = 0
            stepMessage = ""
            
            // エラー表示後にisGeneratingImagesをfalseに設定
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isGeneratingImages = false
            }
            return
        }
        
        isGeneratingImages = false
    }
    
    // MARK: - テーマデータ読み込み
    @MainActor
    private func loadThemeData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 認証状態を事前チェック（緩和版）
            print("🔍 ThemeSelectView: 認証状態チェック開始")
            
            // 認証済みユーザーIDを取得
            guard let userId = authService.getCurrentUserId() else {
                print("❌ ThemeSelectView: ユーザーIDが取得できません")
                // ユーザーIDが取得できない場合は、認証エラーではなくデータなしとして扱う
                themePages = []
                print("⚠️ ThemeSelectView: ユーザーIDが取得できないため、空のテーマリストを表示")
                return
            }
            
            print("✅ ThemeSelectView: ユーザーID取得OK - userId: \(userId)")
            
            guard let storybookService = storybookService else {
                print("❌ ThemeSelectView: StorybookServiceが初期化されていません")
                themePages = []
                return
            }
            
            // 最新のstory_setting_idを取得
            let storySettingId = try await storybookService.fetchLatestStorySettingId(userId: userId)
            
            // テーマプロット一覧を取得
            let themePlotsResponse = try await storybookService.fetchThemePlots(userId: userId, storySettingId: storySettingId, limit: 3)
            
            // ThemePlotResponseからThemePageに変換
            themePages = themePlotsResponse.items.map { ThemePage(from: $0) }
            
            print("✅ テーマデータ読み込み完了: \(themePages.count)件")
            
        } catch {
            print("❌ テーマデータ読み込みエラー: \(error)")
            
            // 認証エラーの場合は特別な処理
            if let storybookError = error as? StorybookAPIError,
               case .serverError(let code, _) = storybookError,
               code == 401 {
                print("🚨 ThemeSelectView: 認証エラー検出 - ログアウト処理を実行")
                
                // 認証エラーの場合は自動的にログアウト
                DispatchQueue.main.async {
                    self.authService.logout()
                    // トップページに戻る
                    self.coordinator.navigateToTop()
                }
                
                errorMessage = "認証に問題があります。ログインし直してください。"
            } else {
                // その他のエラーは空のテーマリストとして扱う（エラー表示しない）
                print("⚠️ ThemeSelectView: APIエラーのため、空のテーマリストを表示")
                themePages = []
            }
        }
        
        isLoading = false
    }
    
    // 同期版のloadThemeData（ボタンアクション用）
    private func loadThemeDataSync() {
        Task {
            await loadThemeData()
        }
    }
    
    // エラーメッセージをユーザーフレンドリーに変換
    private func convertToUserFriendlyMessage(_ error: Error) -> String {
        if let storybookError = error as? StorybookAPIError {
            switch storybookError {
            case .networkError(let error):
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    return "処理に時間がかかっています。しばらく待ってからもう一度お試しください。"
                }
                return "ネットワーク接続に問題があります。インターネット接続を確認してください。"
            case .serverError(let code, let message):
                switch code {
                case 401:
                    return "認証に問題があります。ログインし直してください。"
                case 500...599:
                    return "サーバーでエラーが発生しました。しばらく時間をおいてから再度お試しください。"
                case 400...499:
                    return "リクエストに問題があります。もう一度お試しください。"
                default:
                    return "サーバーエラーが発生しました。"
                }
            case .storybookNotFound:
                return "絵本が見つかりません。"
            case .decodingError:
                return "データの処理中にエラーが発生しました。"
            case .invalidURL:
                return "無効なURLです。"
            case .noData:
                return "データが取得できませんでした。"
            case .invalidResponse:
                return "サーバーからの応答に問題があります。"
            }
        }
        
        // 一般的なエラーメッセージ
        return "予期しないエラーが発生しました。もう一度お試しください。"
    }
}

/*
#Preview {
    ThemeSelectView()
}
*/
