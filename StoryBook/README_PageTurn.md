# PageTurnView - SwiftUI絵本アプリ用ページめくりコンポーネント

## 概要

`PageTurnView`は、SwiftUIで本格的なページめくりアニメーションを実装するためのコンポーネントです。絵本アプリや電子書籍リーダーに最適な、リアルな紙のめくり感を再現します。

## 主な機能

### 📱 3つのページめくりスタイル

1. **Native Curl** (`curlNative`)
   - UIKit の `UIPageViewController` を使用
   - iOS標準の本物のページカールアニメーション
   - 最もリアルな紙のめくり感
   - パフォーマンスに優れる

2. **Simulated Curl** (`curlSimulated`)
   - 純SwiftUIによる実装
   - `DragGesture` + `rotation3DEffect` + 動的陰影
   - カスタマイズ性が高い
   - 60fps目標の滑らかなアニメーション

3. **Flip** (`flip`)
   - シンプルなフリップアニメーション
   - 軽量で高速
   - アクセシビリティ優先時に推奨

### ✨ 主要機能

- ✅ インタラクティブなドラッグ操作
- ✅ タップ/スワイプでのページ遷移
- ✅ 両面表示対応（`isDoubleSided`）
- ✅ 右綴じ対応（`isRTL`）
- ✅ 触覚フィードバック（`haptics`）
- ✅ VoiceOver完全対応
- ✅ Dynamic Type対応
- ✅ ページ先読み機能
- ✅ 状態管理とバインディング

## 基本的な使い方

### 最小構成

```swift
import SwiftUI

struct SimpleBookView: View {
    @State private var currentPage = 0
    
    let pages = [
        AnyView(Text("ページ1")),
        AnyView(Text("ページ2")),
        AnyView(Text("ページ3"))
    ]
    
    var body: some View {
        PageTurnView(
            pages: pages,
            currentIndex: $currentPage
        )
    }
}
```

### フル機能版

```swift
import SwiftUI

struct EnhancedBookView: View {
    @State private var currentPage = 0
    
    let pages = (1...12).map { AnyView(PageTemplate(number: $0)) }
    
    var body: some View {
        PageTurnView(
            pages: pages,
            currentIndex: $currentPage,
            style: .curlSimulated,      // ページめくりスタイル
            isDoubleSided: true,         // 両面表示
            isRTL: true,                 // 右綴じ（日本語絵本など）
            haptics: true,               // 触覚フィードバック
            onPageChanged: { newIndex in
                print("新しいページ: \(newIndex + 1)")
                // アナリティクスやロギング処理
            }
        )
    }
}
```

### ジェネリック版（型安全）

```swift
struct TypeSafeBookView: View {
    @State private var currentPage = 0
    
    var body: some View {
        PageTurnView(
            pageCount: 10,
            currentIndex: $currentPage,
            style: .curlNative
        ) { index in
            // ページコンテンツをクロージャで生成
            VStack {
                Text("ページ \(index + 1)")
                    .font(.largeTitle)
                Image(systemName: "book.fill")
                    .font(.system(size: 100))
            }
        }
    }
}
```

## パラメータ詳細

| パラメータ | 型 | デフォルト | 説明 |
|-----------|-----|----------|------|
| `pages` | `[AnyView]` | - | 表示するページの配列 |
| `currentIndex` | `Binding<Int>` | - | 現在のページインデックス（双方向バインディング） |
| `style` | `PageTurnStyle` | `.curlSimulated` | ページめくりスタイル |
| `isDoubleSided` | `Bool` | `true` | 両面表示の有効化 |
| `isRTL` | `Bool` | `false` | 右綴じ（Right-to-Left）対応 |
| `haptics` | `Bool` | `true` | 触覚フィードバックの有効化 |
| `onPageChanged` | `((Int) -> Void)?` | `nil` | ページ変更時のコールバック |

## アーキテクチャ

### ファイル構成

```
PageTurnView/
├── PageTurnView.swift                    # 公開API・メインコンポーネント
├── PageTurnController.swift              # 状態管理・ロジック
├── PageCurlNativeRepresentable.swift    # UIKit ブリッジ
├── PageCurlSimulated.swift              # 純SwiftUI実装
└── BookDemoView.swift                    # デモ・サンプル
```

### コンポーネント図

```
┌─────────────────────────────────────┐
│      PageTurnView (公開API)        │
│  ・pages, currentIndex, style       │
│  ・isDoubleSided, isRTL, haptics    │
└────────────┬────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────┐      ┌────▼─────────────────┐
│ Native │      │ Simulated / Flip     │
│ Curl   │      │ Curl                 │
└────────┘      └──────────────────────┘
                         │
                  ┌──────┴──────┐
                  │             │
            ┌─────▼──────┐  ┌──▼──────────────┐
            │ Controller │  │ DragGesture +   │
            │ (状態管理)  │  │ rotation3DEffect │
            └────────────┘  └─────────────────┘
```

## 実装の詳細

### Native Curl（UIKit ブリッジ）

- `UIPageViewController(transitionStyle: .pageCurl)` を使用
- `UIViewControllerRepresentable` でSwiftUIにブリッジ
- 両面表示：`isDoubleSided = true`
- スパイン位置：RTLに応じて `.min` / `.max` を切り替え
- SwiftUIの `currentIndex` と双方向同期

#### 実装のポイント

```swift
// UIPageViewControllerの設定
let options: [UIPageViewController.OptionsKey: Any] = [
    .spineLocation: isRTL ? UIPageViewController.SpineLocation.max.rawValue 
                          : UIPageViewController.SpineLocation.min.rawValue
]

let pageViewController = UIPageViewController(
    transitionStyle: .pageCurl,
    navigationOrientation: .horizontal,
    options: options
)

pageViewController.isDoubleSided = isDoubleSided
```

### Simulated Curl（純SwiftUI）

#### アニメーション計算

1. **進捗計算**（`t ∈ [0,1]`）
   ```swift
   let progress = dragOffset / screenWidth
   ```

2. **回転角度**
   ```swift
   rotation3DEffect(
       .degrees(progress * 180),
       axis: (x: 0, y: 1, z: 0),
       anchor: .trailing,
       perspective: 0.6
   )
   ```

3. **カールハイライト**（折り目の光沢）
   ```swift
   LinearGradient(
       gradient: Gradient(colors: [
           Color.white.opacity(0),
           Color.white.opacity(abs(progress) * 0.5),
           Color.white.opacity(0)
       ]),
       startPoint: .trailing,
       endPoint: .leading
   )
   ```

4. **動的シャドウ**
   ```swift
   .shadow(
       color: .black.opacity(abs(progress) * 0.3),
       radius: abs(progress) * 20,
       x: progress > 0 ? -10 : 10,
       y: 5
   )
   ```

#### ヒステリシス（確定判定）

```swift
// 閾値：40%以上でページ確定
let confirmThreshold: CGFloat = 0.4

// または速度判定
let velocityThreshold: CGFloat = 500

if abs(progress) > confirmThreshold || abs(velocity) > velocityThreshold {
    // ページめくり確定
    confirmPageTurn()
} else {
    // キャンセル（元に戻る）
    resetToCurrentPage()
}
```

## パフォーマンス最適化

### 1. ページ先読み

```swift
// PageTurnControllerで自動的に前後1ページを先読み
controller.enablePreload = true
controller.preloadRange = 1  // 前後1ページ
```

### 2. 画像最適化

```swift
Image("page-image")
    .resizable()
    .interpolation(.medium)  // 品質とパフォーマンスのバランス
    .aspectRatio(contentMode: .fit)
```

### 3. State最小化

- 必要最小限のState変数のみ使用
- 計算プロパティを活用
- 不要な再描画を避ける

### 4. アニメーション最適化

```swift
// interactiveSpringで60fps維持
withAnimation(.interactiveSpring(
    response: 0.4,
    dampingFraction: 0.85,
    blendDuration: 0
)) {
    // アニメーション処理
}
```

## アクセシビリティ

### VoiceOver対応

```swift
.accessibilityElement(children: .contain)
.accessibilityLabel("絵本ページビュー")
.accessibilityHint("左右にスワイプしてページをめくります")
.accessibilityScrollAction { edge in
    // エッジに応じてページ遷移
}
```

### Dynamic Type対応

```swift
Text("ページタイトル")
    .font(.largeTitle)  // 自動的にDynamic Typeに対応
```

### Reduce Motion対応

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// アニメーションを無効化
if reduceMotion {
    // アニメーションなしで遷移
} else {
    withAnimation {
        // 通常のアニメーション
    }
}
```

## テスト観点

### 境界条件

- ✅ 先頭ページでの前ページ遷移試行
- ✅ 最終ページでの次ページ遷移試行
- ✅ 1ページのみの場合

### 操作テスト

- ✅ 素早い連続スワイプ
- ✅ ドラッグ中のキャンセル
- ✅ 画面端からのドラッグ
- ✅ タップでのページ遷移

### 状態テスト

- ✅ デバイス回転時の状態保持
- ✅ アプリ復帰時のページ保持
- ✅ 外部からの`currentIndex`変更
- ✅ RTL切り替え時の動作

### アクセシビリティテスト

- ✅ VoiceOverでのページ遷移
- ✅ Dynamic Type大サイズでの表示
- ✅ Reduce Motion有効時の動作

## 既知の制約と注意点

### 1. Native Curlの制約

- iOS標準の`UIPageViewController`に依存
- カスタマイズ性が限定的
- アニメーション速度やカーブの調整が困難

### 2. Simulated Curlの制約

- 複雑な3D変形は計算コスト高
- 古いデバイスではフレームレート低下の可能性
- 本物のカールと比べて若干の違和感

### 3. パフォーマンス

- 高解像度画像を多用する場合は先読みを調整
- ページ数が100以上の場合は仮想化を検討
- メモリ消費に注意（特に画像多用時）

### 4. RTL対応

- 日本語の縦書き絵本など、文化圏に応じた調整が必要
- スパイン位置の視覚的確認を推奨

## 拡張ポイント

### カスタムページコンテンツ

```swift
struct CustomPage: View {
    let data: PageData
    
    var body: some View {
        // 独自のレイアウト実装
        ZStack {
            AsyncImage(url: data.imageURL)
            VStack {
                Text(data.title)
                Text(data.content)
            }
        }
    }
}
```

### カスタムアニメーション

```swift
// PageCurlSimulatedを継承してカスタマイズ
class CustomPageCurl: PageCurlSimulated {
    override func calculateRotationAngle(progress: CGFloat) -> Double {
        // 独自の回転計算
        return Double(progress) * 360  // 2回転など
    }
}
```

### イベント追跡

```swift
PageTurnView(
    pages: pages,
    currentIndex: $currentPage,
    onPageChanged: { newIndex in
        // アナリティクス送信
        Analytics.logEvent("page_viewed", parameters: [
            "page_number": newIndex + 1
        ])
        
        // 進捗保存
        UserDefaults.standard.set(newIndex, forKey: "lastReadPage")
    }
)
```

## トラブルシューティング

### Q: ページめくりが遅い

**A:** 以下を確認してください：
- 画像サイズを最適化
- 先読み範囲を調整（`controller.preloadRange`）
- スタイルを`.curlNative`に変更

### Q: RTLが正しく動作しない

**A:** 以下を確認：
- `isRTL`パラメータが正しく設定されているか
- デバイスの言語設定（一部の動作に影響）

### Q: VoiceOverで操作できない

**A:** 
- アクセシビリティラベルが設定されているか確認
- `.accessibilityScrollAction`が実装されているか確認

## ライセンスと貢献

このコンポーネントはサンプル実装です。自由に改変・使用してください。

## サポート

- 最小iOS: 15.0+
- 推奨iOS: 16.0+
- SwiftUI: 必須

## 更新履歴

- v1.0.0: 初回リリース
  - 3つのページめくりスタイル
  - RTL対応
  - アクセシビリティ完全対応

