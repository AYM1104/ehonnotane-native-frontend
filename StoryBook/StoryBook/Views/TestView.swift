import SwiftUI
import PhotosUI

struct TestView: View {
    // PhotosPickerの選択状態を管理するState
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()
            }
            
            // ヘッダー
            Header()
            
            // メインカード（画面下部に配置）
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                MainText(text: "どんな え でえほんを")
                MainText(text: "つくろうかな？")
                Spacer()
                mainCard(width: .screen95) {
                    VStack(spacing: 16) {
                        Spacer()
                        
                        if let image = selectedImage {
                            // 画像が選択されている場合はプレビューを表示
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
                            .padding(.top, 16) // ボタンの上に余白を追加
                        } else {
                            // 画像が選択されていない場合は選択ボタンを表示
                            PhotoPickerButton(
                                selectedItem: $selectedItem,
                                title: "画像を選択する",
                                fontSize: 20
                            )
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 16) // パディングを減らしてカードを広く表示
                .padding(.bottom, -10) // 画面下部からの余白
            }
        }
        .onChange(of: selectedItem) { oldValue, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    #if canImport(UIKit)
                    if let image = UIImage(data: data) {
                        selectedImage = image
                    }
                    #endif
                }
            }
        }
    }
}

#Preview {
    TestView()
}
