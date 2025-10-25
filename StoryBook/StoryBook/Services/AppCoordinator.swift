//
//  AppCoordinator.swift
//  StoryBook
//
//  Created by ayu on 2025/01/27.
//

import SwiftUI
import Combine

/// アプリ全体の画面遷移を管理するCoordinator
class AppCoordinator: ObservableObject {
    @Published var currentView: AppView = .top
    
    // MARK: - 認証サービス
    @Published var authService: AuthService
    @Published var storybookService: StorybookService
    
    /// アプリの画面状態を定義
    enum AppView {
        case top
        case uploadImage
        case question(storySettingId: Int)
        case themeSelect
        case storybook(storybookId: Int)
        case bookDemoModern
    }
    
    init() {
        let authService = AuthService()
        self.authService = authService
        self.storybookService = StorybookService(authManager: authService.authManager)
    }
    
    // MARK: - Navigation Methods
    
    /// UploadImageViewに遷移
    func navigateToUploadImage() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentView = .uploadImage
        }
    }
    
    /// QuestionViewに遷移
    /// - Parameter storySettingId: 物語設定ID
    func navigateToQuestion(storySettingId: Int) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentView = .question(storySettingId: storySettingId)
        }
    }
    
    /// ThemeSelectViewに遷移
    func navigateToThemeSelect() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentView = .themeSelect
        }
    }
    
    /// StorybookViewに遷移
    /// - Parameter storybookId: ストーリーブックID
    func navigateToStorybook(storybookId: Int) {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentView = .storybook(storybookId: storybookId)
        }
    }
    
    /// BookDemoViewmodernに遷移
    func navigateToBookDemoModern() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentView = .bookDemoModern
        }
    }
    
    /// トップ画面に戻る
    func navigateToTop() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentView = .top
        }
    }
    
    /// 前の画面に戻る（簡易実装）
    func navigateBack() {
        switch currentView {
        case .top:
            break // トップ画面からは戻れない
        case .uploadImage:
            navigateToTop()
        case .question:
            navigateToUploadImage()
        case .themeSelect:
            // QuestionViewに戻る場合はstorySettingIdが必要だが、
            // 簡易実装のためトップに戻る
            navigateToTop()
        case .storybook:
            // ストーリーブックからはテーマ選択に戻る
            navigateToThemeSelect()
        case .bookDemoModern:
            // BookDemoModernからはテーマ選択に戻る
            navigateToThemeSelect()
        }
    }
}
