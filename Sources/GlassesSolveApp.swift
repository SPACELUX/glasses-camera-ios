import SwiftUI

@main
struct GlassesSolveApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    // 先用手机摄像头验证整条链路; DAT 调通后换成 GlassesCameraSource()。
    @StateObject private var vm = SolveVM(source: PhoneCameraSource())

    var body: some View {
        VStack(spacing: 20) {
            Text("眼镜拍照解题").font(.title2).bold()
            Text(vm.sourceName).font(.caption).foregroundColor(.secondary)

            ScrollView {
                Text(vm.answer.isEmpty ? "按下方按钮拍题" : vm.answer)
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: 320)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            if let status = vm.status {
                Text(status).font(.footnote)
                    .foregroundColor(vm.isError ? .red : .secondary)
            }

            Button(action: { Task { await vm.captureAndSolve() } }) {
                Label(vm.busy ? "解题中…" : "拍照解题", systemImage: "camera.viewfinder")
                    .font(.title3).frame(maxWidth: .infinity).padding()
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.busy)
        }
        .padding()
        .task { await vm.prepare() }
    }
}

@MainActor
final class SolveVM: ObservableObject {
    @Published var answer = ""
    @Published var status: String?
    @Published var busy = false
    @Published var isError = false

    private let source: CameraSource
    var sourceName: String { source.displayName }

    init(source: CameraSource) { self.source = source }

    func prepare() async {
        if let phone = source as? PhoneCameraSource {
            do { try phone.start() } catch { show(error.localizedDescription, err: true) }
        }
        // DAT: if let g = source as? GlassesCameraSource { try? await g.connect() }
    }

    func captureAndSolve() async {
        busy = true; isError = false; status = "📷 拍照中…"
        defer { busy = false }
        do {
            let img = try await source.capture()
            status = "🧠 上传解题中…(答案会同时显示到眼镜)"
            let r = try await SolveClient.solve(image: img)
            if r.answer.isEmpty || r.answer == "[NO_QUESTION]" {
                show("没看到题目", err: true)
            } else {
                answer = r.answer
                status = "✅ \(r.ms) ms"
            }
        } catch {
            show(error.localizedDescription, err: true)
        }
    }

    private func show(_ s: String, err: Bool) { status = s; isError = err }
}
