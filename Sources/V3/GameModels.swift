import Foundation

// MARK: - Enemy IDs

enum EnemyID: String, Codable, CaseIterable, Sendable {
    case graveSkeleton
    case cursedHound
    case fallenKnight
    case swampGhoul
    case shadowCultist
    case abyssDemon
}

// MARK: - Enemy presentation

enum EnemySpawnStyle: String, Codable, Sendable {
    case shadows
    case abyssFog
}

enum EnemyDeathStyle: String, Codable, Sendable {
    case bones
    case darkSmoke
    case armorCollapse
    case swampSmoke
    case violetSmoke
    case ash
}

// MARK: - Enemy definition

struct EnemyDefinition: Identifiable, Hashable, Sendable {
    let id: EnemyID
    let displayName: String

    let baseHP: Int
    let baseReward: Int

    let atlasName: String

    let spawnStyle: EnemySpawnStyle
    let deathStyle: EnemyDeathStyle

    let isBoss: Bool

    static let roster: [EnemyDefinition] = [
        EnemyDefinition(
            id: .graveSkeleton,
            displayName: "МОГИЛЬНЫЙ СКЕЛЕТ",
            baseHP: 20,
            baseReward: 5,
            atlasName: "Skeleton",
            spawnStyle: .shadows,
            deathStyle: .bones,
            isBoss: false
        ),

        EnemyDefinition(
            id: .cursedHound,
            displayName: "ПРОКЛЯТАЯ ГОНЧАЯ",
            baseHP: 30,
            baseReward: 8,
            atlasName: "Hound",
            spawnStyle: .shadows,
            deathStyle: .darkSmoke,
            isBoss: false
        ),

        EnemyDefinition(
            id: .fallenKnight,
            displayName: "ПАДШИЙ РЫЦАРЬ",
            baseHP: 45,
            baseReward: 12,
            atlasName: "Knight",
            spawnStyle: .shadows,
            deathStyle: .armorCollapse,
            isBoss: false
        ),

        EnemyDefinition(
            id: .swampGhoul,
            displayName: "БОЛОТНЫЙ УПЫРЬ",
            baseHP: 60,
            baseReward: 18,
            atlasName: "Ghoul",
            spawnStyle: .shadows,
            deathStyle: .swampSmoke,
            isBoss: false
        ),

        EnemyDefinition(
            id: .shadowCultist,
            displayName: "ТЕНЕВОЙ КУЛЬТИСТ",
            baseHP: 80,
            baseReward: 25,
            atlasName: "Cultist",
            spawnStyle: .shadows,
            deathStyle: .violetSmoke,
            isBoss: false
        ),

        EnemyDefinition(
            id: .abyssDemon,
            displayName: "ДЕМОН БЕЗДНЫ",
            baseHP: 150,
            baseReward: 60,
            atlasName: "AbyssDemon",
            spawnStyle: .abyssFog,
            deathStyle: .ash,
            isBoss: true
        )
    ]

    static func enemy(at index: Int) -> EnemyDefinition {
        let safeIndex = min(
            max(index, 0),
            roster.count - 1
        )

        return roster[safeIndex]
    }
}

// MARK: - Attack system

enum AttackKind: String, Codable, Sendable {
    case normal
    case strong
    case critical

    var damage: Int {
        switch self {
        case .normal:
            return 1

        case .strong:
            return 3

        case .critical:
            return 5
        }
    }
}

// MARK: - Combat state

enum CombatPhase: String, Codable, Sendable {
    case enteringBattle
    case spawningEnemy
    case fighting
    case enemyDying
    case rewarding
    case bossIntro
    case cycleTransition
    case paused
}

// MARK: - Boss visual phase

enum BossVisualPhase: String, Codable, Sendable {
    case calm
    case angry
    case enraged

    static func phase(
        currentHP: Int,
        maximumHP: Int
    ) -> BossVisualPhase {
        guard maximumHP > 0 else {
            return .enraged
        }

        let percentage =
            Double(currentHP)
            / Double(maximumHP)

        if percentage > 0.60 {
            return .calm
        }

        if percentage > 0.30 {
            return .angry
        }

        return .enraged
    }
}

// MARK: - Save data

struct GameProgress: Codable, Equatable, Sendable {
    var coins: Int

    var cycle: Int
    var enemyIndex: Int
    var enemyHP: Int

    var comboCounter: Int

    var musicEnabled: Bool
    var sfxEnabled: Bool

    var hasStartedGame: Bool
    var tutorialCompleted: Bool

    static let fresh = GameProgress(
        coins: 0,
        cycle: 1,
        enemyIndex: 0,
        enemyHP: EnemyDefinition.roster[0].baseHP,
        comboCounter: 0,
        musicEnabled: true,
        sfxEnabled: true,
        hasStartedGame: false,
        tutorialCompleted: false
    )

    var currentEnemy: EnemyDefinition {
        EnemyDefinition.enemy(
            at: enemyIndex
        )
    }
}

// MARK: - Runtime combat information

struct DamageEvent: Identifiable, Equatable, Sendable {
    let id: UUID

    let amount: Int
    let attackKind: AttackKind

    init(
        amount: Int,
        attackKind: AttackKind
    ) {
        self.id = UUID()
        self.amount = amount
        self.attackKind = attackKind
    }
}

struct RewardEvent: Identifiable, Equatable, Sendable {
    let id: UUID

    let coins: Int

    init(
        coins: Int
    ) {
        self.id = UUID()
        self.coins = coins
    }
}

// MARK: - V3 constants

enum GameConstants {
    static let enemiesPerCycle = 6

    static let normalDamage = 1
    static let strongDamage = 3
    static let criticalDamage = 5

    static let strongHitInterval = 5
    static let criticalHitInterval = 10

    static let cycleGrowthStep = 0.25

    static let normalEnemySpawnDuration = 0.50
    static let bossSpawnDuration = 1.70

    static let normalEnemyTransitionDelay = 0.40
    static let bossDeathDuration = 1.40

    static let damageNumberDuration = 0.45

    static let hunterCanvasWidth = 128
    static let hunterCanvasHeight = 128

    static let demonCanvasWidth = 192
    static let demonCanvasHeight = 192
}
