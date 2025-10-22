import SwiftUI

/// テスト用質問カードビュー - コンポーネント化されたバージョンを使用
struct TestQuestionCard: View {
    // テーマ選択画面への遷移コールバック
    let onNavigateToThemeSelect: () -> Void
    // テスト用の物語設定ID
    let storySettingId: Int = 89
    
    var body: some View {
        QuestionCardView(onNavigateToThemeSelect: onNavigateToThemeSelect, storySettingId: storySettingId)
    }
}

#Preview {
    TestQuestionCard(onNavigateToThemeSelect: {
        print("テーマ選択ページに遷移")
    })
}