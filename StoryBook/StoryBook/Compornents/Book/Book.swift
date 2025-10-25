import SwiftUI

// MARK: - リファクタリング後のBook.swift
// このファイルは主にPreviewとテスト用のサンプルデータを提供します
// 分離されたコンポーネントをインポート

// MARK: - Preview

/*
#Preview("APIから取得した絵本") {
    // APIから取得した絵本データを表示（ID=1に固定）
    if #available(iOS 15.0, *) {
        BookFromAPI(storybookId: 1)
            .environmentObject(AuthService())
            .environmentObject(StorybookService())
    } else {
        Text("iOS 15.0以上が必要です")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.3))
    }
}
*/

#Preview("デモ絵本（ローカル）") {
    VStack(spacing: 12) {
        // 1) ローカル画像（Assetsの "Sample1", "Sample2" を想定）
        let p1 = BookImagePage(Image("Sample1"), contentInset: 0, fit: .fill, background: .white, text: "むかしむかし、あるところに、とてもかわいいうさぎがいました。")
        let p2 = BookImagePage(Image("Sample2"), contentInset: 0, fit: .fill, background: .white, text: "そのうさぎは、毎日森の中を散歩するのが大好きでした。")

        // 2) リモート画像（実行時に任意のURLへ差し替え推奨）
        let remotePages: [AnyView] = {
            if #available(iOS 15.0, *) {
                let u1 = URL(string: "https://picsum.photos/900/1600")!
                let u2 = URL(string: "https://picsum.photos/1000/1600")!
                return [
                    AnyView(BookRemoteImagePage(u1, contentInset: 0, fit: .fill, text: "ある日、うさぎは美しい花を見つけました。")),
                    AnyView(BookRemoteImagePage(u2, contentInset: 0, fit: .fill, text: "花は「こんにちは」と笑顔で言いました。"))
                ]
            } else {
                return []
            }
        }()

        Book(
            pages: [AnyView(p1), AnyView(p2)] + remotePages,
            title: "デモのえほん",
            showTitle: false,
            heightRatio: 1,
            aspectRatio: 9.0/16.0,
            cornerRadius: 16,
            paperColor: Color(red: 252/255, green: 252/255, blue: 252/255)
        )
        .background(
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}
