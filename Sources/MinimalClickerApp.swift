import SwiftUI
import UIKit
import AVFoundation
import Combine

@main
struct MinimalClickerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private enum Theme {
    static let background = Color(red: 0.035, green: 0.035, blue: 0.050)
    static let panel = Color(red: 0.075, green: 0.075, blue: 0.100)
    static let stone = Color(red: 0.090, green: 0.090, blue: 0.115)
    static let stoneLight = Color(red: 0.145, green: 0.145, blue: 0.175)
    static let silver = Color(red: 0.37, green: 0.39, blue: 0.43)
    static let silverHighlight = Color(red: 0.76, green: 0.77, blue: 0.81)
    static let text = Color(red: 0.86, green: 0.86, blue: 0.90)
    static let secondaryText = Color(red: 0.52, green: 0.52, blue: 0.58)
    static let purple = Color(red: 0.49, green: 0.23, blue: 0.93)
    static let purpleDeep = Color(red: 0.30, green: 0.11, blue: 0.58)
}

final class AudioManager: ObservableObject {
    private var players: [String: AVAudioPlayer] = [:]
    private var ambientPlayer: AVAudioPlayer?

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Если звук не запустится, сама игра всё равно будет работать.
        }
    }

    func startAmbient() {
        guard ambientPlayer == nil else {
            ambientPlayer?.play()
            return
        }

        guard let url = Bundle.main.url(
            forResource: "ambient_dark_fantasy_loop",
            withExtension: "wav"
        ) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.12
            player.prepareToPlay()
            player.play()
            ambientPlayer = player
        } catch { }
    }

    func pauseAmbient() {
        ambientPlayer?.pause()
    }

    func playRune() {
        playEffect(
            name: "rune_tap_ancient_metal",
            volume: 0.46
        )
    }

    func playCard() {
        playEffect(
            name: "card_press_metal",
            volume: 0.34
        )
    }

    func playMenuOpen() {
        playEffect(
            name: "menu_open_magic",
            volume: 0.28
        )
    }

    func playMenuClose() {
        playEffect(
            name: "menu_close_magic",
            volume: 0.26
        )
    }

    private func playEffect(name: String, volume: Float) {
        if let cached = players[name] {
            cached.stop()
            cached.currentTime = 0
            cached.volume = volume
            cached.play()
            return
        }

        guard let url = Bundle.main.url(
            forResource: name,
            withExtension: "wav"
        ) else { return }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            players[name] = player
            player.play()
        } catch { }
    }
}

struct ContentView: View {
    @AppStorage("coins") private var coins: Int = 0
    @StateObject private var audio = AudioManager()
    @Environment(\.scenePhase) private var scenePhase

    @State private var runeFlash = false
    @State private var counterPulse = false
    @State private var gains: [GainEvent] = []
    @State private var modalTitle: String?
    @State private var introVisible = false

    var body: some View {
        ZStack {
            FogBackground()

            GeometryReader { proxy in
                let runeSize = min(
                    280.0,
                    proxy.size.width * 0.69
                )

                VStack(spacing: 0) {
                    CoinPanel(
                        coins: coins,
                        pulsing: counterPulse
                    )
                    .padding(.top, 18)
                    .opacity(introVisible ? 1 : 0)
                    .offset(y: introVisible ? 0 : -18)

                    Spacer(minLength: 22)

                    ZStack {
                        ForEach(gains) { gain in
                            FloatingGainView()
                                .id(gain.id)
                        }

                        RuneButton(
                            size: runeSize,
                            flash: runeFlash
                        ) {
                            runeTapped()
                        }
                    }
                    .opacity(introVisible ? 1 : 0)
                    .scaleEffect(introVisible ? 1 : 0.92)

                    VStack(spacing: 5) {
                        Text("КОСНИСЬ РУНЫ")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold,
                                    design: .serif
                                )
