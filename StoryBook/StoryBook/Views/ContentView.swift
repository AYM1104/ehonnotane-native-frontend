//
//  ContentView.swift
//  StoryBook
//
//  Created by ayu on 2025/10/12.
//

import SwiftUI

struct ContentView: View {
    // ボタン表示状態を管理
    @State private var showButton = false
    @State private var isLoginModalPresented = false
    @State private var isKeyboardVisible = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var focusedField = 0
    
    var body: some View {
        NavigationStack {
            // 星空背景を適用
            Background {
                VStack(spacing: 40) {
                    Spacer()
                    
                    // ロゴアニメーション
                    LogoAnimation()
                    
                    // タイトルテキストアニメーション
                    TitleText()
                    
                    // ボタン（タイトル表示後に表示）
                    VStack(spacing: 15) {
                        NavigationLink(destination: LoginModal(
                            isPresented: $isLoginModalPresented,
                            isKeyboardVisible: $isKeyboardVisible,
                            keyboardHeight: keyboardHeight,
                            focusedField: $focusedField,
                            onLogin: {
                                // ログイン成功時の処理
                                print("ログイン成功")
                            }
                        )) {
                            Text("えほんをつくる")
                                .font(.custom("YuseiMagic-Regular", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 48)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 16/255, green: 185/255, blue: 129/255),
                                            Color(red: 20/255, green: 184/255, blue: 166/255),
                                            Color(red: 6/255, green: 182/255, blue: 212/255)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 50))
                                .shadow(
                                    color: Color(red: 52/255, green: 211/255, blue: 153/255).opacity(0.5),
                                    radius: 15,
                                    x: 0,
                                    y: 5
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 20)
                    .opacity(showButton ? 1.0 : 0.0)
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    // タイトルテキストが全て表示された後にボタンを表示（5秒後）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation(.easeIn(duration: 0.8)) {
                            showButton = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
