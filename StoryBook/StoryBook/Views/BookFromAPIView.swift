//
//  BookFromAPIView.swift
//  StoryBook
//
//  Created by ayu on 2025/10/16.
//

import SwiftUI
import Combine

// MARK: - APIから取得した絵本データを表示するビュー

/// APIから取得した絵本データを表示するビューの共通ロジック
@available(iOS 15.0, macOS 12.0, *)
class BookFromAPIViewModel: ObservableObject {
    // テスト用にID=1に固定
    private let storybookId: Int = 1
    @Published private var storybookService = StorybookService.shared
    @Published var storybook: StorybookResponse?
    @Published var story: Story?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGeneratingImages = false
    @Published var generationMessage = "絵本の絵を描いています..."
    
    // タイトル更新コールバック（オプショナル）
    var onTitleUpdate: ((String) -> Void)?
    
    init(onTitleUpdate: ((String) -> Void)? = nil) {
        self.onTitleUpdate = onTitleUpdate
    }
    
    // タイトルを外部から取得できるように公開
    var storyTitle: String {
        storybook?.title ?? "絵本を読み込み中..."
    }
    
    /// 絵本データを読み込む
    func loadStorybook() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            print("📚 Loading storybook with ID: \(storybookId)")
            
            let response = try await storybookService.fetchStorybook(storybookId: storybookId)
            
            DispatchQueue.main.async {
                self.storybook = response
                self.story = Story(from: response)
                
                // タイトルを更新
                self.onTitleUpdate?(response.title)
                
                print("✅ Storybook loaded successfully")
                print("📖 Title: \(response.title)")
                print("📄 Number of pages: \(self.story?.pages.count ?? 0)")
                print("🖼️ Image generation status: \(response.imageGenerationStatus)")
                
                // 画像生成状態をチェック
                if self.storybookService.isGeneratingImages(response) {
                    self.isGeneratingImages = true
                    self.generationMessage = self.storybookService.getGenerationMessage(response.imageGenerationStatus)
                    
                    // 画像生成の進捗をシミュレート
                    self.simulateImageGenerationProgress()
                }
                
                self.isLoading = false
            }
            
        } catch {
            DispatchQueue.main.async {
                print("❌ Error loading storybook: \(error)")
                self.errorMessage = error.localizedDescription
                self.onTitleUpdate?("エラーが発生しました")
                self.isLoading = false
            }
        }
    }
    
    /// 画像生成の進捗をシミュレート
    private func simulateImageGenerationProgress() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.generationMessage = "絵本の絵を描いています... (50%)"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.generationMessage = "絵本の絵を描いています... (90%)"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.generationMessage = "絵本が完成しました！"
            self.isGeneratingImages = false
            
            // 完了後にデータを再読み込み
            Task {
                await self.loadStorybook()
            }
        }
    }
    
    /// StoryからBookページを作成
    func createBookPages(from story: Story) -> [AnyView] {
        return story.pages.map { page in
            if let imageURLString = page.imageURL,
               let imageURL = URL(string: imageURLString) {
                // リモート画像がある場合（余白なし）
                return AnyView(
                    BookRemoteImagePage(
                        imageURL,
                        contentInset: 0,
                        fit: .fill,
                        text: page.text,
                        textAreaHeight: 120
                    )
                )
            } else {
                // 画像がない場合はテキストのみ
                return AnyView(
                    VStack(spacing: 0) {
                        Text(page.text)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .background(Color.white)
                )
            }
        }
    }
}

/// APIから取得した絵本データを表示するビュー
@available(iOS 15.0, macOS 12.0, *)
public struct BookFromAPI: View {
    @StateObject private var viewModel = BookFromAPIViewModel()
    
    public init() {}
    
    public var body: some View {
        BookFromAPIView(viewModel: viewModel)
    }
}

/// タイトル更新コールバック付きのBookFromAPI
@available(iOS 15.0, macOS 12.0, *)
public struct BookFromAPIWithTitleUpdate: View {
    @StateObject private var viewModel: BookFromAPIViewModel
    
    public init(onTitleUpdate: @escaping (String) -> Void) {
        self._viewModel = StateObject(wrappedValue: BookFromAPIViewModel(onTitleUpdate: onTitleUpdate))
    }
    
    public var body: some View {
        BookFromAPIView(viewModel: viewModel)
    }
}

/// 共通のビュー実装
@available(iOS 15.0, macOS 12.0, *)
private struct BookFromAPIView: View {
    @ObservedObject var viewModel: BookFromAPIViewModel
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                // ローディング画面
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("絵本を読み込んでいます...")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                // エラー画面
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("エラーが発生しました")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("再試行") {
                        Task {
                            await viewModel.loadStorybook()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let story = viewModel.story {
                // 絵本表示画面
                VStack {
                    if viewModel.isGeneratingImages {
                        // 画像生成中のメッセージ
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(viewModel.generationMessage)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.top, 20)
                    }
                    
                    // 絵本コンテンツ
                    Book(
                        pages: viewModel.createBookPages(from: story),
                        title: story.title,
                        showTitle: false,
                        heightRatio: 0.9,
                        aspectRatio: 10/16.0,
                        cornerRadius: 16,
                        paperColor: Color(red: 252/255, green: 252/255, blue: 252/255)
                    )
                    .opacity(viewModel.isGeneratingImages ? 0.7 : 1.0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 初期状態
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 50))
                        .foregroundColor(.primary)
                    Text("絵本を読み込み中...")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await viewModel.loadStorybook()
        }
        .refreshable {
            await viewModel.loadStorybook()
        }
    }
}
