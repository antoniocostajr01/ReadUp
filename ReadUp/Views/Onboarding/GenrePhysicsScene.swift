import SpriteKit

/// Cena SpriteKit com os chips de gênero "caindo" sob gravidade.
/// Cada chip é um `SKSpriteNode` cuja textura é uma view SwiftUI renderizada em imagem
/// (feita no `GenreOnboardingView` com `ImageRenderer`) — por isso têm ícone + texto.
final class GenrePhysicsScene: SKScene {

    /// Um chip já renderizado em texturas (normal e selecionado) + seu tamanho.
    struct ChipRender {
        let id: String          // título do gênero (valor salvo no backend)
        let normal: SKTexture
        let selected: SKTexture
        let size: CGSize
    }

    private let chips: [ChipRender]
    private let gravityY: CGFloat
    private let bounce: CGFloat
    private let startDelay: TimeInterval
    private let onSelectionChange: ([String]) -> Void

    private var selectedIDs: Set<String> = []
    private var didDrop = false

    init(size: CGSize,
         chips: [ChipRender],
         gravityY: CGFloat = -4.0,
         bounce: CGFloat = 0.3,
         startDelay: TimeInterval = 0.1,
         onSelectionChange: @escaping ([String]) -> Void) {
        self.chips = chips
        self.gravityY = gravityY
        self.bounce = bounce
        self.startDelay = startDelay
        self.onSelectionChange = onSelectionChange
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        isPaused = false
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityY)
        setupIfReady()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        setupIfReady()
    }

    /// Só monta a borda e solta os chips quando a cena já tem o tamanho real.
    private func setupIfReady() {
        guard size.width > 1, size.height > 1 else { return }
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size.height + 2000))
        path.addLine(to: CGPoint(x: 0, y: 0))               // Chão
        path.addLine(to: CGPoint(x: size.width, y: 0))      // Chão
        path.addLine(to: CGPoint(x: size.width, y: size.height + 2000)) // Parede alta direita
        
        physicsBody = SKPhysicsBody(edgeChainFrom: path)
        physicsBody?.friction = 0.4
        
        if !didDrop {
            didDrop = true
            onSelectionChange(Array(selectedIDs))
            dropChips()
        }
    }

    private func dropChips() {
        let initialWaitTime: TimeInterval = 1.0
        
        for (index, chip) in chips.enumerated() {
            let totalDelay = initialWaitTime + (startDelay * TimeInterval(index))
            
            let delayAction = SKAction.wait(forDuration: totalDelay)
            let addAction = SKAction.run { [weak self] in
                self?.addChip(chip)
            }
            
            run(SKAction.sequence([delayAction, addAction]))
        }
    }

    private func addChip(_ chip: ChipRender) {
        let isSelected = selectedIDs.contains(chip.id)
        let initialTexture = isSelected ? chip.selected : chip.normal
        
        let node = SKSpriteNode(texture: initialTexture, size: chip.size)
        node.name = chip.id
        
        node.position = CGPoint(
            x: CGFloat.random(in: size.width * 0.1 ... size.width * 0.9), // Espalhamento horizontal
            y: size.height + 400
        )
        node.zRotation = CGFloat.random(in: -0.3 ... 0.3)

        let body = SKPhysicsBody(rectangleOf: chip.size)
        body.restitution = bounce
        body.friction = 0.5
        body.linearDamping = 1.5
        body.allowsRotation = true
        node.physicsBody = body

        addChild(node)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        let node = nodes(at: point).first {
            $0 is SKSpriteNode && $0.name != nil
        } as? SKSpriteNode

        guard let node,
              let id = node.name,
              let chip = chips.first(where: { $0.id == id }) else { return }

        let nowSelected: Bool
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
            nowSelected = false
        } else {
            selectedIDs.insert(id)
            nowSelected = true
        }

        node.texture = nowSelected ? chip.selected : chip.normal
        node.run(.sequence([.scale(to: 1.12, duration: 0.08), .scale(to: 1.0, duration: 0.08)]))
        node.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 7))

        onSelectionChange(Array(selectedIDs))
    }
}
