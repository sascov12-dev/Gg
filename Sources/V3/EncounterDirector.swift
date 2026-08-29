import Foundation
import Combine

// MARK: - Encounter Director

@MainActor
final class EncounterDirector: ObservableObject {

    // MARK: - Dependencies

    let gameState: GameState
    let hunterController: HunterController
    let enemyController: EnemyController

    // MARK: - Runtime

    private var transitionElapsed: Double = 0
    private var transitionDuration: Double = 0

    private var bossSpawnStarted = false
    private var rewardHandled = false

    // MARK: - Callbacks for scene / UI

    var onEncounterStarted: ((EnemyDefinition) -> Void)?
    var onEncounterActivated: ((EnemyDefinition) -> Void)?

    var onRewardGranted: ((
        EnemyDefinition,
        Int
    ) -> Void)?

    var onBossIntroStarted: (() -> Void)?
    var onCycleTransitionStarted: ((Int) -> Void)?

    var onProgressShouldSave: ((GameProgress) -> Void)?

    // MARK: - Init

    init(
        gameState: GameState,
        hunterController: HunterController,
        enemyController: EnemyController
    ) {
        self.gameState = gameState
        self.hunterController = hunterController
        self.enemyController = enemyController

        connectControllers()
    }

    // MARK: - Controller connections

    private func connectControllers() {

        hunterController.onSwordContact = {
            [weak self] resolution in

            guard let self else {
                return
            }

            self.enemyController.receiveHit(
                resolution
            )
        }

        enemyController.onSpawnFinished = {
            [weak self] enemy in

            guard let self else {
                return
            }

            self.onEncounterActivated?(
                enemy
            )

            self.requestSave()
        }

        enemyController.onDeathFinished = {
            [weak self] enemy in

            guard let self else {
                return
            }

            self.handleEnemyDeathFinished(
                enemy
            )
        }
    }

    // MARK: - Start new game

    func startNewGame() {
        resetRuntime()

        gameState.startNewGame()

        requestSave()

        beginCurrentEncounter()
    }

    // MARK: - Continue existing game

    func continueGame() {
        resetRuntime()

        guard gameState.hasStartedGame else {
            startNewGame()
            return
        }

        gameState.continueGame()

        beginCurrentEncounter()
    }

    // MARK: - Begin encounter

    func beginCurrentEncounter() {
        transitionElapsed = 0
        transitionDuration = 0

        rewardHandled = false
        bossSpawnStarted = false

        hunterController.prepareForEnemySpawn()
        enemyController.hide()

        let enemy =
            gameState.currentEnemy

        onEncounterStarted?(
            enemy
        )

        if enemy.isBoss {
            beginBossIntro()
        } else {
            beginNormalEnemySpawn()
        }
    }

    // MARK: - Normal enemy spawn

    private func beginNormalEnemySpawn() {
        gameState.setCombatPhase(
            .spawningEnemy
        )

        hunterController.prepareForEnemySpawn()

        enemyController.prepareCurrentEncounter()
    }

    // MARK: - Boss intro

    private func beginBossIntro() {
        gameState.setCombatPhase(
            .bossIntro
        )

        hunterController.prepareForBossIntro()
        enemyController.hide()

        bossSpawnStarted = false

        transitionElapsed = 0

        // First Demon entrance gets more silence
        // and buildup. Later cycles are faster.

        transitionDuration =
            gameState.cycle <= 1
            ? 0.55
            : 0.30

        onBossIntroStarted?()
    }

    // MARK: - Update loop

    func update(
        deltaTime: Double
    ) {
        guard deltaTime > 0 else {
            return
        }

        guard gameState.combatPhase != .paused else {
            return
        }

        hunterController.update(
            deltaTime: deltaTime
        )

        enemyController.update(
            deltaTime: deltaTime
        )

        switch gameState.combatPhase {

        case .bossIntro:
            updateBossIntro(
                deltaTime: deltaTime
            )

        case .rewarding:
            updateRewardTransition(
                deltaTime: deltaTime
            )

        case .cycleTransition:
            updateCycleTransition(
                deltaTime: deltaTime
            )

        default:
            break
        }
    }

    // MARK: - Boss intro update

    private func updateBossIntro(
        deltaTime: Double
    ) {
        guard !bossSpawnStarted else {
            return
        }

        transitionElapsed += deltaTime

        if transitionElapsed
            >= transitionDuration {

            bossSpawnStarted = true

            transitionElapsed = 0
            transitionDuration = 0

            enemyController.prepareCurrentEncounter()
        }
    }

    // MARK: - Enemy death

    private func handleEnemyDeathFinished(
        _ enemy: EnemyDefinition
    ) {
        guard !rewardHandled else {
            return
        }

        rewardHandled = true

        hunterController.forceIdle()

        gameState.setCombatPhase(
            .rewarding
        )

        let reward =
            gameState.grantCurrentEnemyReward()

        onRewardGranted?(
            enemy,
            reward
        )

        requestSave()

        transitionElapsed = 0

        // Small pause after enemy death and reward.
        // Boss already has a longer death animation,
        // so this stays short.

        transitionDuration =
            enemy.isBoss
            ? 0.40
            : GameConstants.normalEnemyTransitionDelay
    }

    // MARK: - Reward transition

    private func updateRewardTransition(
        deltaTime: Double
    ) {
        transitionElapsed += deltaTime

        guard transitionElapsed
                >= transitionDuration else {
            return
        }

        transitionElapsed = 0
        transitionDuration = 0

        advanceAfterReward()
    }

    // MARK: - Advance encounter

    private func advanceAfterReward() {
        let startedNewCycle =
            gameState.advanceToNextEncounter()

        requestSave()

        if startedNewCycle {
            beginCycleTransition()
            return
        }

        beginCurrentEncounter()
    }

    // MARK: - Cycle transition

    private func beginCycleTransition() {
        hunterController.prepareForCycleTransition()
        enemyController.hide()

        gameState.setCombatPhase(
            .cycleTransition
        )

        gameState.showCycleBanner()

        transitionElapsed = 0
        transitionDuration = 0.70

        onCycleTransitionStarted?(
            gameState.cycle
        )

        requestSave()
    }

    private func updateCycleTransition(
        deltaTime: Double
    ) {
        transitionElapsed += deltaTime

        guard transitionElapsed
                >= transitionDuration else {
            return
        }

        transitionElapsed = 0
        transitionDuration = 0

        gameState.hideCycleBanner()

        beginCurrentEncounter()
    }

    // MARK: - Player input

    @discardableResult
    func handleAttackInput() -> Bool {
        guard gameState.combatPhase
                == .fighting else {
            return false
        }

        return hunterController
            .handleAttackInput()
    }

    // MARK: - Pause

    func pauseGame() {
        guard gameState.combatPhase
                != .paused else {
            return
        }

        gameState.pauseGame()
        hunterController.pause()

        requestSave()
    }

    func resumeGame() {
        guard gameState.combatPhase
                == .paused else {
            return
        }

        gameState.resumeGame()
        hunterController.resume()
    }

    // MARK: - Exit to menu

    func prepareForMainMenu() {
        requestSave()

        hunterController.forceIdle()
        enemyController.hide()

        transitionElapsed = 0
        transitionDuration = 0

        bossSpawnStarted = false
        rewardHandled = false
    }

    // MARK: - App lifecycle

    func applicationDidEnterBackground() {
        requestSave()
    }

    func applicationWillTerminate() {
        requestSave()
    }

    // MARK: - Save

    func requestSave() {
        guard gameState.hasStartedGame else {
            return
        }

        onProgressShouldSave?(
            gameState.snapshot
        )
    }

    // MARK: - Restore

    func restore(
        _ progress: GameProgress
    ) {
        resetRuntime()

        gameState.restore(
            progress
        )

        beginCurrentEncounter()
    }

    // MARK: - Runtime reset

    private func resetRuntime() {
        transitionElapsed = 0
        transitionDuration = 0

        bossSpawnStarted = false
        rewardHandled = false

        hunterController.resetVisualState()
        enemyController.hide()
    }

    // MARK: - Current encounter helpers

    var currentEnemy: EnemyDefinition {
        gameState.currentEnemy
    }

    var currentEnemyHP: Int {
        gameState.currentEnemyHP
    }

    var currentEnemyMaxHP: Int {
        gameState.currentEnemyMaxHP
    }

    var currentReward: Int {
        gameState.currentEnemyReward
    }

    var isBossEncounter: Bool {
        gameState.currentEnemy.isBoss
    }

    var isCombatActive: Bool {
        gameState.combatPhase
            == .fighting
    }

    var canReceiveAttackInput: Bool {
        isCombatActive
        && gameState.currentEnemyHP > 0
    }
}
