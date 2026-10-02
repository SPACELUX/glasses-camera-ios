import UIKit

/// 抽象「拍一张照片」这件事。两种实现:
///  - PhoneCameraSource : 用 iPhone 自身摄像头。今天就能跑通整条链路 (解题+上眼镜),无需 DAT。
///  - GlassesCameraSource: 用 Meta DAT 从 Ray-Ban 眼镜摄像头拍。接入点已标注,对照官方 reference 填。
protocol CameraSource {
    var displayName: String { get }
    /// 触发一次拍照,回调拿到 UIImage。
    func capture() async throws -> UIImage
}

// MARK: - 手机摄像头实现 (立即可用, 用于验证服务器链路)
import AVFoundation

final class PhoneCameraSource: NSObject, CameraSource, AVCapturePhotoCaptureDelegate {
    let displayName = "iPhone 摄像头 (测试用)"
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var cont: CheckedContinuation<UIImage, Error>?

    func start() throws {
        session.beginConfiguration()
        guard let dev = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: dev),
              session.canAddInput(input), session.canAddOutput(output) else {
            throw NSError(domain: "cam", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法打开摄像头"])
        }
        session.addInput(input); session.addOutput(output)
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    func capture() async throws -> UIImage {
        try await withCheckedThrowingContinuation { c in
            self.cont = c
            output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    func photoOutput(_ o: AVCapturePhotoOutput, didFinishProcessingPhoto p: AVCapturePhoto, error: Error?) {
        if let error { cont?.resume(throwing: error); cont = nil; return }
        if let d = p.fileDataRepresentation(), let img = UIImage(data: d) {
            cont?.resume(returning: img)
        } else {
            cont?.resume(throwing: NSError(domain: "cam", code: 2))
        }
        cont = nil
    }
}

// MARK: - 眼镜摄像头实现 (Meta Wearables Device Access Toolkit)
//
// DAT 的精确类名/方法签名在官方 reference, 随 preview 版本会变, 这里把接入点框好:
//   SPM:   https://github.com/facebook/meta-wearables-dat-ios
//   文档:  https://wearables.developer.meta.com/docs/develop/
//   参考:  https://wearables.developer.meta.com/docs/reference/ios_swift/dat/latest
//   样例:  仓库 samples/ 目录
//
// 步骤 (对照 reference 把下面 3 个 TODO 填上):
//   1. 初始化 SDK + 连接眼镜 (配对/会话)。
//   2. 申请并确认 camera 权限 (DAT 侧 + iOS 侧)。
//   3. 发起一次「拍照 (camera capture, 实验特性)」, 拿到 Data/图像字节 → UIImage。
//
// 注意: Meta 强制拍摄指示灯, 且拍照通常需要明确用户动作 (App 内按钮 / 眼镜手势), 不能静默连拍。
import MetaWearablesDAT   // ← 名称以实际 SPM 产物为准 (import 失败就看 Package 里的 module 名)

final class GlassesCameraSource: CameraSource {
    let displayName = "Ray-Ban Display 摄像头"

    // TODO(1): 持有 DAT 的 session/device 句柄
    // private var device: WearableDevice?

    /// 连接 + 授权。App 启动或用户点「连接眼镜」时调一次。
    func connect() async throws {
        // TODO(1): 初始化 SDK, 扫描/连接已配对眼镜。
        // TODO(2): 请求 camera 权限, 等待用户在 Meta AI App 侧确认。
        // 例 (伪代码, 以 reference 为准):
        //   let sdk = MetaWearables.shared
        //   try await sdk.connect()
        //   try await sdk.requestAccess([.camera])
        //   self.device = sdk.connectedDevice
        throw NSError(domain: "dat", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "GlassesCameraSource.connect 未接入 DAT — 先用 PhoneCameraSource 验证链路"])
    }

    func capture() async throws -> UIImage {
        // TODO(3): 调 DAT 的拍照接口, 拿到图像数据。
        // 例 (伪代码):
        //   let photo = try await device!.camera.capturePhoto()
        //   guard let img = UIImage(data: photo.jpegData) else { throw ... }
        //   return img
        throw NSError(domain: "dat", code: -2,
            userInfo: [NSLocalizedDescriptionKey: "GlassesCameraSource.capture 未接入 DAT"])
    }
}
