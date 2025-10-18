//
//  BigCharacter.swift
//  StoryBook
//
//  Created by ayu on 2025/10/12.
//

import SwiftUI

// シンプルなキャラクター画像表示コンポーネント
struct BigCharacter: View {
    // サイズクラスを取得
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer() // 上部に空白を追加
            HStack {
                Spacer()
                Image("charactor-smartphone")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: characterWidth)
                    .allowsHitTesting(false) // タップイベントを無効化（装飾用途）
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    // iPhone向けのサイズ設定
    private var characterWidth: CGFloat {
        return verticalSizeClass == .compact ? 450 : 500
    }
}

#Preview("デフォルト") {
    BigCharacter()
}