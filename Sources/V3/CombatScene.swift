import Foundation
import SpriteKit
import UIKit

@MainActor
final class CombatScene: SKScene {

    // MARK: - Game systems

    let gameState: GameState
    let hunterController: HunterController
    let enemyController: EnemyController
    let encounterDirector: EncounterDirector

    private let audioManager: AudioManager

    // MARK: - Scene layers

    private let worldNode = SKNode()

    private let backgroundLayer = SKNode()
    private let farForestLayer = SKNode()
    private let midForestLayer = SKNode()
    private let groundLayer = SKNode()

    private let actorsLayer = SKNode()
    private let effectsLayer = SKNode()
    private let foregroundLayer = SKNode()

    // MARK: - Characters

    private let hunterNode = SKNode()
    private let enemyNode = SKNode()

    private let hunterEyesNode = SKNode()
    private let enemyAuraNode = SKNode()

    private var hunterSwordNode: SKShapeNode?

    // MARK: - Runtime

    private var sceneBuilt = false
    private var lastUpdateTime: TimeInterval = 0

    private var currentEnemyID: EnemyID?

    // MARK: - Init

    init(
        size: CGSize,
        gameState: GameState,
        hunterController: HunterController,
        enemyController: EnemyController,
        encounterDirector: EncounterDirector,
        audioManager: AudioManager = .shared
    ) {
        self.gameState = gameState
        self.hunterController = hunterController
        self.enemyController = enemyController
        self.encounterDirector = encounterDirector
        self.audioManager = audioManager

        super.init(
            size: size
        )

        scaleMode = .resizeFill
        backgroundColor = UIColor(
            red: 0.035,
            green: 0.043,
            blue: 0.055,
            alpha: 1
        )

        bindCallbacks()
    }

    required init?(
        coder aDecoder: NSCoder
    ) {
        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    // MARK: - Scene lifecycle

    override func didMove(
        to view: SKView
    ) {
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true

        if !sceneBuilt {
            buildScene()
            sceneBuilt = true
        }

        layoutScene()

        audioManager.applySettings(
            from: gameState.snapshot
        )
    }

    override func didChangeSize(
        _ oldSize: CGSize
    ) {
        super.didChangeSize(
            oldSize
        )

        guard sceneBuilt else {
            return
        }

        layoutScene()
    }

    // MARK: - Public start

    func startNewGame() {
        lastUpdateTime = 0

        audioManager.applySettings(
            from: gameState.snapshot
        )

        encounterDirector.startNewGame()
    }

    func continueGame() {
        lastUpdateTime = 0

        audioManager.applySettings(
            from: gameState.snapshot
        )

        encounterDirector.continueGame()
    }

    // MARK: - Pause

    func pauseFromUI() {
        guard !isPaused else {
            return
        }

        encounterDirector.pauseGame()
        audioManager.playPause()

        isPaused = true
    }

    func resumeFromUI() {
        guard isPaused else {
            return
        }

        isPaused = false

        encounterDirector.resumeGame()
        audioManager.playResume()

        lastUpdateTime = 0
    }

    // MARK: - Update

    override func update(
        _ currentTime: TimeInterval
    ) {
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        var delta =
            currentTime - lastUpdateTime

        lastUpdateTime = currentTime

        delta = min(
            max(
                delta,
                0
            ),
            0.05
        )

        encounterDirector.update(
            deltaTime: delta
        )

        syncRuntimeVisuals()
    }

    // MARK: - Touch

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard !isPaused else {
            return
        }

        guard encounterDirector
            .canReceiveAttackInput else {
            return
        }

        _ = encounterDirector
            .handleAttackInput()
    }

    // MARK: - Bind systems

    private func bindCallbacks() {

        // Preserve EncounterDirector's important
        // sword-contact callback and add visuals.

        let previousSwordContact =
            hunterController.onSwordContact

        hunterController.onSwordContact = {
            [weak self] resolution in

            previousSwordContact?(
                resolution
            )

            self?.handleSwordContact(
                resolution
            )
        }

        let previousAttackStarted =
            hunterController.onAttackStarted

        hunterController.onAttackStarted = {
            [weak self] resolution in

            previousAttackStarted?(
                resolution
            )

            self?.handleAttackStarted(
                resolution
            )
        }

        let previousAttackFinished =
            hunterController.onAttackFinished

        hunterController.onAttackFinished = {
            [weak self] resolution in

            previousAttackFinished?(
                resolution
            )

            self?.handleAttackFinished(
                resolution
            )
        }

        let previousSpawnStarted =
            enemyController.onSpawnStarted

        enemyController.onSpawnStarted = {
            [weak self] enemy in

            previousSpawnStarted?(
                enemy
            )

            self?.handleEnemySpawnStarted(
                enemy
            )
        }

        let previousHurt =
            enemyController.onHurt

        enemyController.onHurt = {
            [weak self] enemy,
            attackKind in

            previousHurt?(
                enemy,
                attackKind
            )

            self?.handleEnemyHurt(
                enemy,
                attackKind: attackKind
            )
        }

        let previousDeathStarted =
            enemyController.onDeathStarted

        enemyController.onDeathStarted = {
            [weak self] enemy in

            previousDeathStarted?(
                enemy
            )

            self?.handleEnemyDeathStarted(
                enemy
            )
        }

        let previousBossPhase =
            enemyController.onBossPhaseChanged

        enemyController.onBossPhaseChanged = {
            [weak self] oldPhase,
            newPhase in

            previousBossPhase?(
                oldPhase,
                newPhase
            )

            self?.handleBossPhaseChanged(
                newPhase
            )
        }

        let previousEncounterStarted =
            encounterDirector.onEncounterStarted

        encounterDirector.onEncounterStarted = {
            [weak self] enemy in

            previousEncounterStarted?(
                enemy
            )

            self?.handleEncounterStarted(
                enemy
            )
        }

        let previousEncounterActivated =
            encounterDirector.onEncounterActivated

        encounterDirector.onEncounterActivated = {
            [weak self] enemy in

            previousEncounterActivated?(
                enemy
            )

            self?.handleEncounterActivated(
                enemy
            )
        }

        let previousReward =
            encounterDirector.onRewardGranted

        encounterDirector.onRewardGranted = {
            [weak self] enemy,
            reward in

            previousReward?(
                enemy,
                reward
            )

            self?.handleReward(
                enemy: enemy,
                reward: reward
            )
        }

        let previousBossIntro =
            encounterDirector.onBossIntroStarted

        encounterDirector.onBossIntroStarted = {
            [weak self] in

            previousBossIntro?()

            self?.handleBossIntro()
        }

        let previousCycle =
            encounterDirector.onCycleTransitionStarted

        encounterDirector.onCycleTransitionStarted = {
            [weak self] cycle in

            previousCycle?(
                cycle
            )

            self?.handleCycleTransition(
                cycle: cycle
            )
        }
    }

    // MARK: - Build scene

    private func buildScene() {
        removeAllChildren()

        addChild(
            worldNode
        )

        worldNode.addChild(
            backgroundLayer
        )

        worldNode.addChild(
            farForestLayer
        )

        worldNode.addChild(
            midForestLayer
        )

        worldNode.addChild(
            groundLayer
        )

        worldNode.addChild(
            actorsLayer
        )

        worldNode.addChild(
            effectsLayer
        )

        worldNode.addChild(
            foregroundLayer
        )

        backgroundLayer.zPosition = -100
        farForestLayer.zPosition = -80
        midForestLayer.zPosition = -60
        groundLayer.zPosition = -30

        actorsLayer.zPosition = 10
        effectsLayer.zPosition = 40
        foregroundLayer.zPosition = 70

        buildForest()
        buildHunter()

        actorsLayer.addChild(
            hunterNode
        )

        actorsLayer.addChild(
            enemyNode
        )

        enemyNode.isHidden = true
    }

    // MARK: - Forest

    private func buildForest() {
        backgroundLayer.removeAllChildren()
        farForestLayer.removeAllChildren()
        midForestLayer.removeAllChildren()
        groundLayer.removeAllChildren()
        foregroundLayer.removeAllChildren()

        let background =
            SKShapeNode(
                rect: CGRect(
                    origin: .zero,
                    size: size
                )
            )

        background.fillColor =
            UIColor(
                red: 0.035,
                green: 0.043,
                blue: 0.055,
                alpha: 1
            )

        background.strokeColor = .clear

        backgroundLayer.addChild(
            background
        )

        buildMoon()
        buildTrees()
        buildGround()
        buildFog()
        buildLeaves()
    }

    private func buildMoon() {
        let moon =
            SKShapeNode(
                circleOfRadius:
                    max(
                        34,
                        size.width * 0.105
                    )
            )

        moon.fillColor =
            UIColor(
                red: 0.46,
                green: 0.60,
                blue: 0.72,
                alpha: 0.22
            )

        moon.strokeColor =
            UIColor(
                red: 0.65,
                green: 0.74,
                blue: 0.82,
                alpha: 0.12
            )

        moon.lineWidth = 2
        moon.isAntialiased = false

        moon.position =
            CGPoint(
                x: size.width * 0.69,
                y: size.height * 0.77
            )

        farForestLayer.addChild(
            moon
        )

        let glow =
            SKShapeNode(
                circleOfRadius:
                    max(
                        50,
                        size.width * 0.16
                    )
            )

        glow.fillColor =
            UIColor(
                red: 0.46,
                green: 0.60,
                blue: 0.72,
                alpha: 0.035
            )

        glow.strokeColor = .clear

        moon.addChild(
            glow
        )
    }

    private func buildTrees() {
        let farColor =
            UIColor(
                red: 0.086,
                green: 0.11,
                blue: 0.145,
                alpha: 1
            )

        let nearColor =
            UIColor(
                red: 0.055,
                green: 0.065,
                blue: 0.082,
                alpha: 1
            )

        let farCount = 11

        for index in 0..<farCount {
            let x =
                CGFloat(index)
                / CGFloat(farCount - 1)
                * size.width

            let trunk =
                makeTree(
                    height:
                        size.height
                        * CGFloat.random(
                            in: 0.43...0.72
                        ),
                    width:
                        CGFloat.random(
                            in: 12...24
                        ),
                    color: farColor
                )

            trunk.position =
                CGPoint(
                    x:
                        x
                        + CGFloat.random(
                            in: -12...12
                        ),
                    y:
                        size.height * 0.19
                )

            farForestLayer.addChild(
                trunk
            )
        }

        let nearPositions: [CGFloat] = [
            0.02,
            0.18,
            0.86,
            0.98
        ]

        for factor in nearPositions {
            let trunk =
                makeTree(
                    height:
                        size.height
                        * CGFloat.random(
                            in: 0.58...0.82
                        ),
                    width:
                        CGFloat.random(
                            in: 20...34
                        ),
                    color: nearColor
                )

            trunk.position =
                CGPoint(
                    x: size.width * factor,
                    y: size.height * 0.16
                )

            midForestLayer.addChild(
                trunk
            )
        }
    }

    private func makeTree(
        height: CGFloat,
        width: CGFloat,
        color: UIColor
    ) -> SKNode {
        let container = SKNode()

        let trunk =
            SKShapeNode(
                rectOf:
                    CGSize(
                        width: width,
                        height: height
                    ),
                cornerRadius: 2
            )

        trunk.fillColor = color
        trunk.strokeColor = color
        trunk.isAntialiased = false

        trunk.position.y =
            height * 0.5

        container.addChild(
            trunk
        )

        for branchIndex in 0..<4 {
            let branch =
                SKShapeNode()

            let path =
                CGMutablePath()

            let branchY =
                height
                * (
                    0.46
                    + CGFloat(branchIndex)
                    * 0.11
                )

            let direction: CGFloat =
                branchIndex % 2 == 0
                ? -1
                : 1

            path.move(
                to:
                    CGPoint(
                        x: 0,
                        y: branchY
                    )
            )

            path.addLine(
                to:
                    CGPoint(
                        x:
                            direction
                            * CGFloat.random(
                                in: 28...54
                            ),
                        y:
                            branchY
                            + CGFloat.random(
                                in: 20...46
                            )
                    )
            )

            branch.path = path
            branch.strokeColor = color
            branch.lineWidth =
                CGFloat.random(
                    in: 5...9
                )

            branch.lineCap = .square
            branch.isAntialiased = false

            container.addChild(
                branch
            )
        }

        return container
    }

    private func buildGround() {
        let ground =
            SKShapeNode(
                rect:
                    CGRect(
                        x: 0,
                        y: 0,
                        width: size.width,
                        height: size.height * 0.28
                    )
            )

        ground.fillColor =
            UIColor(
                red: 0.13,
                green: 0.11,
                blue: 0.10,
                alpha: 1
            )

        ground.strokeColor = .clear

        groundLayer.addChild(
            ground
        )

        for _ in 0..<14 {
            let stone =
                SKShapeNode(
                    ellipseOf:
                        CGSize(
                            width:
                                CGFloat.random(
                                    in: 8...22
                                ),
                            height:
                                CGFloat.random(
                                    in: 3...8
                                )
                        )
                )

            stone.fillColor =
                UIColor(
                    red: 0.27,
                    green: 0.29,
                    blue: 0.31,
                    alpha: 0.24
                )

            stone.strokeColor = .clear
            stone.isAntialiased = false

            stone.position =
                CGPoint(
                    x:
                        CGFloat.random(
                            in: 10...(size.width - 10)
                        ),
                    y:
                        CGFloat.random(
                            in:
                                size.height * 0.08
                                ...
                                size.height * 0.22
                        )
                )

            groundLayer.addChild(
                stone
            )
        }

        buildGravestones()
    }

    private func buildGravestones() {
        let positions: [
            (
                CGFloat,
                CGFloat
            )
        ] = [
            (0.08, 0.21),
            (0.91, 0.20),
            (0.14, 0.16),
            (0.82, 0.15)
        ]

        for (
            xFactor,
            yFactor
        ) in positions {

            let grave =
                SKShapeNode(
                    rectOf:
                        CGSize(
                            width: 18,
                            height: 28
                        ),
                    cornerRadius: 5
                )

            grave.fillColor =
                UIColor(
                    red: 0.27,
                    green: 0.29,
                    blue: 0.31,
                    alpha: 0.55
                )

            grave.strokeColor =
                UIColor(
                    red: 0.10,
                    green: 0.11,
                    blue: 0.12,
                    alpha: 1
                )

            grave.lineWidth = 2
            grave.isAntialiased = false

            grave.position =
                CGPoint(
                    x: size.width * xFactor,
                    y: size.height * yFactor
                )

            grave.zRotation =
                CGFloat.random(
                    in: -0.10...0.10
                )

            groundLayer.addChild(
                grave
            )
        }
    }

    private func buildFog() {
        for index in 0..<5 {
            let fog =
                SKShapeNode(
                    ellipseOf:
                        CGSize(
                            width:
                                size.width
                                * CGFloat.random(
                                    in: 0.55...0.95
                                ),
                            height:
                                CGFloat.random(
                                    in: 28...55
                                )
                        )
                )

            fog.fillColor =
                UIColor(
                    red: 0.29,
                    green: 0.35,
                    blue: 0.40,
                    alpha:
                        CGFloat.random(
                            in: 0.035...0.075
                        )
                )

            fog.strokeColor = .clear
            fog.isAntialiased = false

            fog.position =
                CGPoint(
                    x:
                        size.width
                        * CGFloat.random(
                            in: 0.2...0.8
                        ),
                    y:
                        size.height
                        * CGFloat.random(
                            in: 0.17...0.31
                        )
                )

            fog.zPosition =
                CGFloat(index)

            let moveRight =
                SKAction.moveBy(
                    x: 30,
                    y: 0,
                    duration:
                        TimeInterval.random(
                            in: 4.0...7.0
                        )
                )

            let moveLeft =
                moveRight.reversed()

            fog.run(
                .repeatForever(
                    .sequence(
                        [
                            moveRight,
                            moveLeft
                        ]
                    )
                )
            )

            foregroundLayer.addChild(
                fog
            )
        }
    }

    private func buildLeaves() {
        for _ in 0..<12 {
            let leaf =
                SKShapeNode(
                    rectOf:
                        CGSize(
                            width: 3,
                            height: 2
                        )
                )

            leaf.fillColor =
                UIColor(
                    red: 0.28,
                    green: 0.22,
                    blue: 0.18,
                    alpha: 0.6
                )

            leaf.strokeColor = .clear
            leaf.isAntialiased = false

            resetLeaf(
                leaf
            )

            foregroundLayer.addChild(
                leaf
            )

            animateLeaf(
                leaf
            )
        }
    }

    private func resetLeaf(
        _ leaf: SKNode
    ) {
        leaf.position =
            CGPoint(
                x:
                    CGFloat.random(
                        in: 0...size.width
                    ),
                y:
                    CGFloat.random(
                        in:
                            size.height * 0.35
                            ...
                            size.height * 0.95
                    )
            )

        leaf.alpha =
            CGFloat.random(
                in: 0.20...0.70
            )

        leaf.zRotation =
            CGFloat.random(
                in: 0...(CGFloat.pi * 2)
            )
    }

    private func animateLeaf(
        _ leaf: SKNode
    ) {
        let duration =
            TimeInterval.random(
                in: 4.0...7.0
            )

        let move =
            SKAction.moveBy(
                x:
                    CGFloat.random(
                        in: -80...80
                    ),
                y:
                    -size.height * 0.65,
                duration: duration
            )

        let rotate =
            SKAction.rotate(
                byAngle:
                    CGFloat.random(
                        in: -4...4
                    ),
                duration: duration
            )

        let group =
            SKAction.group(
                [
                    move,
                    rotate
                ]
            )

        leaf.run(
            .sequence(
                [
                    group,
                    .run {
                        [weak self, weak leaf] in

                        guard let self,
                              let leaf else {
                            return
                        }

                        self.resetLeaf(
                            leaf
                        )

                        self.animateLeaf(
                            leaf
                        )
                    }
                ]
            )
        )
    }

    // MARK: - Hunter

    private func buildHunter() {
        hunterNode.removeAllChildren()

        if let texture =
            textureIfAvailable(
                named: "hunter_idle_0"
            ) {

            let sprite =
                SKSpriteNode(
                    texture: texture
                )

            sprite.texture?.filteringMode =
                .nearest

            sprite.size =
                CGSize(
                    width: 128,
                    height: 128
                )

            hunterNode.addChild(
                sprite
            )

            return
        }

        buildHunterPlaceholder()
    }

    private func buildHunterPlaceholder() {
        let cloakPath =
            CGMutablePath()

        cloakPath.move(
            to:
                CGPoint(
                    x: -20,
                    y: -48
                )
        )

        cloakPath.addLine(
            to:
                CGPoint(
                    x: -14,
                    y: 22
                )
        )

        cloakPath.addLine(
            to:
                CGPoint(
                    x: 0,
                    y: 38
                )
        )

        cloakPath.addLine(
            to:
                CGPoint(
                    x: 15,
                    y: 20
                )
        )

        cloakPath.addLine(
            to:
                CGPoint(
                    x: 23,
                    y: -48
                )
        )

        cloakPath.closeSubpath()

        let cloak =
            SKShapeNode(
                path: cloakPath
            )

        cloak.fillColor =
            UIColor(
                red: 0.035,
                green: 0.04,
                blue: 0.045,
                alpha: 1
            )

        cloak.strokeColor =
            UIColor(
                red: 0.20,
                green: 0.22,
                blue: 0.24,
                alpha: 1
            )

        cloak.lineWidth = 2
        cloak.isAntialiased = false

        hunterNode.addChild(
            cloak
        )

        let hood =
            SKShapeNode(
                circleOfRadius: 15
            )

        hood.fillColor =
            UIColor(
                red: 0.015,
                green: 0.018,
                blue: 0.020,
                alpha: 1
            )

        hood.strokeColor =
            UIColor(
                red: 0.23,
                green: 0.25,
                blue: 0.27,
                alpha: 1
            )

        hood.lineWidth = 2
        hood.position.y = 29
        hood.isAntialiased = false

        hunterNode.addChild(
            hood
        )

        hunterEyesNode.removeAllChildren()
        hunterEyesNode.position =
            CGPoint(
                x: 2,
                y: 31
            )

        let leftEye =
            makeEye(
                color:
                    UIColor(
                        red: 0.33,
                        green: 0.91,
                        blue: 0.47,
                        alpha: 1
                    )
            )

        leftEye.position.x = -5

        let rightEye =
            makeEye(
                color:
                    UIColor(
                        red: 0.33,
                        green: 0.91,
                        blue: 0.47,
                        alpha: 1
                    )
            )

        rightEye.position.x = 5

        hunterEyesNode.addChild(
            leftEye
        )

        hunterEyesNode.addChild(
            rightEye
        )

        hunterNode.addChild(
            hunterEyesNode
        )

        let swordPath =
            CGMutablePath()

        swordPath.move(
            to:
                CGPoint(
                    x: 0,
                    y: 0
                )
        )

        swordPath.addLine(
            to:
                CGPoint(
                    x: 0,
                    y: -55
                )
        )

        let sword =
            SKShapeNode(
                path: swordPath
            )

        sword.strokeColor =
            UIColor(
                red: 0.76,
                green: 0.80,
                blue: 0.82,
                alpha: 1
            )

        sword.lineWidth = 4
        sword.lineCap = .square
        sword.isAntialiased = false

        sword.position =
            CGPoint(
                x: 23,
                y: 4
            )

        sword.zRotation = -0.45

        hunterNode.addChild(
            sword
        )

        hunterSwordNode = sword

        let guardPath =
            CGMutablePath()

        guardPath.move(
            to:
                CGPoint(
                    x: -9,
                    y: 0
                )
        )

        guardPath.addLine(
            to:
                CGPoint(
                    x: 9,
                    y: 0
                )
        )

        let swordGuard =
            SKShapeNode(
                path: guardPath
            )

        swordGuard.strokeColor =
            UIColor(
                red: 0.66,
                green: 0.53,
                blue: 0.25,
                alpha: 1
            )

        swordGuard.lineWidth = 4
        swordGuard.isAntialiased = false
        swordGuard.position.y = -3

        sword.addChild(
            swordGuard
        )
    }

    // MARK: - Enemy visual

    private func refreshEnemyVisual(
        _ enemy: EnemyDefinition
    ) {
        currentEnemyID = enemy.id

        enemyNode.removeAllChildren()

        enemyAuraNode.removeAllChildren()

        if let texture =
            textureIfAvailable(
                named:
                    enemyTextureName(
                        enemy.id
                    )
            ) {

            let sprite =
                SKSpriteNode(
                    texture: texture
                )

            sprite.texture?.filteringMode =
                .nearest

            let targetSize =
                enemy.isBoss
                ? CGSize(
                    width: 192,
                    height: 192
                )
                : CGSize(
                    width: 128,
                    height: 128
                )

            sprite.size = targetSize

            enemyNode.addChild(
                sprite
            )

        } else {
            buildEnemyPlaceholder(
                enemy
            )
        }

        if enemy.isBoss {
            buildBossAura()
        }
    }

    private func buildEnemyPlaceholder(
        _ enemy: EnemyDefinition
    ) {
        let bodyColor: UIColor
        let eyeColor: UIColor

        switch enemy.id {

        case .graveSkeleton:
            bodyColor =
                UIColor(
                    red: 0.66,
                    green: 0.65,
                    blue: 0.58,
                    alpha: 1
                )

            eyeColor =
                UIColor(
                    red: 0.41,
                    green: 0.72,
                    blue: 0.91,
                    alpha: 1
                )

        case .cursedHound:
            bodyColor =
                UIColor(
                    red: 0.15,
                    green: 0.13,
                    blue: 0.12,
                    alpha: 1
                )

            eyeColor =
                UIColor(
                    red: 0.89,
                    green: 0.57,
                    blue: 0.20,
                    alpha: 1
                )

        case .fallenKnight:
            bodyColor =
                UIColor(
                    red: 0.19,
                    green: 0.20,
                    blue: 0.22,
                    alpha: 1
                )

            eyeColor =
                UIColor(
                    red: 0.78,
                    green: 0.22,
                    blue: 0.22,
                    alpha: 1
                )

        case .swampGhoul:
            bodyColor =
                UIColor(
                    red: 0.24,
                    green: 0.29,
                    blue: 0.22,
                    alpha: 1
                )

            eyeColor =
                UIColor(
                    red: 0.83,
                    green: 0.78,
                    blue: 0.29,
                    alpha: 1
                )

        case .shadowCultist:
            bodyColor =
                UIColor(
                    red: 0.055,
                    green: 0.045,
                    blue: 0.065,
                    alpha: 1
                )

            eyeColor =
                UIColor(
                    red: 0.60,
                    green: 0.33,
                    blue: 0.85,
                    alpha: 1
                )

        case .abyssDemon:
            bodyColor =
                UIColor(
                    red: 0.39,
                    green: 0.12,
                    blue: 0.14,
                    alpha: 1
                )

            eyeColor =
                UIColor(
                    red: 0.90,
                    green: 0.22,
                    blue: 0.20,
                    alpha: 1
                )
        }

        let scale: CGFloat =
            enemy.isBoss
            ? 1.45
            : 1.0

        let body =
            SKShapeNode(
                rectOf:
                    CGSize(
                        width: 42 * scale,
                        height: 72 * scale
                    ),
                cornerRadius: 10
            )

        body.fillColor = bodyColor

        body.strokeColor =
            UIColor(
                red: 0.035,
                green: 0.035,
                blue: 0.04,
                alpha: 1
            )

        body.lineWidth = 3
        body.isAntialiased = false

        enemyNode.addChild(
            body
        )

        let head =
            SKShapeNode(
                circleOfRadius:
                    16 * scale
            )

        head.fillColor = bodyColor
        head.strokeColor = body.strokeColor
        head.lineWidth = 3
        head.isAntialiased = false

        head.position.y =
            45 * scale

        enemyNode.addChild(
            head
        )

        let leftEye =
            makeEye(
                color: eyeColor
            )

        let rightEye =
            makeEye(
                color: eyeColor
            )

        leftEye.position =
            CGPoint(
                x: -6 * scale,
                y: 47 * scale
            )

        rightEye.position =
            CGPoint(
                x: 6 * scale,
                y: 47 * scale
            )

        enemyNode.addChild(
            leftEye
        )

        enemyNode.addChild(
            rightEye
        )

        if enemy.id == .cursedHound {
            body.xScale = 1.45
            body.yScale = 0.62
            body.position.y = -17

            head.position =
                CGPoint(
                    x: -28,
                    y: 2
                )

            leftEye.position =
                CGPoint(
                    x: -34,
                    y: 7
                )

            rightEye.position =
                CGPoint(
                    x: -27,
                    y: 7
                )
        }

        if enemy.id == .fallenKnight {
            body.xScale = 1.35
        }

        if enemy.id == .swampGhoul {
            body.yScale = 1.15
            body.zRotation = -0.10
        }

        if enemy.id == .shadowCultist {
            body.yScale = 1.20
        }

        if enemy.id == .abyssDemon {
            addDemonHorns(
                scale: scale
            )
        }
    }

    private func addDemonHorns(
        scale: CGFloat
    ) {
        for direction in [-1.0, 1.0] {
            let path =
                CGMutablePath()

            path.move(
                to:
                    CGPoint(
                        x:
                            CGFloat(direction)
                            * 10 * scale,
                        y: 56 * scale
                    )
            )

            path.addLine(
                to:
                    CGPoint(
                        x:
                            CGFloat(direction)
                            * 26 * scale,
                        y: 84 * scale
                    )
            )

            let horn =
                SKShapeNode(
                    path: path
                )

            horn.strokeColor =
                UIColor(
                    red: 0.09,
                    green: 0.07,
                    blue: 0.075,
                    alpha: 1
                )

            horn.lineWidth = 8
            horn.lineCap = .square
            horn.isAntialiased = false

            enemyNode.addChild(
                horn
            )
        }
    }

    private func buildBossAura() {
        let aura =
            SKShapeNode(
                circleOfRadius: 78
            )

        aura.fillColor =
            UIColor(
                red: 0.82,
                green: 0.10,
                blue: 0.10,
                alpha: 0.055
            )

        aura.strokeColor = .clear

        aura.zPosition = -5

        enemyAuraNode.addChild(
            aura
        )

        enemyNode.addChild(
            enemyAuraNode
        )

        aura.run(
            .repeatForever(
                .sequence(
                    [
                        .fadeAlpha(
                            to: 0.16,
                            duration: 0.6
                        ),
                        .fadeAlpha(
                            to: 0.05,
                            duration: 0.6
                        )
                    ]
                )
            )
        )
    }

    private func makeEye(
        color: UIColor
    ) -> SKShapeNode {
        let eye =
            SKShapeNode(
                rectOf:
                    CGSize(
                        width: 5,
                        height: 2
                    )
            )

        eye.fillColor = color
        eye.strokeColor = color
        eye.glowWidth = 3
        eye.isAntialiased = false

        return eye
    }

    // MARK: - Layout

    private func layoutScene() {
        hunterNode.position =
            CGPoint(
                x: size.width * 0.29,
                y: size.height * 0.31
            )

        enemyNode.position =
            CGPoint(
                x: size.width * 0.72,
                y: size.height * 0.31
            )

        hunterNode.setScale(
            max(
                1.15,
                size.height / 760
            )
        )

        enemyNode.setScale(
            max(
                1.10,
                size.height / 780
            )
        )
    }

    // MARK: - Encounter

    private func handleEncounterStarted(
        _ enemy: EnemyDefinition
    ) {
        refreshEnemyVisual(
            enemy
        )

        enemyNode.removeAllActions()
        enemyNode.isHidden = false

        if enemy.isBoss {
            return
        }

        audioManager.startCombatAudio()
    }

    private func handleEncounterActivated(
        _ enemy: EnemyDefinition
    ) {
        enemyNode.alpha = 1

        enemyNode.position =
            enemyBattlePosition()

        enemyNode.setScale(
            enemy.isBoss
            ? max(
                1.20,
                size.height / 700
            )
            : max(
                1.10,
                size.height / 780
            )
        )
    }

    // MARK: - Spawn

    private func handleEnemySpawnStarted(
        _ enemy: EnemyDefinition
    ) {
        refreshEnemyVisual(
            enemy
        )

        enemyNode.isHidden = false
        enemyNode.removeAllActions()

        enemyNode.alpha = 0

        let finalPosition =
            enemyBattlePosition()

        enemyNode.position =
            CGPoint(
                x:
                    finalPosition.x
                    + (
                        enemy.isBoss
                        ? 60
                        : 32
                    ),
                y:
                    finalPosition.y
                    - (
                        enemy.id == .cursedHound
                        ? 8
                        : 0
                    )
            )

        let duration =
            spawnDuration(
                enemy
            )

        enemyNode.run(
            .group(
                [
                    .fadeIn(
                        withDuration: duration
                    ),
                    .move(
                        to: finalPosition,
                        duration: duration
                    )
                ]
            ),
            withKey: "spawn"
        )

        audioManager.playEnemySpawn(
            enemy
        )

        showSpawnEyes(
            enemy
        )
    }

    private func showSpawnEyes(
        _ enemy: EnemyDefinition
    ) {
        guard !enemy.isBoss else {
            return
        }

        let color =
            enemyEyeColor(
                enemy.id
            )

        let eyes = SKNode()

        eyes.position =
            CGPoint(
                x:
                    enemyBattlePosition().x
                    + 20,
                y:
                    enemyBattlePosition().y
                    + 45
            )

        let left =
            makeEye(
                color: color
            )

        let right =
            makeEye(
                color: color
            )

        left.position.x = -6
        right.position.x = 6

        eyes.addChild(
            left
        )

        eyes.addChild(
            right
        )

        effectsLayer.addChild(
            eyes
        )

        eyes.run(
            .sequence(
                [
                    .fadeIn(
                        withDuration: 0.08
                    ),
                    .wait(
                        forDuration: 0.18
                    ),
                    .fadeOut(
                        withDuration: 0.18
                    ),
                    .removeFromParent()
                ]
            )
        )
    }

    // MARK: - Hunter attack

    private func handleAttackStarted(
        _ resolution: CombatResolution
    ) {
        audioManager.playHunterAttack(
            resolution
        )

        animateHunterAttack(
            resolution
        )
    }

    private func animateHunterAttack(
        _ resolution: CombatResolution
    ) {
        hunterNode.removeAction(
            forKey: "attack"
        )

        let original =
            hunterBattlePosition()

        let attackDirection: CGFloat =
            1

        let movement: CGFloat

        switch resolution.attackKind {
        case .normal:
            movement = 10

        case .strong:
            movement = 16

        case .critical:
            movement = 24
        }

        let moveForward =
            SKAction.moveTo(
                x:
                    original.x
                    + movement
                    * attackDirection,
                duration:
                    resolution.attackDuration
                    * 0.40
            )

        moveForward.timingMode =
            .easeIn

        let moveBack =
            SKAction.moveTo(
                x: original.x,
                duration:
                    resolution.attackDuration
                    * 0.45
            )

        moveBack.timingMode =
            .easeOut

        hunterNode.run(
            .sequence(
                [
                    moveForward,
                    moveBack
                ]
            ),
            withKey: "attack"
        )

        animateSword(
            resolution
        )

        if resolution.isCritical {
            animateCriticalEyes()
        }
    }

    private func animateSword(
        _ resolution: CombatResolution
    ) {
        guard let sword =
                hunterSwordNode else {
            return
        }

        sword.removeAction(
            forKey: "swordAttack"
        )

        let startAngle =
            sword.zRotation

        let targetAngle: CGFloat

        switch resolution.animation {

        case .attack1:
            targetAngle = 0.85

        case .attack2:
            targetAngle = -1.05

        case .attack3:
            targetAngle = 0.10

        case .strong:
            targetAngle = 1.15

        case .critical:
            targetAngle = 1.45
        }

        let slash =
            SKAction.rotate(
                toAngle: targetAngle,
                duration:
                    resolution.attackDuration
                    * 0.48,
                shortestUnitArc: true
            )

        slash.timingMode = .easeIn

        let recover =
            SKAction.rotate(
                toAngle: startAngle,
                duration:
                    resolution.attackDuration
                    * 0.42,
                shortestUnitArc: true
            )

        recover.timingMode = .easeOut

        sword.run(
            .sequence(
                [
                    slash,
                    recover
                ]
            ),
            withKey: "swordAttack"
        )
    }

    private func animateCriticalEyes() {
        hunterEyesNode.removeAction(
            forKey: "criticalEyes"
        )

        hunterEyesNode.run(
            .sequence(
                [
                    .group(
                        [
                            .scale(
                                to: 1.55,
                                duration: 0.07
                            ),
                            .fadeAlpha(
                                to: 1,
                                duration: 0.07
                            )
                        ]
                    ),
                    .wait(
                        forDuration: 0.12
                    ),
                    .group(
                        [
                            .scale(
                                to: 1,
                                duration: 0.16
                            ),
                            .fadeAlpha(
                                to: 0.85,
                                duration: 0.16
                            )
                        ]
                    )
                ]
            ),
            withKey: "criticalEyes"
        )
    }

    private func handleAttackFinished(
        _ resolution: CombatResolution
    ) {
        if !hunterController.isAttacking {
            hunterNode.run(
                .move(
                    to: hunterBattlePosition(),
                    duration: 0.08
                )
            )
        }
    }

    // MARK: - Contact FX

    private func handleSwordContact(
        _ resolution: CombatResolution
    ) {
        showSlash(
            resolution
        )

        showDamageNumber(
            resolution
        )

        createImpactParticles(
            resolution
        )

        shakeScene(
            pixels:
                resolution.sceneShakePixels
        )

        audioManager.playEnemyHit(
            gameState.currentEnemy,
            attackKind:
                resolution.attackKind
        )
    }

    private func showSlash(
        _ resolution: CombatResolution
    ) {
        let slash =
            SKShapeNode()

        let path =
            CGMutablePath()

        switch resolution.animation {

        case .attack1,
             .strong,
             .critical:

            path.move(
                to:
                    CGPoint(
                        x: -34,
                        y: 30
                    )
            )

            path.addLine(
                to:
                    CGPoint(
                        x: 34,
                        y: -30
                    )
            )

        case .attack2:

            path.move(
                to:
                    CGPoint(
                        x: -34,
                        y: -28
                    )
            )

            path.addLine(
                to:
                    CGPoint(
                        x: 34,
                        y: 30
                    )
            )

        case .attack3:

            path.move(
                to:
                    CGPoint(
                        x: -38,
                        y: 0
                    )
            )

            path.addLine(
                to:
                    CGPoint(
                        x: 38,
                        y: 0
                    )
            )
        }

        slash.path = path

        slash.strokeColor =
            resolution.isCritical
            ? UIColor(
                red: 0.55,
                green: 1.0,
                blue: 0.65,
                alpha: 1
            )
            : UIColor(
                red: 0.82,
                green: 0.87,
                blue: 0.91,
                alpha: 1
            )

        slash.lineWidth =
            resolution.isCritical
            ? 5
            : (
                resolution.isStrong
                ? 4
                : 3
            )

        slash.lineCap = .square
        slash.isAntialiased = false

        slash.position =
            CGPoint(
                x:
                    enemyNode.position.x
                    - 12,
                y:
                    enemyNode.position.y
                    + 20
            )

        effectsLayer.addChild(
            slash
        )

        slash.run(
            .sequence(
                [
                    .fadeAlpha(
                        to: 0.95,
                        duration: 0.02
                    ),
                    .fadeOut(
                        withDuration:
                            resolution.isCritical
                            ? 0.18
                            : 0.12
                    ),
                    .removeFromParent()
                ]
            )
        )
    }

    private func showDamageNumber(
        _ resolution: CombatResolution
    ) {
        let label =
            SKLabelNode(
                fontNamed:
                    "AvenirNextCondensed-Bold"
            )

        switch resolution.attackKind {

        case .normal:
            label.text =
                "\(resolution.damage)"

            label.fontColor =
                UIColor(
                    red: 0.82,
                    green: 0.84,
                    blue: 0.86,
                    alpha: 1
                )

            label.fontSize = 18

        case .strong:
            label.text =
                "\(resolution.damage)"

            label.fontColor = .white
            label.fontSize = 23

        case .critical:
            label.text =
                "\(resolution.damage) КРИТ"

            label.fontColor =
                UIColor(
                    red: 0.52,
                    green: 1.0,
                    blue: 0.63,
                    alpha: 1
                )

            label.fontSize = 27
        }

        label.horizontalAlignmentMode =
            .center

        label.verticalAlignmentMode =
            .center

        label.position =
            CGPoint(
                x:
                    enemyNode.position.x
                    + CGFloat.random(
                        in: -16...16
                    ),
                y:
                    enemyNode.position.y
                    + 70
            )

        label.zPosition = 100

        effectsLayer.addChild(
            label
        )

        let move =
            SKAction.moveBy(
                x:
                    CGFloat.random(
                        in: -5...5
                    ),
                y: 36,
                duration:
                    GameConstants
                    .damageNumberDuration
            )

        let fade =
            SKAction.fadeOut(
                withDuration:
                    GameConstants
                    .damageNumberDuration
            )

        label.run(
            .sequence(
                [
                    .group(
                        [
                            move,
                            fade
                        ]
                    ),
                    .removeFromParent()
                ]
            )
        )
    }

    private func createImpactParticles(
        _ resolution: CombatResolution
    ) {
        let count: Int

        switch resolution.attackKind {
        case .normal:
            count = 4

        case .strong:
            count = 7

        case .critical:
            count = 10
        }

        for _ in 0..<count {
            let particle =
                SKShapeNode(
                    rectOf:
                        CGSize(
                            width:
                                CGFloat.random(
                                    in: 2...4
                                ),
                            height:
                                CGFloat.random(
                                    in: 2...4
                                )
                        )
                )

            particle.fillColor =
                resolution.isCritical
                ? UIColor(
                    red: 0.40,
                    green: 0.95,
                    blue: 0.55,
                    alpha: 1
                )
                : UIColor(
                    red: 0.80,
                    green: 0.84,
                    blue: 0.87,
                    alpha: 1
                )

            particle.strokeColor = .clear
            particle.isAntialiased = false

            particle.position =
                CGPoint(
                    x:
                        enemyNode.position.x
                        + CGFloat.random(
                            in: -10...10
                        ),
                    y:
                        enemyNode.position.y
                        + CGFloat.random(
                            in: 5...38
                        )
                )

            effectsLayer.addChild(
                particle
            )

            particle.run(
                .sequence(
                    [
                        .group(
                            [
                                .moveBy(
                                    x:
                                        CGFloat.random(
                                            in: -24...24
                                        ),
                                    y:
                                        CGFloat.random(
                                            in: -12...28
                                        ),
                                    duration: 0.18
                                ),
                                .fadeOut(
                                    withDuration: 0.18
                                )
                            ]
                        ),
                        .removeFromParent()
                    ]
                )
            )
        }
    }

    // MARK: - Enemy hurt

    private func handleEnemyHurt(
        _ enemy: EnemyDefinition,
        attackKind: AttackKind
    ) {
        enemyNode.removeAction(
            forKey: "hurt"
        )

        let amount: CGFloat

        switch attackKind {
        case .normal:
            amount = 3

        case .strong:
            amount = 6

        case .critical:
            amount = 9
        }

        let original =
            enemyBattlePosition()

        enemyNode.run(
            .sequence(
                [
                    .moveTo(
                        x:
                            original.x
                            + amount,
                        duration: 0.05
                    ),
                    .moveTo(
                        x: original.x,
                        duration: 0.09
                    )
                ]
            ),
            withKey: "hurt"
        )
    }

    // MARK: - Death

    private func handleEnemyDeathStarted(
        _ enemy: EnemyDefinition
    ) {
        audioManager.playEnemyDeath(
            enemy
        )

        enemyNode.removeAllActions()

        switch enemy.id {

        case .graveSkeleton:
            enemyNode.run(
                .sequence(
                    [
                        .group(
                            [
                                .scaleY(
                                    to: 0.45,
                                    duration: 0.30
                                ),
                                .fadeAlpha(
                                    to: 0.55,
                                    duration: 0.30
                                )
                            ]
                        ),
                        .fadeOut(
                            withDuration: 0.30
                        )
                    ]
                )
            )

        case .cursedHound:
            enemyNode.run(
                .group(
                    [
                        .moveBy(
                            x: 16,
                            y: -18,
                            duration: 0.55
                        ),
                        .fadeOut(
                            withDuration: 0.65
                        )
                    ]
                )
            )

        case .fallenKnight:
            enemyNode.run(
                .sequence(
                    [
                        .rotate(
                            byAngle: -0.18,
                            duration: 0.25
                        ),
                        .moveBy(
                            x: 0,
                            y: -15,
                            duration: 0.25
                        ),
                        .fadeOut(
                            withDuration: 0.28
                        )
                    ]
                )
            )

        case .swampGhoul:
            enemyNode.run(
                .group(
                    [
                        .moveBy(
                            x: 0,
                            y: -30,
                            duration: 0.70
                        ),
                        .fadeOut(
                            withDuration: 0.70
                        )
                    ]
                )
            )

        case .shadowCultist:
            enemyNode.run(
                .group(
                    [
                        .scale(
                            to: 0.86,
                            duration: 0.75
                        ),
                        .fadeOut(
                            withDuration: 0.82
                        )
                    ]
                )
            )

        case .abyssDemon:
            animateBossDeath()
        }

        createDeathParticles(
            enemy
        )
    }

    private func animateBossDeath() {
        let originalScale =
            enemyNode.xScale

        enemyNode.run(
            .sequence(
                [
                    .wait(
                        forDuration: 0.10
                    ),
                    .group(
                        [
                            .scale(
                                to:
                                    originalScale
                                    * 1.03,
                                duration: 0.18
                            ),
                            .fadeAlpha(
                                to: 0.85,
                                duration: 0.18
                            )
                        ]
                    ),
                    .wait(
                        forDuration: 0.18
                    ),
                    .group(
                        [
                            .scale(
                                to:
                                    originalScale
                                    * 0.92,
                                duration: 0.65
                            ),
                            .fadeOut(
                                withDuration: 0.75
                            )
                        ]
                    )
                ]
            )
        )

        run(
            .sequence(
                [
                    .wait(
                        forDuration: 0.42
                    ),
                    .run {
                        [weak self] in

                        self?.audioManager
                            .playBossAsh()
                    },
                    .wait(
                        forDuration: 0.48
                    ),
                    .run {
                        [weak self] in

                        self?.audioManager
                            .playBossSwordFall()
                    }
                ]
            )
        )

        shakeScene(
            pixels: 4
        )
    }

    private func createDeathParticles(
        _ enemy: EnemyDefinition
    ) {
        let count =
            enemy.isBoss
            ? 24
            : 10

        let color: UIColor

        switch enemy.id {

        case .graveSkeleton:
            color =
                UIColor(
                    red: 0.45,
                    green: 0.62,
                    blue: 0.72,
                    alpha: 0.60
                )

        case .cursedHound:
            color =
                UIColor(
                    red: 0.18,
                    green: 0.15,
                    blue: 0.13,
                    alpha: 0.75
                )

        case .fallenKnight:
            color =
                UIColor(
                    red: 0.55,
                    green: 0.12,
                    blue: 0.12,
                    alpha: 0.60
                )

        case .swampGhoul:
            color =
                UIColor(
                    red: 0.30,
                    green: 0.34,
                    blue: 0.20,
                    alpha: 0.65
                )

        case .shadowCultist:
            color =
                UIColor(
                    red: 0.48,
                    green: 0.25,
                    blue: 0.68,
                    alpha: 0.65
                )

        case .abyssDemon:
            color =
                UIColor(
                    red: 0.54,
                    green: 0.12,
                    blue: 0.12,
                    alpha: 0.75
                )
        }

        for _ in 0..<count {
            let particle =
                SKShapeNode(
                    rectOf:
                        CGSize(
                            width:
                                CGFloat.random(
                                    in: 2...6
                                ),
                            height:
                                CGFloat.random(
                                    in: 2...6
                                )
                        )
                )

            particle.fillColor = color
            particle.strokeColor = .clear
            particle.isAntialiased = false

            particle.position =
                CGPoint(
                    x:
                        enemyNode.position.x
                        + CGFloat.random(
                            in: -35...35
                        ),
                    y:
                        enemyNode.position.y
                        + CGFloat.random(
                            in: -30...65
                        )
                )

            effectsLayer.addChild(
                particle
            )

            let duration =
                TimeInterval.random(
                    in: 0.40...0.95
                )

            particle.run(
                .sequence(
                    [
                        .group(
                            [
                                .moveBy(
                                    x:
                                        CGFloat.random(
                                            in: -40...40
                                        ),
                                    y:
                                        CGFloat.random(
                                            in: 18...70
                                        ),
                                    duration: duration
                                ),
                                .fadeOut(
                                    withDuration: duration
                                )
                            ]
                        ),
                        .removeFromParent()
                    ]
                )
            )
        }
    }

    // MARK: - Boss

    private func handleBossIntro() {
        audioManager.startBossAudio()

        let overlay =
            SKShapeNode(
                rect:
                    CGRect(
                        origin: .zero,
                        size: size
                    )
            )

        overlay.fillColor =
            UIColor(
                red: 0.20,
                green: 0.015,
                blue: 0.02,
                alpha: 0.16
            )

        overlay.strokeColor = .clear
        overlay.zPosition = 60

        effectsLayer.addChild(
            overlay
        )

        overlay.run(
            .sequence(
                [
                    .fadeIn(
                        withDuration: 0.20
                    ),
                    .wait(
                        forDuration: 0.35
                    ),
                    .fadeOut(
                        withDuration: 0.55
                    ),
                    .removeFromParent()
                ]
            )
        )

        shakeScene(
            pixels: 3
        )
    }

    private func handleBossPhaseChanged(
        _ phase: BossVisualPhase
    ) {
        audioManager.playBossPhase(
            phase
        )

        guard let aura =
                enemyAuraNode.children.first else {
            return
        }

        switch phase {

        case .calm:
            aura.alpha = 0.08

        case .angry:
            aura.run(
                .fadeAlpha(
                    to: 0.18,
                    duration: 0.18
                )
            )

        case .enraged:
            aura.run(
                .fadeAlpha(
                    to: 0.30,
                    duration: 0.15
                )
            )

            shakeScene(
                pixels: 2
            )
        }
    }

    // MARK: - Reward

    private func handleReward(
        enemy: EnemyDefinition,
        reward: Int
    ) {
        audioManager.playReward(
            boss: enemy.isBoss
        )

        showRewardCoins(
            reward: reward,
            boss: enemy.isBoss
        )
    }

    private func showRewardCoins(
        reward: Int,
        boss: Bool
    ) {
        let coinCount =
            boss
            ? 6
            : 3

        let target =
            CGPoint(
                x: 38,
                y: size.height - 46
            )

        for index in 0..<coinCount {
            let coin =
                SKShapeNode(
                    circleOfRadius:
                        boss
                        ? 5
                        : 4
                )

            coin.fillColor =
                UIColor(
                    red: 0.80,
                    green: 0.65,
                    blue: 0.24,
                    alpha: 1
                )

            coin.strokeColor =
                UIColor(
                    red: 0.95,
                    green: 0.82,
                    blue: 0.38,
                    alpha: 1
                )

            coin.lineWidth = 1
            coin.isAntialiased = false

            coin.position =
                CGPoint(
                    x:
                        enemyBattlePosition().x
                        + CGFloat.random(
                            in: -18...18
                        ),
                    y:
                        enemyBattlePosition().y
                        + CGFloat.random(
                            in: 10...42
                        )
                )

            effectsLayer.addChild(
                coin
            )

            coin.run(
                .sequence(
                    [
                        .wait(
                            forDuration:
                                Double(index)
                                * 0.045
                        ),
                        .run {
                            [weak self] in

                            self?.audioManager
                                .playCoinFlight()
                        },
                        .group(
                            [
                                .move(
                                    to: target,
                                    duration:
                                        boss
                                        ? 0.52
                                        : 0.42
                                ),
                                .scale(
                                    to: 0.65,
                                    duration:
                                        boss
                                        ? 0.52
                                        : 0.42
                                )
                            ]
                        ),
                        .removeFromParent()
                    ]
                )
            )
        }

        let rewardLabel =
            SKLabelNode(
                fontNamed:
                    "AvenirNextCondensed-Bold"
            )

        rewardLabel.text =
            "+\(reward)"

        rewardLabel.fontSize =
            boss
            ? 26
            : 21

        rewardLabel.fontColor =
            UIColor(
                red: 0.90,
                green: 0.74,
                blue: 0.31,
                alpha: 1
            )

        rewardLabel.position =
            CGPoint(
                x:
                    enemyBattlePosition().x,
                y:
                    enemyBattlePosition().y
                    + 72
            )

        effectsLayer.addChild(
            rewardLabel
        )

        rewardLabel.run(
            .sequence(
                [
                    .group(
                        [
                            .moveBy(
                                x: 0,
                                y: 28,
                                duration: 0.48
                            ),
                            .fadeOut(
                                withDuration: 0.48
                            )
                        ]
                    ),
                    .removeFromParent()
                ]
            )
        )
    }

    // MARK: - Cycle

    private func handleCycleTransition(
        cycle: Int
    ) {
        audioManager.endBossAudio()
        audioManager.playCycleTransition()

        let label =
            SKLabelNode(
                fontNamed:
                    "AvenirNextCondensed-Heavy"
            )

        label.text =
            gameState.cycleLabel

        label.fontSize = 36

        label.fontColor =
            UIColor(
                red: 0.77,
                green: 0.82,
                blue: 0.86,
                alpha: 1
            )

        label.position =
            CGPoint(
                x: size.width * 0.5,
                y: size.height * 0.55
            )

        label.alpha = 0
        label.setScale(0.92)

        label.zPosition = 200

        effectsLayer.addChild(
            label
        )

        label.run(
            .sequence(
                [
                    .group(
                        [
                            .fadeIn(
                                withDuration: 0.16
                            ),
                            .scale(
                                to: 1.0,
                                duration: 0.16
                            )
                        ]
                    ),
                    .wait(
                        forDuration: 0.34
                    ),
                    .fadeOut(
                        withDuration: 0.20
                    ),
                    .removeFromParent()
                ]
            )
        )
    }

    // MARK: - Scene shake

    private func shakeScene(
        pixels: Int
    ) {
        guard pixels > 0 else {
            return
        }

        worldNode.removeAction(
            forKey: "sceneShake"
        )

        worldNode.position = .zero

        var actions: [SKAction] = []

        for _ in 0..<4 {
            actions.append(
                .moveTo(
                    x:
                        CGFloat.random(
                            in:
                                -CGFloat(pixels)
                                ...
                                CGFloat(pixels)
                        ),
                    duration: 0.025
                )
            )
        }

        actions.append(
            .move(
                to: .zero,
                duration: 0.035
            )
        )

        worldNode.run(
            .sequence(
                actions
            ),
            withKey: "sceneShake"
        )
    }

    // MARK: - Runtime sync

    private func syncRuntimeVisuals() {
        if hunterController.eyeFlareActive {
            hunterEyesNode.alpha = 1
        }

        if gameState.combatPhase
            == .paused {
            return
        }
    }

    // MARK: - Resource lookup

    private func textureIfAvailable(
        named name: String
    ) -> SKTexture? {
        let extensions = [
            "png",
            "jpg"
        ]

        for ext in extensions {
            guard let url =
                    Bundle.main.url(
                        forResource: name,
                        withExtension: ext
                    ) else {
                continue
            }

            guard let image =
                    UIImage(
                        contentsOfFile:
                            url.path
                    ) else {
                continue
            }

            let texture =
                SKTexture(
                    image: image
                )

            texture.filteringMode =
                .nearest

            return texture
        }

        return nil
    }

    private func enemyTextureName(
        _ id: EnemyID
    ) -> String {
        switch id {

        case .graveSkeleton:
            return "skeleton_idle_0"

        case .cursedHound:
            return "hound_idle_0"

        case .fallenKnight:
            return "knight_idle_0"

        case .swampGhoul:
            return "ghoul_idle_0"

        case .shadowCultist:
            return "cultist_idle_0"

        case .abyssDemon:
            return "abyss_demon_idle_0"
        }
    }

    // MARK: - Enemy colors

    private func enemyEyeColor(
        _ id: EnemyID
    ) -> UIColor {
        switch id {

        case .graveSkeleton:
            return UIColor(
                red: 0.41,
                green: 0.72,
                blue: 0.91,
                alpha: 1
            )

        case .cursedHound:
            return UIColor(
                red: 0.89,
                green: 0.57,
                blue: 0.20,
                alpha: 1
            )

        case .fallenKnight:
            return UIColor(
                red: 0.78,
                green: 0.22,
                blue: 0.22,
                alpha: 1
            )

        case .swampGhoul:
            return UIColor(
                red: 0.83,
                green: 0.78,
                blue: 0.29,
                alpha: 1
            )

        case .shadowCultist:
            return UIColor(
                red: 0.60,
                green: 0.33,
                blue: 0.85,
                alpha: 1
            )

        case .abyssDemon:
            return UIColor(
                red: 0.90,
                green: 0.22,
                blue: 0.20,
                alpha: 1
            )
        }
    }

    // MARK: - Positions

    private func hunterBattlePosition()
        -> CGPoint {

        CGPoint(
            x: size.width * 0.29,
            y: size.height * 0.31
        )
    }

    private func enemyBattlePosition()
        -> CGPoint {

        CGPoint(
            x: size.width * 0.72,
            y: size.height * 0.31
        )
    }

    // MARK: - Spawn duration

    private func spawnDuration(
        _ enemy: EnemyDefinition
    ) -> TimeInterval {

        switch enemy.id {

        case .graveSkeleton:
            return 0.45

        case .cursedHound:
            return 0.50

        case .fallenKnight:
            return 0.65

        case .swampGhoul:
            return 0.60

        case .shadowCultist:
            return 0.70

        case .abyssDemon:
            return gameState.cycle <= 1
                ? 1.70
                : 1.15
        }
    }

    // MARK: - App lifecycle

    func applicationDidEnterBackground() {
        encounterDirector
            .applicationDidEnterBackground()

        audioManager
            .applicationDidEnterBackground()
    }

    func applicationDidBecomeActive() {
        audioManager
            .applicationDidBecomeActive()

        lastUpdateTime = 0
    }

    func prepareForMainMenu() {
        encounterDirector
            .prepareForMainMenu()

        audioManager
            .startMenuAudio()

        enemyNode.removeAllActions()
        enemyNode.isHidden = true

        hunterNode.removeAllActions()

        effectsLayer.removeAllChildren()

        worldNode.position = .zero

        lastUpdateTime = 0
    }
}
