//
//  ImageGenerationService.swift
//  StoryBook
//
//  Created by ayu on 2025/01/27.
//

import Foundation
import Combine

// MARK: - 画像生成エラー定義
enum ImageGenerationError: Error, LocalizedError {
    case invalidStorySettingId
    case networkError(Error)
    case serverError(Int, String)
    case generationFailed(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidStorySettingId:
            return "ストーリー設定IDが無効です"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "サーバーエラー (\(code)): \(message)"
        case .generationFailed(let message):
            return "画像生成に失敗しました: \(message)"
        case .invalidResponse:
            return "無効なレスポンスです"
        }
    }
}

// MARK: - 画像生成進捗状態
struct ImageGenerationProgressState {
    var total: Int = 0
    var current: Int = 0
    var currentImageDetails: String = ""
    var isGenerating: Bool = false
    
    mutating func start(total: Int) {
        self.total = total
        self.current = 0
        self.currentImageDetails = "画像生成中... (0/\(total))"
        self.isGenerating = true
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
        self.isGenerating = false
    }
    
    mutating func reset() {
        total = 0
        current = 0
        currentImageDetails = ""
        isGenerating = false
    }
}

// MARK: - 画像生成サービス
@MainActor
class ImageGenerationService: ObservableObject {
    private let baseURL: String
    static let shared = ImageGenerationService()
    
    @Published var progress = ImageGenerationProgressState()
    @Published var errorMessage: String?
    
    // MARK: - 認証トークン管理
    private let authManager = AuthManager()
    
    private init() {
        // 環境変数からAPIベースURLを取得、デフォルトはlocalhost
        self.baseURL = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://192.168.3.93:8000"
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
    
    // MARK: - 画像生成開始
    func generateImages(for storySettingId: Int, themeTitle: String, storyPlotId: Int) async throws {
        guard storySettingId > 0 && storyPlotId > 0 else {
            throw ImageGenerationError.invalidStorySettingId
        }
        
        // 認証トークンが必須
        guard let token = getAccessToken() else {
            print("❌ 認証トークンが未設定です")
            throw ImageGenerationError.serverError(401, "認証が必要です")
        }
        
        print("✅ 認証済みユーザーで画像生成を実行")
        
        // 進捗状態をリセットして開始
        progress.start(total: 5)
        errorMessage = nil
        
        do {
            // 実際のAPI呼び出し
            try await performImageGeneration(storySettingId: storySettingId, themeTitle: themeTitle, storyPlotId: storyPlotId)
            
            progress.finish()
            
        } catch {
            progress.reset()
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - 実際の画像生成処理
    private func performImageGeneration(storySettingId: Int, themeTitle: String, storyPlotId: Int) async throws {
        // 実際のAPI呼び出しを実行
        try await callImageGenerationAPI(storySettingId: storySettingId, themeTitle: themeTitle, storyPlotId: storyPlotId)
    }
    
    // MARK: - 実際のAPI実装
    private func callImageGenerationAPI(storySettingId: Int, themeTitle: String, storyPlotId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/images/generation/generate-storyplot-all-pages-image-to-image") else {
            throw ImageGenerationError.invalidStorySettingId
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 180
        
        // 認証トークンを設定
        if let token = getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "story_plot_id": storyPlotId,
            "strength": 0.8,
            "prefix": "storyplot_i2i_all"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("🎨 画像生成API呼び出し開始: \(url)")
            print("📝 リクエストボディ: \(requestBody)")
            
            // 生成開始メッセージ
            progress.setGenerating(
                pageNumber: 1,
                message: "画像生成を開始しています..."
            )
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 画像生成API レスポンス: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    // 成功時の処理
                    progress.setCompleted(pageNumber: 5)
                    print("✅ 画像生成API呼び出し成功")
                    break
                case 400...599:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    print("❌ 画像生成API エラー: \(httpResponse.statusCode) - \(errorMessage)")
                    throw ImageGenerationError.serverError(httpResponse.statusCode, errorMessage)
                default:
                    print("❌ 画像生成API 予期しないエラー: \(httpResponse.statusCode)")
                    throw ImageGenerationError.serverError(httpResponse.statusCode, "予期しないエラー")
                }
            }
            
        } catch let error as ImageGenerationError {
            throw error
        } catch {
            print("❌ 画像生成API ネットワークエラー: \(error)")
            throw ImageGenerationError.networkError(error)
        }
    }
    
    // MARK: - 進捗リセット
    func resetProgress() {
        progress.reset()
        errorMessage = nil
    }
    
    // MARK: - 生成状態の確認
    var isGenerating: Bool {
        return progress.isGenerating
    }
    
    var isCompleted: Bool {
        return progress.current >= progress.total && !progress.isGenerating
    }
}
