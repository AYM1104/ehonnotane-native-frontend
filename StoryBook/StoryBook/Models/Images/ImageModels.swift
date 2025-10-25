import Foundation

// MARK: - 画像アップロード関連モデル

// 画像アップロード用のレスポンスモデル
struct UploadImageResponse: Codable {
    let id: Int
    let file_name: String
    let file_path: String
    let content_type: String
    let size_bytes: Int
    let user_id: String  // Supabaseではvarchar型（Auth0のユーザーID）
    let uploaded_at: String
    let meta_data: String?
    let public_url: String?
}

// 認証済みURLレスポンスモデル
struct SignedUrlResponse: Codable {
    let signed_url: String
}
