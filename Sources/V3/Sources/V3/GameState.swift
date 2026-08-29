import Foundation
import Combine

@MainActor
final class GameState: ObservableObject {

    // MARK: - Published state

    @Published private(set) var progress: GameProgress
    @Published private(set) var combatPhase: CombatPhase

    @Published private(set) var damageEvents: [DamageEvent] = []
    @Published private(set) var rewardEvents: [RewardEvent] = []

    @Published private(set) var isCycleBannerVisible = false
    @Published private(set) var cycleBannerText = ""

    private var phaseBeforePause: CombatPhase?

    // MARK: - Init

    init(
        progress: GameProgress = .fresh
    ) {
        let normalized = Self.normalized(
            progress
        )

        self.progress = normalized

        self.combatPhase =
            normalized.hasStartedGame
            ? .spawningEnemy
            : .enteringBattle
    }

    // MARK: - Current values

    var coins: Int {
        progress.coins
    }

    var cycle: Int {
        progress.cycle
    }

    var enemyIndex: Int {
        progress.enemyIndex
    }

    var currentEnemyHP: Int {
        progress.enemyHP
    }

    var comboCounter: Int {
        progress.comboCounter
    }

    var musicEnabled: Bool {
        progress.musicEnabled
    }

    var sfxEnabled: Bool {
        progress.sfxEnabled
    }

    var hasStartedGame: Bool {
        progress.hasStartedGame
    }

    var tutorialCompleted: Bool {
        progress.tutorialCompleted
    }

    var currentEnemy: EnemyDefinition {
        EnemyDefinition.enemy(
            at: progress.enemyIndex
        )
    }

    var isBoss: Bool {
        currentEnemy.isBoss
    }

    var cycleMultiplier: Double {
        Self.cycleMultiplier(
            for: progress.cycle
        )
    }

    var currentEnemyMaxHP: Int {
        Self.scaledHP(
            baseHP: currentEnemy.baseHP,
            cycle: progress.cycle
        )
    }

    var currentEnemyReward: Int {
        Self.scaledReward(
            baseReward: currentEnemy.baseReward,
            cycle: progress.cycle
        )
    }

    var bossVisualPhase: BossVisualPhase {
        BossVisualPhase.phase(
            currentHP: currentEnemyHP,
            maximumHP: currentEnemyMaxHP
        )
    }

    var canAttack: Bool {
        combatPhase == .fighting
        && currentEnemyHP > 0
    }

    var cycleLabel: String {
        "ЦИКЛ \(romanNumeral(progress.cycle))"
    }

    var enemyCounterLabel: String {
        "\(progress.enemyIndex + 1)/\(GameConstants.enemiesPerCycle)"
    }

    // MARK: - Game start

    func startNewGame() {
        var fresh = GameProgress.fresh

        fresh.hasStartedGame = true
        fresh.enemyHP = Self.scaledHP(
            baseHP: fresh.currentEnemy.baseHP,
            cycle: fresh.cycle
        )

        progress = fresh

        damageEvents.removeAll()
        rewardEvents.removeAll()

        phaseBeforePause = nil
        isCycleBannerVisible = false
        cycleBannerText = ""

        combatPhase = .spawningEnemy
    }

    func continueGame() {
        guard progress.hasStartedGame else {
            startNewGame()
            return
        }

        combatPhase =
            currentEnemy.isBoss
            ? .bossIntro
            : .spawningEnemy
    }

    // MARK: - Combat phase

    func setCombatPhase(
        _ phase: CombatPhase
    ) {
        combatPhase = phase
    }

    func enemyDidFinishSpawning() {
        guard currentEnemyHP > 0 else {
            return
        }

        combatPhase = .fighting
    }

    // MARK: - Combo

    @discardableResult
    func registerAttackInput() -> Int {
        let next =
            progress.comboCounter + 1

        updateProgress {
            $0.comboCounter = next
        }

        return next
    }

    func resetComboCounter() {
        updateProgress {
            $0.comboCounter = 0
        }
    }

    // MARK: - Damage

    func applyDamage(
        _ damageEvent: DamageEvent
    ) {
        guard canAttack else {
            return
        }

        let newHP = max(
            0,
            progress.enemyHP
                - damageEvent.amount
        )

        updateProgress {
            $0.enemyHP = newHP
        }

        damageEvents.append(
            damageEvent
        )

        if newHP == 0 {
            combatPhase = .enemyDying
        }
    }

    func removeDamageEvent(
        id: UUID
    ) {
        damageEvents.removeAll {
            $0.id == id
        }
    }

    // MARK: - Rewards

    @discardableResult
    func grantCurrentEnemyReward() -> Int {
        let reward =
            currentEnemyReward

        updateProgress {
            $0.coins += reward
        }

        rewardEvents.append(
            RewardEvent(
                coins: reward
            )
        )

        return reward
    }

    func removeRewardEvent(
        id: UUID
    ) {
        rewardEvents.removeAll {
            $0.id == id
        }
    }

    // MARK: - Enemy progression

    func prepareCurrentEnemy() {
        let hp = currentEnemyMaxHP

        updateProgress {
            $0.enemyHP = hp
        }

        combatPhase =
            currentEnemy.isBoss
            ? .bossIntro
            : .spawningEnemy
    }

    @discardableResult
    func advanceToNextEncounter() -> Bool {
        let completedBoss =
            currentEnemy.isBoss

        if completedBoss {
            updateProgress {
                $0.cycle += 1
                $0.enemyIndex = 0
                $0.comboCounter = 0

                let enemy =
                    EnemyDefinition.enemy(
                        at: 0
                    )

                $0.enemyHP =
                    Self.scaledHP(
                        baseHP: enemy.baseHP,
                        cycle: $0.cycle
                    )
            }

            showCycleBanner()

            combatPhase =
                .cycleTransition

            return true
        }

        updateProgress {
            $0.enemyIndex += 1

            let enemy =
                EnemyDefinition.enemy(
                    at: $0.enemyIndex
                )

            $0.enemyHP =
                Self.scaledHP(
                    baseHP: enemy.baseHP,
                    cycle: $0.cycle
                )
        }

        combatPhase =
            currentEnemy.isBoss
            ? .bossIntro
            : .spawningEnemy

        return false
    }

    // MARK: - Cycle banner

    func showCycleBanner() {
        cycleBannerText =
            "ЦИКЛ \(romanNumeral(progress.cycle))"

        isCycleBannerVisible = true
    }

    func hideCycleBanner() {
        isCycleBannerVisible = false
    }

    // MARK: - Tutorial

    func completeTutorial() {
        guard !progress.tutorialCompleted else {
            return
        }

        updateProgress {
            $0.tutorialCompleted = true
        }
    }

    // MARK: - Settings

    func setMusicEnabled(
        _ enabled: Bool
    ) {
        updateProgress {
            $0.musicEnabled = enabled
        }
    }

    func setSFXEnabled(
        _ enabled: Bool
    ) {
        updateProgress {
            $0.sfxEnabled = enabled
        }
    }

    func toggleMusic() {
        setMusicEnabled(
            !progress.musicEnabled
        )
    }

    func toggleSFX() {
        setSFXEnabled(
            !progress.sfxEnabled
        )
    }

    // MARK: - Pause

    func pauseGame() {
        guard combatPhase != .paused else {
            return
        }

        phaseBeforePause =
            combatPhase

        combatPhase = .paused
    }

    func resumeGame() {
        guard combatPhase == .paused else {
            return
        }

        combatPhase =
            phaseBeforePause
            ?? .fighting

        phaseBeforePause = nil
    }

    // MARK: - Save restore

    var snapshot: GameProgress {
        progress
    }

    func restore(
        _ savedProgress: GameProgress
    ) {
        let normalized =
            Self.normalized(
                savedProgress
            )

        progress = normalized

        damageEvents.removeAll()
        rewardEvents.removeAll()

        phaseBeforePause = nil
        isCycleBannerVisible = false
        cycleBannerText = ""

        combatPhase =
            normalized.currentEnemy.isBoss
            ? .bossIntro
            : .spawningEnemy
    }

    // MARK: - Calculations

    static func cycleMultiplier(
        for cycle: Int
    ) -> Double {
        let safeCycle =
            max(1, cycle)

        return 1.0
            + Double(
                safeCycle - 1
            )
            * GameConstants.cycleGrowthStep
    }

    static func scaledHP(
        baseHP: Int,
        cycle: Int
    ) -> Int {
        let value =
            Double(baseHP)
            * cycleMultiplier(
                for: cycle
            )

        return max(
            1,
            Int(
                value.rounded()
            )
        )
    }

    static func scaledReward(
        baseReward: Int,
        cycle: Int
    ) -> Int {
        let value =
            Double(baseReward)
            * cycleMultiplier(
                for: cycle
            )

        return max(
            1,
            Int(
                value.rounded()
            )
        )
    }

    // MARK: - Internal helpers

    private func updateProgress(
        _ change: (
            inout GameProgress
        ) -> Void
    ) {
        var copy = progress

        change(
            &copy
        )

        progress = copy
    }

    private static func normalized(
        _ value: GameProgress
    ) -> GameProgress {
        var result = value

        result.coins =
            max(
                0,
                result.coins
            )

        result.cycle =
            max(
                1,
                result.cycle
            )

        result.enemyIndex =
            min(
                max(
                    result.enemyIndex,
                    0
                ),
                EnemyDefinition.roster.count - 1
            )

        result.comboCounter =
            max(
                0,
                result.comboCounter
            )

        let enemy =
            EnemyDefinition.enemy(
                at: result.enemyIndex
            )

        let maximumHP =
            scaledHP(
                baseHP: enemy.baseHP,
                cycle: result.cycle
            )

        if result.hasStartedGame {
            result.enemyHP =
                min(
                    max(
                        1,
                        result.enemyHP
                    ),
                    maximumHP
                )
        } else {
            result.enemyHP =
                maximumHP
        }

        return result
    }

    private func romanNumeral(
        _ number: Int
    ) -> String {
        guard number > 0 else {
            return "I"
        }

        let values: [
            (
                Int,
                String
            )
        ] = [
            (1000, "M"),
            (900, "CM"),
            (500, "D"),
            (400, "CD"),
            (100, "C"),
            (90, "XC"),
            (50, "L"),
            (40, "XL"),
            (10, "X"),
            (9, "IX"),
            (5, "V"),
            (4, "IV"),
            (1, "I")
        ]

        var remaining =
            number

        var result = ""

        for (
            value,
            numeral
        ) in values {
            while remaining >= value {
                result += numeral
                remaining -= value
            }
        }

        return result
    }
}
