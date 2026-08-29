import Foundation
import Combine

// MARK: - Hunter runtime state

enum HunterCombatState: Equatable {
    case idle
    case attacking(HunterAttackAnimation)
    case returning
}

// MARK: - Hunter Controller

@MainActor
final class HunterController: ObservableObject {

    // MARK: - Published state

    @Published private(set) var state: HunterCombatState = .idle
    @Published private(set) var currentResolution: CombatResolution?

    @Published private(set) var eyeFlareActive = false
    @Published private(set) var hasBufferedAttack = false

    // MARK: - Dependencies

    private let gameState: GameState

    // MARK: - Attack timing

    private var attackElapsed: Double = 0
    private var returnElapsed: Double = 0

    private var contactApplied = false

    // Only one next attack can be buffered.
    // This prevents a huge attack queue.
    private var bufferedAttack = false

    // If the player stops tapping,
    // Hunter settles back into calm idle.
    private let returnToIdleDelay: Double = 0.50

    // MARK: - Scene callbacks

    var onAttackStarted: ((CombatResolution) -> Void)?
    var onSwordContact: ((CombatResolution) -> Void)?
    var onAttackFinished: ((CombatResolution) -> Void)?
    var onReturnedToIdle: (() -> Void)?

    // MARK: - Init

    init(
        gameState: GameState
    ) {
        self.gameState = gameState
    }

    // MARK: - Input

    @discardableResult
    func handleAttackInput() -> Bool {
        guard gameState.canAttack else {
            return false
        }

        if !gameState.tutorialCompleted {
            gameState.completeTutorial()
        }

        switch state {

        case .idle:
            beginNextAttack()
            return true

        case .returning:
            beginNextAttack()
            return true

        case .attacking:
            return bufferNextAttack()
        }
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

        switch state {

        case .idle:
            break

        case .attacking:
            updateAttack(
                deltaTime: deltaTime
            )

        case .returning:
            updateReturn(
                deltaTime: deltaTime
            )
        }
    }

    // MARK: - Begin attack

    private func beginNextAttack() {
        guard gameState.canAttack else {
            clearBufferedAttack()
            return
        }

        let hitNumber =
            gameState.registerAttackInput()

        let resolution =
            CombatResolver.resolution(
                forHitNumber: hitNumber
            )

        currentResolution =
            resolution

        state =
            .attacking(
                resolution.animation
            )

        attackElapsed = 0
        returnElapsed = 0

        contactApplied = false

        clearBufferedAttack()

        eyeFlareActive =
            resolution.isCritical

        onAttackStarted?(
            resolution
        )
    }

    // MARK: - Attack update

    private func updateAttack(
        deltaTime: Double
    ) {
        guard let resolution =
                currentResolution else {
            resetVisualState()
            return
        }

        attackElapsed += deltaTime

        // Damage happens only when
        // the sword reaches the contact frame.

        if !contactApplied,
           attackElapsed >= resolution.contactDelay {

            applyContact(
                resolution
            )
        }

        if attackElapsed
            >= resolution.attackDuration {

            finishAttack(
                resolution
            )
        }
    }

    // MARK: - Sword contact

    private func applyContact(
        _ resolution: CombatResolution
    ) {
        guard !contactApplied else {
            return
        }

        contactApplied = true

        guard gameState.canAttack else {
            return
        }

        let damageEvent =
            CombatResolver.makeDamageEvent(
                from: resolution
            )

        gameState.applyDamage(
            damageEvent
        )

        onSwordContact?(
            resolution
        )
    }

    // MARK: - Finish attack

    private func finishAttack(
        _ resolution: CombatResolution
    ) {
        onAttackFinished?(
            resolution
        )

        eyeFlareActive = false

        attackElapsed = 0
        contactApplied = false

        // If the enemy died on contact,
        // never attack the next enemy automatically.

        guard gameState.canAttack else {
            clearBufferedAttack()

            currentResolution = nil
            state = .returning
            returnElapsed = 0

            return
        }

        // One buffered tap immediately
        // continues the attack chain.

        if bufferedAttack {
            clearBufferedAttack()

            beginNextAttack()

            return
        }

        currentResolution = nil

        state = .returning

        returnElapsed = 0
    }

    // MARK: - Input buffer

    @discardableResult
    private func bufferNextAttack() -> Bool {
        guard !bufferedAttack else {
            return false
        }

        bufferedAttack = true
        hasBufferedAttack = true

        return true
    }

    private func clearBufferedAttack() {
        bufferedAttack = false
        hasBufferedAttack = false
    }

    // MARK: - Return to idle

    private func updateReturn(
        deltaTime: Double
    ) {
        // A new tap is handled immediately
        // by handleAttackInput(),
        // so this timer only runs while
        // the player is not attacking.

        returnElapsed += deltaTime

        if returnElapsed
            >= returnToIdleDelay {

            state = .idle

            returnElapsed = 0

            currentResolution = nil
            eyeFlareActive = false

            onReturnedToIdle?()
        }
    }

    // MARK: - Encounter transitions

    func prepareForEnemySpawn() {
        resetVisualState()
    }

    func prepareForBossIntro() {
        resetVisualState()
    }

    func prepareForCycleTransition() {
        resetVisualState()
    }

    // MARK: - Pause

    func pause() {
        eyeFlareActive = false
    }

    func resume() {
        // Timers continue from the exact
        // point where the game was paused.
    }

    // MARK: - Reset visual combat state

    func resetVisualState() {
        state = .idle

        currentResolution = nil

        attackElapsed = 0
        returnElapsed = 0

        contactApplied = false

        eyeFlareActive = false

        clearBufferedAttack()
    }

    // MARK: - Animation helpers

    var isAttacking: Bool {
        if case .attacking = state {
            return true
        }

        return false
    }

    var currentAnimation: HunterAttackAnimation? {
        if case let .attacking(animation) = state {
            return animation
        }

        return nil
    }

    var attackProgress: Double {
        guard let resolution =
                currentResolution,
              resolution.attackDuration > 0 else {
            return 0
        }

        return min(
            1,
            max(
                0,
                attackElapsed
                    / resolution.attackDuration
            )
        )
    }

    var contactProgress: Double {
        guard let resolution =
                currentResolution,
              resolution.contactDelay > 0 else {
            return 0
        }

        return min(
            1,
            max(
                0,
                attackElapsed
                    / resolution.contactDelay
            )
        )
    }

    // MARK: - Debug / safety

    func forceIdle() {
        resetVisualState()
    }
}
