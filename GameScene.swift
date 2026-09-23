import SpriteKit
import UIKit

private enum V12Area: String {
    case farm = "NÔNG TRẠI"
    case village = "LÀNG"
    case market = "CHỢ"
    case fishing = "BẾN CÂU"
    case forest = "RỪNG"
}

final class FarmV12Scene: SKScene {
    private let worldSize = CGSize(width: 2400, height: 1500)
    private let player = SKSpriteNode(color: .clear, size: CGSize(width: 78, height: 98))
    private var currentArea: V12Area = .farm
    private var target: CGPoint?
    private var joystick = CGVector(dx: 0, dy: 0)
    private var last: TimeInterval = 0
    private var facing = "down"
    private var moving = false
    private let animationKey = "player_anim"
    private var crops = Array(repeating: CGFloat(0), count: 30)
    private var cropNodes: [SKShapeNode] = []
    private var obstacles: [(CGPoint, CGSize)] = []
    private var npcs: [SKShapeNode] = []
    private var pets: [SKShapeNode] = []
    private let fishingPoint = CGPoint(x: 140, y: 40)
    private var biteTimer: TimeInterval = 0
    private var fishBiting = false

    var onStatus: ((String) -> Void)?
    var onHarvest: ((Int) -> Void)?
    var onBite: (() -> Void)?
    var onTalk: ((String) -> Void)?
    var onPet: (() -> Void)?
    var onClock: ((String) -> Void)?

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.48, green: 0.72, blue: 0.35, alpha: 1)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        camera = SKCameraNode()
        if let camera { addChild(camera) }
        buildWorld()
        buildPlayer()
        camera?.position = player.position
        onStatus?("🌱 Farm Việt V12 đã sẵn sàng")
    }

    private func sprite(_ name: String, size: CGSize, at position: CGPoint, z: CGFloat = 20) {
        let node = SKSpriteNode(imageNamed: name)
        node.size = size
        node.position = position
        node.zPosition = z
        addChild(node)
    }

    private func pixelTile(_ name: String, at position: CGPoint, size: CGSize, z: CGFloat = 3) {
        let node = SKSpriteNode(imageNamed: name)
        node.position = position
        node.size = size
        node.zPosition = z
        addChild(node)
    }

    private func buildWorld() {
        let ground = SKShapeNode(rectOf: worldSize)
        ground.fillColor = SKColor(red: 0.50, green: 0.74, blue: 0.38, alpha: 1)
        ground.strokeColor = .clear
        ground.zPosition = -10
        addChild(ground)

        buildRoads()
        buildPond()
        buildPlots()
        buildNPCs()
        buildPets()
        buildTrees()
        buildPixelArtDecorations()
        buildGrid()
        buildAreaPortals()
        buildAreaLabels()
    }

    private func buildRoads() {
        for y: CGFloat in [-470, -20, 430] {
            let road = SKShapeNode(rectOf: CGSize(width: worldSize.width, height: 105))
            road.fillColor = SKColor(red: 0.76, green: 0.64, blue: 0.43, alpha: 1)
            road.strokeColor = .clear
            road.position = CGPoint(x: 0, y: y)
            road.zPosition = -5
            addChild(road)
        }

        for x: CGFloat in [-820, 0, 820] {
            let road = SKShapeNode(rectOf: CGSize(width: 105, height: worldSize.height))
            road.fillColor = SKColor(red: 0.76, green: 0.64, blue: 0.43, alpha: 1)
            road.strokeColor = .clear
            road.position = CGPoint(x: x, y: 0)
            road.zPosition = -5
            addChild(road)
        }
    }

    private func buildPond() {
        let pond = SKShapeNode(ellipseOf: CGSize(width: 820, height: 500))
        pond.fillColor = SKColor(red: 0.18, green: 0.52, blue: 0.78, alpha: 1)
        pond.strokeColor = SKColor(red: 0.08, green: 0.30, blue: 0.55, alpha: 1)
        pond.lineWidth = 14
        pond.position = CGPoint(x: 610, y: 260)
        pond.zPosition = 1
        addChild(pond)
        obstacles.append((pond.position, CGSize(width: 820, height: 500)))

        let spot = SKShapeNode(circleOfRadius: 48)
        spot.fillColor = SKColor(red: 1, green: 0.80, blue: 0.12, alpha: 1)
        spot.strokeColor = .white
        spot.lineWidth = 5
        spot.position = fishingPoint
        spot.zPosition = 10
        addChild(spot)
        spot.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.45),
            .scale(to: 1.0, duration: 0.45)
        ])))

        for i in 0..<8 {
            let ripple = SKShapeNode(ellipseOf: CGSize(width: 95, height: 28))
            ripple.fillColor = .clear
            ripple.strokeColor = .white.withAlphaComponent(0.2)
            ripple.lineWidth = 4
            ripple.position = CGPoint(
                x: 320 + CGFloat(i % 4) * 190,
                y: 150 + CGFloat(i / 4) * 180
            )
            addChild(ripple)
            ripple.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.15, duration: 0.9),
                .fadeAlpha(to: 0.55, duration: 0.9)
            ])))
        }
    }

    private func buildPlots() {
        let xs: [CGFloat] = [-720, -480, -240, 0, 240, 480]
        let ys: [CGFloat] = [-670, -510, -350, -190, -30]
        var index = 0

        for y in ys {
            for x in xs {
                let plot = SKShapeNode(
                    rectOf: CGSize(width: 160, height: 105),
                    cornerRadius: 16
                )
                plot.fillColor = SKColor(red: 0.35, green: 0.23, blue: 0.12, alpha: 1)
                plot.strokeColor = SKColor(red: 0.72, green: 0.52, blue: 0.28, alpha: 1)
                plot.lineWidth = 7
                plot.position = CGPoint(x: x, y: y)
                plot.name = "PLOT_\(index)"
                addChild(plot)
                cropNodes.append(plot)
                index += 1
            }
        }
    }

    private func buildNPCs() {
        let data: [(String, CGPoint)] = [
            ("👩", CGPoint(x: -420, y: 410)),
            ("👨", CGPoint(x: 360, y: -510)),
            ("🧑", CGPoint(x: 980, y: 480))
        ]

        for (emoji, position) in data {
            let npc = SKShapeNode(circleOfRadius: 38)
            npc.fillColor = .white
            npc.position = position
            npc.name = "NPC"
            addChild(npc)

            let label = SKLabelNode(text: emoji)
            label.fontSize = 38
            label.verticalAlignmentMode = .center
            npc.addChild(label)
            npcs.append(npc)
        }
    }

    private func buildPets() {
        for position in [
            CGPoint(x: -250, y: 280),
            CGPoint(x: 160, y: -500)
        ] {
            let pet = SKShapeNode(circleOfRadius: 28)
            pet.fillColor = SKColor(red: 0.95, green: 0.84, blue: 0.55, alpha: 1)
            pet.position = position
            pet.name = "PET"
            addChild(pet)
            pets.append(pet)
        }
    }

    private func buildTrees() {
        let positions = [
            CGPoint(x: -1050, y: 520),
            CGPoint(x: -950, y: 520),
            CGPoint(x: -1080, y: -560),
            CGPoint(x: 1020, y: -560),
            CGPoint(x: 1060, y: 610)
        ]

        for position in positions {
            let tree = SKShapeNode(circleOfRadius: 70)
            tree.fillColor = SKColor(red: 0.18, green: 0.52, blue: 0.18, alpha: 1)
            tree.strokeColor = .clear
            tree.position = position
            addChild(tree)
            obstacles.append((position, CGSize(width: 140, height: 140)))
        }
    }

    private func buildPixelArtDecorations() {
        sprite("Boat.png", size: CGSize(width: 180, height: 110), at: CGPoint(x: 620, y: 255), z: 8)
        sprite("Fishing_hut.png", size: CGSize(width: 220, height: 160), at: CGPoint(x: 820, y: -400), z: 12)
        sprite("Stay.png", size: CGSize(width: 90, height: 90), at: CGPoint(x: -900, y: 120), z: 13)
        sprite("Barrel.png", size: CGSize(width: 65, height: 65), at: CGPoint(x: -930, y: 60), z: 13)
        sprite("Box.png", size: CGSize(width: 75, height: 75), at: CGPoint(x: -850, y: 70), z: 13)

        let grasses = ["Grass1.png", "Grass2.png", "Grass3.png", "Grass4.png"]
        for i in 0..<28 {
            let name = grasses[i % grasses.count]
            let x = CGFloat(-1050 + (i * 173) % 2050)
            let y = CGFloat(-620 + (i * 97) % 1180)
            sprite(name, size: CGSize(width: 58, height: 58), at: CGPoint(x: x, y: y), z: 18)
        }

        pixelTile("Barrel.png", at: CGPoint(x: -910, y: 85), size: CGSize(width: 64, height: 64), z: 25)
        pixelTile("Box.png", at: CGPoint(x: -835, y: 85), size: CGSize(width: 70, height: 70), z: 25)
        pixelTile("Stay.png", at: CGPoint(x: -760, y: 85), size: CGSize(width: 62, height: 62), z: 25)

        for i in 0..<5 {
            pixelTile(
                "Stay.png",
                at: CGPoint(x: 120 + CGFloat(i) * 70, y: 92),
                size: CGSize(width: 62, height: 62),
                z: 20
            )
        }
    }

    private func buildGrid() {
        let tile: CGFloat = 80

        for x in stride(from: -1120 as CGFloat, through: 1120, by: tile) {
            let line = SKShapeNode(rectOf: CGSize(width: 2, height: worldSize.height))
            line.fillColor = SKColor.white.withAlphaComponent(0.025)
            line.strokeColor = .clear
            line.position = CGPoint(x: x, y: 0)
            line.zPosition = 0.5
            addChild(line)
        }

        for y in stride(from: -680 as CGFloat, through: 680, by: tile) {
            let line = SKShapeNode(rectOf: CGSize(width: worldSize.width, height: 2))
            line.fillColor = SKColor.white.withAlphaComponent(0.025)
            line.strokeColor = .clear
            line.position = CGPoint(x: 0, y: y)
            line.zPosition = 0.5
            addChild(line)
        }
    }

    private func buildAreaPortals() {
        let portals: [(V12Area, CGPoint)] = [
            (.farm, CGPoint(x: -980, y: -660)),
            (.village, CGPoint(x: -980, y: 620)),
            (.market, CGPoint(x: 980, y: 620)),
            (.fishing, CGPoint(x: 1040, y: 120)),
            (.forest, CGPoint(x: 980, y: -620))
        ]

        for (area, position) in portals {
            let node = SKShapeNode(circleOfRadius: 42)
            node.fillColor = .white.withAlphaComponent(0.16)
            node.strokeColor = .white.withAlphaComponent(0.8)
            node.lineWidth = 4
            node.position = position
            node.name = "PORTAL_\(area.rawValue)"
            node.zPosition = 30
            addChild(node)
        }
    }

    private func buildAreaLabels() {
        let labels: [(String, CGPoint)] = [
            ("🏡 NÔNG TRẠI", CGPoint(x: -650, y: 620)),
            ("🏘️ LÀNG", CGPoint(x: -650, y: 520)),
            ("🛒 CHỢ", CGPoint(x: 720, y: 620)),
            ("🎣 BẾN CÂU", CGPoint(x: 720, y: 520)),
            ("🌲 RỪNG", CGPoint(x: 720, y: -620))
        ]

        for (text, position) in labels {
            let label = SKLabelNode(text: text)
            label.fontName = "AvenirNext-Bold"
            label.fontSize = 22
            label.fontColor = .white
            label.alpha = 0.86
            label.position = position
            label.zPosition = 60
            addChild(label)
        }
    }

    private func buildPlayer() {
        player.position = CGPoint(x: -80, y: -80)
        player.name = "PLAYER"
        addChild(player)
        playPlayerAnimation(moving: false)
    }

    private func playPlayerAnimation(moving: Bool) {
        let prefix = moving ? "Fisherman_walk" : "Fisherman_idle"
        let names = (0..<4).map { "\(prefix)_\($0)" }
        let images = names.compactMap { UIImage(named: $0) }

        if !images.isEmpty {
            let textures = images.map { SKTexture(image: $0) }
            player.removeAction(forKey: animationKey)
            player.texture = textures[0]
            player.run(
                .repeatForever(.animate(with: textures, timePerFrame: moving ? 0.11 : 0.18)),
                withKey: animationKey
            )
        } else {
            player.texture = SKTexture(imageNamed: "Fisherman_idle.png")
        }
    }

    func setJoystick(_ value: CGVector) {
        joystick = value
        target = nil
    }

    func interact() {
        if let npc = nearest(npcs), npc.position.distance(to: player.position) < 145 {
            onTalk?([
                "👩: Chào bạn!",
                "👨: Ao cá hôm nay nhiều cá!",
                "🧑: Nhớ chăm thú nhé!"
            ].randomElement() ?? "👩: Chào bạn!")
            return
        }

        if let pet = nearest(pets), pet.position.distance(to: player.position) < 125 {
            pet.run(.sequence([
                .scale(to: 1.25, duration: 0.12),
                .scale(to: 1.0, duration: 0.12)
            ]))
            onPet?()
            onStatus?("🐾 Thú cưng rất vui!")
            return
        }

        if let index = nearestCropIndex(), cropNodes[index].position.distance(to: player.position) < 155 {
            if crops[index] <= 0 {
                crops[index] = 0.01
                onStatus?("🌱 Đã gieo hạt ô \(index + 1)")
            } else if crops[index] >= 1 {
                crops[index] = 0
                onHarvest?(index)
                onStatus?("🌾 Thu hoạch thành công!")
            } else {
                onStatus?("⏳ Cây \(Int(crops[index] * 100))%")
            }
            return
        }

        if player.position.distance(to: fishingPoint) < 150 {
            if fishBiting {
                fishBiting = false
                onBite?()
                onStatus?("🐟 Dính cá! Giật cần!")
            } else {
                biteTimer = 1.5
                onStatus?("🎣 Đã thả câu — chờ cá...")
            }
            return
        }

        onStatus?("📍 Hãy đến gần ruộng, NPC, thú hoặc điểm câu")
    }

    private func nearest(_ nodes: [SKShapeNode]) -> SKShapeNode? {
        nodes.min {
            $0.position.distance(to: player.position) < $1.position.distance(to: player.position)
        }
    }

    private func nearestCropIndex() -> Int? {
        cropNodes.indices.min {
            cropNodes[$0].position.distance(to: player.position) < cropNodes[$1].position.distance(to: player.position)
        }
    }

    func setNight(_ enabled: Bool) {
        camera?.childNode(withName: "NIGHT")?.removeFromParent()

        guard enabled else { return }

        let overlay = SKShapeNode(rectOf: CGSize(width: 1550, height: 1050))
        overlay.fillColor = SKColor(red: 0.03, green: 0.05, blue: 0.16, alpha: 0.42)
        overlay.strokeColor = .clear
        overlay.name = "NIGHT"
        overlay.zPosition = 500
        camera?.addChild(overlay)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        if point.distance(to: player.position) < 125 {
            interact()
        } else {
            target = point
        }
    }

    private func canMove(_ point: CGPoint) -> Bool {
        let margin: CGFloat = 45

        if point.x < -worldSize.width / 2 + margin ||
            point.x > worldSize.width / 2 - margin ||
            point.y < -worldSize.height / 2 + margin ||
            point.y > worldSize.height / 2 - margin {
            return false
        }

        for (center, size) in obstacles {
            let rect = CGRect(
                x: center.x - size.width / 2 - 20,
                y: center.y - size.height / 2 - 20,
                width: size.width + 40,
                height: size.height + 40
            )
            if rect.contains(point) {
                return false
            }
        }

        return true
    }

    override func update(_ now: TimeInterval) {
        let delta: CGFloat
        if last == 0 {
            delta = 0.016
        } else {
            delta = CGFloat(min(now - last, 0.05))
        }
        last = now

        if biteTimer > 0 {
            biteTimer -= TimeInterval(delta)
            if biteTimer <= 0 {
                fishBiting = true
                onBite?()
                onStatus?("🐟 CÁ CẮN! Nhấn Tương tác!")
            }
        }

        var velocity = joystick

        if velocity.dx == 0 && velocity.dy == 0, let destination = target {
            let dx = destination.x - player.position.x
            let dy = destination.y - player.position.y
            let length = max(1, sqrt(dx * dx + dy * dy))
            velocity = CGVector(dx: dx / length, dy: dy / length)
            if length < 10 {
                target = nil
            }
        }

        let isMoving = abs(velocity.dx) > 0.01 || abs(velocity.dy) > 0.01

        if isMoving {
            let next = CGPoint(
                x: player.position.x + velocity.dx * 235 * delta,
                y: player.position.y + velocity.dy * 235 * delta
            )
            if canMove(next) {
                player.position = next
            }
        }

        if isMoving != moving {
            moving = isMoving
            playPlayerAnimation(moving: isMoving)
        }

        if abs(velocity.dx) > abs(velocity.dy), abs(velocity.dx) > 0.01 {
            facing = velocity.dx < 0 ? "left" : "right"
        } else if abs(velocity.dy) > 0.05 {
            facing = velocity.dy < 0 ? "down" : "up"
        }
        player.xScale = facing == "left" ? -1 : 1

        camera?.position = player.position

        for index in cropNodes.indices {
            if crops[index] > 0 && crops[index] < 1 {
                crops[index] = min(1, crops[index] + 0.0028 * delta * 60)
            }

            let progress = crops[index]
            cropNodes[index].fillColor = progress >= 1
                ? SKColor(red: 0.88, green: 0.73, blue: 0.16, alpha: 1)
                : progress > 0
                    ? SKColor(red: 0.28, green: 0.52 + 0.18 * progress, blue: 0.16, alpha: 1)
                    : SKColor(red: 0.35, green: 0.23, blue: 0.12, alpha: 1)

            updateCropVisual(index, progress: progress)
        }

        for (index, pet) in pets.enumerated() {
            let desired = CGPoint(
                x: player.position.x + (index == 0 ? -65 : 65),
                y: player.position.y - 55
            )
            let dx = desired.x - pet.position.x
            let dy = desired.y - pet.position.y
            let length = max(1, sqrt(dx * dx + dy * dy))
            if length > 90 {
                pet.position.x += dx / length * delta * 70
                pet.position.y += dy / length * delta * 70
            }
        }

        let hours = 8 + Int(now / 60) % 12
        let minutes = Int(now.truncatingRemainder(dividingBy: 60))
        onClock?(String(format: "%02d:%02d", hours, minutes))

        updateArea()
        updateInteractionMarker()
    }

    private func updateCropVisual(_ index: Int, progress: CGFloat) {
        let name = "CROP_MARKER_\(index)"
        cropNodes[index].childNode(withName: name)?.removeFromParent()
        guard progress > 0 else { return }

        let marker = SKShapeNode(circleOfRadius: progress >= 1 ? 18 : 10 + 8 * progress)
        marker.name = name
        marker.fillColor = progress >= 1
            ? SKColor(red: 0.95, green: 0.78, blue: 0.18, alpha: 1)
            : SKColor(red: 0.20, green: 0.62, blue: 0.18, alpha: 1)
        marker.strokeColor = .clear
        marker.position = CGPoint(x: 0, y: 12)
        marker.zPosition = 2
        cropNodes[index].addChild(marker)
    }

    private func updateArea() {
        let portalData: [(V12Area, CGPoint)] = [
            (.farm, CGPoint(x: -980, y: -660)),
            (.village, CGPoint(x: -980, y: 620)),
            (.market, CGPoint(x: 980, y: 620)),
            (.fishing, CGPoint(x: 1040, y: 120)),
            (.forest, CGPoint(x: 980, y: -620))
        ]

        for (area, position) in portalData {
            if player.position.distance(to: position) < 90, currentArea != area {
                currentArea = area
                onStatus?("📍 Đã đến \(area.rawValue)")
            }
        }
    }

    private func updateInteractionMarker() {
        childNode(withName: "INTERACT_MARKER")?.removeFromParent()

        var point: CGPoint?
        if let npc = nearest(npcs), npc.position.distance(to: player.position) < 150 {
            point = npc.position
        } else if let pet = nearest(pets), pet.position.distance(to: player.position) < 130 {
            point = pet.position
        } else if player.position.distance(to: fishingPoint) < 155 {
            point = fishingPoint
        }

        guard let point else { return }

        let marker = SKLabelNode(text: "!")
        marker.name = "INTERACT_MARKER"
        marker.fontSize = 34
        marker.fontColor = .yellow
        marker.position = CGPoint(x: point.x, y: point.y + 55)
        marker.zPosition = 520
        addChild(marker)
        marker.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 8, duration: 0.35),
            .moveBy(x: 0, y: -8, duration: 0.35)
        ])))
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}
