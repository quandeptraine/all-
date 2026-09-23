import SwiftUI
import SpriteKit

struct FarmV12View: View {
    @State private var coins = 1200
    @State private var level = 1
    @State private var wheat = 0
    @State private var fish = 0
    @State private var pets = 0
    @State private var stamina = 100
    @State private var status = "🌱 Sẵn sàng"
    @State private var clock = "08:00"
    @State private var night = false
    @State private var bag = false
    @State private var shop = false
    @State private var fishing = false
    @State private var phase = 0
    @State private var reel = 0
    @State private var sceneRef: FarmV12Scene?
    @State private var quest = "Trồng 1 cây"

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.allowsTransparency])
                .ignoresSafeArea()

            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    pill("💰\(coins)")
                    pill("⭐\(level)")
                    pill("🌾\(wheat)")
                    pill("🐟\(fish)")
                    pill("🐾\(pets)")
                    pill("⚡\(stamina)")
                    pill("🕐\(clock)")
                    Spacer()
                    Button(night ? "☀️" : "🌙") {
                        night.toggle()
                        sceneRef?.setNight(night)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()

                Text(status)
                    .font(.headline)
                    .padding(9)
                    .background(.ultraThinMaterial, in: Capsule())

                Text("📜 \(quest)")
                    .font(.caption.bold())
                    .padding(7)
                    .background(.ultraThinMaterial, in: Capsule())

                HStack(spacing: 6) {
                    Button("🎒 Túi") { bag = true }
                    Button("🛒 Shop") { shop = true }
                    Button("🎣 Câu") {
                        fishing = true
                        phase = 1
                    }
                    Button("💾 Lưu") { saveGame() }
                    Button("🖐 Tương tác") {
                        guard stamina >= 2 else {
                            status = "⚡ Hết năng lượng"
                            return
                        }
                        stamina -= 2
                        sceneRef?.interact()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(10)

            V12Joystick(scene: sceneRef)

            if bag {
                Panel(title: "🎒 Kho đồ") {
                    Text("🌾 Lúa: \(wheat)")
                    Text("🐟 Cá: \(fish)")
                    Text("🐾 Chăm thú: \(pets)")
                    Text("💰 Tiền: \(coins)")
                    Button("Đóng") { bag = false }
                }
            }

            if shop {
                Panel(title: "🛒 Shop") {
                    Button("🌽 Hạt giống 50💰") {
                        if coins >= 50 { coins -= 50 }
                    }
                    Button("⚡ +25 năng lượng 100💰") {
                        if coins >= 100 {
                            coins -= 100
                            stamina = min(100, stamina + 25)
                        }
                    }
                    Button("🎣 Mồi câu 75💰") {
                        if coins >= 75 { coins -= 75 }
                    }
                    Button("Đóng") { shop = false }
                }
            }

            if fishing {
                Panel(title: "🎣 Câu cá") {
                    if phase == 1 {
                        Text("Đang chờ cá cắn...")
                        ProgressView()
                    } else if phase == 2 {
                        Text("🐟 CÁ CẮN!")
                        Button("GIẬT CẦN!") {
                            phase = 3
                            reel = 0
                        }
                    } else if phase == 3 {
                        Text("Kéo cá \(reel)%")
                        ProgressView(value: Double(reel), total: 100)
                        Button("KÉO CÁ") {
                            reel = min(100, reel + Int.random(in: 9...22))
                            if reel >= 100 {
                                phase = 4
                                fish += 1
                                coins += 60
                                status = "🎉 Bắt được cá! +60💰"
                            }
                        }
                    } else {
                        Text("🎉 Bắt được cá!")
                        Button("Đóng") { fishing = false }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var scene: FarmV12Scene {
        let s = FarmV12Scene(size: CGSize(width: 1100, height: 760))
        s.scaleMode = .aspectFill
        s.onStatus = { value in status = value }
        s.onClock = { value in clock = value }
        s.onHarvest = { _ in
            wheat += 1
            coins += 35
            stamina = max(0, stamina - 4)
            level = 1 + wheat / 8
            quest = "Thu hoạch thêm 1 ô"
        }
        s.onBite = {
            fishing = true
            phase = 2
        }
        s.onTalk = { value in status = value }
        s.onPet = {
            pets += 1
            coins += 10
            quest = "Tìm điểm câu cá"
        }
        DispatchQueue.main.async {
            sceneRef = s
        }
        return s
    }

    private func saveGame() {
        UserDefaults.standard.set(coins, forKey: "farm.coins")
        UserDefaults.standard.set(wheat, forKey: "farm.wheat")
        UserDefaults.standard.set(fish, forKey: "farm.fish")
        UserDefaults.standard.set(pets, forKey: "farm.pets")
        UserDefaults.standard.set(level, forKey: "farm.level")
        status = "💾 Đã lưu!"
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(7)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct V12Joystick: View {
    let scene: FarmV12Scene?
    @State private var drag = CGSize.zero

    var body: some View {
        GeometryReader { _ in
            VStack {
                Spacer()
                HStack {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.30))
                            .frame(width: 110, height: 110)
                        Circle()
                            .fill(.white.opacity(0.35))
                            .frame(width: 52, height: 52)
                            .offset(drag)
                    }
                    .frame(width: 120, height: 120)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let dx = max(-42, min(42, value.translation.width))
                                let dy = max(-42, min(42, value.translation.height))
                                drag = CGSize(width: dx, height: dy)
                                let length = max(1, sqrt(dx * dx + dy * dy))
                                scene?.setJoystick(CGVector(dx: dx / length, dy: -dy / length))
                            }
                            .onEnded { _ in
                                drag = .zero
                                scene?.setJoystick(CGVector(dx: 0, dy: 0))
                            }
                    )
                    Spacer()
                }
            }
            .padding(24)
        }
        .allowsHitTesting(true)
    }
}

private struct Panel<Content: View>: View {
    let title: String
    let content: () -> Content

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.largeTitle.bold())
            content()
        }
        .padding(24)
        .frame(maxWidth: 430)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .shadow(radius: 25)
    }
}
