import SwiftUI
import PhotosUI

#if canImport(UIKit)
import UIKit
#endif

struct UploadImageView: View {
    // MARK: - Properties
    let onNavigateToQuestions: (Int) -> Void
    
    // PhotosPickerの選択状態を管理するState
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // 画像アップロード関連の状態
    @EnvironmentObject var authService: AuthService
    @State private var imageUploadService: ImageUploadService?
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showingError = false
    
    // MARK: - 初期化
    init(onNavigateToQuestions: @escaping (Int) -> Void) {
        self.onNavigateToQuestions = onNavigateToQuestions
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景
            Background {
                BigCharacter()  // 背景に大きなキャラクターを表示
            }
            
            // ヘッダー
            Header()
            
            // メインコンテンツ
            VStack {
                // ヘッダーの高さ分のスペースを確保
                Spacer()
                    .frame(height: 80)
                
                // メインテキストを表示
                MainText(text: "どんな え でえほんを")
                MainText(text: "つくろうかな？")
                Spacer()

                // メインカードを表示
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
                                title: isUploading ? "アップロード中..." : "これにけってい",
                                action: {
                                    handleImageUpload() // 画像をアップロード
                                }
                            )
                            .disabled(isUploading)
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
        .onAppear {
            // ImageUploadServiceを初期化（AuthServiceのAuthManagerを使用）
            imageUploadService = ImageUploadService(authManager: authService.authManager)
            // 認証状態を確認
            setupAuthentication()
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
        .alert("エラー", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(uploadError ?? "不明なエラーが発生しました")
        }
    }
    
    // MARK: - 認証設定
    
    /// 認証状態を確認してアクセストークンを設定
    private func setupAuthentication() {
        // AuthServiceの認証状態を確認
        if authService.authManager.isLoggedIn && authService.authManager.verifyAuthState() {
            print("✅ 認証済みユーザー: 認証状態を確認")
        } else {
            // 未ログインの場合、エラーを設定
            uploadError = "ログインが必要です。ログイン画面に戻ってください。"
            showingError = true
            print("❌ 未ログイン: 認証が必要です")
        }
    }
    
    
    // 「これにけってい」ボタンをタップすると以下が実行される
    #if canImport(UIKit)
    private func handleImageUpload() {
        print("🔄 handleImageUpload()が呼び出されました")
        
        // 認証状態を再確認
        guard authService.authManager.isLoggedIn && authService.authManager.verifyAuthState() else {
            uploadError = "ログインが必要です。ログイン画面に戻ってください。"
            showingError = true
            return
        }
        
        guard let image = selectedImage else { 
            print("❌ selectedImageがnilです")
            return 
        }
        
        guard let imageUploadService = imageUploadService else {
            print("❌ imageUploadServiceがnilです")
            return
        }
        
        print("========== 🔄 アップロード処理開始 ==========")
        isUploading = true
        uploadError = nil
        
        Task {
            do {
                // 画像をアップロードして物語設定も作成（Services/ImageUploadService.swiftで実行）
                let result = try await imageUploadService.uploadImageAndCreateStorySetting(image)
                
                print("✅ アップロード成功:")
                print("   - 画像ID: \(result.uploadResponse.id)")
                print("   - 物語設定ID: \(result.storySettingId)")
                print("   - 生成データ: \(result.generatedData ?? "なし")")
                
                // メインスレッドでUIを更新
                await MainActor.run {
                    isUploading = false
                    print("🔄 アップロード完了: onNavigateToQuestions(storySettingId)を呼び出し")
                    onNavigateToQuestions(result.storySettingId)
                }
                
            } catch {
                print("❌ アップロードエラー: \(error.localizedDescription)")
                
                // メインスレッドでエラーを表示
                await MainActor.run {
                    isUploading = false
                    uploadError = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    #endif
}

/*
#Preview {
    UploadImageView(onNavigateToQuestions: { storySettingId in
        print("プレビュー: QuestionCardViewへの遷移 (storySettingId=\(storySettingId))")
    })
}
*/