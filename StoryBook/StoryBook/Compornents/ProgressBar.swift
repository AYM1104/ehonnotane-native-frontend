//
//  ProgressBar.swift
//  StoryBook
//
//  Created by ayu on 2025/01/27.
//

import SwiftUI

/// ドットプログレスバーコンポーネント
/// Primaryボタンと同じ色のグラデーションと光る効果を持つ
struct ProgressBar: View {
    // MARK: - Properties
    
    /// 総ステップ数
    let totalSteps: Int
    
    /// 現在のステップ（0から始まる）
    let currentStep: Int
    
    /// ドットのサイズ
    var dotSize: CGFloat = 8
    
    /// ドット間のスペース
    var spacing: CGFloat = 8
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? Color.white : Color.gray.opacity(0.3))
                    .frame(width: dotSize, height: dotSize)
                    .shadow(
                        color: index == currentStep ? Color.white.opacity(0.8) : Color.clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ProgressBar(totalSteps: 5, currentStep: 0)
        
        ProgressBar(totalSteps: 5, currentStep: 2)
        
        ProgressBar(totalSteps: 5, currentStep: 4)
        
        ProgressBar(totalSteps: 3, currentStep: 1)
        
        ProgressBar(totalSteps: 7, currentStep: 3, dotSize: 12, spacing: 12)
    }
    .padding()
}
