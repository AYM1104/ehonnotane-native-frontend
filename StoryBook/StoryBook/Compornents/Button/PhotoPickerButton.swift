import SwiftUI
import PhotosUI

/// PrimaryButtonをPhotosPickerでラップしたコンポーネント
struct PhotoPickerButton: View {
    // MARK: - Properties
    
    /// PhotosPickerの選択状態
    @Binding var selectedItem: PhotosPickerItem?
    
    /// ボタンのタイトル
    var title: String = "画像を選択する"
    
    /// ボタンが無効かどうか
    var disabled: Bool = false
    
    /// ボタンの幅（nilの場合は自動調整）
    var width: CGFloat? = nil
    
    /// フォント名（デフォルトはYuseiMagic-Regular）
    var fontName: String? = "YuseiMagic-Regular"
    
    /// フォントサイズ
    var fontSize: CGFloat = 20
    
    // MARK: - Body
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            // 共通のボタンスタイルを使用
            CustomButtonStyle(
                title: title,
                width: width,
                fontName: fontName,
                fontSize: fontSize,
                disabled: disabled
            )
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedItem: PhotosPickerItem? = nil
    
    return VStack {
        PhotoPickerButton(
            selectedItem: $selectedItem,
            title: "画像を選択する（デフォルトフォント）"
        )
        
        PhotoPickerButton(
            selectedItem: $selectedItem,
            title: "カスタムサイズ",
            width: 200,
            fontSize: 18
        )
        
        PhotoPickerButton(
            selectedItem: $selectedItem,
            title: "システムフォント",
            fontName: nil
        )
    }
    .padding()
}
