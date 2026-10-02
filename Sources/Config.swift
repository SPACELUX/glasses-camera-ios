import Foundation

// 单人自用配置。生产可改为从 Keychain / 设置页读取, 别硬编码进公开仓库。
enum Config {
    /// 服务器解题端点 (relay 的 /solve, 走 nginx /glasses-app/ 前缀)。
    static let solveURL = URL(string: "https://interviewasssistant.com/glasses-app/solve")!

    /// 与服务器 .env 的 GLASSES_PUSH_SECRET 必须一致 (relay 用它鉴权 /solve 和 /push)。
    /// ⚠️ 填成你服务器上的真实值。
    static let pushSecret = "<<< 填 GLASSES_PUSH_SECRET >>>"

    /// 发给模型的额外指令 (可空)。例: "Answer in Chinese." 或留空用默认。
    static let extraInstruction = ""

    /// JPEG 压缩质量 (0~1)。0.6 够清晰且上传快 (12MP 原图太大)。
    static let jpegQuality: CGFloat = 0.6
}
