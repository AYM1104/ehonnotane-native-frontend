import Foundation

// MARK: - データモデル定義

// バックエンドAPIから取得する絵本データモデル
public struct StorybookResponse: Codable {
    let id: Int
    let storyPlotId: Int
    let userId: String  // Supabaseでは文字列型（Auth0のユーザーID）
    let title: String
    let description: String?
    let keywords: [String]?  // APIからは配列として返される可能性がある
    let storyContent: String  // ネストしたJSON文字列
    let page1: String
    let page2: String
    let page3: String
    let page4: String
    let page5: String
    let page1ImageUrl: String?
    let page2ImageUrl: String?
    let page3ImageUrl: String?
    let page4ImageUrl: String?
    let page5ImageUrl: String?
    let imageGenerationStatus: String
    let createdAt: String
    let updatedAt: String?
    let uploadedImage: UploadedImageInfo?  // オプショナルとして定義（APIに存在しない場合がある）
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, keywords
        case storyPlotId = "story_plot_id"
        case userId = "user_id"
        case storyContent = "story_content"
        case page1 = "page_1"
        case page2 = "page_2"
        case page3 = "page_3"
        case page4 = "page_4"
        case page5 = "page_5"
        case page1ImageUrl = "page_1_image_url"
        case page2ImageUrl = "page_2_image_url"
        case page3ImageUrl = "page_3_image_url"
        case page4ImageUrl = "page_4_image_url"
        case page5ImageUrl = "page_5_image_url"
        case imageGenerationStatus = "image_generation_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case uploadedImage = "uploaded_image"
    }
    
    // カスタムデコーダーでエラーを回避
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        storyPlotId = try container.decode(Int.self, forKey: .storyPlotId)
        userId = try container.decode(String.self, forKey: .userId)  // 文字列型に変更
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // keywordsフィールドを柔軟に処理（文字列または配列として）
        keywords = try Self.decodeKeywords(from: container)
        
        storyContent = try container.decode(String.self, forKey: .storyContent)
        page1 = try container.decode(String.self, forKey: .page1)
        page2 = try container.decode(String.self, forKey: .page2)
        page3 = try container.decode(String.self, forKey: .page3)
        page4 = try container.decode(String.self, forKey: .page4)
        page5 = try container.decode(String.self, forKey: .page5)
        page1ImageUrl = try container.decodeIfPresent(String.self, forKey: .page1ImageUrl)
        page2ImageUrl = try container.decodeIfPresent(String.self, forKey: .page2ImageUrl)
        page3ImageUrl = try container.decodeIfPresent(String.self, forKey: .page3ImageUrl)
        page4ImageUrl = try container.decodeIfPresent(String.self, forKey: .page4ImageUrl)
        page5ImageUrl = try container.decodeIfPresent(String.self, forKey: .page5ImageUrl)
        imageGenerationStatus = try container.decode(String.self, forKey: .imageGenerationStatus)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        uploadedImage = try container.decodeIfPresent(UploadedImageInfo.self, forKey: .uploadedImage)
    }
    
    // keywordsデコードの共通ロジック
    private static func decodeKeywords(from container: KeyedDecodingContainer<CodingKeys>) throws -> [String]? {
        if let keywordsArray = try? container.decodeIfPresent([String].self, forKey: .keywords) {
            return keywordsArray
        } else if let keywordsString = try? container.decodeIfPresent(String.self, forKey: .keywords) {
            // 文字列の場合は配列に変換
            return keywordsString.isEmpty ? nil : [keywordsString]
        } else {
            return nil
        }
    }
}

// アップロード画像情報
struct UploadedImageInfo: Codable {
    let id: Int
    let filename: String
    let filePath: String
    let publicUrl: String
    let uploadedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, filename
        case filePath = "file_path"
        case publicUrl = "public_url"
        case uploadedAt = "uploaded_at"
    }
}

// テーマプロットレスポンス（APIから取得）
struct ThemePlotResponse: Codable {
    let storyPlotId: Int
    let title: String
    let description: String?
    let selectedTheme: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case title, description
        case storyPlotId = "story_plot_id"
        case selectedTheme = "selected_theme"
        case createdAt = "created_at"
    }
}

// テーマプロット一覧レスポンス
struct ThemePlotsListResponse: Codable {
    let count: Int
    let items: [ThemePlotResponse]
}

// 物語ページのデータモデル
public struct StoryPage {
    let id: UUID
    let pageNumber: Int
    let imageURL: String?
    let text: String
    let imageData: Data?
    
    init(id: UUID = UUID(), pageNumber: Int, imageURL: String? = nil, text: String, imageData: Data? = nil) {
        self.id = id
        self.pageNumber = pageNumber
        self.imageURL = imageURL
        self.text = text
        self.imageData = imageData
    }
    
    // StorybookResponseからStoryPageに変換するイニシャライザ
    public init(from storybookResponse: StorybookResponse, pageNumber: Int) {
        self.id = UUID()
        self.pageNumber = pageNumber
        
        switch pageNumber {
        case 1:
            self.text = storybookResponse.page1
            self.imageURL = storybookResponse.page1ImageUrl
        case 2:
            self.text = storybookResponse.page2
            self.imageURL = storybookResponse.page2ImageUrl
        case 3:
            self.text = storybookResponse.page3
            self.imageURL = storybookResponse.page3ImageUrl
        case 4:
            self.text = storybookResponse.page4
            self.imageURL = storybookResponse.page4ImageUrl
        case 5:
            self.text = storybookResponse.page5
            self.imageURL = storybookResponse.page5ImageUrl
        default:
            self.text = ""
            self.imageURL = nil
        }
        
        self.imageData = nil
    }
}

// 物語全体のデータモデル
public struct Story {
    let id: UUID
    let title: String
    let pages: [StoryPage]
    let createdAt: Date
    let theme: String?
    let imageGenerationStatus: String
    
    init(id: UUID = UUID(), title: String, pages: [StoryPage], createdAt: Date = Date(), theme: String? = nil, imageGenerationStatus: String = "pending") {
        self.id = id
        self.title = title
        self.pages = pages
        self.createdAt = createdAt
        self.theme = theme
        self.imageGenerationStatus = imageGenerationStatus
    }
    
    // StorybookResponseからStoryに変換するイニシャライザ
    public init(from storybookResponse: StorybookResponse) {
        self.id = UUID()
        self.title = storybookResponse.title
        
        var pages: [StoryPage] = []
        let pageTexts = [
            storybookResponse.page1,
            storybookResponse.page2,
            storybookResponse.page3,
            storybookResponse.page4,
            storybookResponse.page5
        ]
        
        for (index, text) in pageTexts.enumerated() {
            if !text.isEmpty {
                let pageNumber = index + 1
                let page = StoryPage(from: storybookResponse, pageNumber: pageNumber)
                pages.append(page)
            }
        }
        self.pages = pages
        let formatter = ISO8601DateFormatter()
        self.createdAt = formatter.date(from: storybookResponse.createdAt) ?? Date()
        
        // keywordsを文字列に変換（配列の場合は最初の要素を使用、または配列を文字列に結合）
        if let keywordsArray = storybookResponse.keywords {
            self.theme = keywordsArray.joined(separator: ", ")
        } else {
            self.theme = nil
        }
        self.imageGenerationStatus = storybookResponse.imageGenerationStatus
    }
}

// テーマページのデータモデル（ThemeSelectView用）
struct ThemePage: Identifiable {
    let id: String
    let title: String
    let content: String
    let storyPlotId: Int
    let selectedTheme: String
    
    init(id: String = UUID().uuidString, title: String, content: String, storyPlotId: Int, selectedTheme: String) {
        self.id = id
        self.title = title
        self.content = content
        self.storyPlotId = storyPlotId
        self.selectedTheme = selectedTheme
    }
    
    // ThemePlotResponseからThemePageに変換
    init(from themePlot: ThemePlotResponse) {
        self.id = "\(themePlot.storyPlotId)"
        self.title = themePlot.title
        self.content = themePlot.description ?? "テーマの説明"
        self.storyPlotId = themePlot.storyPlotId
        self.selectedTheme = themePlot.selectedTheme
    }
}
