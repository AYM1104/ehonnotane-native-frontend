import SwiftUI
import CoreText
import CoreGraphics

// フォント登録ヘルパー
class FontRegistration {
    /// カスタムフォントを登録
    static func registerFonts() {
        registerFont(bundle: Bundle.main, fontName: "YuseiMagic-Regular", fontExtension: "ttf")
    }
    
    /// 指定されたフォントファイルを登録
    /// - Parameters:
    ///   - bundle: フォントファイルが含まれるバンドル
    ///   - fontName: フォントファイル名（拡張子なし）
    ///   - fontExtension: フォント拡張子
    fileprivate static func registerFont(bundle: Bundle, fontName: String, fontExtension: String) {
        guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension) else {
            print("⚠️ フォントファイルが見つかりません: \(fontName).\(fontExtension)")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
            if let error = error?.takeRetainedValue() {
                let errorDescription = CFErrorCopyDescription(error) as String
                print("⚠️ フォント登録エラー: \(errorDescription)")
            }
        } else {
            print("✅ フォント登録成功: \(fontName)")
        }
    }
}

// Yusei Magicフォントを簡単に使用するための拡張
extension Font {
    /// Yusei Magicフォントを指定したサイズで取得
    /// - Parameter size: フォントサイズ
    /// - Returns: カスタムフォント
    static func yuseiMagic(size: CGFloat) -> Font {
        return .custom("YuseiMagic-Regular", size: size)
    }
    
    // よく使うサイズをプリセットとして定義
    static let yuseiMagicLargeTitle = yuseiMagic(size: 34)
    static let yuseiMagicTitle = yuseiMagic(size: 28)
    static let yuseiMagicTitle2 = yuseiMagic(size: 22)
    static let yuseiMagicTitle3 = yuseiMagic(size: 20)
    static let yuseiMagicHeadline = yuseiMagic(size: 17)
    static let yuseiMagicBody = yuseiMagic(size: 17)
    static let yuseiMagicCallout = yuseiMagic(size: 16)
    static let yuseiMagicSubheadline = yuseiMagic(size: 15)
    static let yuseiMagicFootnote = yuseiMagic(size: 13)
    static let yuseiMagicCaption = yuseiMagic(size: 12)
    static let yuseiMagicCaption2 = yuseiMagic(size: 11)
}
