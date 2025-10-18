//
//  BookPageComponents.swift
//  StoryBook
//
//  Created by ayu on 2025/10/16.
//

import SwiftUI

// MARK: - ページ（紙面）に画像を表示するための共通ビュー

/// 紙面にローカル画像（SwiftUI.Image）を表示
public struct BookImagePage: View {
    public enum FitMode { case fit, fill }

    let image: Image
    let contentInset: CGFloat
    let fit: FitMode
    let background: Color
    let text: String?
    let textAreaHeight: CGFloat

    public init(
        _ image: Image,
        contentInset: CGFloat = 24,
        fit: FitMode = .fit,
        background: Color = .white,
        text: String? = nil,
        textAreaHeight: CGFloat = 120
    ) {
        self.image = image
        self.contentInset = contentInset
        self.fit = fit
        self.background = background
        self.text = text
        self.textAreaHeight = textAreaHeight
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 画像エリア
            GeometryReader { geo in
                let w = geo.size.width
                let imageHeight = geo.size.height
                image
                    .resizable()
                    .modifier(ScaledModifier(mode: fit))
                    .frame(width: w, height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .white.opacity(1.0), radius: 55, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.75), radius: 30, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(1.0), lineWidth: 40)
                            .blur(radius: 30)
                    )
            }
            .frame(maxWidth: .infinity)
            
            // テキストエリア
            if let text = text {
                VStack(spacing: 0) {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .lineSpacing(4)
                }
                .frame(height: textAreaHeight)
                .frame(maxWidth: .infinity, alignment: .top)
                .background(background)
            }
        }
        .background(background)
    }

    private struct ScaledModifier: ViewModifier {
        let mode: FitMode
        func body(content: Content) -> some View {
            switch mode {
            case .fit:  return AnyView(content.scaledToFit())
            case .fill: return AnyView(content.scaledToFill())
            }
        }
    }
}

/// 紙面にリモート画像（URL）を表示
@available(iOS 15.0, macOS 12.0, *)
public struct BookRemoteImagePage: View {
    public enum FitMode { case fit, fill }

    let url: URL
    let contentInset: CGFloat
    let fit: FitMode
    let background: Color
    let placeholderBackground: Color
    let text: String?
    let textAreaHeight: CGFloat

    public init(
        _ url: URL,
        contentInset: CGFloat = 24,
        fit: FitMode = .fit,
        background: Color = .white,
        placeholderBackground: Color = Color.black.opacity(0.05),
        text: String? = nil,
        textAreaHeight: CGFloat = 120
    ) {
        self.url = url
        self.contentInset = contentInset
        self.fit = fit
        self.background = background
        self.placeholderBackground = placeholderBackground
        self.text = text
        self.textAreaHeight = textAreaHeight
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 画像エリア
            GeometryReader { geo in
                let w = geo.size.width
                let imageHeight = geo.size.height
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .modifier(Scaled(mode: fit))
                            .frame(width: w, height: imageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(color: .white.opacity(1.0), radius: 55, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.75), radius: 30, x: 0, y: 0)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(1.0), lineWidth: 40)
                                    .blur(radius: 30)
                            )
                    case .failure(_):
                        ZStack {
                            placeholderBackground
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: w, height: imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .empty:
                        ZStack {
                            placeholderBackground
                            ProgressView()
                        }
                        .frame(width: w, height: imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    @unknown default:
                        Color.clear
                            .frame(width: w, height: imageHeight)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // テキストエリア
            if let text = text {
                VStack(spacing: 0) {
                    Text(text)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .lineSpacing(4)
                }
                .frame(height: textAreaHeight)
                .frame(maxWidth: .infinity, alignment: .top)
                .background(background)
            }
        }
        .background(background)
    }

    private struct Scaled: ViewModifier {
        let mode: FitMode
        func body(content: Content) -> some View {
            switch mode {
            case .fit:  return AnyView(content.scaledToFit())
            case .fill: return AnyView(content.scaledToFill())
            }
        }
    }
}
