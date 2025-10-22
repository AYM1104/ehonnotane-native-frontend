
import Foundation
import SwiftUI
import Combine

// MARK: - テーマデータ読み込みサービス

/// テーマデータの読み込みと管理を行うサービス
class ThemeLoadService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var themePages: [ThemePage] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    // テストユーザーID
    private let testUserId = "google-oauth2|104323599082993871312"
    
    // MARK: - Public Methods
    
    /// テーマデータを読み込む
    func loadThemeData() {
        Task {
            do {
                await MainActor.run {
                    self.isLoading = true
                    self.errorMessage = nil
                }
                
                // 1. 最新のstory_setting_idを取得
                let storySettingId = try await StorybookService.shared.fetchLatestStorySettingId(userId: testUserId)
                
                // 2. テーマプロット一覧を取得
                let themePlotsResponse = try await StorybookService.shared.fetchThemePlots(
                    userId: testUserId,
                    storySettingId: storySettingId,
                    limit: 3
                )
                
                // 3. テーマが見つからない場合は、既存のデータがあるstory_setting_idを試す
                if themePlotsResponse.items.isEmpty {
                    print("⚠️ story_setting_id \(storySettingId) にテーマが見つかりません。既存のデータを探します...")
                    
                    // 既存のデータがあるstory_setting_id=89を使用
                    let fallbackStorySettingId = 89
                    let fallbackThemePlotsResponse = try await StorybookService.shared.fetchThemePlots(
                        userId: testUserId,
                        storySettingId: fallbackStorySettingId,
                        limit: 3
                    )
                    
                    if !fallbackThemePlotsResponse.items.isEmpty {
                        print("✅ story_setting_id \(fallbackStorySettingId) でテーマが見つかりました")
                        let pages = fallbackThemePlotsResponse.items.map { ThemePage(from: $0) }
                        
                        await MainActor.run {
                            self.themePages = pages
                            self.isLoading = false
                        }
                        return
                    }
                }
                
                // 4. ThemePageに変換
                let pages = themePlotsResponse.items.map { ThemePage(from: $0) }
                
                await MainActor.run {
                    self.themePages = pages
                    self.isLoading = false
                }
                
            } catch {
                print("❌ ThemeLoadService Error: \(error)")
                if let storybookError = error as? StorybookAPIError {
                    print("❌ StorybookAPIError: \(storybookError.errorDescription ?? "不明なエラー")")
                }
                
                await MainActor.run {
                    self.errorMessage = "エラー: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// テーマデータを再読み込みする
    func reloadThemeData() {
        loadThemeData()
    }
}
