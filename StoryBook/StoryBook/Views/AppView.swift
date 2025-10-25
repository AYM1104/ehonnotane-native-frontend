//
//  AppView.swift
//  StoryBook
//
//  Created by ayu on 2025/01/27.
//

import SwiftUI

/// アプリのメインビュー - 画面遷移を管理
struct MainAppView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            switch coordinator.currentView {
            case .top:
                TopView()
                    .environmentObject(coordinator.authService)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                
            case .uploadImage:
                UploadImageView(onNavigateToQuestions: coordinator.navigateToQuestion)
                    .environmentObject(coordinator.authService)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
            case .question(let storySettingId):
                QuestionCardView(
                    onNavigateToThemeSelect: coordinator.navigateToThemeSelect,
                    storySettingId: storySettingId
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .themeSelect:
                ThemeSelectView()
                    .environmentObject(coordinator.authService)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
            case .storybook(let storybookId):
                StoryBookView(storybookId: storybookId)
                    .environmentObject(coordinator.authService)
                    .environmentObject(coordinator.storybookService)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
            case .bookDemoModern:
                CenterBookCurlDemoWrapper()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .navigationBarHidden(true)
    }
}

/*
#Preview {
    MainAppView()
        .environmentObject(AppCoordinator())
}
*/
