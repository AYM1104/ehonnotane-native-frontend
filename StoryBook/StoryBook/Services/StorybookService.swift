//
//  StorybookService.swift
//  StoryBook
//
//  Created by ayu on 2025/10/16.
//

import Foundation
import Combine
import SwiftUI

// MARK: - API エラー定義

enum StorybookAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int, String)
    case storybookNotFound
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .noData:
            return "データが取得できませんでした"
        case .decodingError:
            return "データの解析に失敗しました"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "サーバーエラー (\(code)): \(message)"
        case .storybookNotFound:
            return "絵本が見つかりません"
        case .invalidResponse:
            return "無効なレスポンスです"
        }
    }
}

// MARK: - 絵本データ取得サービス

public class StorybookService: ObservableObject {
    private let baseURL = "http://192.168.3.93:8000"
    public static let shared = StorybookService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - 認証トークン管理
    private let authManager: AuthManager
    
    // MARK: - 初期化
    public init(authManager: AuthManager = AuthManager()) {
        self.authManager = authManager
    }
    
    // MARK: - 認証状態の同期（後方互換性のため残す）
    func syncAuthState(with authManager: AuthManager) {
        // 初期化時にAuthManagerを設定するため、このメソッドは不要
        print("⚠️ syncAuthStateは非推奨です。初期化時にAuthManagerを渡してください")
    }
    
    /// 認証トークンを設定（外部から）
    func setAuthToken(_ token: String?) {
        authManager.setAccessToken(token)
        print("✅ StorybookService: AuthManager経由でトークンを設定しました")
    }
    
    /// 現在のユーザーIDを取得
    func getCurrentUserId() -> String? {
        return authManager.getCurrentUserId()
    }
    
    // MARK: - 認証トークン管理メソッド（AuthManagerを使用）
    
    /// アクセストークンを設定
    func setAccessToken(_ token: String?) {
        // AuthManagerを使用するため、このメソッドは非推奨
        print("⚠️ setAccessTokenは非推奨です。AuthManagerを使用してください")
    }
    
    /// 現在のアクセストークンを取得
    func getAccessToken() -> String? {
        return authManager.getAccessToken()
    }
    
    /// 認証状態を確認
    func isAuthenticated() -> Bool {
        return authManager.verifyAuthState()
    }
    
    // MARK: - 認証エラー処理
    
    /// 認証エラー時の自動ログアウト処理
    private func handleAuthError(_ error: StorybookAPIError) {
        if case .serverError(let code, let message) = error {
            if code == 401 {
                print("🚨 StorybookService: 認証エラー検出 - 自動ログアウト実行")
                print("   - エラーメッセージ: \(message)")
                
                // AuthManager経由でログアウト
                DispatchQueue.main.async {
                    self.authManager.logout()
                }
            }
        }
    }
    
    /// リクエスト前の認証状態チェック
    private func checkAuthBeforeRequest() throws {
        guard let token = getAccessToken() else {
            print("❌ StorybookService: アクセストークンが存在しません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        // トークンの有効性をチェック
        if !authManager.verifyAuthState() {
            print("❌ StorybookService: トークンが無効です")
            
            // トークンリフレッシュを試行
            if authManager.shouldRefreshToken() && authManager.hasRefreshToken() {
                print("🔄 StorybookService: トークンリフレッシュを試行中...")
                // 注意: 実際のリフレッシュ処理は非同期で実行する必要があります
                // 現在は同期的なチェックのみ
            }
            
            throw StorybookAPIError.serverError(401, "トークンが無効です")
        }
        
        print("✅ StorybookService: 認証状態OK - トークン: \(String(token.prefix(20)))...")
    }
    
    func fetchStorybook(storybookId: Int) async throws -> StorybookResponse {
        guard let url = URL(string: "\(baseURL)/storybook/\(storybookId)") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("📚 Fetching storybook from: \(url)")
        guard let token = getAccessToken(), authManager.verifyAuthState() else {
            print("❌ fetchStorybook: 認証トークンが無効または存在しません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        print("✅ fetchStorybook: 認証トークンを設定しました")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    break
                case 404:
                    throw StorybookAPIError.storybookNotFound
                case 400...599:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
                    handleAuthError(error)
                    throw error
                default:
                    throw StorybookAPIError.serverError(httpResponse.statusCode, "予期しないエラー")
                }
            }
            
            // レスポンスデータの詳細ログ
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
                        
            let decoder = JSONDecoder()
            let storybookResponse: StorybookResponse = try decoder.decode(StorybookResponse.self, from: data)
            
            print("✅ Storybook data received successfully")
            print("📖 Title: \(storybookResponse.title)")
            print("📄 Pages with content: \(([storybookResponse.page1, storybookResponse.page2, storybookResponse.page3, storybookResponse.page4, storybookResponse.page5] as [String]).filter { !$0.isEmpty }.count)")
            print("🖼️ Image URLs: page1=\(storybookResponse.page1ImageUrl != nil ? "✅" : "❌"), page2=\(storybookResponse.page2ImageUrl != nil ? "✅" : "❌"), page3=\(storybookResponse.page3ImageUrl != nil ? "✅" : "❌"), page4=\(storybookResponse.page4ImageUrl != nil ? "✅" : "❌"), page5=\(storybookResponse.page5ImageUrl != nil ? "✅" : "❌")")
            print("📊 Image generation status: \(storybookResponse.imageGenerationStatus)")
            
            return storybookResponse
            
        } catch let error as StorybookAPIError {
            throw error
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error: \(decodingError)")
            handleDecodingError(decodingError)
            throw StorybookAPIError.decodingError
        } catch {
            print("❌ Network error: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // デコーディングエラーの詳細ログ出力
    private func handleDecodingError(_ error: DecodingError) {
        switch error {
        case .typeMismatch(let type, let context):
            print("🔍 Type mismatch: expected \(type)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        case .valueNotFound(let type, let context):
            print("🔍 Value not found: \(type)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        case .keyNotFound(let key, let context):
            print("🔍 Key not found: \(key.stringValue)")
            print("🔍 Context: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        case .dataCorrupted(let context):
            print("🔍 Data corrupted: \(context.debugDescription)")
            print("🔍 Coding path: \(context.codingPath.map { $0.stringValue })")
        @unknown default:
            print("🔍 Unknown decoding error")
        }
    }
    
    // 画像生成状態の判定
    func isGeneratingImages(_ storybook: StorybookResponse) -> Bool {
        return storybook.imageGenerationStatus == "generating" || storybook.imageGenerationStatus == "pending"
    }
    
    // 生成状態に応じたメッセージを取得
    func getGenerationMessage(_ status: String) -> String {
        switch status {
        case "pending":
            return "絵本の準備中..."
        case "generating":
            return "絵本の絵を描いています..."
        case "completed":
            return "絵本が完成しました！"
        case "failed":
            return "絵本の生成に失敗しました"
        default:
            return "処理中..."
        }
    }
}


// MARK: - テーマ取得サービス

extension StorybookService {
    
    // APIレスポンス用の簡易ストーリー設定情報
    private struct StorySettingSummary: Codable {
        let id: Int
        let uploadImageId: Int
        let titleSuggestion: String
        let protagonistName: String
        let protagonistType: String
        let settingPlace: String
        let tone: String
        let targetAge: String
        let language: String
        let readingLevel: String
        let styleGuideline: String
        let createdAt: String
        let updatedAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case uploadImageId = "upload_image_id"
            case titleSuggestion = "title_suggestion"
            case protagonistName = "protagonist_name"
            case protagonistType = "protagonist_type"
            case settingPlace = "setting_place"
            case tone
            case targetAge = "target_age"
            case language
            case readingLevel = "reading_level"
            case styleGuideline = "style_guideline"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    // ユーザーの最新のstory_setting_idを取得
    func fetchLatestStorySettingId(userId: String) async throws -> Int {
        // 認証状態を事前チェック
        try checkAuthBeforeRequest()
        
        guard let url = URL(string: "\(baseURL)/story/story_settings") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🔍 Fetching latest story setting for user: \(userId)")
        
        // 認証ヘッダーを追加
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを追加
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
                    
                    // 認証エラーの場合は自動ログアウト
                    handleAuthError(error)
                    
                    throw error
                }
            }
            
            // レスポンスデータの詳細ログ
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response (story_settings):")
                print(jsonString)
            }
            
            // JSON配列として解析（型注釈を追加）
            let storySettings: [StorySettingSummary] = try JSONDecoder().decode([StorySettingSummary].self, from: data)
            
            guard !storySettings.isEmpty else {
                throw StorybookAPIError.storybookNotFound
            }
            
            // created_at で最新順にソートして最新のレコードを取得
            let isoFormatter = ISO8601DateFormatter()
            let latestSetting = storySettings
                .sorted {
                    guard
                        let lhs = isoFormatter.date(from: $0.createdAt),
                        let rhs = isoFormatter.date(from: $1.createdAt)
                    else {
                        return $0.createdAt > $1.createdAt
                    }
                    return lhs > rhs
                }
                .first!
            
            print("✅ Latest story setting ID: \(latestSetting.id)")
            return latestSetting.id
            
        } catch let error as StorybookAPIError {
            throw error
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error (story settings): \(decodingError)")
            handleDecodingError(decodingError)
            throw StorybookAPIError.decodingError
        } catch {
            print("❌ Network error: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // テーマプロット一覧を取得
    func fetchThemePlots(userId: String, storySettingId: Int, limit: Int = 3) async throws -> ThemePlotsListResponse {
        // 認証状態を事前チェック
        try checkAuthBeforeRequest()
        
        var components = URLComponents(string: "\(baseURL)/story/story_plots")!
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userId),
            URLQueryItem(name: "story_setting_id", value: String(storySettingId)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🎨 Fetching theme plots from: \(url)")
        
        // 認証ヘッダーを追加
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 認証トークンを追加
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
                    
                    // 認証エラーの場合は自動ログアウト
                    handleAuthError(error)
                    
                    throw error
                }
            }
            
            // レスポンスデータの詳細ログ
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
            
            let decoder = JSONDecoder()
            let themePlotsResponse: ThemePlotsListResponse = try decoder.decode(ThemePlotsListResponse.self, from: data)
            
            print("✅ Theme plots data received successfully")
            print("🎨 Count: \(themePlotsResponse.count)")
            print("📝 Items: \(themePlotsResponse.items.map { $0.title })")
            
            return themePlotsResponse
            
        } catch let error as StorybookAPIError {
            throw error
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding error: \(decodingError)")
            handleDecodingError(decodingError)
            throw StorybookAPIError.decodingError
        } catch {
            print("❌ Network error: \(error)")
            throw StorybookAPIError.networkError(error)
        }
    }
    
    // MARK: - テーマ選択フロー
    
    // テーマ選択フロー用のレスポンスモデル
    struct ThemeSelectionResponse: Codable {
        let storybookId: Int
        let message: String
        
        enum CodingKeys: String, CodingKey {
            case storybookId = "storybook_id"
            case message
        }
    }
    
    struct StoryGenerationResponse: Codable {
        let storyPlotId: Int
        let storySettingId: Int
        let selectedTheme: String
        let message: String
        
        enum CodingKeys: String, CodingKey {
            case storyPlotId = "story_plot_id"
            case storySettingId = "story_setting_id"
            case selectedTheme = "selected_theme"
            case message
        }
    }
    
    struct ImageGenerationResponse: Codable {
        let message: String
        let generatedImages: [String]
        
        enum CodingKeys: String, CodingKey {
            case message
            case generatedImages = "generated_images"
        }
        
        init(message: String, generatedImages: [String]) {
            self.message = message
            self.generatedImages = generatedImages
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
            self.generatedImages = try container.decodeIfPresent([String].self, forKey: .generatedImages) ?? []
        }
    }
    
    struct ImageUrlUpdateResponse: Codable {
        let message: String
        let updatedPages: [String]
        // デコードの互換性確保のために件数も保持（配列/数値どちらにも対応）
        let updatedPagesCount: Int
        
        enum CodingKeys: String, CodingKey {
            case message
            case updatedPages = "updated_pages"
        }
        
        // 明示的なイニシャライザ（テスト等で利用）
        init(message: String, updatedPages: [String]) {
            self.message = message
            self.updatedPages = updatedPages
            self.updatedPagesCount = updatedPages.count
        }
        
        // バックエンドが updated_pages を配列（推奨）または数値（後方互換）で返すケースに対応
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
            if let pagesArray = try? container.decode([String].self, forKey: .updatedPages) {
                self.updatedPages = pagesArray
                self.updatedPagesCount = pagesArray.count
            } else if let pagesInt = try? container.decode(Int.self, forKey: .updatedPages) {
                self.updatedPages = []
                self.updatedPagesCount = max(0, pagesInt)
            } else {
                self.updatedPages = []
                self.updatedPagesCount = 0
            }
        }
    }
    
    // ステップ1: 物語生成
    func generateStory(storySettingId: Int, selectedTheme: String) async throws -> StoryGenerationResponse {
        // 認証状態を事前チェック
        try checkAuthBeforeRequest()
        
        guard let url = URL(string: "\(baseURL)/story/select_theme") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("📚 Generating story from theme: storySettingId=\(storySettingId), selectedTheme=\(selectedTheme)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        // 認証トークンを追加
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        let requestBody: [String: Any] = [
            "story_setting_id": storySettingId,
            "selected_theme": selectedTheme
        ]
        
        // リクエストボディのデバッグ出力
        if let jsonData = try? JSONSerialization.data(withJSONObject: requestBody),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 Request body: \(jsonString)")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        // レスポンスのデバッグ出力
        print("📥 Response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            let error = StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
            
            // 認証エラーの場合は自動ログアウト
            handleAuthError(error)
            
            print("❌ Server error: \(httpResponse.statusCode) - \(errorMessage)")
            throw error
        }
        
        let decoder = JSONDecoder()
        let storyResponse = try decoder.decode(StoryGenerationResponse.self, from: data)
        
        print("✅ Story generated successfully: storyPlotId=\(storyResponse.storyPlotId)")
        return storyResponse
    }
    
    // ステップ2: ストーリーブック作成
    func createStorybook(storyPlotId: Int, selectedTheme: String) async throws -> ThemeSelectionResponse {
        guard let url = URL(string: "\(baseURL)/storybook/confirm-theme-and-create") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("📖 Creating storybook from plot: storyPlotId=\(storyPlotId), selectedTheme=\(selectedTheme)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        // 認証トークンを追加
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        let requestBody: [String: Any] = [
            "story_plot_id": storyPlotId,
            "selected_theme": selectedTheme
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        let storybookResponse = try decoder.decode(ThemeSelectionResponse.self, from: data)
        
        print("✅ Storybook created successfully: storybookId=\(storybookResponse.storybookId)")
        return storybookResponse
    }
    
    // ステップ3: 画像生成
    func generateStoryImages(storybookId: Int) async throws -> ImageGenerationResponse {
        guard let url = URL(string: "\(baseURL)/images/generation/generate-storyplot-all-pages-image-to-image") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🎨 Generating images for storybook: storybookId=\(storybookId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        // 認証トークンを設定
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = [
            "storybook_id": storybookId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        let imageResponse = try decoder.decode(ImageGenerationResponse.self, from: data)
        
        print("✅ Images generated successfully: \(imageResponse.generatedImages.count) images")
        return imageResponse
    }
    
    // ステップ4: 画像URL更新
    func updateImageUrls(storybookId: Int) async throws -> ImageUrlUpdateResponse {
        guard let url = URL(string: "\(baseURL)/storybook/update-image-urls") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🔄 Updating image URLs for storybook: storybookId=\(storybookId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300
        
        // 認証トークンを追加
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("✅ 認証トークンを設定しました")
        } else {
            print("❌ 認証トークンが取得できません")
            throw StorybookAPIError.serverError(401, "認証が必要です")
        }
        
        let requestBody = [
            "storybook_id": storybookId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StorybookAPIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
            throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        let updateResponse = try decoder.decode(ImageUrlUpdateResponse.self, from: data)
        
        print("✅ Image URLs updated successfully: \(updateResponse.updatedPagesCount) pages")
        return updateResponse
    }
    
    // テーマ選択フロー全体を実行
    func executeThemeSelectionFlow(storySettingId: Int, storyPlotId: Int, selectedTheme: String) async throws -> Int {
        print("🚀 Starting theme selection flow: storySettingId=\(storySettingId), storyPlotId=\(storyPlotId), selectedTheme=\(selectedTheme)")
        
        var generatedStoryPlotId: Int?
        var storybookId: Int?
        
        do {
            // ステップ1: 物語生成
            print("📝 Step 1: Generating story...")
            let storyResponse = try await generateStory(storySettingId: storySettingId, selectedTheme: selectedTheme)
            generatedStoryPlotId = storyResponse.storyPlotId
            
            // ステップ2: ストーリーブック作成
            print("📖 Step 2: Creating storybook...")
            let storybookResponse = try await createStorybook(storyPlotId: storyResponse.storyPlotId, selectedTheme: storyResponse.selectedTheme)
            storybookId = storybookResponse.storybookId
            
            // ステップ3: 画像生成
            print("🎨 Step 3: Generating images...")
            _ = try await generateStoryImages(storybookId: storybookResponse.storybookId)
            
            // ステップ4: 画像URL更新
            print("🔄 Step 4: Updating image URLs...")
            _ = try await updateImageUrls(storybookId: storybookResponse.storybookId)
            
            print("✅ Theme selection flow completed successfully: storybookId=\(storybookResponse.storybookId)")
            return storybookResponse.storybookId
            
        } catch {
            print("❌ Theme selection flow failed: \(error)")
            
            // ロールバック処理
            await rollbackThemeSelectionFlow(storyPlotId: generatedStoryPlotId, storybookId: storybookId)
            
            throw error
        }
    }
    
    // ロールバック処理
    private func rollbackThemeSelectionFlow(storyPlotId: Int?, storybookId: Int?) async {
        print("🔄 Starting rollback process...")
        
        // 注意: 実際のロールバック処理は、バックエンドAPIで
        // 適切なロールバック機能が実装されている場合にのみ有効
        // 現在はログ出力のみ
        
        if let storybookId = storybookId {
            print("🗑️ Rollback: Storybook \(storybookId) should be deleted")
        }
        
        if let storyPlotId = storyPlotId {
            print("🗑️ Rollback: Story plot \(storyPlotId) should be deleted")
        }
        
        print("🔄 Rollback process completed")
    }
}
