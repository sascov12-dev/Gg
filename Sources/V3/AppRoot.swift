import SwiftUI

// MARK: - Root screen

private enum RootScreen {
    case menu
    case game(GameLaunchMode)
}

// MARK: - App Root

struct AppRootView: View {

    @Environment(\.scenePhase)
    private var scenePhase

    @State
    private var screen: RootScreen = .menu

    @State
    private var gameSessionID = UUID()

    @State
    private var transitionOverlayVisible = false

    var body: some View {

        ZStack {

            switch screen {

            case .menu:

                MainMenuView(
                    onStartNewGame: {
                        openGame(
                            mode: .newGame
                        )
                    },
                    onContinueGame: {
                        openGame(
                            mode: .continueGame
                        )
                    }
                )
                .transition(
                    .opacity
                )

            case .game(
                let mode
            ):

                GameView(
                    mode: mode,
                    onExitToMenu: {
                        returnToMenu()
                    }
                )
                .id(
                    gameSessionID
                )
                .transition(
                    .opacity
                )
            }

            if transitionOverlayVisible {

                Color.black
                    .ignoresSafeArea()
                    .transition(
                        .opacity
                    )
                    .zIndex(1000)
            }
        }
        .background(
            Color.black
        )
        .preferredColorScheme(
            .dark
        )
        .onChange(
            of: scenePhase
        ) {
            phase in

            switch phase {

            case .background:

                AudioManager.shared
                    .applicationDidEnterBackground()

            case .active:

                AudioManager.shared
                    .applicationDidBecomeActive()

            default:
                break
            }
        }
    }

    // MARK: - Open game

    private func openGame(
        mode: GameLaunchMode
    ) {

        guard !transitionOverlayVisible else {
            return
        }

        withAnimation(
            .easeIn(
                duration: 0.22
            )
        ) {
            transitionOverlayVisible = true
        }

        DispatchQueue.main
            .asyncAfter(
                deadline:
                    .now() + 0.24
            ) {

                gameSessionID = UUID()

                screen =
                    .game(
                        mode
                    )

                DispatchQueue.main
                    .asyncAfter(
                        deadline:
                            .now() + 0.18
                    ) {

                        withAnimation(
                            .easeOut(
                                duration: 0.42
                            )
                        ) {
                            transitionOverlayVisible = false
                        }
                    }
            }
    }

    // MARK: - Return to menu

    private func returnToMenu() {

        guard !transitionOverlayVisible else {
            return
        }

        withAnimation(
            .easeIn(
                duration: 0.18
            )
        ) {
            transitionOverlayVisible = true
        }

        DispatchQueue.main
            .asyncAfter(
                deadline:
                    .now() + 0.20
            ) {

                screen = .menu

                DispatchQueue.main
                    .asyncAfter(
                        deadline:
                            .now() + 0.14
                    ) {

                        withAnimation(
                            .easeOut(
                                duration: 0.34
                            )
                        ) {
                            transitionOverlayVisible = false
                        }
                    }
            }
    }
}

// MARK: - Application entry point

@main
struct TheLastHunterApp: App {

    init() {

        let musicEnabled =
            AppSettingsStore
                .musicEnabled

        let sfxEnabled =
            AppSettingsStore
                .sfxEnabled

        AudioManager.shared
            .applySettings(
                musicEnabled:
                    musicEnabled,
                sfxEnabled:
                    sfxEnabled
            )
    }

    var body: some Scene {

        WindowGroup {

            AppRootView()
                .background(
                    Color.black
                )
                .ignoresSafeArea(
                    .keyboard
                )
        }
    }
}
