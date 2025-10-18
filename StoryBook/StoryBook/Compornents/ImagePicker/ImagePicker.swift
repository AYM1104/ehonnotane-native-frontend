//
//  ImagePicker.swift
//  StoryBook
//
//  Created by ayu on 2025/10/13.
//

import SwiftUI
import UIKit

/// UIImagePickerControllerをSwiftUIで使用するためのラッパー
struct ImagePicker: UIViewControllerRepresentable {
    // MARK: - Properties
    
    /// 画像ソース（写真ライブラリ、カメラなど）
    let sourceType: UIImagePickerController.SourceType
    
    /// 画像が選択された時のコールバック
    let onImagePicked: (UIImage) -> Void
    
    /// ピッカーを閉じる時のコールバック
    let onCancel: (() -> Void)?
    
    // MARK: - Initializer
    
    init(
        sourceType: UIImagePickerController.SourceType,
        onImagePicked: @escaping (UIImage) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.sourceType = sourceType
        self.onImagePicked = onImagePicked
        self.onCancel = onCancel
    }
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true // 画像の編集を許可
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 更新処理は不要
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel?()
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview

#Preview {
    ImagePicker(sourceType: .photoLibrary) { image in
        print("画像が選択されました: \(image)")
    }
}
