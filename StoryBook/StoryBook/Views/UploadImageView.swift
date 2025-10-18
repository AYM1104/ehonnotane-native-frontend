import SwiftUI
import PhotosUI

#if canImport(UIKit)
import UIKit
#endif

struct UploadImageView: View {
    // MARK: - State
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    #if canImport(UIKit)
    @State private var selectedImage: UIImage?
    @State private var imageSource: UIImagePickerController.SourceType = .photoLibrary
    #endif
    @State private var selectedItem: PhotosPickerItem?
    
    // 画像アップロード関連の状態
    @StateObject private var imageUploadService = ImageUploadService()
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showingError = false
    @State private var uploadedImageId: Int?
    // 質問画面への遷移フラグ
    @State private var navigateToQuestions: Bool = false
    
    var body: some View {
        // ヘッダーを含む全体レイアウト
        ZStack(alignment: .top) {
            // 星空背景を適用
            Background {
                // キャラクターを背景として配置
                BigCharacter()  

                // メインコンテンツ
                VStack {
                    // ヘッダーの高さ分のスペースを確保
                    Spacer()
                        .frame(height: 120)
                    
                    // メインテキスト（カードコンポーネントと同じ光る効果）
                    VStack(spacing: 8) {
                        MainText(text: "どんな え でえほんを")
                        MainText(text: "つくろうかな？")
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // ガラス風カードを表示
                    mainCard(width: .medium) {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            // カードの真ん中にボタンを配置
                            #if canImport(UIKit)
                            if selectedImage != nil {
                                // 画像が選択されている場合はプレビューを表示
                                VStack(spacing: 16) {
                                    ZStack(alignment: .topTrailing) {
                                        // 画像プレビュー
                                        Image(uiImage: selectedImage!)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: 200, maxHeight: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        // 右上のバツボタン
                                        Button(action: {
                                            selectedImage = nil
                                            selectedItem = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                        }
                                        .offset(x: 10, y: -10)
                                    }
                                    
                                    PrimaryButton(
                                        title: isUploading ? "アップロード中..." : "この画像にけってい",
                                        fontName: "YuseiMagic-Regular",
                                        fontSize: 20,
                                        action: {
                                            handleConfirmImage()
                                        }
                                    )
                                    .disabled(isUploading)
                                }
                            } else {
                                // 画像が選択されていない場合は選択ボタンを表示
                                PhotosPicker(
                                    selection: $selectedItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    Text("画像を選択する")
                                        .font(.custom("YuseiMagic-Regular", size: 24))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 48)
                                        .padding(.vertical, 12)
                                        .frame(width: 280)
                                        .background(
                                            ZStack {
                                                // グラデーション背景
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 16/255, green: 185/255, blue: 129/255), // emerald-500
                                                        Color(red: 20/255, green: 184/255, blue: 166/255), // teal-500
                                                        Color(red: 6/255, green: 182/255, blue: 212/255)   // cyan-500
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                
                                                // 光るボーダーエフェクト
                                                RoundedRectangle(cornerRadius: 50)
                                                    .strokeBorder(
                                                        Color(red: 110/255, green: 231/255, blue: 183/255).opacity(0.5),
                                                        lineWidth: 1
                                                    )
                                            }
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 50))
                                        .shadow(
                                            color: Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.5),
                                            radius: 15,
                                            x: 0,
                                            y: 5
                                        )
                                }
                            }
                            #else
                            if selectedItem != nil {
                                // PhotosPickerで画像が選択されている場合
                                VStack(spacing: 16) {
                                    Text("画像が選択されました")
                                        .font(.custom("YuseiMagic-Regular", size: 18))
                                        .foregroundColor(.white)
                                    
                                    PrimaryButton(
                                        title: isUploading ? "アップロード中..." : "この画像にけってい",
                                        fontName: "YuseiMagic-Regular",
                                        fontSize: 20,
                                        action: {
                                            handleConfirmImage()
                                        }
                                    )
                                    .disabled(isUploading)
                                }
                            } else {
                                // 画像が選択されていない場合は選択ボタンを表示
                                PhotosPicker(
                                    selection: $selectedItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    Text("画像を選択する")
                                        .font(.custom("YuseiMagic-Regular", size: 24))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 48)
                                        .padding(.vertical, 12)
                                        .frame(width: 280)
                                        .background(
                                            ZStack {
                                                // グラデーション背景
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 16/255, green: 185/255, blue: 129/255), // emerald-500
                                                        Color(red: 20/255, green: 184/255, blue: 166/255), // teal-500
                                                        Color(red: 6/255, green: 182/255, blue: 212/255)   // cyan-500
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                
                                                // 光るボーダーエフェクト
                                                RoundedRectangle(cornerRadius: 50)
                                                    .strokeBorder(
                                                        Color(red: 110/255, green: 231/255, blue: 183/255).opacity(0.5),
                                                        lineWidth: 1
                                                    )
                                            }
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 50))
                                        .shadow(
                                            color: Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.5),
                                            radius: 15,
                                            x: 0,
                                            y: 5
                                        )
                                }
                            }
                            #endif
                            
                            Spacer()
                        }
                    }
                    .padding()
                    
                    Spacer()
                        .frame(maxHeight: 30)
                }
            }
            
            // 画面上部に固定されるヘッダー
            Header(
                title: "えほんのたね",
                logoName: "logo",
                navItems: [
                    HeaderNavItem(label: "ホーム", href: "/home", action: { print("ホームクリック") }),
                    HeaderNavItem(label: "マイページ", href: "/mypage", action: { print("マイページクリック") }),
                    HeaderNavItem(label: "ログアウト", action: { print("ログアウトクリック") })
                ]
            )
            // 非表示の遷移リンク
            NavigationLink(destination: QuestionView(), isActive: $navigateToQuestions) { EmptyView() }
        }
        .navigationBarHidden(true)
        #if canImport(UIKit)
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("画像を選択"),
                message: Text("画像の取得方法を選択してください"),
                buttons: [
                    .default(Text("写真ライブラリ")) {
                        imageSource = UIImagePickerController.SourceType.photoLibrary
                        showingImagePicker = true
                    },
                    .default(Text("写真を撮る")) {
                        imageSource = UIImagePickerController.SourceType.camera
                        showingImagePicker = true
                    },
                    .default(Text("ファイルを選択")) {
                        // ファイル選択の処理（必要に応じて実装）
                        print("ファイル選択が選択されました")
                    },
                    .cancel(Text("キャンセル"))
                ]
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: imageSource) { image in
                selectedImage = image
            }
        }
        #endif
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
    
    // MARK: - Private Methods
    
    /// 画像決定時の処理（アップロード実行）
    private func handleConfirmImage() {
        #if canImport(UIKit)
        guard let image = selectedImage else {
            uploadError = "画像が選択されていません"
            showingError = true
            return
        }
        
        Task {
            await uploadImage(image)
        }
        #else
        // UIKitが利用できない場合の処理
        uploadError = "このプラットフォームでは画像アップロードがサポートされていません"
        showingError = true
        #endif
    }
    
    /// 画像をアップロードする
    #if canImport(UIKit)
    @MainActor
    private func uploadImage(_ image: UIImage) async {
        isUploading = true
        uploadError = nil
        
        do {
            let response = try await imageUploadService.uploadImage(image)
            
            uploadedImageId = response.id
            print("✅ 画像アップロード成功: ID \(response.id)")
            print("ファイル名: \(response.file_name)")
            print("公開URL: \(response.public_url ?? "なし")")
            
            // 画像アップロードが完了したら、すぐに質問画面へ遷移
            navigateToQuestions = true

            // 物語設定の作成は遷移後も非同期で続行（QuestionView は既定のロード表示を行う）
            if let imageId = uploadedImageId {
                Task {
                    do {
                        let created = try await createStorySettingFromImage(uploadImageId: imageId)
                        // UserDefaults へ保存（QuestionView が参照）
                        UserDefaults.standard.set(String(created.story_setting_id), forKey: "story_setting_id")
                        if let dataString = created.generated_data_jsonString {
                            UserDefaults.standard.set(dataString, forKey: "story_setting_data")
                        }
                    } catch {
                        print("❌ 物語設定作成エラー: \(error.localizedDescription)")
                        uploadError = "物語設定の作成に失敗しました"
                        showingError = true
                    }
                }
            }
            
        } catch {
            print("❌ 画像アップロードエラー: \(error.localizedDescription)")
            uploadError = error.localizedDescription
            showingError = true
        }
        
        isUploading = false
    }
    #endif
}

#Preview {
    UploadImageView()
}

// MARK: - 物語設定作成 用ユーティリティ
private struct StorySettingCreateResp: Decodable {
    let story_setting_id: Int
    let generated_data: StorySettingGeneratedData?
}

private struct StorySettingGeneratedData: Codable {
    let title_suggestion: String?
    let protagonist_name: String?
    let protagonist_type: String?
    let setting_place: String?
    let tone: String?
    let target_age: String?
    let language: String?
    let reading_level: String?
    let style_guideline: String?
}

private extension UploadImageView {
    /// 画像IDから物語設定を作成し、IDとJSON文字列を返す
    func createStorySettingFromImage(uploadImageId: Int) async throws -> (story_setting_id: Int, generated_data_jsonString: String?) {
        let base = ProcessInfo.processInfo.environment["NEXT_PUBLIC_API_URL"] ?? "http://localhost:8000"
        guard let url = URL(string: "\(base)/story/story_settings/\(uploadImageId)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // このエンドポイントはボディ不要仕様

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "StorySettingCreate", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: body])
        }

        let decoded = try JSONDecoder().decode(StorySettingCreateResp.self, from: data)
        var jsonString: String? = nil
        if let gen = decoded.generated_data, let encoded = try? JSONEncoder().encode(gen) {
            jsonString = String(data: encoded, encoding: .utf8)
        }
        return (decoded.story_setting_id, jsonString)
    }
}
