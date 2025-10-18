import SwiftUI

// シンプルなヘッダーコンポーネント
struct Header: View {
    var title: String = "えほんのたね"
    var logoName: String = "logo"
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    // ロゴ
                    Image(logoName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .padding(.leading, 16)  // 画面左から16px
                    
                    // タイトル
                    Text(title)
                        .font(.custom("YuseiMagic-Regular", size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.bottom, 10)  // ヘッダー背景下部から10px余白
                
                Spacer()
            }
            .padding(.top, geometry.safeAreaInsets.top)
            .frame(height: max(geometry.size.height * 0.06,10) + geometry.safeAreaInsets.top)  // 画面の縦サイズの12%か90ポイントのうち大きい方
            .background(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.4), location: 0),
                        .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.25), location: 0.7),
                        .init(color: Color(red: 2/255, green: 6/255, blue: 23/255, opacity: 0.15), location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .top)
        }
    }
}

#Preview {
    ZStack(alignment: .top) {
        // 背景
        Background {
            BigCharacter()
        }
        
        // ヘッダー
        Header()
    }
}
