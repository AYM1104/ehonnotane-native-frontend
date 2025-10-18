//
//  StorybookService.swift
//  StoryBook
//
//  Created by ayu on 2025/10/16.
//

import Foundation
import Combine

// MARK: - API エラー定義

enum StorybookAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case serverError(Int, String)
    case storybookNotFound
    
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
        }
    }
}

// MARK: - 絵本データ取得サービス

class StorybookService: ObservableObject {
    private let baseURL = "http://localhost:8000"
    static let shared = StorybookService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    func fetchStorybook(storybookId: Int) async throws -> StorybookResponse {
        guard let url = URL(string: "\(baseURL)/storybook/\(storybookId)") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("📚 Fetching storybook from: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200:
                    break
                case 404:
                    throw StorybookAPIError.storybookNotFound
                case 400...599:
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
                default:
                    throw StorybookAPIError.serverError(httpResponse.statusCode, "予期しないエラー")
                }
            }
            
            // レスポンスデータの詳細ログ
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw JSON response:")
                print(jsonString)
            }
            
            // デバッグ用：JSONデコードをスキップしてテスト
            // この行をコメントアウトしてデバッグ
            /*
            print("🔧 Debug mode: Skipping JSON decode")
            throw StorybookAPIError.decodingError
            */
            
            let decoder = JSONDecoder()
            let storybookResponse = try decoder.decode(StorybookResponse.self, from: data)
            
            print("✅ Storybook data received successfully")
            print("📖 Title: \(storybookResponse.title)")
            print("📄 Pages with content: \([storybookResponse.page1, storybookResponse.page2, storybookResponse.page3, storybookResponse.page4, storybookResponse.page5].filter { !$0.isEmpty }.count)")
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
