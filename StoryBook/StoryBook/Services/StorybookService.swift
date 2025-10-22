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
        guard let url = URL(string: "\(baseURL)/story/story_settings") else {
            throw StorybookAPIError.invalidURL
        }
        
        print("🔍 Fetching latest story setting for user: \(userId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
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
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "不明なエラー"
                    throw StorybookAPIError.serverError(httpResponse.statusCode, errorMessage)
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
}
