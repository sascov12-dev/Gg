import Foundation

// MARK: - Hunter attack animation

enum HunterAttackAnimation: String, Codable, Sendable {
    case attack1
    case attack2
    case attack3
    case strong
    case critical
}

// MARK: - Combat resolution

struct CombatResolution: Equatable, Sendable {
    let hitNumber: Int

    let attackKind: AttackKind
    let animation: HunterAttackAnimation

    let damage: Int

    let attackDuration: Double
    let contactDelay: Double

    let sceneShakePixels: Int

    var isStrong: Bool {
        attackKind == .strong
    }

    var isCritical: Bool {
        attackKind == .critical
    }
}

// MARK: - Combat Resolver

enum CombatResolver {

    // MARK: - Resolve next hit

    static func nextResolution(
        after comboCounter: Int
    ) -> CombatResolution {
        let nextHit = max(
            1,
            comboCounter + 1
        )

        return resolution(
            forHitNumber: nextHit
        )
    }

    // MARK: - Resolve exact hit

    static func resolution(
        forHitNumber hitNumber: Int
    ) -> CombatResolution {
        let safeHitNumber = max(
            1,
            hitNumber
        )

        let kind = attackKind(
            forHitNumber: safeHitNumber
        )

        let animation = attackAnimation(
            forHitNumber: safeHitNumber,
            kind: kind
        )

        return CombatResolution(
            hitNumber: safeHitNumber,
            attackKind: kind,
            animation: animation,
            damage: kind.damage,
            attackDuration: attackDuration(
                for: kind
            ),
            contactDelay: contactDelay(
                for: kind
            ),
            sceneShakePixels: sceneShake(
                for: kind
            )
        )
    }

    // MARK: - Attack type

    static func attackKind(
        forHitNumber hitNumber: Int
    ) -> AttackKind {
        let safeHitNumber = max(
            1,
            hitNumber
        )

        // Every 10th hit is critical.
        // Critical replaces the strong hit.
        if safeHitNumber
            % GameConstants.criticalHitInterval == 0 {
            return .critical
        }

        // Every 5th hit is strong,
        // unless it is also the 10th hit.
        if safeHitNumber
            % GameConstants.strongHitInterval == 0 {
            return .strong
        }

        return .normal
    }

    // MARK: - Animation

    static func attackAnimation(
        forHitNumber hitNumber: Int,
        kind: AttackKind
    ) -> HunterAttackAnimation {
        switch kind {

        case .strong:
            return .strong

        case .critical:
            return .critical

        case .normal:
            let comboStep =
                (max(1, hitNumber) - 1) % 3

            switch comboStep {
            case 0:
                return .attack1

            case 1:
                return .attack2

            default:
                return .attack3
            }
        }
    }

    // MARK: - Damage

    static func damage(
        forHitNumber hitNumber: Int
    ) -> Int {
        attackKind(
            forHitNumber: hitNumber
        ).damage
    }

    static func makeDamageEvent(
        from resolution: CombatResolution
    ) -> DamageEvent {
        DamageEvent(
            amount: resolution.damage,
            attackKind: resolution.attackKind
        )
    }

    // MARK: - Attack timing

    static func attackDuration(
        for kind: AttackKind
    ) -> Double {
        switch kind {
        case .normal:
            return 0.31

        case .strong:
            return 0.40

        case .critical:
            return 0.50
        }
    }

    // Damage is applied at the sword contact frame,
    // not immediately when the screen is tapped.

    static func contactDelay(
        for kind: AttackKind
    ) -> Double {
        switch kind {
        case .normal:
            return 0.15

        case .strong:
            return 0.22

        case .critical:
            return 0.27
        }
    }

    // MARK: - Camera impact

    static func sceneShake(
        for kind: AttackKind
    ) -> Int {
        switch kind {
        case .normal:
            return 0

        case .strong:
            return 2

        case .critical:
            return 3
        }
    }

    // MARK: - Helpers

    static func isStrongHit(
        _ hitNumber: Int
    ) -> Bool {
        attackKind(
            forHitNumber: hitNumber
        ) == .strong
    }

    static func isCriticalHit(
        _ hitNumber: Int
    ) -> Bool {
        attackKind(
            forHitNumber: hitNumber
        ) == .critical
    }
}
