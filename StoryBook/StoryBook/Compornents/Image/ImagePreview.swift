import SwiftUI
import PhotosUI

#if canImport(UIKit)
import UIKit
#endif

/// 画像プレビューとキャンセルボタンを含むコンポーネント
struct ImagePreview: View {
    // MARK: - Properties
    
    #if canImport(UIKit)
    /// 表示する画像
    let image: UIImage
    
    /// 画像の最大サイズ
    var maxSize: CGFloat = 300
    
    /// コーナー半径
    var cornerRadius: CGFloat = 12
    
    /// キャンセルボタンのサイズ
    var cancelButtonSize: CGFloat = 24
    
    /// キャンセルボタンのオフセット
    var cancelButtonOffset: CGSize = CGSize(width: 10, height: -10)
    #endif
    
    /// キャンセル時のコールバック
    let onCancel: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        #if canImport(UIKit)
        ZStack(alignment: .topTrailing) {
            // 画像プレビュー
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: maxSize, height: maxSize)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            
            // 右上のバツボタン
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: cancelButtonSize))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(cancelButtonOffset)
        }
        #else
        // UIKitが利用できない場合の代替表示
        Text("画像プレビュー")
            .font(.custom("YuseiMagic-Regular", size: 18))
            .foregroundColor(.white)
        #endif
    }
}

// MARK: - Preview

#Preview("ImagePreview Demo") {
    ImagePreviewDemo()
}

// プレビュー用のヘルパービュー
private struct ImagePreviewDemo: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    
    #if canImport(UIKit)
    @State private var selectedImage: UIImage? = nil
    #endif
    
    var body: some View {
        #if canImport(UIKit)
        VStack(spacing: 20) {
        if let image = selectedImage {
            VStack(spacing: 20) {
                // 選択された画像を表示
                ImagePreview(
                    image: image,
                    onCancel: {
                        selectedImage = nil
                        selectedItem = nil
                    }
                )
                
                // 決定ボタン
                PrimaryButton(
                    title: "これにけってい",
                    action: {
                        // 決定時の処理（必要に応じて実装）
                        print("画像が決定されました")
                    }
                )
                .padding(.top, 10) // ボタンの上に余白を追加
            }
        } else {
                // 画像選択ボタン
                PhotoPickerButton(
                    selectedItem: $selectedItem,
                    title: "画像を選択する",
                    fontSize: 18
                )
            }
        }
        .padding(10)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
        #else
        Text("Preview not available")
        #endif
    }
}
