# 眼镜拍照解题 — iOS App

Ray-Ban Display + iPhone。拍一张题 → 服务器用 Claude 视觉解题 → 答案自动显示到眼镜镜片上
(复用现有 `glasses.html` + `/glasses/ws`),手机上也显示一份。

## 架构

```
[Ray-Ban 摄像头] --DAT蓝牙--> [iPhone App] --HTTPS POST /solve--> [glasses-assist relay]
                                                                      │ Claude 视觉解题
                                                                      ▼
                                   [眼镜 glasses.html] <--/glasses/ws-- 广播答案 (自动上屏)
```

- 服务器端 **已完成并上线**:`/opt/hireme-ai/apps/glasses-assist/server.js` 的 `/solve` 路由
  (`POST https://interviewasssistant.com/glasses-app/solve`,头 `x-push-secret`)。已实测
  `17×23 → 391`,~0.9s。
- App 要做的只有:**拍照 → POST**。答案回显 + 上眼镜都是现成的。

## 两步走(建议)

**第一步:先用 iPhone 摄像头把链路跑通(今天就能做,不碰 DAT)**
默认的 `PhoneCameraSource` 直接用手机摄像头。装上 App、填好 secret,就能拍题验证
「解题 + 答案上眼镜」整条链路对不对。

**第二步:接 DAT,把拍照换成眼镜摄像头**
`CameraSource.swift` 里的 `GlassesCameraSource` 有 3 个 TODO,对照官方 reference 填:
连接眼镜、申请 camera 权限、拍照拿图像数据。填完把 `ContentView` 里的
`PhoneCameraSource()` 换成 `GlassesCameraSource()` 即可。

## Xcode 建项目

1. Xcode → New Project → iOS App → SwiftUI、语言 Swift。
2. 把 `Sources/` 里 4 个 `.swift` 拖进项目(删掉模板自带的 `ContentView.swift` 避免重名)。
3. `Config.swift` 里填 `pushSecret`(= 服务器 `.env` 的 `GLASSES_PUSH_SECRET`)。
4. **Info.plist** 加权限说明:
   - `NSCameraUsageDescription` = “拍摄题目用于解题”(手机摄像头测试需要)
   - DAT 接入后按官方文档再加其所需的 key(连接/蓝牙等)。
5. 真机运行(摄像头在模拟器上没有)。

## 接 DAT(第二步详细)

- SPM 依赖:`https://github.com/facebook/meta-wearables-dat-ios`
- 文档:https://wearables.developer.meta.com/docs/develop/
- API reference:https://wearables.developer.meta.com/docs/reference/ios_swift/dat/latest
- 样例:仓库 `samples/` 目录
- Info.plist 需加 `MWDAT` 配置键(见 README)。
- 设备前置条件(你在 Meta AI App 里做):开发者模式(App Info 连点版本号 5 次)、
  固件/App 版本达标、眼镜已配对。
- **拍照需要明确动作 + 有拍摄指示灯**,不能静默连拍——现实用法是「点一下/手势 → 拍一张」。
- 没有真机也能开发:DAT 带 **Mock Device Kit**。

## 服务器端备忘(已部署,供排查)

- 代码:`/opt/hireme-ai/apps/glasses-assist/server.js`(路由 `/solve`;备份 `server.js.bak_*`)
- 模型:`.env` 的 `GLASSES_VISION_LLM=anthropic:claude-sonnet-5-5`
  (OpenAI key 当前失效;要用 gpt-4o 得先换有效 key 再把这行改回 `openai:gpt-4o`)
- 答案长度:`GLASSES_SOLVE_MAX_TOKENS`(默认 700)
- 重启:`systemctl restart glasses-assist.service`
- 自测:
  ```bash
  SECRET=$(grep ^GLASSES_PUSH_SECRET= /opt/hireme-ai/apps/glasses-assist/.env | cut -d= -f2-)
  B64=$(base64 -w0 某张题目图.jpg)
  curl -s -X POST http://127.0.0.1:5090/solve \
    -H "x-push-secret: $SECRET" -H "Content-Type: application/json" \
    -d "{\"image\":\"$B64\",\"mime\":\"image/jpeg\"}"
  ```
- 眼镜看答案:`glasses.html` 已连 `/glasses/ws`,解题完会自动推送上屏(`{type:'answer'}`)。
