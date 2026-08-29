import SwiftUI
import Combine

// MARK: - Shared app settings

enum AppSettingsStore {

    static let musicKey =
        "the_last_hunter_music_enabled"

    static let sfxKey =
        "the_last_hunter_sfx_enabled"

    static var musicEnabled: Bool {
        get {
            if UserDefaults.standard
                .object(
                    forKey: musicKey
                ) == nil {
                return true
            }

            return UserDefaults.standard
                .bool(
                    forKey: musicKey
                )
        }

        set {
            UserDefaults.standard.set(
                newValue,
                forKey: musicKey
            )
        }
    }

    static var sfxEnabled: Bool {
        get {
            if UserDefaults.standard
                .object(
                    forKey: sfxKey
                ) == nil {
                return true
            }

            return UserDefaults.standard
                .bool(
                    forKey: sfxKey
                )
        }

        set {
            UserDefaults.standard.set(
                newValue,
                forKey: sfxKey
            )
        }
    }
}

// MARK: - Main Menu

struct MainMenuView: View {

    let onStartNewGame: () -> Void
    let onContinueGame: () -> Void

    @State
    private var hasProgress = false

    @State
    private var showSettings = false

    @State
    private var musicEnabled =
        AppSettingsStore.musicEnabled

    @State
    private var sfxEnabled =
        AppSettingsStore.sfxEnabled

    @State
    private var forestAnimated = false

    @State
    private var hunterAnimated = false

    // MARK: - Body

    var body: some View {

        ZStack {

            MenuForestBackground(
                animated:
                    forestAnimated
            )
            .ignoresSafeArea()

            menuVignette
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(
                spacing: 0
            ) {

                Spacer()
                    .frame(
                        height: 38
                    )

                gameLogo

                Spacer()

                HunterMenuSpriteView()
                .frame(
                    width: 180,
                    height: 290
                )
                .offset(
                    y: 10
                )

                Spacer()

                menuButtons
                    .padding(
                        .horizontal,
                        34
                    )
                    .padding(
                        .bottom,
                        38
                    )
            }

            if showSettings {
                settingsOverlay
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
        }
        .background(
            Color.black
        )
        .statusBar(
            hidden: true
        )
        .onAppear {

            reloadProgress()

            AudioManager.shared
                .applySettings(
                    musicEnabled:
                        musicEnabled,
                    sfxEnabled:
                        sfxEnabled
                )

            AudioManager.shared
                .startMenuAudio()

            withAnimation(
                .easeInOut(
                    duration: 3.0
                )
                .repeatForever(
                    autoreverses: true
                )
            ) {
                forestAnimated = true
            }

            withAnimation(
                .easeInOut(
                    duration: 2.2
                )
                .repeatForever(
                    autoreverses: true
                )
            ) {
                hunterAnimated = true
            }
        }
    }

    // MARK: - Logo

    private var gameLogo:
        some View {

        VStack(
            spacing: -5
        ) {

            Text(
                "THE LAST"
            )
            .font(
                .system(
                    size: 21,
                    weight: .black,
                    design: .serif
                )
            )
            .kerning(4.5)
            .foregroundColor(
                Color(
                    red: 0.60,
                    green: 0.67,
                    blue: 0.73
                )
            )
            .shadow(
                color:
                    Color.black
                    .opacity(0.95),
                radius: 2,
                x: 0,
                y: 2
            )

            Text(
                "HUNTER"
            )
            .font(
                .system(
                    size: 52,
                    weight: .black,
                    design: .serif
                )
            )
            .kerning(2.2)
            .foregroundColor(
                Color(
                    red: 0.76,
                    green: 0.80,
                    blue: 0.83
                )
            )
            .shadow(
                color:
                    Color(
                        red: 0.30,
                        green: 0.40,
                        blue: 0.48
                    )
                    .opacity(0.30),
                radius: 3,
                x: 0,
                y: 1
            )
            .shadow(
                color:
                    Color.black
                    .opacity(0.95),
                radius: 4,
                x: 0,
                y: 3
            )

            Rectangle()
                .fill(
                    Color(
                        red: 0.50,
                        green: 0.56,
                        blue: 0.61
                    )
                    .opacity(0.62)
                )
                .frame(
                    width: 168,
                    height: 1
                )
                .padding(
                    .top,
                    4
                )
        }
    }

    // MARK: - Buttons

    private var menuButtons:
        some View {

        VStack(
            spacing: 11
        ) {

            if hasProgress {

                Button {

                    AudioManager.shared
                        .playUITap()

                    onContinueGame()

                } label: {

                    Text(
                        "ПРОДОЛЖИТЬ"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(
                        height: 53
                    )
                }
                .buttonStyle(
                    MenuMetalButtonStyle(
                        emphasized: true
                    )
                )

            } else {

                Button {

                    AudioManager.shared
                        .playUITap()

                    onStartNewGame()

                } label: {

                    Text(
                        "ИГРАТЬ"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(
                        height: 53
                    )
                }
                .buttonStyle(
                    MenuMetalButtonStyle(
                        emphasized: true
                    )
                )
            }

            Button {

                AudioManager.shared
                    .playUIOpen()

                withAnimation(
                    .easeOut(
                        duration: 0.18
                    )
                ) {
                    showSettings = true
                }

            } label: {

                Text(
                    "НАСТРОЙКИ"
                )
                .frame(
                    maxWidth: .infinity
                )
                .frame(
                    height: 49
                )
            }
            .buttonStyle(
                MenuMetalButtonStyle()
            )
        }
        .frame(
            maxWidth: 330
        )
    }

    // MARK: - Settings

    private var settingsOverlay:
        some View {

        ZStack {

            Color.black
                .opacity(0.72)
                .ignoresSafeArea()

            VStack(
                spacing: 13
            ) {

                Text(
                    "НАСТРОЙКИ"
                )
                .font(
                    .system(
                        size: 28,
                        weight: .black,
                        design: .serif
                    )
                )
                .kerning(1.2)
                .foregroundColor(
                    Color(
                        red: 0.77,
                        green: 0.81,
                        blue: 0.84
                    )
                )
                .padding(
                    .bottom,
                    8
                )

                settingsButton(
                    title:
                        "МУЗЫКА",
                    enabled:
                        musicEnabled
                ) {

                    musicEnabled.toggle()

                    AppSettingsStore
                        .musicEnabled =
                        musicEnabled

                    updateSavedSettings()

                    AudioManager.shared
                        .setMusicEnabled(
                            musicEnabled
                        )

                    AudioManager.shared
                        .playToggle(
                            enabled:
                                musicEnabled
                        )
                }

                settingsButton(
                    title:
                        "ЗВУКИ",
                    enabled:
                        sfxEnabled
                ) {

                    sfxEnabled.toggle()

                    AppSettingsStore
                        .sfxEnabled =
                        sfxEnabled

                    updateSavedSettings()

                    AudioManager.shared
                        .setSFXEnabled(
                            sfxEnabled
                        )

                    if sfxEnabled {
                        AudioManager.shared
                            .playToggle(
                                enabled: true
                            )
                    }
                }

                Button {

                    AudioManager.shared
                        .playUIClose()

                    withAnimation(
                        .easeOut(
                            duration: 0.16
                        )
                    ) {
                        showSettings = false
                    }

                } label: {

                    Text(
                        "ЗАКРЫТЬ"
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(
                        height: 47
                    )
                }
                .buttonStyle(
                    MenuMetalButtonStyle(
                        emphasized: true
                    )
                )
                .padding(
                    .top,
                    6
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
                maxWidth: 320
            )
            .background(
                settingsPanel
            )
            .padding(
                .horizontal,
                28
            )
        }
    }

    private func settingsButton(
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
                        red: 0.39,
                        green: 0.82,
                        blue: 0.50
                    )
                    : Color(
                        red: 0.68,
                        green: 0.31,
                        blue: 0.30
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
                height: 47
            )
        }
        .buttonStyle(
            MenuMetalButtonStyle()
        )
    }

    private var settingsPanel:
        some View {

        Rectangle()
            .fill(
                Color(
                    red: 0.035,
                    green: 0.04,
                    blue: 0.048
                )
                .opacity(0.98)
            )
            .overlay(
                Rectangle()
                    .stroke(
                        Color(
                            red: 0.40,
                            green: 0.44,
                            blue: 0.47
                        )
                        .opacity(0.70),
                        lineWidth: 1
                    )
            )
            .overlay(
                Rectangle()
                    .stroke(
                        Color.black
                            .opacity(0.90),
                        lineWidth: 5
                    )
                    .padding(4)
            )
            .shadow(
                color:
                    Color.black
                    .opacity(0.85),
                radius: 22
            )
    }

    // MARK: - Progress

    private func reloadProgress() {

        if let progress =
            SaveManager.shared.load(),
           progress.hasStartedGame {

            hasProgress = true

            musicEnabled =
                progress.musicEnabled

            sfxEnabled =
                progress.sfxEnabled

            AppSettingsStore
                .musicEnabled =
                progress.musicEnabled

            AppSettingsStore
                .sfxEnabled =
                progress.sfxEnabled

        } else {

            hasProgress = false

            musicEnabled =
                AppSettingsStore
                .musicEnabled

            sfxEnabled =
                AppSettingsStore
                .sfxEnabled
        }
    }

    private func updateSavedSettings() {

        guard var progress =
                SaveManager.shared.load() else {
            return
        }

        progress.musicEnabled =
            musicEnabled

        progress.sfxEnabled =
            sfxEnabled

        _ = SaveManager.shared.save(
            progress
        )
    }

    // MARK: - Menu shade

    private var menuVignette:
        some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color.black
                        .opacity(0.50),
                    Color.clear,
                    Color.black
                        .opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [
                    Color.black
                        .opacity(0.36),
                    Color.clear,
                    Color.black
                        .opacity(0.36)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Forest background

private struct MenuForestBackground: View {

    let animated: Bool

    var body: some View {

        GeometryReader {
            geometry in

            ZStack {

                Color(
                    red: 0.035,
                    green: 0.043,
                    blue: 0.055
                )

                moon(
                    in:
                        geometry.size
                )

                farTrees(
                    size:
                        geometry.size
                )

                nearTrees(
                    size:
                        geometry.size
                )

                ground(
                    size:
                        geometry.size
                )

                fog(
                    size:
                        geometry.size
                )

                leaves(
                    size:
                        geometry.size
                )
            }
            .clipped()
        }
    }

    // MARK: Moon

    private func moon(
        in size: CGSize
    ) -> some View {

        Circle()
            .fill(
                Color(
                    red: 0.46,
                    green: 0.60,
                    blue: 0.72
                )
                .opacity(0.20)
            )
            .overlay(
                Circle()
                    .stroke(
                        Color(
                            red: 0.65,
                            green: 0.74,
                            blue: 0.82
                        )
                        .opacity(0.12),
                        lineWidth: 2
                    )
            )
            .frame(
                width:
                    max(
                        80,
                        size.width * 0.25
                    ),
                height:
                    max(
                        80,
                        size.width * 0.25
                    )
            )
            .position(
                x:
                    size.width * 0.69,
                y:
                    size.height * 0.24
            )
    }

    // MARK: Far trees

    private func farTrees(
        size: CGSize
    ) -> some View {

        ZStack {

            ForEach(
                0..<10,
                id: \.self
            ) {
                index in

                MenuTreeView(
                    near: false,
                    index: index
                )
                .frame(
                    width: 90,
                    height:
                        size.height
                        * treeHeight(
                            index: index
                        )
                )
                .position(
                    x:
                        size.width
                        * treeX(
                            index:
                                index,
                            count: 10
                        ),
                    y:
                        size.height * 0.44
                )
            }
        }
    }

    // MARK: Near trees

    private func nearTrees(
        size: CGSize
    ) -> some View {

        ZStack {

            MenuTreeView(
                near: true,
                index: 20
            )
            .frame(
                width: 130,
                height:
                    size.height * 0.70
            )
            .position(
                x:
                    size.width * 0.05,
                y:
                    size.height * 0.42
            )

            MenuTreeView(
                near: true,
                index: 21
            )
            .frame(
                width: 125,
                height:
                    size.height * 0.74
            )
            .scaleEffect(
                x: -1,
                y: 1
            )
            .position(
                x:
                    size.width * 0.96,
                y:
                    size.height * 0.41
            )
        }
    }

    // MARK: Ground

    private func ground(
        size: CGSize
    ) -> some View {

        ZStack {

            Rectangle()
                .fill(
                    Color(
                        red: 0.13,
                        green: 0.11,
                        blue: 0.10
                    )
                )
                .frame(
                    height:
                        size.height * 0.29
                )
                .position(
                    x:
                        size.width * 0.5,
                    y:
                        size.height * 0.87
                )

            ForEach(
                0..<7,
                id: \.self
            ) {
                index in

                RoundedRectangle(
                    cornerRadius: 3
                )
                .fill(
                    Color(
                        red: 0.27,
                        green: 0.29,
                        blue: 0.31
                    )
                    .opacity(0.38)
                )
                .frame(
                    width:
                        CGFloat(
                            8
                            + (
                                index
                                % 3
                            )
                            * 5
                        ),
                    height:
                        CGFloat(
                            4
                            + (
                                index
                                % 2
                            )
                            * 3
                        )
                )
                .rotationEffect(
                    .degrees(
                        Double(
                            index * 17
                            - 35
                        )
                    )
                )
                .position(
                    x:
                        size.width
                        * groundX(
                            index:
                                index
                        ),
                    y:
                        size.height
                        * groundY(
                            index:
                                index
                        )
                )
            }

            MenuGravestone()
                .frame(
                    width: 27,
                    height: 42
                )
                .rotationEffect(
                    .degrees(-8)
                )
                .position(
                    x:
                        size.width * 0.13,
                    y:
                        size.height * 0.78
                )

            MenuGravestone()
                .frame(
                    width: 23,
                    height: 36
                )
                .rotationEffect(
                    .degrees(6)
                )
                .position(
                    x:
                        size.width * 0.87,
                    y:
                        size.height * 0.80
                )
        }
    }

    // MARK: Fog

    private func fog(
        size: CGSize
    ) -> some View {

        ZStack {

            ForEach(
                0..<4,
                id: \.self
            ) {
                index in

                Ellipse()
                    .fill(
                        Color(
                            red: 0.29,
                            green: 0.35,
                            blue: 0.40
                        )
                        .opacity(
                            0.035
                            + Double(index)
                            * 0.008
                        )
                    )
                    .frame(
                        width:
                            size.width
                            * (
                                0.60
                                + CGFloat(index)
                                * 0.08
                            ),
                        height:
                            CGFloat(
                                42
                                + index * 8
                            )
                    )
                    .offset(
                        x:
                            animated
                            ? CGFloat(
                                24
                                - index * 12
                            )
                            : CGFloat(
                                -25
                                + index * 9
                            ),
                        y:
                            size.height
                            * (
                                0.25
                                + CGFloat(index)
                                * 0.035
                            )
                    )
            }
        }
    }

    // MARK: Leaves

    private func leaves(
        size: CGSize
    ) -> some View {

        ZStack {

            ForEach(
                0..<12,
                id: \.self
            ) {
                index in

                Rectangle()
                    .fill(
                        Color(
                            red: 0.28,
                            green: 0.22,
                            blue: 0.18
                        )
                        .opacity(0.55)
                    )
                    .frame(
                        width:
                            index % 3 == 0
                            ? 4
                            : 3,
                        height: 2
                    )
                    .rotationEffect(
                        .degrees(
                            animated
                            ? Double(
                                index * 37
                                + 80
                            )
                            : Double(
                                index * 23
                            )
                        )
                    )
                    .position(
                        x:
                            animated
                            ? size.width
                                * leafEndX(
                                    index:
                                        index
                                )
                            : size.width
                                * leafStartX(
                                    index:
                                        index
                                ),
                        y:
                            animated
                            ? size.height
                                * leafEndY(
                                    index:
                                        index
                                )
                            : size.height
                                * leafStartY(
                                    index:
                                        index
                                )
                    )
            }
        }
    }

    // MARK: Helpers

    private func treeX(
        index: Int,
        count: Int
    ) -> CGFloat {

        guard count > 1 else {
            return 0.5
        }

        return CGFloat(index)
            / CGFloat(count - 1)
    }

    private func treeHeight(
        index: Int
    ) -> CGFloat {

        let values: [CGFloat] = [
            0.55,
            0.63,
            0.58,
            0.68,
            0.61,
            0.66,
            0.59,
            0.69,
            0.62,
            0.56
        ]

        return values[
            index % values.count
        ]
    }

    private func groundX(
        index: Int
    ) -> CGFloat {

        let values: [CGFloat] = [
            0.12,
            0.28,
            0.40,
            0.57,
            0.68,
            0.79,
            0.92
        ]

        return values[
            index % values.count
        ]
    }

    private func groundY(
        index: Int
    ) -> CGFloat {

        let values: [CGFloat] = [
            0.86,
            0.91,
            0.82,
            0.88,
            0.93,
            0.84,
            0.90
        ]

        return values[
            index % values.count
        ]
    }

    private func leafStartX(
        index: Int
    ) -> CGFloat {

        CGFloat(
            (
                index * 23
            )
            % 100
        ) / 100
    }

    private func leafStartY(
        index: Int
    ) -> CGFloat {

        0.20
        + CGFloat(
            (
                index * 17
            )
            % 55
        ) / 100
    }

    private func leafEndX(
        index: Int
    ) -> CGFloat {

        CGFloat(
            (
                index * 31
                + 18
            )
            % 100
        ) / 100
    }

    private func leafEndY(
        index: Int
    ) -> CGFloat {

        0.55
        + CGFloat(
            (
                index * 11
            )
            % 40
        ) / 100
    }
}

// MARK: - Tree

private struct MenuTreeView: View {

    let near: Bool
    let index: Int

    var body: some View {

        GeometryReader {
            geometry in

            let width =
                geometry.size.width

            let height =
                geometry.size.height

            let treeColor =
                near
                ? Color(
                    red: 0.055,
                    green: 0.065,
                    blue: 0.082
                )
                : Color(
                    red: 0.086,
                    green: 0.11,
                    blue: 0.145
                )

            ZStack {

                Rectangle()
                    .fill(
                        treeColor
                    )
                    .frame(
                        width:
                            near
                            ? 26
                            : 16,
                        height:
                            height * 0.80
                    )
                    .position(
                        x:
                            width * 0.5,
                        y:
                            height * 0.60
                    )

                branch(
                    color:
                        treeColor,
                    width:
                        width * 0.64,
                    thickness:
                        near
                        ? 9
                        : 6
                )
                .rotationEffect(
                    .degrees(-38)
                )
                .position(
                    x:
                        width * 0.37,
                    y:
                        height * 0.27
                )

                branch(
                    color:
                        treeColor,
                    width:
                        width * 0.62,
                    thickness:
                        near
                        ? 8
                        : 5
                )
                .rotationEffect(
                    .degrees(36)
                )
                .position(
                    x:
                        width * 0.64,
                    y:
                        height * 0.35
                )

                branch(
                    color:
                        treeColor,
                    width:
                        width * 0.54,
                    thickness:
                        near
                        ? 7
                        : 5
                )
                .rotationEffect(
                    .degrees(-28)
                )
                .position(
                    x:
                        width * 0.39,
                    y:
                        height * 0.45
                )

                branch(
                    color:
                        treeColor,
                    width:
                        width * 0.52,
                    thickness:
                        near
                        ? 7
                        : 5
                )
                .rotationEffect(
                    .degrees(30)
                )
                .position(
                    x:
                        width * 0.62,
                    y:
                        height * 0.53
                )
            }
        }
    }

    private func branch(
        color: Color,
        width: CGFloat,
        thickness: CGFloat
    ) -> some View {

        Rectangle()
            .fill(
                color
            )
            .frame(
                width: width,
                height: thickness
            )
    }
}

// MARK: - Gravestone

private struct MenuGravestone: View {

    var body: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 6
            )
            .fill(
                Color(
                    red: 0.25,
                    green: 0.27,
                    blue: 0.29
                )
                .opacity(0.72)
            )

            RoundedRectangle(
                cornerRadius: 6
            )
            .stroke(
                Color.black
                    .opacity(0.70),
                lineWidth: 2
            )

            Rectangle()
                .fill(
                    Color(
                        red: 0.09,
                        green: 0.10,
                        blue: 0.11
                    )
                    .opacity(0.48)
                )
                .frame(
                    width: 2,
                    height: 12
                )

            Rectangle()
                .fill(
                    Color(
                        red: 0.09,
                        green: 0.10,
                        blue: 0.11
                    )
                    .opacity(0.48)
                )
                .frame(
                    width: 10,
                    height: 2
                )
                .offset(
                    y: -3
                )
        }
    }
}

// MARK: - Hunter back silhouette

private struct HunterBackView: View {

    let animated: Bool

    var body: some View {

        GeometryReader {
            geometry in

            let width =
                geometry.size.width

            let height =
                geometry.size.height

            ZStack {

                // Shadow under Hunter

                Ellipse()
                    .fill(
                        Color.black
                            .opacity(0.55)
                    )
                    .frame(
                        width:
                            width * 0.66,
                        height: 18
                    )
                    .position(
                        x:
                            width * 0.5,
                        y:
                            height * 0.92
                    )

                // Sword

                ZStack {

                    Rectangle()
                        .fill(
                            Color(
                                red: 0.72,
                                green: 0.77,
                                blue: 0.80
                            )
                        )
                        .frame(
                            width: 5,
                            height:
                                height * 0.43
                        )

                    Rectangle()
                        .fill(
                            Color(
                                red: 0.66,
                                green: 0.53,
                                blue: 0.25
                            )
                        )
                        .frame(
                            width: 29,
                            height: 5
                        )
                        .offset(
                            y:
                                -height
                                * 0.19
                        )

                    Rectangle()
                        .fill(
                            Color(
                                red: 0.055,
                                green: 0.055,
                                blue: 0.06
                            )
                        )
                        .frame(
                            width: 7,
                            height: 25
                        )
                        .offset(
                            y:
                                -height
                                * 0.24
                        )
                }
                .rotationEffect(
                    .degrees(-13)
                )
                .position(
                    x:
                        width * 0.70,
                    y:
                        height * 0.66
                )

                // Cloak

                HunterCloakShape()
                    .fill(
                        Color(
                            red: 0.025,
                            green: 0.028,
                            blue: 0.032
                        )
                    )
                    .overlay(
                        HunterCloakShape()
                            .stroke(
                                Color(
                                    red: 0.22,
                                    green: 0.24,
                                    blue: 0.26
                                )
                                .opacity(0.72),
                                lineWidth: 2
                            )
                    )
                    .frame(
                        width:
                            width * 0.62,
                        height:
                            height * 0.69
                    )
                    .rotationEffect(
                        .degrees(
                            animated
                            ? 1.3
                            : -1.0
                        ),
                        anchor:
                            .top
                    )
                    .position(
                        x:
                            width * 0.5,
                        y:
                            height * 0.62
                    )

                // Shoulder armor

                HStack(
                    spacing: 39
                ) {

                    Rectangle()
                        .fill(
                            Color(
                                red: 0.26,
                                green: 0.29,
                                blue: 0.31
                            )
                        )
                        .frame(
                            width: 31,
                            height: 12
                        )
                        .rotationEffect(
                            .degrees(-14)
                        )

                    Rectangle()
                        .fill(
                            Color(
                                red: 0.26,
                                green: 0.29,
                                blue: 0.31
                            )
                        )
                        .frame(
                            width: 31,
                            height: 12
                        )
                        .rotationEffect(
                            .degrees(14)
                        )
                }
                .position(
                    x:
                        width * 0.5,
                    y:
                        height * 0.31
                )

                // Hood from back

                ZStack {

                    Circle()
                        .fill(
                            Color(
                                red: 0.018,
                                green: 0.020,
                                blue: 0.023
                            )
                        )
                        .frame(
                            width: 72,
                            height: 72
                        )

                    Circle()
                        .stroke(
                            Color(
                                red: 0.22,
                                green: 0.24,
                                blue: 0.26
                            )
                            .opacity(0.65),
                            lineWidth: 2
                        )
                        .frame(
                            width: 72,
                            height: 72
                        )

                    Rectangle()
                        .fill(
                            Color(
                                red: 0.045,
                                green: 0.048,
                                blue: 0.052
                            )
                        )
                        .frame(
                            width: 44,
                            height: 27
                        )
                        .offset(
                            y: 25
                        )
                }
                .position(
                    x:
                        width * 0.5,
                    y:
                        height * 0.23
                )
            }
        }
    }
}

// MARK: - Cloak shape

private struct HunterCloakShape:
    Shape {

    func path(
        in rect: CGRect
    ) -> Path {

        var path = Path()

        path.move(
            to:
                CGPoint(
                    x:
                        rect.width * 0.34,
                    y: 0
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.66,
                    y: 0
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.82,
                    y:
                        rect.height * 0.38
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.91,
                    y:
                        rect.height * 0.97
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.76,
                    y:
                        rect.height * 0.92
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.63,
                    y:
                        rect.height
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.48,
                    y:
                        rect.height * 0.94
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.34,
                    y:
                        rect.height
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.18,
                    y:
                        rect.height * 0.91
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.09,
                    y:
                        rect.height * 0.97
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x:
                        rect.width * 0.18,
                    y:
                        rect.height * 0.38
                )
        )

        path.closeSubpath()

        return path
    }
}

// MARK: - Menu Button Style

private struct MenuMetalButtonStyle:
    ButtonStyle {

    let emphasized: Bool

    init(
        emphasized: Bool = false
    ) {
        self.emphasized =
            emphasized
    }

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .font(
                .system(
                    size:
                        emphasized
                        ? 17
                        : 15,
                    weight: .black,
                    design: .serif
                )
            )
            .foregroundColor(
                emphasized
                ? Color(
                    red: 0.84,
                    green: 0.87,
                    blue: 0.89
                )
                : Color(
                    red: 0.70,
                    green: 0.74,
                    blue: 0.77
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
                            red: 0.038,
                            green: 0.043,
                            blue: 0.050
                        )
                    )
            )
            .overlay(
                Rectangle()
                    .stroke(
                        emphasized
                        ? Color(
                            red: 0.48,
                            green: 0.53,
                            blue: 0.57
                        )
                        : Color(
                            red: 0.29,
                            green: 0.32,
                            blue: 0.35
                        ),
                        lineWidth:
                            emphasized
                            ? 2
                            : 1
                    )
            )
            .overlay(
                Rectangle()
                    .stroke(
                        Color.black
                            .opacity(0.68),
                        lineWidth: 1
                    )
                    .padding(4)
            )
            .shadow(
                color:
                    Color.black
                    .opacity(0.56),
                radius: 5,
                x: 0,
                y: 3
            )
            .scaleEffect(
                configuration.isPressed
                ? 0.985
                : 1
            )
            .opacity(
                configuration.isPressed
                ? 0.86
                : 1
            )
    }
}
