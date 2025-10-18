import Foundation
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

// 画像アップロード用のレスポンスモデル
struct UploadImageResponse: Codable {
    let id: Int
    let file_name: String
    let file_path: String
    let content_type: String
    let size_bytes: Int
    let uploaded_at: String
    let meta_data: String?
    let public_url: String?
}

// ゲストログイン用のリクエストモデル
struct GuestLoginRequest: Codable {
    let device_uuid: String
}

// 認証レスポンスモデル
struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
}

// ユーザー情報モデル
struct UserInfo: Codable {
    let user_id: String
    let user_name: String?
}

// 認証済みURLレスポンスモデル
struct SignedUrlResponse: Codable {
    let signed_url: String
}

// 物語設定作成レスポンスモデル
struct StorySettingCreateResponse: Codable {
    let story_setting_id: Int
    let generated_data: StorySettingGeneratedData?
}

// 物語設定生成データモデル
struct StorySettingGeneratedData: Codable {
    let title_suggestion: String?
    let protagonist_name: String?
    let protagonist_type: String?
    let setting_place: String?
    let tone: String?
    let target_age: String?
    let language: String?
    let reading_level: String?
    let style_guideline: String?
}

// 画像アップロードサービス
class ImageUploadService: ObservableObject {
    // ObservableObjectの要件を満たすためのPublishedプロパティ
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    // バックエンドAPIのベースURL（環境変数優先、未設定時はローカル）
    private let baseURL = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://localhost:8000"
    
    private var accessToken: String?
    
    // デバイスUUIDを生成または取得
    private var deviceUUID: String {
        if let uuid = UserDefaults.standard.string(forKey: "device_uuid") {
            return uuid
        } else {
            let newUUID = UUID().uuidString
            UserDefaults.standard.set(newUUID, forKey: "device_uuid")
            return newUUID
        }
    }
    
    // 現在のユーザーIDを取得
    private func getCurrentUserId() -> String {
        // Auth0のユーザーIDをそのまま使用（Supabaseでも同じIDを使用）
        return UserDefaults.standard.string(forKey: "auth0_user_id") ?? "0"
    }
    
    // ゲストログインを実行
    func guestLogin() async throws -> String {
        let url = URL(string: "\(baseURL)/auth/guest")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let loginRequest = GuestLoginRequest(device_uuid: deviceUUID)
        request.httpBody = try JSONEncoder().encode(loginRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        accessToken = authResponse.access_token
        return authResponse.access_token
    }
    
    // 画像をアップロードして物語設定も作成する統合メソッド
    func uploadImageAndCreateStorySetting(_ image: Any) async throws -> (uploadResponse: UploadImageResponse, storySettingId: Int, generatedData: String?) {
        // 画像をアップロード
        let uploadResponse = try await uploadImage(image)
        
        // 物語設定を作成
        let storySettingResponse = try await createStorySettingFromImage(imageId: uploadResponse.id)
        
        return (uploadResponse, storySettingResponse.story_setting_id, storySettingResponse.generated_data_jsonString)
    }
    
    // 画像をアップロード
    func uploadImage(_ image: Any) async throws -> UploadImageResponse {
        #if canImport(UIKit)
        guard let uiImage = image as? UIImage else {
            throw NetworkError.imageConversionFailed
        }
        
        // まず認証トークンを取得
        if accessToken == nil {
            _ = try await guestLogin()
        }
        
        // 画像形式を自動判定して最適なデータに変換
        let imageData: Data
        let contentType: String
        
        // 透明度があるかどうかをチェック
        if hasTransparency(uiImage) {
            // 透明度がある場合はPNGを使用
            guard let pngData = uiImage.pngData() else {
                throw NetworkError.imageConversionFailed
            }
            imageData = pngData
            contentType = "image/png"
        } else {
            // 透明度がない場合はJPEGを使用（ファイルサイズが小さい）
            // ファイルサイズを最適化するため、適切な圧縮率を選択
            let compressionQuality: CGFloat = uiImage.size.width > 1920 || uiImage.size.height > 1080 ? 0.7 : 0.8
            guard let jpegData = uiImage.jpegData(compressionQuality: compressionQuality) else {
                throw NetworkError.imageConversionFailed
            }
            imageData = jpegData
            contentType = "image/jpeg"
        }
        
        // 選択された形式をログ出力
        print("📸 画像形式選択: \(contentType)")
        print("📏 画像サイズ: \(uiImage.size.width)x\(uiImage.size.height)")
        print("💾 ファイルサイズ: \(imageData.count) bytes")
        
        // マルチパートフォームデータを作成
        let boundary = UUID().uuidString
        var body = Data()
        
        // user_id フィールド（Auth0のユーザーIDを取得）
        let userId = getCurrentUserId()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        // 画像ファイルフィールド
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        
        // ファイル名とContent-Typeを適切に設定
        let filename = contentType == "image/png" ? "image.png" : "image.jpg"
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // リクエストを作成
        let url = URL(string: "\(baseURL)/images/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        
        // リクエストを送信
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            // トークンが無効な場合、再ログインを試行
            _ = try await guestLogin()
            
            // 再リクエスト
            if let token = accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let (retryData, retryResponse) = try await URLSession.shared.data(for: request)
            
            guard let retryHttpResponse = retryResponse as? HTTPURLResponse,
                  retryHttpResponse.statusCode == 200 else {
                throw NetworkError.uploadFailed
            }
            
            return try JSONDecoder().decode(UploadImageResponse.self, from: retryData)
        } else if httpResponse.statusCode != 200 {
            throw NetworkError.uploadFailed
        }
        
        return try JSONDecoder().decode(UploadImageResponse.self, from: data)
        
        #else
        throw NetworkError.uploadFailed
        #endif
    }
    
    // 画像に透明度があるかどうかをチェックする
    #if canImport(UIKit)
    private func hasTransparency(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        
        // カラースペースとアルファチャンネルの情報を取得
        let alphaInfo = cgImage.alphaInfo
        
        // アルファチャンネルがあるかどうかを判定
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return false // アルファチャンネルなし
        case .premultipliedFirst, .premultipliedLast, .first, .last, .alphaOnly:
            return true // アルファチャンネルあり
        @unknown default:
            return false
        }
    }
    #endif
    
    // 認証済みURLを取得する
    func getSignedUrl(imageId: Int) async throws -> String {
        let url = URL(string: "\(baseURL)/images/signed-url/\(imageId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let signedUrlResponse = try JSONDecoder().decode(SignedUrlResponse.self, from: data)
        return signedUrlResponse.signed_url
    }
    
    // 画像IDから物語設定を作成する
    private func createStorySettingFromImage(imageId: Int) async throws -> (story_setting_id: Int, generated_data_jsonString: String?) {
        let url = URL(string: "\(baseURL)/story/story_settings/\(imageId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "StorySettingCreate", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: body])
        }
        
        let decoded = try JSONDecoder().decode(StorySettingCreateResponse.self, from: data)
        var jsonString: String? = nil
        if let gen = decoded.generated_data, let encoded = try? JSONEncoder().encode(gen) {
            jsonString = String(data: encoded, encoding: .utf8)
        }
        return (decoded.story_setting_id, jsonString)
    }
}

// ネットワークエラー定義
enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case imageConversionFailed
    case uploadFailed
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .uploadFailed:
            return "画像のアップロードに失敗しました"
        case .authenticationFailed:
            return "認証に失敗しました"
        }
    }
}