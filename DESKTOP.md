# 桌面端(Mac)要做什么

眼镜拍照解题的**服务器端已经写好并在线上跑**,你在 Mac 上要做的只有 **iOS App**。

## 现状(服务器端,已完成,你不用碰)

- 线上 relay:新加坡机 `interviewasssistant.com`,解题接口
  `POST https://interviewasssistant.com/glasses-app/solve`(头 `x-push-secret`)。
- 解题模型:**Claude Opus 5.5**(默认),实测拍照题 ~2s 出答案。
- 答案自动推送到眼镜 `glasses.html` 上屏(复用现有链路,无需改)。
- 代码位置(仅备查,已在线上):`/opt/hireme-ai/apps/glasses-assist/server.js`,
  systemd `glasses-assist.service`。**这份不在 git 里,改它要直接在服务器上改,别从别处覆盖。**

## 你在 Mac 上做的事

1. 拉这个 repo(`q1q1-spefic/meta-glasses-messenger-bot`),进 `glasses_camera_ios/`。
2. Xcode 新建 SwiftUI iOS App,把 `Sources/` 里 4 个 `.swift` 拖进去(删模板自带的 ContentView)。
3. `Config.swift` 填 `pushSecret`(= 服务器 `.env` 的 `GLASSES_PUSH_SECRET`,找我或在服务器上取)。
4. Info.plist 加 `NSCameraUsageDescription`。真机运行。
5. **先用默认的 `PhoneCameraSource`(iPhone 摄像头)验证整条链路**:拍张题,看答案是否
   同时出现在 App 和眼镜上。通了再接 DAT。
6. 接 DAT:按 `README_iOS.md` 填 `GlassesCameraSource` 的 3 个 TODO,把 `ContentView` 里
   `PhoneCameraSource()` 换成 `GlassesCameraSource()`。

详细步骤见同目录 `README_iOS.md`。
