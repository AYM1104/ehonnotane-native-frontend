//
//  Header.swift
//  StoryBook
//
//  Created by ayu on 2025/10/13.
//

import SwiftUI

// ヘッダー用のナビゲーションアイテム型定義
struct HeaderNavItem: Identifiable {
    let id = UUID()
    let label: String // 表示ラベル
    var href: String? // 遷移先（任意）
    var action: (() -> Void)? // クリックハンドラ（任意）
}

/**
 * 画面上部に配置されるヘッダーコンポーネント
 * - 透過ガラス風の背景
 * - デバイスサイズとサイズクラスに応じたレスポンシブ対応
 * - SafeAreaを考慮した設計
 */
struct Header: View {
    // プロパティ
    var title: String = "えほんのたね"
    var logoName: String = "logo" // アセット名
    var navItems: [HeaderNavItem] = []
    
    // デバイス環境の取得
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            headerContent(geometry: geometry)
                .frame(maxWidth: .infinity)
                .frame(height: headerHeight + geometry.safeAreaInsets.top)
                .ignoresSafeArea(edges: .top)
        }
    }
    
    // ヘッダーのメインコンテンツ
    private func headerContent(geometry: GeometryProxy) -> some View {
        ZStack {
            // 透け感のあるグラデーション背景
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.4), location: 0),
                    .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.25), location: 0.7),
                    .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.15), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .ignoresSafeArea(edges: .top)
            
            // コンテンツレイアウト
            HStack(spacing: 0) {
                // 左：ロゴ + タイトル
                HStack(spacing: logoGap) {
                    // ロゴ
                    Image(logoName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: logoSize, height: logoSize)
                    
                    // タイトル
                    if !title.isEmpty {
                        Text(title)
                            .font(titleFont)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color(red: 1, green: 1, blue: 1), location: 0.3),
                                        .init(color: Color(red: 224/255, green: 231/255, blue: 1), location: 0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .kerning(0.2)
                    }
                }
                
                Spacer()
                
                // 右：ナビゲーション（デバイスサイズに応じて表示）
                if shouldShowNavigation && !navItems.isEmpty {
                    navigationView
                }
            }
            .padding(.top, geometry.safeAreaInsets.top)
            .padding(.horizontal, horizontalPadding)
        }
    }
    
    // ナビゲーションビュー
    private var navigationView: some View {
        HStack(spacing: navGap) {
            ForEach(navItems) { item in
                if item.href != nil {
                    // Linkタイプ（ボーダーなし）
                    Button(action: {
                        item.action?()
                        // 実際のナビゲーション処理はここで実装
                    }) {
                        Text(item.label)
                            .font(.system(size: navFontSize))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.white.opacity(0.9))
                            .padding(.horizontal, navPaddingH)
                            .padding(.vertical, navPaddingV)
                            .background(Color.white.opacity(0.0))
                            .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                } else {
                    // Buttonタイプ（ボーダーあり）
                    Button(action: {
                        item.action?()
                    }) {
                        Text(item.label)
                            .font(.system(size: navFontSize))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.white.opacity(0.9))
                            .padding(.horizontal, navPaddingH)
                            .padding(.vertical, navPaddingV)
                            .background(Color.white.opacity(0.0))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
    
    
    // MARK: - 計算プロパティ（iOSベストプラクティス）
    
    // デバイスタイプ判定
    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
    
    // ナビゲーション表示判定（iPhoneは横向き or Regular、iPadは常に表示）
    private var shouldShowNavigation: Bool {
        if isIPad {
            return true
        } else {
            // iPhoneの場合、Regularサイズクラス（横向きなど）で表示
            return horizontalSizeClass == .regular
        }
    }
    
    // ヘッダーの高さ（SafeAreaを含まない）
    private var headerHeight: CGFloat {
        isIPad ? 64 : 56
    }
    
    // ロゴサイズ
    private var logoSize: CGFloat {
        if isIPad {
            return 48
        } else {
            return horizontalSizeClass == .regular ? 40 : 32
        }
    }
    
    // ロゴとタイトルの間隔
    private var logoGap: CGFloat {
        isIPad ? 16 : 12
    }
    
    // 水平パディング
    private var horizontalPadding: CGFloat {
        if isIPad {
            return 32
        } else {
            return horizontalSizeClass == .regular ? 24 : 16
        }
    }
    
    // ナビゲーション間隔
    private var navGap: CGFloat {
        isIPad ? 20 : 12
    }
    
    // ナビゲーションフォントサイズ
    private var navFontSize: CGFloat {
        isIPad ? 17 : 15
    }
    
    // ナビゲーション水平パディング
    private var navPaddingH: CGFloat {
        isIPad ? 16 : 12
    }
    
    // ナビゲーション垂直パディング
    private var navPaddingV: CGFloat {
        isIPad ? 10 : 8
    }
    
    // タイトルフォント
    private var titleFont: Font {
        let size: CGFloat
        if isIPad {
            size = 24
        } else {
            size = horizontalSizeClass == .regular ? 20 : 18
        }
        return .custom("YuseiMagic-Regular", size: size)
    }
}

// ホバー時のスケールエフェクト用ボタンスタイル
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.1 : 0.0))
            )
    }
}

#Preview("Header - 基本") {
    ZStack(alignment: .top) {
        // 背景
        LinearGradient(
            colors: [
                Color(red: 0.5, green: 0.2, blue: 0.6),  // purple
                Color(red: 0.1, green: 0.2, blue: 0.6),  // blue
                Color(red: 0.2, green: 0.1, blue: 0.5)   // indigo
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // ヘッダー
        VStack(spacing: 0) {
            Header(
                title: "えほんのたね",
                logoName: "logo",
                navItems: [
                    HeaderNavItem(label: "ホーム", href: "/home", action: { print("ホームクリック") }),
                    HeaderNavItem(label: "マイページ", href: "/mypage", action: { print("マイページクリック") }),
                    HeaderNavItem(label: "ログアウト", action: { print("ログアウトクリック") })
                ]
            )
            
            Spacer()
        }
    }
}

#Preview("Header - スクロールコンテンツ") {
    ZStack(alignment: .top) {
        // メインコンテンツ
        ScrollView {
            VStack(spacing: 16) {
                // コンテンツ
                ForEach(0..<30) { index in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 80)
                        .overlay(
                            Text("コンテンツ \(index + 1)")
                                .foregroundColor(.white)
                        )
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.5, green: 0.2, blue: 0.6),
                    Color(red: 0.1, green: 0.2, blue: 0.6),
                    Color(red: 0.2, green: 0.1, blue: 0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        
        // 画面上部に固定されるヘッダー
        VStack(spacing: 0) {
            Header(
                title: "えほんのたね",
                logoName: "logo",
                navItems: [
                    HeaderNavItem(label: "ホーム", href: "/home", action: { print("ホームクリック") }),
                    HeaderNavItem(label: "マイページ", href: "/mypage", action: { print("マイページクリック") }),
                    HeaderNavItem(label: "ログアウト", action: { print("ログアウトクリック") })
                ]
            )
            
            Spacer()
        }
    }
}
