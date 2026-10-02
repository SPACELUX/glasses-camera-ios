import Foundation
import UIKit

/// 把一张图片 POST 到服务器 /solve。服务器会:
///  1) 调 Claude 视觉解题
///  2) 把答案广播到眼镜 glasses.html (镜片上自动显示)
///  3) 把答案原样返回给本 App (用于手机上也显示 / 调试)
enum SolveClient {

    struct Result { let answer: String; let ms: Int }

    enum SolveError: LocalizedError {
        case encodeFailed, http(Int, String), badResponse, server(String)
        var errorDescription: String? {
            switch self {
            case .encodeFailed:      return "图片编码失败"
            case .http(let c, let b):return "HTTP \(c): \(b)"
            case .badResponse:       return "响应解析失败"
            case .server(let m):     return "服务器: \(m)"
            }
        }
    }

    static func solve(image: UIImage) async throws -> Result {
        guard let jpeg = image.jpegData(compressionQuality: Config.jpegQuality) else {
            throw SolveError.encodeFailed
        }
        let b64 = jpeg.base64EncodedString()

        var req = URLRequest(url: Config.solveURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(Config.pushSecret, forHTTPHeaderField: "x-push-secret")
        req.timeoutInterval = 45

        let payload: [String: Any] = [
            "image": b64,
            "mime": "image/jpeg",
            "extra": Config.extraInstruction
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw SolveError.badResponse }
        guard http.statusCode == 200 else {
            throw SolveError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SolveError.badResponse
        }
        if let ok = json["ok"] as? Bool, ok == false {
            throw SolveError.server(json["error"] as? String ?? "unknown")
        }
        let answer = json["answer"] as? String ?? ""
        let ms = json["ms"] as? Int ?? 0
        return Result(answer: answer, ms: ms)
    }
}
