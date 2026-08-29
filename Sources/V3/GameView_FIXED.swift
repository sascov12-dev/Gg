import SwiftUI
import SpriteKit
import Combine
import UIKit

// MARK: - Game launch mode

enum GameLaunchMode {
    case newGame
    case continueGame
}

// MARK: - Game Session

@MainActor
final class GameSession: ObservableObject {

    let gameState: GameState
    let hunterController: HunterController
    let enemyController: EnemyController
    let encounterDirector: EncounterDirector
    let combatScene: CombatScene

    private let audioManager: AudioManager
    private let saveManager: SaveManager

    private let launchMode: GameLaunchMode

    private var cancellables:
        Set<AnyCancellable> = []

    private var hasStartedScene = false

    // MARK: - Init

    init(
        mode: GameLaunchMode
    ) {
        self.launchMode = mode
        self.audioManager = .shared
        self.saveManager = .shared

        let initialProgress: GameProgress

        switch mode {

        case .newGame:
            initialProgress = .fresh

        case .continueGame:
            initialProgress =
                SaveManager.shared.load()
                ?? .fresh
        }

        let state =
            GameState(
                progress: initialProgress
            )

        let hunter =
            HunterController(
                gameState: state
            )

        let enemy =
            EnemyController(
                gameState: state
            )

        let director =
            EncounterDirector(
                gameState: state,
                hunterController: hunter,
                enemyController: enemy
            )

        let scene =
            CombatScene(
                size:
                    UIScreen.main.bounds.size,
                gameState: state,
                hunterController: hunter,
                enemyController: enemy,
                encounterDirector: director,
                audioManager:
                    AudioManager.shared
            )

        self.gameState = state
        self.hunterController = hunter
        self.enemyController = enemy
        self.encounterDirector = director
        self.combatScene = scene

        director.onProgressShouldSave = {
            progress in

            _ = SaveManager.shared.save(
                progress
            )
        }

        state.objectWillChange
            .sink {
                [weak self] _ in

                self?.objectWillChange.send()
            }
            .store(
                in: &cancellables
            )

        audioManager.applySettings(
            from: state.snapshot
        )
    }

    // MARK: - Start

    func startIfNeeded() {
        guard !hasStartedScene else {
            return
        }

        hasStartedScene = true

        switch launchMode {

        case .newGame:
            combatScene.startNewGame()

        case .continueGame:
            if gameState.hasStartedGame {
                combatScene.continueGame()
            } else {
                combatScene.startNewGame()
            }
        }

        installCursedForestWhenReady()
    }

    // MARK: - Cursed Forest

    private func installCursedForestWhenReady(
        attempt: Int = 0
    ) {
        let expectedLayerZ: Set<Int> = [
            -100, -80, -60, -30,
            10, 40, 70
        ]

        let worldIsReady =
            combatScene.children.contains { node in
                let zValues =
                    Set(
                        node.children.map {
                            Int($0.zPosition)
                        }
                    )

                return expectedLayerZ
                    .isSubset(
                        of: zValues
                    )
            }

        if worldIsReady {
            CursedForestEnvironment.install(
                on: combatScene
            )
            return
        }

        guard attempt < 120 else {
            return
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.05
        ) {
            [weak self] in

            self?.installCursedForestWhenReady(
                attempt: attempt + 1
            )
        }
    }

    // MARK: - Pause

    func pause() {
        guard !combatScene.isPaused else {
            return
        }

        combatScene.pauseFromUI()
    }

    func resume() {
        guard combatScene.isPaused else {
            return
        }

        combatScene.resumeFromUI()
    }

    // MARK: - Settings

    func toggleMusic() {
        gameState.toggleMusic()

        audioManager.setMusicEnabled(
            gameState.musicEnabled
        )

        audioManager.playToggle(
            enabled:
                gameState.musicEnabled
        )

        saveNow()
    }

    func toggleSFX() {
        gameState.toggleSFX()

        audioManager.setSFXEnabled(
            gameState.sfxEnabled
        )

        if gameState.sfxEnabled {
            audioManager.playToggle(
                enabled: true
            )
        }

        saveNow()
    }

    // MARK: - Coming soon

    func playComingSoon() {
        audioManager.playComingSoon()
    }

    // MARK: - Main menu

    func prepareForMainMenu() {
        saveNow()

        combatScene
            .prepareForMainMenu()
    }

    // MARK: - Save

    func saveNow() {
        guard gameState.hasStartedGame else {
            return
        }

        _ = saveManager.save(
            gameState.snapshot
        )
    }

    // MARK: - App lifecycle

    func applicationDidEnterBackground() {
        combatScene
            .applicationDidEnterBackground()

        saveNow()
    }

    func applicationDidBecomeActive() {
        combatScene
            .applicationDidBecomeActive()
    }
}

// MARK: - Game View

struct GameView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @StateObject
    private var session: GameSession

    @State
    private var showPause = false

    @State
    private var showComingSoon = false

    @State
    private var comingSoonTitle = ""

    private let onExitToMenu: () -> Void

    // MARK: - Init

    init(
        mode: GameLaunchMode,
        onExitToMenu:
            @escaping () -> Void
    ) {
        _session =
            StateObject(
                wrappedValue:
                    GameSession(
                        mode: mode
                    )
            )

        self.onExitToMenu =
            onExitToMenu
    }

    // MARK: - Body

    var body: some View {
        ZStack {

            SpriteView(
                scene:
                    session.combatScene
            )
            .ignoresSafeArea()

            darkEdgeOverlay
                .allowsHitTesting(false)

            gameHUD

            if showPause {
                pauseOverlay
                    .transition(
                        .opacity
                        .combined(
                            with:
                                .scale(
                                    scale: 0.97
                                )
                        )
                    )
                    .zIndex(100)
            }

            if showComingSoon {
                comingSoonOverlay
                    .transition(
                        .opacity
                        .combined(
                            with:
                                .scale(
                                    scale: 0.96
                                )
                        )
                    )
                    .zIndex(110)
            }
        }
        .background(
            Color.black
        )
        .statusBar(
            hidden: true
        )
        .onAppear {
            session.startIfNeeded()
        }
        .onChange(
            of: scenePhase
        ) {
            phase in

            switch phase {

            case .background:
                session
                    .applicationDidEnterBackground()

            case .active:
                session
                    .applicationDidBecomeActive()

            default:
                break
            }
        }
    }

    // MARK: - Vignette

    private var darkEdgeOverlay:
        some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color.black.opacity(0.44),
                    Color.clear,
                    Color.black.opacity(0.16)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.30),
                    Color.clear,
                    Color.black.opacity(0.30)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - HUD

    private var gameHUD:
        some View {

        VStack(
            spacing: 0
        ) {

            topHUD

            enemyHUD
                .padding(
                    .top,
                    10
                )

            Spacer()

            tutorialView

            Spacer()

            bottomHUD
        }
        .padding(
            .horizontal,
            14
        )
        .padding(
            .top,
            8
        )
        .padding(
            .bottom,
            10
        )
    }

    // MARK: - Top HUD

    private var topHUD:
        some View {

        HStack(
            alignment: .top
        ) {

            coinCounter

            Spacer()

            cycleCounter

            Spacer()

            settingsButton
        }
        .frame(
            minHeight: 54
        )
    }

    private var coinCounter:
        some View {

        HStack(
            spacing: 7
        ) {

            ZStack {
                Circle()
                    .fill(
                        Color(
                            red: 0.66,
                            green: 0.53,
                            blue: 0.25
                        )
                    )
                    .frame(
                        width: 25,
                        height: 25
                    )

                Circle()
                    .stroke(
                        Color(
                            red: 0.81,
                            green: 0.70,
                            blue: 0.38
                        ),
                        lineWidth: 2
                    )
                    .frame(
                        width: 19,
                        height: 19
                    )

                Text("◆")
                    .font(
                        .system(
                            size: 9,
                            weight: .black,
                            design: .serif
                        )
                    )
                    .foregroundColor(
                        Color.black
                            .opacity(0.65)
                    )
            }

            Text(
                "\(session.gameState.coins)"
            )
            .font(
                .system(
                    size: 20,
                    weight: .bold,
                    design: .serif
                )
            )
            .monospacedDigit()
            .foregroundColor(
                Color(
                    red: 0.87,
                    green: 0.82,
                    blue: 0.70
                )
            )
        }
        .padding(
            .horizontal,
            10
        )
        .frame(
            height: 40
        )
        .background(
            MetalPanelBackground()
        )
    }

    private var cycleCounter:
        some View {

        VStack(
            spacing: 2
        ) {

            Text(
                session.gameState
                    .cycleLabel
            )
            .font(
                .system(
                    size: 14,
                    weight: .bold,
                    design: .serif
                )
            )
            .foregroundColor(
                Color(
                    red: 0.72,
                    green: 0.77,
                    blue: 0.81
                )
            )

            Text(
                session.gameState
                    .currentEnemy.isBoss
                ? "БОСС"
                : session.gameState
                    .enemyCounterLabel
            )
            .font(
                .system(
                    size: 12,
                    weight: .semibold,
                    design: .serif
                )
            )
            .foregroundColor(
                session.gameState
                    .currentEnemy.isBoss
                ? Color(
                    red: 0.80,
                    green: 0.24,
                    blue: 0.22
                )
                : Color.white
                    .opacity(0.62)
            )
        }
        .padding(
            .horizontal,
            14
        )
        .frame(
            height: 40
        )
        .background(
            MetalPanelBackground()
        )
    }

    private var settingsButton:
        some View {

        Button {
            guard !showPause,
                  !showComingSoon else {
                return
            }

            session.pause()

            withAnimation(
                .easeOut(
                    duration: 0.18
                )
            ) {
                showPause = true
            }
        } label: {

            Image(
                systemName:
                    "gearshape.fill"
            )
            .font(
                .system(
                    size: 19,
                    weight: .semibold
                )
            )
            .foregroundColor(
                Color(
                    red: 0.72,
                    green: 0.77,
                    blue: 0.81
                )
            )
            .frame(
                width: 42,
                height: 40
            )
            .background(
                MetalPanelBackground()
            )
        }
        .buttonStyle(
            PressOnlyButtonStyle()
        )
    }

    // MARK: - Enemy HUD

    private var enemyHUD:
        some View {

        EnemyHealthBarView(
            name:
                session.gameState
                    .currentEnemy
                    .displayName,
            currentHP:
                session.gameState
                    .currentEnemyHP,
            maximumHP:
                session.gameState
                    .currentEnemyMaxHP,
            isBoss:
                session.gameState
                    .currentEnemy
                    .isBoss,
            bossPhase:
                session.gameState
                    .bossVisualPhase
        )
    }

    // MARK: - Tutorial

    @ViewBuilder
    private var tutorialView:
        some View {

        if session.gameState
            .hasStartedGame,
           !session.gameState
            .tutorialCompleted,
           session.gameState
            .combatPhase == .fighting {

            Text(
                "КОСНИСЬ ЭКРАНА, ЧТОБЫ АТАКОВАТЬ"
            )
            .font(
                .system(
                    size: 15,
                    weight: .bold,
                    design: .serif
                )
            )
            .multilineTextAlignment(
                .center
            )
            .foregroundColor(
                Color.white
                    .opacity(0.86)
            )
            .padding(
                .horizontal,
                16
            )
            .padding(
                .vertical,
                9
            )
            .background(
                Color.black
                    .opacity(0.48)
            )
            .overlay(
                Rectangle()
                    .stroke(
                        Color.white
                            .opacity(0.12),
                        lineWidth: 1
                    )
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: - Bottom HUD

    private var bottomHUD:
        some View {

        HStack(
            spacing: 10
        ) {

            featureButton(
                title:
                    "УЛУЧШЕНИЯ"
            )

            featureButton(
                title:
                    "СПУТНИК"
            )
        }
        .padding(
            .bottom,
            2
        )
    }

    private func featureButton(
        title: String
    ) -> some View {

        Button {

            guard !showPause,
                  !showComingSoon else {
                return
            }

            comingSoonTitle =
                title

            session
                .playComingSoon()

            session.pause()

            withAnimation(
                .easeOut(
                    duration: 0.18
                )
            ) {
                showComingSoon = true
            }

        } label: {

            Text(
                title
            )
            .font(
                .system(
                    size: 15,
                    weight: .bold,
                    design: .serif
                )
            )
            .kerning(0.6)
            .frame(
                maxWidth: .infinity
            )
            .frame(
                height: 48
            )
        }
        .buttonStyle(
            DarkMetalButtonStyle()
        )
    }

    // MARK: - Pause Overlay

    private var pauseOverlay:
        some View {

        ZStack {

            Color.black
                .opacity(0.72)
                .ignoresSafeArea()

            VStack(
                spacing: 13
            ) {

                Text(
                    "ПАУЗА"
                )
                .font(
                    .system(
                        size: 31,
                        weight: .black,
                        design: .serif
                    )
                )
                .kerning(1.4)
                .foregroundColor(
                    Color(
                        red: 0.78,
                        green: 0.82,
                        blue: 0.85
                    )
                )
                .padding(
                    .bottom,
                    7
                )

                settingsToggleButton(
                    title: "МУЗЫКА",
                    enabled:
                        session.gameState
                            .musicEnabled
                ) {
                    session.toggleMusic()
                }

                settingsToggleButton(
                    title: "ЗВУКИ",
                    enabled:
                        session.gameState
                            .sfxEnabled
                ) {
                    session.toggleSFX()
                }

                Button {

                    withAnimation(
                        .easeOut(
                            duration: 0.16
                        )
                    ) {
                        showPause = false
                    }

                    session.resume()

                } label: {

                    Text(
                        "ПРОДОЛЖИТЬ"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(
                        height: 48
                    )
                }
                .buttonStyle(
                    DarkMetalButtonStyle(
                        emphasized: true
                    )
                )
                .padding(
                    .top,
                    6
                )

                Button {

                    session
                        .prepareForMainMenu()

                    showPause = false

                    onExitToMenu()

                } label: {

                    Text(
                        "ВЫЙТИ В ГЛАВНОЕ МЕНЮ"
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .bold,
                            design: .serif
                        )
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(
                        height: 46
                    )
                }
                .buttonStyle(
                    DarkMetalButtonStyle()
                )
            }
            .padding(
                .horizontal,
                22
            )
            .padding(
                .vertical,
                26
            )
            .frame(
                maxWidth: 330
            )
            .background(
                pausePanelBackground
            )
            .padding(
                .horizontal,
                24
            )
        }
    }

    private func settingsToggleButton(
        title: String,
        enabled: Bool,
        action:
            @escaping () -> Void
    ) -> some View {

        Button(
            action: action
        ) {

            HStack {

                Text(
                    title
                )

                Spacer()

                Text(
                    enabled
                    ? "ВКЛ"
                    : "ВЫКЛ"
                )
                .foregroundColor(
                    enabled
                    ? Color(
                        red: 0.42,
                        green: 0.82,
                        blue: 0.52
                    )
                    : Color(
                        red: 0.68,
                        green: 0.33,
                        blue: 0.31
                    )
                )
            }
            .font(
                .system(
                    size: 15,
                    weight: .bold,
                    design: .serif
                )
            )
            .padding(
                .horizontal,
                15
            )
            .frame(
                height: 46
            )
        }
        .buttonStyle(
            DarkMetalButtonStyle()
        )
    }

    private var pausePanelBackground:
        some View {

        Rectangle()
            .fill(
                Color(
                    red: 0.045,
                    green: 0.05,
                    blue: 0.058
                )
                .opacity(0.97)
            )
            .overlay(
                Rectangle()
                    .stroke(
                        Color(
                            red: 0.39,
                            green: 0.43,
                            blue: 0.46
                        )
                        .opacity(0.75),
                        lineWidth: 1
                    )
            )
            .overlay(
                Rectangle()
                    .stroke(
                        Color.black
                            .opacity(0.85),
                        lineWidth: 5
                    )
                    .padding(4)
            )
            .shadow(
                color:
                    Color.black
                    .opacity(0.8),
                radius: 20
            )
    }

    // MARK: - Coming Soon

    private var comingSoonOverlay:
        some View {

        ZStack {

            Color.black
                .opacity(0.66)
                .ignoresSafeArea()
                .onTapGesture {
                    closeComingSoon()
                }

            VStack(
                spacing: 10
            ) {

                if !comingSoonTitle.isEmpty {
                    Text(
                        comingSoonTitle
                    )
                    .font(
                        .system(
                            size: 12,
                            weight: .bold,
                            design: .serif
                        )
                    )
                    .kerning(0.8)
                    .foregroundColor(
                        Color.white
                            .opacity(0.44)
                    )
                }

                Text(
                    "СКОРО"
                )
                .font(
                    .system(
                        size: 32,
                        weight: .black,
                        design: .serif
                    )
                )
                .kerning(1.5)
                .foregroundColor(
                    Color(
                        red: 0.77,
                        green: 0.81,
                        blue: 0.84
                    )
                )

                Text(
                    "Функция появится позже"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .medium,
                        design: .serif
                    )
                )
                .foregroundColor(
                    Color.white
                        .opacity(0.63)
                )
                .padding(
                    .bottom,
                    9
                )

                Button {

                    closeComingSoon()

                } label: {

                    Text(
                        "ЗАКРЫТЬ"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(
                        height: 44
                    )
                }
                .buttonStyle(
                    DarkMetalButtonStyle()
                )
            }
            .padding(
                22
            )
            .frame(
                maxWidth: 300
            )
            .background(
                pausePanelBackground
            )
            .padding(
                .horizontal,
                30
            )
        }
    }

    private func closeComingSoon() {
        withAnimation(
            .easeOut(
                duration: 0.16
            )
        ) {
            showComingSoon = false
        }

        session.resume()
    }
}

// MARK: - Enemy Health Bar

private struct EnemyHealthBarView: View {

    let name: String

    let currentHP: Int
    let maximumHP: Int

    let isBoss: Bool
    let bossPhase: BossVisualPhase

    @State
    private var trailingRatio:
        CGFloat = 1

    private var healthRatio:
        CGFloat {

        guard maximumHP > 0 else {
            return 0
        }

        return min(
            1,
            max(
                0,
                CGFloat(currentHP)
                / CGFloat(maximumHP)
            )
        )
    }

    var body: some View {

        VStack(
            spacing: 5
        ) {

            HStack {

                Text(
                    name
                )
                .font(
                    .system(
                        size:
                            isBoss
                            ? 15
                            : 13,
                        weight: .bold,
                        design: .serif
                    )
                )
                .kerning(
                    isBoss
                    ? 0.7
                    : 0.3
                )
                .foregroundColor(
                    isBoss
                    ? bossNameColor
                    : Color.white
                        .opacity(0.82)
                )

                Spacer()

                Text(
                    "\(currentHP) / \(maximumHP)"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold,
                        design: .monospaced
                    )
                )
                .monospacedDigit()
                .foregroundColor(
                    Color.white
                        .opacity(0.62)
                )
            }

            GeometryReader {
                geometry in

                ZStack(
                    alignment: .leading
                ) {

                    Rectangle()
                        .fill(
                            Color.black
                                .opacity(0.82)
                        )

                    Rectangle()
                        .fill(
                            Color(
                                red: 0.60,
                                green: 0.55,
                                blue: 0.47
                            )
                            .opacity(0.42)
                        )
                        .frame(
                            width:
                                geometry.size.width
                                * trailingRatio
                        )

                    Rectangle()
                        .fill(
                            healthColor
                        )
                        .frame(
                            width:
                                geometry.size.width
                                * healthRatio
                        )
                        .animation(
                            .linear(
                                duration: 0.06
                            ),
                            value:
                                healthRatio
                        )
                }
                .overlay(
                    Rectangle()
                        .stroke(
                            isBoss
                            ? Color(
                                red: 0.47,
                                green: 0.17,
                                blue: 0.16
                            )
                            : Color(
                                red: 0.35,
                                green: 0.39,
                                blue: 0.42
                            ),
                            lineWidth:
                                isBoss
                                ? 2
                                : 1
                        )
                )
            }
            .frame(
                height:
                    isBoss
                    ? 17
                    : 13
            )
        }
        .padding(
            .horizontal,
            isBoss
            ? 11
            : 9
        )
        .padding(
            .vertical,
            isBoss
            ? 9
            : 7
        )
        .background(
            Color(
                red: 0.03,
                green: 0.033,
                blue: 0.038
            )
            .opacity(0.84)
        )
        .overlay(
            Rectangle()
                .stroke(
                    Color.white
                        .opacity(
                            isBoss
                            ? 0.14
                            : 0.08
                        ),
                    lineWidth: 1
                )
        )
        .onAppear {
            trailingRatio =
                healthRatio
        }
        .onChange(
            of: healthRatio
        ) {
            newRatio in

            withAnimation(
                .easeOut(
                    duration: 0.24
                )
            ) {
                trailingRatio =
                    newRatio
            }
        }
    }

    private var healthColor:
        Color {

        if isBoss {
            switch bossPhase {

            case .calm:
                return Color(
                    red: 0.58,
                    green: 0.13,
                    blue: 0.13
                )

            case .angry:
                return Color(
                    red: 0.70,
                    green: 0.13,
                    blue: 0.12
                )

            case .enraged:
                return Color(
                    red: 0.83,
                    green: 0.18,
                    blue: 0.16
                )
            }
        }

        return Color(
            red: 0.45,
            green: 0.12,
            blue: 0.12
        )
    }

    private var bossNameColor:
        Color {

        switch bossPhase {

        case .calm:
            return Color(
                red: 0.76,
                green: 0.70,
                blue: 0.67
            )

        case .angry:
            return Color(
                red: 0.84,
                green: 0.52,
                blue: 0.45
            )

        case .enraged:
            return Color(
                red: 0.94,
                green: 0.40,
                blue: 0.32
            )
        }
    }
}

// MARK: - Metal Panel

private struct MetalPanelBackground: View {

    var body: some View {

        Rectangle()
            .fill(
                Color(
                    red: 0.035,
                    green: 0.04,
                    blue: 0.047
                )
                .opacity(0.86)
            )
            .overlay(
                Rectangle()
                    .stroke(
                        Color(
                            red: 0.33,
                            green: 0.37,
                            blue: 0.40
                        )
                        .opacity(0.65),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Button Style

private struct DarkMetalButtonStyle:
    ButtonStyle {

    var emphasized = false

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .font(
                .system(
                    size: 15,
                    weight: .bold,
                    design: .serif
                )
            )
            .foregroundColor(
                emphasized
                ? Color(
                    red: 0.86,
                    green: 0.89,
                    blue: 0.91
                )
                : Color(
                    red: 0.72,
                    green: 0.76,
                    blue: 0.79
                )
            )
            .background(
                Rectangle()
                    .fill(
                        configuration
                            .isPressed
                        ? Color(
                            red: 0.095,
                            green: 0.105,
                            blue: 0.115
                        )
                        : Color(
                            red: 0.045,
                            green: 0.05,
                            blue: 0.058
                        )
                    )
            )
            .overlay(
                Rectangle()
                    .stroke(
                        emphasized
                        ? Color(
                            red: 0.46,
                            green: 0.51,
                            blue: 0.55
                        )
                        : Color(
                            red: 0.28,
                            green: 0.31,
                            blue: 0.34
                        ),
                        lineWidth:
                            emphasized
                            ? 2
                            : 1
                    )
            )
            .scaleEffect(
                configuration.isPressed
                ? 0.985
                : 1
            )
    }
}

private struct PressOnlyButtonStyle:
    ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .scaleEffect(
                configuration.isPressed
                ? 0.94
                : 1
            )
            .opacity(
                configuration.isPressed
                ? 0.72
                : 1
            )
    }
}
