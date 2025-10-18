import SwiftUI

struct StoryBookView: View {
    @State private var storyTitle = "絵本を読み込み中..."
    
    var body: some View {
        // ヘッダー
        ZStack(alignment: .top) {
            // 背景
            Background {
                // メインコンテンツ
                VStack {
                    // ヘッダーの高さ分のスペースを確保
                    Spacer()
                        .frame(height: 120)
                    
                    // APIから取得した絵本を直接表示
                    VStack(spacing: 30) {
                        // API絵本のタイトル（動的に変更）
                        MainText(text: storyTitle)
                        
                        // APIから取得した絵本エリア
                        if #available(iOS 15.0, *) {
                            BookFromAPIWithTitleUpdate(onTitleUpdate: { title in
                                storyTitle = title
                            })
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
            // ヘッダー
            Header(
                title: "えほんのたね",
                logoName: "logo"
            )
            // 非表示の遷移リンク
        }
    }
}

#Preview {
    StoryBookView()
}
