//
//  ThemeCard.swift
//  StoryBook
//
//  Created by ayu on 2025/01/27.
//

import SwiftUI

// テーマ表示用のカードコンポーネント
// InnerCardと同じスタイルでテーマ選択機能を提供

struct ThemeCard: View {
    // テーマ情報
    let theme: Theme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack {
            // 背景 (InnerCardと同じスタイル)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.5))
            
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
        }
        .overlay(
            // 選択状態のボーダー
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isSelected ? Color.blue : Color.clear,
                    lineWidth: isSelected ? 3 : 0
                )
        )
        .onTapGesture {
            onTap()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        VStack(spacing: 16) {
            // テーマアイコンまたは画像
            themeIcon
            
            // テーマ名
            Text(theme.name)
                .font(.custom("YuseiMagic-Regular", size: 24))
                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // テーマ説明（オプション）
            if let description = theme.description {
                Text(description)
                    .font(.custom("YuseiMagic-Regular", size: 16))
                    .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255).opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // 選択状態インジケーター
            if isSelected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    Text("えらばれています")
                        .font(.custom("YuseiMagic-Regular", size: 14))
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    @ViewBuilder
    private var themeIcon: some View {
        if let iconName = theme.iconName {
            // SF Symbolsアイコン
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                .frame(width: 60, height: 60)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        } else if let imageName = theme.imageName {
            // カスタム画像
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
        } else {
            // デフォルトアイコン
            Image(systemName: "book.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(red: 54/255, green: 45/255, blue: 48/255))
                .frame(width: 60, height: 60)
                .background(Color.white.opacity(0.8))
                .clipShape(Circle())
        }
    }
}

// テーマモデル（必要に応じて既存のモデルを使用）
struct Theme {
    let id: String
    let name: String
    let description: String?
    let iconName: String?
    let imageName: String?
    
    init(id: String, name: String, description: String? = nil, iconName: String? = nil, imageName: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.imageName = imageName
    }
}

struct ThemeCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 選択されていない状態
            ThemeCard(
                theme: Theme(
                    id: "1",
                    name: "冒険の物語",
                    description: "勇者が冒険に出るお話",
                    iconName: "star.fill"
                ),
                isSelected: false,
                onTap: {}
            )
            .frame(width: 200, height: 180)
            
            // 選択されている状態
            ThemeCard(
                theme: Theme(
                    id: "2",
                    name: "魔法の世界",
                    description: "魔法使いが活躍するファンタジー",
                    iconName: "wand.and.stars"
                ),
                isSelected: true,
                onTap: {}
            )
            .frame(width: 200, height: 180)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .previewLayout(.sizeThatFits)
    }
}
