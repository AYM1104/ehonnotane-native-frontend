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
    
    private init() {
        // 環境変数からAPIベースURLを取得、デフォルトはlocalhost
        self.baseURL = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://localhost:8000"
    }
    
    // MARK: - 画像生成開始
    func generateImages(for storySettingId: Int, themeTitle: String) async throws {
        guard storySettingId > 0 else {
            throw ImageGenerationError.invalidStorySettingId
        }
        
        // 進捗状態をリセットして開始
        progress.start(total: 5)
        errorMessage = nil
        
        do {
            // 実際のAPI呼び出し（現在はモック）
            try await performImageGeneration(storySettingId: storySettingId, themeTitle: themeTitle)
            
            progress.finish()
            
        } catch {
            progress.reset()
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - 実際の画像生成処理（モック実装）
    private func performImageGeneration(storySettingId: Int, themeTitle: String) async throws {
        // 実際のAPI実装に置き換える
        // 現在は疑似的な生成進行をシミュレート
        
        for page in 1...5 {
            // 生成開始
            progress.setGenerating(
                pageNumber: page,
                message: "ページ \(page) の画像を生成中..."
            )
            
            // 生成時間をシミュレート（実際のAPI呼び出しに置き換え）
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
            
            // 生成完了
            progress.setCompleted(pageNumber: page)
        }
    }
    
    // MARK: - 実際のAPI実装（将来の実装用）
    private func callImageGenerationAPI(storySettingId: Int, themeTitle: String) async throws {
        guard let url = URL(string: "\(baseURL)/story/generate_images") else {
            throw ImageGenerationError.invalidStorySettingId
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "story_setting_id": storySettingId,
            "theme_title": themeTitle
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    // 成功時の処理
                    break
                case 400...599:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    throw ImageGenerationError.serverError(httpResponse.statusCode, errorMessage)
                default:
                    throw ImageGenerationError.serverError(httpResponse.statusCode, "予期しないエラー")
                }
            }
            
        } catch let error as ImageGenerationError {
            throw error
        } catch {
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
