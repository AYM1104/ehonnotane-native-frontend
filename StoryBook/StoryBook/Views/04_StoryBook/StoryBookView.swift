import SwiftUI

struct StoryBookView: View {
    let storybookId: Int
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var storybookService: StorybookService
    @State private var storyTitle = "絵本を読み込み中..."
    
    var body: some View {
        // ヘッダー
        ZStack(alignment: .top) {
            // 背景
            Background {}

            // ヘッダー
            Header()

            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインコンテンツ
                VStack(spacing: 30) {
                    // 絵本のタイトル
                    MainText(text: storyTitle)
                    
                    // 絵本エリア
                    if #available(iOS 15.0, *) {
                        BookFromAPIWithTitleUpdate(
                            storybookId: storybookId,
                            storybookService: storybookService,
                            onTitleUpdate: { title in
                                storyTitle = title
                            }
                        )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("iOS 15.0以上が必要です")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("この機能を使用するにはiOS 15.0以上が必要です")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
        }
    }
}


/*
#Preview {
    let authService = AuthService()
    return StoryBookView(storybookId: 1)
        .environmentObject(authService)
        .environmentObject(StorybookService(authManager: authService.authManager))
}
*/
