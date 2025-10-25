//
//  TestStorybookView.swift
//  StoryBook
//
//  Created by ayu on 2025/10/16.
//

import SwiftUI

/// テスト用の絵本表示ビュー
/// APIから取得した絵本データを表示するテスト用のビュー（ID=1に固定）
@available(iOS 15.0, macOS 12.0, *)
struct TestStorybookView: View {
    @State private var showingStorybook = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // ヘッダー
                VStack(spacing: 16) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("絵本テストビュー")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("APIから絵本データ（ID=1）を取得して表示します")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 絵本表示ボタン
                VStack(spacing: 16) {
                    Text("固定された絵本ID: 1")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button("絵本を表示") {
                        showingStorybook = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Spacer()
                
                // 注意事項
                VStack(spacing: 8) {
                    Text("注意事項")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• バックエンドサーバーが起動している必要があります")
                        Text("• ネットワーク接続が必要です")
                        Text("• 絵本ID=1のデータがDBに存在する必要があります")
                        Text("• サーバーURL: http://192.168.3.93:8000")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("絵本テスト")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .sheet(isPresented: $showingStorybook) {
            // ID=1に固定されたBookFromAPIを使用
            // シンプルな絵本表示ビュー
            NavigationView {
                VStack(spacing: 20) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("絵本ID: 1")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("絵本の内容を読み込み中...")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                }
                .padding()
                .navigationTitle("絵本表示")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("閉じる") {
                            showingStorybook = false
                        }
                    }
                    #else
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") {
                            showingStorybook = false
                        }
                    }
                    #endif
                }
            }
        }
    }
}

/*
#Preview {
    TestStorybookView()
}
*/
