import SwiftUI
import UIKit

struct ThemeSelectView: View {
    // ページの状態管理
    @State private var currentPageIndex = 0
    
    // テーマ読み込みサービス
    @StateObject private var themeLoadService = ThemeLoadService()
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }
            
            // ヘッダー
            Header()

            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキスト（カードコンポーネントと同じ光る効果）
                MainText(text: "すきな おはなしを")
                MainText(text: "えらんでね！")
                Spacer()

                // ガラス風カードを表示
                mainCard(width: .screen95) {
                    if themeLoadService.isLoading {
                        // ローディング表示（インナーカード内）
                        InnerCard(
                            sections: [
                                .init(
                                    fillsRemainingSpace: true,
                                    alignment: .center
                                ) {
                                    VStack(spacing: 20) {
                                        ProgressView()
                                            .scaleEffect(1.5)
                                        SubText(text: "テーマを読み込み中...", fontSize: 16)
                                    }
                                }
                            ]
                        )
                    } else if let errorMessage = themeLoadService.errorMessage {
                        // エラー表示（インナーカード内）
                        InnerCard(
                            sections: [
                                .init(
                                    fillsRemainingSpace: true,
                                    alignment: .center
                                ) {
                                    VStack(spacing: 20) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 40))
                                            .foregroundColor(.red)
                                        SubText(text: errorMessage, fontSize: 16)
                                        Button("再試行") {
                                            themeLoadService.reloadThemeData()
                                        }
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                }
                            ]
                        )
                    } else if themeLoadService.themePages.isEmpty {
                        // データなし表示（インナーカード内）
                        InnerCard(
                            sections: [
                                .init(
                                    fillsRemainingSpace: true,
                                    alignment: .center
                                ) {
                                    VStack(spacing: 20) {
                                        Image(systemName: "book.closed")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        SubText(text: "テーマが見つかりません", fontSize: 16)
                                    }
                                }
                            ]
                        )
                        } else {
                            // テーマデータがある場合
                            VStack(spacing: 16) {                                
                                // PagerViewComponentでスライド機能を実装
                                PagerViewComponent(themeLoadService.themePages, spacing: 20, onPageChanged: { index in
                                    currentPageIndex = index
                                }) { page in
                                    // インナーカードを表示
                                    InnerCard(
                                        sections: [
                                            // おはなしのタイトル
                                            .init(
                                                fixedHeight: 100,
                                                fillsRemainingSpace: false,
                                                alignment: .top
                                            ) {
                                                VStack(spacing: 20) {
                                                    SubText(text: "〈おはなしのタイトル〉")
                                                    SubText(text: page.title)
                                                }
                                            },
                                            // おはなしの概要
                                            .init(
                                                alignment: .top,  // ← 中央揃えではなく上揃えに変更
                                                showDivider: false // 区切り線を表示しない
                                            ) {
                                               ScrollView(showsIndicators: true) {
                                                    SubText(text: page.content)
                                                        .padding(.horizontal, 10) // 左右の余白を追加
                                               }
                                               .frame(maxHeight: .infinity) // 利用可能な高さまで拡張
                                               .padding(.bottom, -10) // 下部の余白を追加
                                            },
                                            // 決定ボタン
                                            .init(
                                                fixedHeight: 80,
                                                fillsRemainingSpace: false,
                                                alignment: .center
                                            ) {
                                                PrimaryButton(
                                                    title: "これにけってい",
                                                    action: {
                                                        // テーマ選択時のアクション
                                                        print("テーマが選択されました: \(page.title)")
                                                    }
                                                )
                                            }
                                        ]
                                    )
                                }
                                // プログレスバーを表示
                                ProgressBar(
                                    totalSteps: themeLoadService.themePages.count,
                                    currentStep: currentPageIndex
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                }
                .padding(.horizontal, 16) // 
                .padding(.bottom, -10) // 画面下部からの余白    
            }
        }
        .onAppear {
            themeLoadService.loadThemeData()
        }
    }
}

#Preview {
    ThemeSelectView()
}
