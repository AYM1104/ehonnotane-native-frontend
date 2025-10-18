import SwiftUI

#if canImport(Auth0)
import Auth0
#endif

struct TestView: View {
    // 表示用ステート
    @State private var isLoggedIn = false
    @State private var accessToken: String?
    @State private var idToken: String?
    @State private var output: String = "ここに結果が出ます"

    // あなたのAuth0設定
    private let domain   = "ehonnotane.jp.auth0.com"
    private let clientId = "b1sTk9gTW2rjddFtvu0w7ZrsFYk2ldfh"
    // Auth0の「APIs」で作成した Identifier（FastAPI側と揃える）
    private let audience = "https://api.ehonnotane"

    // テスト用 API エンドポイント（自分のFastAPIに合わせて変更）
    private let secureEndpoint = "https://YOUR_FASTAPI_HOST/secure"

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Circle()
                        .fill(isLoggedIn ? .green : .red)
                        .frame(width: 10, height: 10)
                    Text(isLoggedIn ? "ログイン済み" : "未ログイン")
                        .font(.headline)
                }

                HStack(spacing: 12) {
                    Button("ログイン") { login() }
                        .buttonStyle(.borderedProminent)
                    Button("ログアウト") { logout() }
                        .buttonStyle(.bordered)
                        .disabled(!isLoggedIn)
                    Button("保護 API 呼び出し") { callProtectedAPI() }
                        .buttonStyle(.bordered)
                        .disabled(!isLoggedIn)
                }

                GroupBox("Tokens") {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("accessToken:")
                                .font(.subheadline).bold()
                            Text(accessToken ?? "なし")
                                .textSelection(.enabled)
                                .font(.footnote)
                                .lineLimit(nil)

                            Divider()

                            Text("idToken:")
                                .font(.subheadline).bold()
                            Text(idToken ?? "なし")
                                .textSelection(.enabled)
                                .font(.footnote)
                                .lineLimit(nil)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                    }
                    .frame(minHeight: 120)
                }

                GroupBox("Output / Logs") {
                    ScrollView {
                        Text(output)
                            .textSelection(.enabled)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 120)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Auth0 Test")
        }
    }

    private func login() {
        output = "ログイン開始..."
        #if canImport(Auth0)
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .scope("openid profile email")
            .audience(audience)  // ← FastAPIを守るなら必須
            .start { result in
                switch result {
                case .success(let credentials):
                    isLoggedIn = true
                    accessToken = credentials.accessToken
                    idToken = credentials.idToken
                    output = """
                    ✅ ログイン成功
                    expiresIn: \(credentials.expiresIn.description)
                    """
                case .failure(let error):
                    isLoggedIn = false
                    accessToken = nil
                    idToken = nil
                    output = "❌ Auth エラー: \(error)"
                    print("Auth error:", error)
                }
            }
        #else
        output = "❌ Auth0モジュールが利用できません"
        #endif
    }

    private func logout() {
        output = "ログアウト中..."
        #if canImport(Auth0)
        Auth0
            .webAuth(clientId: clientId, domain: domain)
            .clearSession(federated: false) { result in
                isLoggedIn = false
                accessToken = nil
                idToken = nil
                switch result {
                case .success:
                    output = "✅ ログアウト完了"
                case .failure(let error):
                    output = "❌ ログアウト失敗: \(error)"
                }
            }
        #else
        output = "❌ Auth0モジュールが利用できません"
        #endif
    }

    private func callProtectedAPI() {
        guard let token = accessToken,
              let url = URL(string: secureEndpoint) else {
            output = "⚠️ accessToken または URL が未設定"
            return
        }
        output = "保護API呼び出し中..."

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err {
                output = "❌ 通信エラー: \(err.localizedDescription)"
                return
            }
            if let http = resp as? HTTPURLResponse {
                let body = String(data: data ?? Data(), encoding: .utf8) ?? ""
                output = "HTTP \(http.statusCode)\n\(body)"
            } else {
                output = "⚠️ 不明なレスポンス"
            }
        }.resume()
    }
}