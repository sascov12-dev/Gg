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
        }
    }

    func startAmbient() {
        if let ambientPlayer {
            if !ambientPlayer.isPlaying {
                ambientPlayer.play()
            }
            return
        }

        guard let url = Bundle.main.url(
            forResource: "ambient_dark_fantasy_loop",
            withExtension: "wav"
        ) else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.12
            player.prepareToPlay()
            player.play()

            ambientPlayer = player
        } catch {
        }
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

    private func playEffect(
        name: String,
        volume: Float
    ) {
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
        ) else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()

            players[name] = player
            player.play()
        } catch {
        }
    }
}

struct ContentView: View {
    @AppStorage("coins")
    private var coins: Int = 0

    @StateObject
    private var audio = AudioManager()

    @Environment(\.scenePhase)
    private var scenePhase

    @State
    private var runeFlash = false

    @State
    private var counterPulse = false

    @State
    private var gains: [GainEvent] = []

    @State
    private var modalTitle: String?

    @State
    private var introVisible = false

    var body: some View {
        ZStack {
            FogBackground()

            GeometryReader { proxy in
                let runeSize = min(
                    CGFloat(280),
                    proxy.size.width * 0.69
                )

                VStack(spacing: 0) {
                    CoinPanel(
                        coins: coins,
                        pulsing: counterPulse
                    )
                    .padding(.top, 18)
                    .opacity(
                        introVisible ? 1 : 0
                    )
                    .offset(
                        y: introVisible ? 0 : -18
                    )

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
                    .opacity(
                        introVisible ? 1 : 0
                    )
                    .scaleEffect(
                        introVisible ? 1 : 0.92
                    )

                    VStack(spacing: 5) {
                        Text("КОСНИСЬ РУНЫ")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold,
                                    design: .serif
                                )
                            )
                            .tracking(1.6)
                            .foregroundColor(
                                Theme.text
                            )

                        Text("+1 ЗА КАСАНИЕ")
                            .font(
                                .system(
                                    size: 12,
                                    weight: .medium,
                                    design: .serif
                                )
                            )
                            .tracking(1.2)
                            .foregroundColor(
                                Theme.secondaryText
                            )
                    }
                    .padding(.top, 22)
                    .opacity(
                        introVisible ? 1 : 0
                    )

                    Spacer(minLength: 24)

                    HStack(spacing: 12) {
                        FeatureCard(
                            title: "УЛУЧШЕНИЯ",
                            symbol: "hammer.fill"
                        ) {
                            openComingSoon(
                                "УЛУЧШЕНИЯ"
                            )
                        }

                        FeatureCard(
                            title: "АВТОКЛИКЕР",
                            symbol: "hourglass"
                        ) {
                            openComingSoon(
                                "АВТОКЛИКЕР"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(
                        .bottom,
                        max(
                            proxy.safeAreaInsets.bottom,
                            18
                        )
                    )
                    .opacity(
                        introVisible ? 1 : 0
                    )
                    .offset(
                        y: introVisible ? 0 : 18
                    )
                }
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
            }
        }
        .preferredColorScheme(.dark)
        .overlay {
            if let modalTitle {
                ComingSoonOverlay(
                    sectionTitle: modalTitle
                ) {
                    closeComingSoon()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            audio.startAmbient()

            withAnimation(
                .easeOut(
                    duration: 0.75
                )
                .delay(0.10)
            ) {
                introVisible = true
            }
        }
        .onChange(
            of: scenePhase
        ) { phase in
            if phase == .active {
                audio.startAmbient()
            } else {
                audio.pauseAmbient()
            }
        }
    }

    private func runeTapped() {
        coins += 1

        audio.playRune()

        UIImpactFeedbackGenerator(
            style: .light
        )
        .impactOccurred()

        withAnimation(
            .easeOut(
                duration: 0.08
            )
        ) {
            runeFlash = true
            counterPulse = true
        }

        let event = GainEvent()
        gains.append(event)

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.14
        ) {
            withAnimation(
                .easeOut(
                    duration: 0.22
                )
            ) {
                runeFlash = false
                counterPulse = false
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.78
        ) {
            gains.removeAll {
                $0.id == event.id
            }
        }
    }

    private func openComingSoon(
        _ title: String
    ) {
        audio.playCard()

        UIImpactFeedbackGenerator(
            style: .soft
        )
        .impactOccurred()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.05
        ) {
            audio.playMenuOpen()
        }

        withAnimation(
            .spring(
                response: 0.32,
                dampingFraction: 0.84
            )
        ) {
            modalTitle = title
        }
    }

    private func closeComingSoon() {
        audio.playMenuClose()

        withAnimation(
            .easeInOut(
                duration: 0.20
            )
        ) {
            modalTitle = nil
        }
    }
}

private struct GainEvent: Identifiable {
    let id = UUID()
}

private struct CoinPanel: View {
    let coins: Int
    let pulsing: Bool

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.silverHighlight
                                    .opacity(0.82),

                                Theme.silver
                                    .opacity(0.72),

                                Color.black
                                    .opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(
                        width: 42,
                        height: 42
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                Theme.silverHighlight
                                    .opacity(0.55),
                                lineWidth: 1
                            )
                    }

                Text("◈")
                    .font(
                        .system(
                            size: 19,
                            weight: .bold,
                            design: .serif
                        )
                    )
                    .foregroundColor(
                        Color.black
                            .opacity(0.72)
                    )
            }

            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                Text("\(coins)")
                    .font(
                        .system(
                            size: 30,
                            weight: .semibold,
                            design: .serif
                        )
                    )
                    .foregroundColor(
                        Theme.text
                    )
                    .scaleEffect(
                        pulsing
                        ? 1.055
                        : 1
                    )

                Text("МОНЕТ")
                    .font(
                        .system(
                            size: 10,
                            weight: .semibold,
                            design: .serif
                        )
                    )
                    .tracking(2.2)
                    .foregroundColor(
                        Theme.secondaryText
                    )
            }

            Spacer(
                minLength: 0
            )
        }
        .padding(
            .horizontal,
            16
        )
        .frame(
            maxWidth: 310
        )
        .frame(
            height: 72
        )
        .background {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Theme.panel
                            .opacity(0.97),

                        Color.black
                            .opacity(0.86)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Theme.silverHighlight
                            .opacity(0.48),

                        Theme.silver
                            .opacity(0.55),

                        Theme.purpleDeep
                            .opacity(0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.15
            )
        }
        .shadow(
            color: Theme.purple
                .opacity(0.10),
            radius: 12,
            y: 5
        )
        .padding(
            .horizontal,
            24
        )
        .animation(
            .spring(
                response: 0.20,
                dampingFraction: 0.72
            ),
            value: pulsing
        )
    }
}

private struct RuneButton: View {
    let size: CGFloat
    let flash: Bool
    let action: () -> Void

    var body: some View {
        Button(
            action: action
        ) {
            ZStack {
                AncientStoneShape()
                    .fill(
                        RadialGradient(
                            colors: [
                                Theme.stoneLight,
                                Theme.stone,
                                Color.black
                                    .opacity(0.96)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: size * 0.52
                        )
                    )
                    .overlay {
                        AncientStoneShape()
                            .stroke(
                                Theme.silver
                                    .opacity(0.62),
                                lineWidth: 2.2
                            )
                    }
                    .shadow(
                        color: Color.black
                            .opacity(0.90),
                        radius: 22,
                        y: 12
                    )
                    .shadow(
                        color: Theme.purple
                            .opacity(
                                flash
                                ? 0.42
                                : 0.18
                            ),
                        radius: flash
                        ? 30
                        : 18
                    )

                AncientStoneShape()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.silverHighlight
                                    .opacity(0.84),

                                Theme.silver
                                    .opacity(0.26),

                                Theme.silverHighlight
                                    .opacity(0.54)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .padding(
                        size * 0.075
                    )

                CrackShape()
                    .stroke(
                        Theme.purple
                            .opacity(
                                flash
                                ? 0.72
                                : 0.25
                            ),
                        style: StrokeStyle(
                            lineWidth: 1.2,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .padding(
                        size * 0.13
                    )
                    .shadow(
                        color: Theme.purple
                            .opacity(
                                flash
                                ? 0.85
                                : 0.30
                            ),
                        radius: flash
                        ? 8
                        : 3
                    )

                AncientRuneGlyph()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.purple
                                    .opacity(0.95),

                                Color(
                                    red: 0.70,
                                    green: 0.53,
                                    blue: 1.0
                                ),

                                Theme.purpleDeep
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(
                            lineWidth: flash
                            ? 6.1
                            : 5.1,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .padding(
                        size * 0.22
                    )
                    .shadow(
                        color: Theme.purple
                            .opacity(
                                flash
                                ? 0.95
                                : 0.62
                            ),
                        radius: flash
                        ? 18
                        : 10
                    )

                Circle()
                    .stroke(
                        Theme.purple
                            .opacity(
                                flash
                                ? 0.72
                                : 0.18
                            ),
                        lineWidth: 1
                    )
                    .padding(
                        size * 0.18
                    )
                    .blur(
                        radius: flash
                        ? 0
                        : 0.4
                    )
            }
            .frame(
                width: size,
                height: size
            )
            .contentShape(
                Circle()
            )
        }
        .buttonStyle(
            RunePressStyle()
        )
        .accessibilityLabel(
            "Коснись руны"
        )
        .animation(
            .easeOut(
                duration: 0.14
            ),
            value: flash
        )
    }
}

private struct RunePressStyle: ButtonStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed
                ? 0.945
                : 1.0
            )
            .brightness(
                configuration.isPressed
                ? 0.055
                : 0
            )
            .animation(
                .spring(
                    response: 0.20,
                    dampingFraction: 0.68
                ),
                value: configuration.isPressed
            )
    }
}

private struct FeatureCard: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(
            action: action
        ) {
            VStack(spacing: 10) {
                Image(
                    systemName: symbol
                )
                .font(
                    .system(
                        size: 24,
                        weight: .medium
                    )
                )
                .foregroundColor(
                    Theme.silverHighlight
                )
                .shadow(
                    color: Theme.purple
                        .opacity(0.26),
                    radius: 4
                )

                Text(title)
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold,
                            design: .serif
                        )
                    )
                    .tracking(0.7)
                    .foregroundColor(
                        Theme.text
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(
                        0.72
                    )
            }
            .frame(
                maxWidth: .infinity
            )
            .frame(
                height: 96
            )
            .background {
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.stoneLight
                                .opacity(0.78),

                            Theme.panel
                                .opacity(0.96),

                            Color.black
                                .opacity(0.90)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 16,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.silverHighlight
                                .opacity(0.42),

                            Theme.silver
                                .opacity(0.46),

                            Theme.purpleDeep
                                .opacity(0.34)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.1
                )
            }
            .shadow(
                color: Theme.purple
                    .opacity(0.08),
                radius: 10,
                y: 5
            )
        }
        .buttonStyle(
            CardPressStyle()
        )
    }
}

private struct CardPressStyle: ButtonStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed
                ? 0.965
                : 1
            )
            .brightness(
                configuration.isPressed
                ? 0.08
                : 0
            )
            .animation(
                .easeOut(
                    duration: 0.11
                ),
                value: configuration.isPressed
            )
    }
}

private struct ComingSoonOverlay: View {
    let sectionTitle: String
    let close: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.68)
                .ignoresSafeArea()
                .onTapGesture {
                    close()
                }

            VStack(spacing: 13) {
                Text(sectionTitle)
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold,
                            design: .serif
                        )
                    )
                    .tracking(2)
                    .foregroundColor(
                        Theme.secondaryText
                    )

                Text("СКОРО")
                    .font(
                        .system(
                            size: 38,
                            weight: .bold,
                            design: .serif
                        )
                    )
                    .tracking(2.2)
                    .foregroundColor(
                        Theme.text
                    )
                    .shadow(
                        color: Theme.purple
                            .opacity(0.35),
                        radius: 9
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
                    Theme.secondaryText
                )

                Button(
                    action: close
                ) {
                    Text("ЗАКРЫТЬ")
                        .font(
                            .system(
                                size: 13,
                                weight: .semibold,
                                design: .serif
                            )
                        )
                        .tracking(1.5)
                        .foregroundColor(
                            Theme.text
                        )
                        .padding(
                            .horizontal,
                            26
                        )
                        .frame(
                            height: 42
                        )
                        .background {
                            Capsule()
                                .fill(
                                    Theme.panel
                                )
                        }
                        .overlay {
                            Capsule()
                                .stroke(
                                    Theme.silver
                                        .opacity(0.62),
                                    lineWidth: 1
                                )
                        }
                }
                .buttonStyle(
                    CardPressStyle()
                )
                .padding(
                    .top,
                    6
                )
            }
            .padding(
                .horizontal,
                30
            )
            .padding(
                .vertical,
                28
            )
            .frame(
                maxWidth: 330
            )
            .background {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.stoneLight
                                .opacity(0.94),

                            Theme.panel,

                            Color.black
                                .opacity(0.96)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.silverHighlight
                                .opacity(0.52),

                            Theme.silver
                                .opacity(0.54),

                            Theme.purple
                                .opacity(0.34)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.25
                )
            }
            .shadow(
                color: Theme.purple
                    .opacity(0.26),
                radius: 26
            )
            .padding(
                .horizontal,
                24
            )
            .transition(
                .scale(
                    scale: 0.94
                )
                .combined(
                    with: .opacity
                )
            )
        }
    }
}

private struct FloatingGainView: View {
    @State
    private var animate = false

    var body: some View {
        Text("+1")
            .font(
                .system(
                    size: 26,
                    weight: .bold,
                    design: .serif
                )
            )
            .foregroundColor(
                Color(
                    red: 0.69,
                    green: 0.53,
                    blue: 1.0
                )
            )
            .shadow(
                color: Theme.purple
                    .opacity(0.75),
                radius: 9
            )
            .offset(
                y: animate
                ? -176
                : -120
            )
            .scaleEffect(
                animate
                ? 1.08
                : 0.82
            )
            .opacity(
                animate
                ? 0
                : 1
            )
            .onAppear {
                withAnimation(
                    .easeOut(
                        duration: 0.72
                    )
                ) {
                    animate = true
                }
            }
    }
}

private struct FogBackground: View {
    @State
    private var driftA = false

    @State
    private var driftB = false

    @State
    private var driftC = false

    var body: some View {
        ZStack {
            Theme.background

            RadialGradient(
                colors: [
                    Theme.purpleDeep
                        .opacity(0.16),
                    Color.clear
                ],
                center: .center,
                startRadius: 10,
                endRadius: 360
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                ZStack {
                    fogBlob(
                        width: proxy.size.width * 1.15,
                        height: 190,
                        opacity: 0.20
                    )
                    .offset(
                        x: driftA
                        ? proxy.size.width * 0.24
                        : -proxy.size.width * 0.24,
                        y: proxy.size.height * 0.16
                    )

                    fogBlob(
                        width: proxy.size.width * 1.30,
                        height: 230,
                        opacity: 0.15
                    )
                    .offset(
                        x: driftB
                        ? -proxy.size.width * 0.22
                        : proxy.size.width * 0.28,
                        y: proxy.size.height * 0.46
                    )

                    fogBlob(
                        width: proxy.size.width * 1.05,
                        height: 180,
                        opacity: 0.13
                    )
                    .offset(
                        x: driftC
                        ? proxy.size.width * 0.20
                        : -proxy.size.width * 0.18,
                        y: proxy.size.height * 0.72
                    )
                }
                .onAppear {
                    withAnimation(
                        .easeInOut(
                            duration: 17
                        )
                        .repeatForever(
                            autoreverses: true
                        )
                    ) {
                        driftA = true
                    }

                    withAnimation(
                        .easeInOut(
                            duration: 22
                        )
                        .repeatForever(
                            autoreverses: true
                        )
                    ) {
                        driftB = true
                    }

                    withAnimation(
                        .easeInOut(
                            duration: 19
                        )
                        .repeatForever(
                            autoreverses: true
                        )
                    ) {
                        driftC = true
                    }
                }
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black
                        .opacity(0.38),
                    Color.clear,
                    Color.black
                        .opacity(0.44)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }

    private func fogBlob(
        width: CGFloat,
        height: CGFloat,
        opacity: Double
    ) -> some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.30,
                            green: 0.30,
                            blue: 0.36
                        )
                        .opacity(
                            opacity
                        ),

                        Theme.purpleDeep
                            .opacity(
                                opacity * 0.72
                            ),

                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(
                width: width,
                height: height
            )
            .blur(
                radius: 48
            )
    }
}

private struct AncientStoneShape: Shape {
    private let points: [CGPoint] = [
        CGPoint(x: 0.50, y: 0.01),
        CGPoint(x: 0.62, y: 0.03),
        CGPoint(x: 0.72, y: 0.07),
        CGPoint(x: 0.83, y: 0.12),
        CGPoint(x: 0.91, y: 0.21),
        CGPoint(x: 0.96, y: 0.32),
        CGPoint(x: 0.99, y: 0.44),
        CGPoint(x: 0.97, y: 0.56),
        CGPoint(x: 0.95, y: 0.69),
        CGPoint(x: 0.88, y: 0.80),
        CGPoint(x: 0.79, y: 0.89),
        CGPoint(x: 0.67, y: 0.95),
        CGPoint(x: 0.55, y: 0.98),
        CGPoint(x: 0.42, y: 0.97),
        CGPoint(x: 0.31, y: 0.94),
        CGPoint(x: 0.20, y: 0.88),
        CGPoint(x: 0.12, y: 0.79),
        CGPoint(x: 0.05, y: 0.68),
        CGPoint(x: 0.02, y: 0.56),
        CGPoint(x: 0.03, y: 0.43),
        CGPoint(x: 0.06, y: 0.31),
        CGPoint(x: 0.12, y: 0.20),
        CGPoint(x: 0.22, y: 0.11),
        CGPoint(x: 0.34, y: 0.05)
    ]

    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        guard let first = points.first else {
            return path
        }

        path.move(
            to: CGPoint(
                x: rect.minX
                    + first.x
                    * rect.width,

                y: rect.minY
                    + first.y
                    * rect.height
            )
        )

        for point in points.dropFirst() {
            path.addLine(
                to: CGPoint(
                    x: rect.minX
                        + point.x
                        * rect.width,

                    y: rect.minY
                        + point.y
                        * rect.height
                )
            )
        }

        path.closeSubpath()

        return path
    }
}

private struct AncientRuneGlyph: Shape {
    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        let center = CGPoint(
            x: rect.midX,
            y: rect.midY
        )

        let radius = min(
            rect.width,
            rect.height
        ) * 0.44

        path.addEllipse(
            in: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )

        path.addArc(
            center: center,
            radius: radius * 0.72,
            startAngle: .degrees(205),
            endAngle: .degrees(332),
            clockwise: false
        )

        path.addArc(
            center: center,
            radius: radius * 0.72,
            startAngle: .degrees(25),
            endAngle: .degrees(152),
            clockwise: false
        )

        path.move(
            to: CGPoint(
                x: center.x,
                y: center.y
                    - radius * 0.70
            )
        )

        path.addLine(
            to: CGPoint(
                x: center.x
                    - radius * 0.24,
                y: center.y
                    - radius * 0.12
            )
        )

        path.addLine(
            to: CGPoint(
                x: center.x
                    + radius * 0.12,
                y: center.y
                    + radius * 0.08
            )
        )

        path.addLine(
            to: CGPoint(
                x: center.x
                    - radius * 0.15,
                y: center.y
                    + radius * 0.63
            )
        )

        path.move(
            to: CGPoint(
                x: center.x
                    - radius * 0.58,
                y: center.y
                    - radius * 0.04
            )
        )

        path.addLine(
            to: CGPoint(
                x: center.x
                    - radius * 0.18,
                y: center.y
                    + radius * 0.10
            )
        )

        path.addLine(
            to: CGPoint(
                x: center.x
                    + radius * 0.44,
                y: center.y
                    - radius * 0.34
            )
        )

        path.move(
            to: CGPoint(
                x: center.x
                    + radius * 0.56,
                y: center.y
                    + radius * 0.10
            )
        )

        path.addLine(
            to: CGPoint(
                x: center.x
                    + radius * 0.10,
                y: center.y
                    + radius * 0.13
            )
        )

        path.addLine(
            to: CGPoint(
                x: center.x
                    + radius * 0.40,
                y: center.y
                    + radius * 0.58
            )
        )

        return path
    }
}

private struct CrackShape: Shape {
    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height

        path.move(
            to: CGPoint(
                x: x + w * 0.12,
                y: y + h * 0.38
            )
        )

        path.addLine(
            to: CGPoint(
                x: x + w * 0.29,
                y: y + h * 0.43
            )
        )

        path.addLine(
            to: CGPoint(
                x: x + w * 0.22,
                y: y + h * 0.56
            )
        )

        path.addLine(
            to: CGPoint(
                x: x + w * 0.36,
                y: y + h * 0.61
            )
        )

        path.move(
            to: CGPoint(
                x: x + w * 0.72,
                y: y + h * 0.15
            )
        )

        path.addLine(
            to: CGPoint(
                x: x + w * 0.66,
                y: y + h * 0.31
            )
        )

        path.addLine(
            to: CGPoint(
                x: x + w * 0.79,
                y: y + h * 0.40
            )
        )

        path.addLine(
            to: CGPoint(
                x: x + w * 0.74,
                y: y + h * 0.53
            )
        )

        path.move(
            to: CGPoint(
                x: x + w * 0.42,
                y: y + h * 0.76
            )
        )

        path.addLine(
            to: CGPoint(
                x: x + w * 0.49,
                y: y + h * 0.65
            )
        )

        path.addLine(
            to: CGPoint(
                x: x + w * 0.59,
                y: y + h * 0.73
            )
        )

        path.addLine(
            to: CGPoint(
                x: x + w * 0.65,
                y: y + h * 0.87
            )
        )

        return path
    }
}
