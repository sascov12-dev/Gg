import Foundation
import Combine

// MARK: - Enemy runtime state

enum EnemyRuntimeState: Equatable {
    case hidden
    case spawning
    case idle
    case hurt
    case strongHurt
    case criticalHurt
    case dying
    case dead
}

// MARK: - Enemy Controller

@MainActor
final class EnemyController: ObservableObject {

    // MARK: - Published state

    @Published private(set) var state: EnemyRuntimeState = .hidden
    @Published private(set) var definition: EnemyDefinition
    @Published private(set) var bossVisualPhase: BossVisualPhase

    @Published private(set) var spawnProgress: Double = 0
    @Published private(set) var deathProgress: Double = 0

    // MARK: - Dependencies

    private let gameState: GameState

    // MARK: - Timing

    private var stateElapsed: Double = 0
    private var currentStateDuration: Double = 0

    // MARK: - Callbacks

    var onSpawnStarted: ((EnemyDefinition) -> Void)?
    var onSpawnFinished: ((EnemyDefinition) -> Void)?

    var onHurt: ((EnemyDefinition, AttackKind) -> Void)?

    var onDeathStarted: ((EnemyDefinition) -> Void)?
    var onDeathFinished: ((EnemyDefinition) -> Void)?

    var onBossPhaseChanged: ((
        BossVisualPhase,
        BossVisualPhase
    ) -> Void)?

    // MARK: - Init

    init(
        gameState: GameState
    ) {
        self.gameState = gameState
        self.definition = gameState.currentEnemy
        self.bossVisualPhase = gameState.bossVisualPhase
    }

    // MARK: - Encounter setup

    func prepareCurrentEncounter() {
        definition = gameState.currentEnemy

        stateElapsed = 0
        spawnProgress = 0
        deathProgress = 0

        bossVisualPhase =
            gameState.bossVisualPhase

        beginSpawn()
    }

    // MARK: - Spawn

    func beginSpawn() {
        definition =
            gameState.currentEnemy

        state = .spawning
        stateElapsed = 0

        spawnProgress = 0
        deathProgress = 0

        currentStateDuration =
            spawnDuration(
                for: definition
            )

        bossVisualPhase =
            gameState.bossVisualPhase

        onSpawnStarted?(
            definition
        )
    }

    private func finishSpawn() {
        state = .idle

        stateElapsed = 0
        spawnProgress = 1

        gameState.enemyDidFinishSpawning()

        onSpawnFinished?(
            definition
        )
    }

    // MARK: - Hit reaction

    func receiveHit(
        _ resolution: CombatResolution
    ) {
        guard state != .dying,
              state != .dead,
              state != .hidden,
              state != .spawning else {
            return
        }

        updateBossPhaseIfNeeded()

        if gameState.currentEnemyHP <= 0 {
            beginDeath()
            return
        }

        switch resolution.attackKind {

        case .normal:
            state = .hurt
            currentStateDuration = 0.12

        case .strong:
            state = .strongHurt
            currentStateDuration = 0.18

        case .critical:
            state = .criticalHurt
            currentStateDuration = 0.22
        }

        stateElapsed = 0

        onHurt?(
            definition,
            resolution.attackKind
        )
    }

    // MARK: - Boss phase

    private func updateBossPhaseIfNeeded() {
        guard definition.isBoss else {
            return
        }

        let oldPhase =
            bossVisualPhase

        let newPhase =
            gameState.bossVisualPhase

        guard oldPhase != newPhase else {
            return
        }

        bossVisualPhase =
            newPhase

        onBossPhaseChanged?(
            oldPhase,
            newPhase
        )
    }

    // MARK: - Death

    func beginDeath() {
        guard state != .dying,
              state != .dead else {
            return
        }

        state = .dying
        stateElapsed = 0
        deathProgress = 0

        currentStateDuration =
            deathDuration(
                for: definition
            )

        onDeathStarted?(
            definition
        )
    }

    private func finishDeath() {
        state = .dead

        stateElapsed = 0
        deathProgress = 1

        onDeathFinished?(
            definition
        )
    }

    // MARK: - Update

    func update(
        deltaTime: Double
    ) {
        guard deltaTime > 0 else {
            return
        }

        guard gameState.combatPhase != .paused else {
            return
        }

        switch state {

        case .hidden,
             .idle,
             .dead:
            break

        case .spawning:
            updateSpawn(
                deltaTime: deltaTime
            )

        case .hurt,
             .strongHurt,
             .criticalHurt:
            updateHurt(
                deltaTime: deltaTime
            )

        case .dying:
            updateDeath(
                deltaTime: deltaTime
            )
        }
    }

    // MARK: - Spawn update

    private func updateSpawn(
        deltaTime: Double
    ) {
        stateElapsed += deltaTime

        guard currentStateDuration > 0 else {
            finishSpawn()
            return
        }

        spawnProgress = min(
            1,
            stateElapsed
                / currentStateDuration
        )

        if stateElapsed
            >= currentStateDuration {

            finishSpawn()
        }
    }

    // MARK: - Hurt update

    private func updateHurt(
        deltaTime: Double
    ) {
        stateElapsed += deltaTime

        if gameState.currentEnemyHP <= 0 {
            beginDeath()
            return
        }

        if stateElapsed
            >= currentStateDuration {

            state = .idle

            stateElapsed = 0
            currentStateDuration = 0
        }
    }

    // MARK: - Death update

    private func updateDeath(
        deltaTime: Double
    ) {
        stateElapsed += deltaTime

        guard currentStateDuration > 0 else {
            finishDeath()
            return
        }

        deathProgress = min(
            1,
            stateElapsed
                / currentStateDuration
        )

        if stateElapsed
            >= currentStateDuration {

            finishDeath()
        }
    }

    // MARK: - Spawn timing

    private func spawnDuration(
        for enemy: EnemyDefinition
    ) -> Double {
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
            // First boss entrance is slower and heavier.
            // Later cycles are slightly faster.

            if gameState.cycle <= 1 {
                return GameConstants.bossSpawnDuration
            }

            return 1.15
        }
    }

    // MARK: - Death timing

    private func deathDuration(
        for enemy: EnemyDefinition
    ) -> Double {
        switch enemy.id {

        case .graveSkeleton:
            return 0.65

        case .cursedHound:
            return 0.70

        case .fallenKnight:
            return 0.80

        case .swampGhoul:
            return 0.80

        case .shadowCultist:
            return 0.90

        case .abyssDemon:
            return GameConstants.bossDeathDuration
        }
    }

    // MARK: - State helpers

    var isAlive: Bool {
        state != .dying
        && state != .dead
        && gameState.currentEnemyHP > 0
    }

    var isSpawning: Bool {
        state == .spawning
    }

    var isDying: Bool {
        state == .dying
    }

    var canReactToHit: Bool {
        switch state {
        case .idle,
             .hurt,
             .strongHurt,
             .criticalHurt:
            return true

        default:
            return false
        }
    }

    // MARK: - Boss helpers

    var isBoss: Bool {
        definition.isBoss
    }

    var bossHealthPercentage: Double {
        guard gameState.currentEnemyMaxHP > 0 else {
            return 0
        }

        return min(
            1,
            max(
                0,
                Double(
                    gameState.currentEnemyHP
                )
                / Double(
                    gameState.currentEnemyMaxHP
                )
            )
        )
    }

    // MARK: - Reset

    func hide() {
        state = .hidden

        stateElapsed = 0
        currentStateDuration = 0

        spawnProgress = 0
        deathProgress = 0
    }

    func forceIdle() {
        definition =
            gameState.currentEnemy

        state = .idle

        stateElapsed = 0
        currentStateDuration = 0

        spawnProgress = 1
        deathProgress = 0

        bossVisualPhase =
            gameState.bossVisualPhase
    }
}
