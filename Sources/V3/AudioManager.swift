import Foundation
import AVFoundation
import Combine

// MARK: - Audio groups

enum AudioGroup {
    case music
    case ambience
    case combat
    case ui
}

// MARK: - Audio cues

enum AudioCue: String, CaseIterable {

    // Music
    case forestMusic = "music_forest"
    case bossMusicLayer = "music_boss_layer"

    // Ambience
    case forestWind = "amb_forest_wind"
    case forestBranches = "amb_branches"
    case forestLeaves = "amb_leaves"
    case bossAmbience = "amb_boss"

    // Hunter
    case hunterSlash1 = "hunter_slash_1"
    case hunterSlash2 = "hunter_slash_2"
    case hunterSlash3 = "hunter_slash_3"

    case hunterStrongWindup = "hunter_strong_windup"
    case hunterStrongSlash = "hunter_strong_slash"

    case hunterCriticalEye = "hunter_critical_eye"
    case hunterCriticalDash = "hunter_critical_dash"
    case hunterCriticalSlash = "hunter_critical_slash"

    case hunterCloth = "hunter_cloth"
    case hunterArmor = "hunter_armor"

    // Generic impacts
    case hitLight1 = "hit_light_1"
    case hitLight2 = "hit_light_2"
    case hitLight3 = "hit_light_3"

    case hitStrong1 = "hit_strong_1"
    case hitStrong2 = "hit_strong_2"

    case hitCritical = "hit_critical"

    // Skeleton
    case skeletonSpawn = "skeleton_spawn"
    case skeletonHit1 = "skeleton_hit_1"
    case skeletonHit2 = "skeleton_hit_2"
    case skeletonDeath = "skeleton_death"

    // Hound
    case houndSpawn = "hound_spawn"
    case houndHit1 = "hound_hit_1"
    case houndHit2 = "hound_hit_2"
    case houndDeath = "hound_death"

    // Knight
    case knightSpawn = "knight_spawn"
    case knightHit1 = "knight_hit_1"
    case knightHit2 = "knight_hit_2"
    case knightDeath = "knight_death"

    // Ghoul
    case ghoulSpawn = "ghoul_spawn"
    case ghoulHit1 = "ghoul_hit_1"
    case ghoulHit2 = "ghoul_hit_2"
    case ghoulDeath = "ghoul_death"

    // Cultist
    case cultistSpawn = "cultist_spawn"
    case cultistHit1 = "cultist_hit_1"
    case cultistHit2 = "cultist_hit_2"
    case cultistMagic = "cultist_magic"
    case cultistDeath = "cultist_death"

    // Demon
    case demonIntroLow = "demon_intro_low"
    case demonEmergence = "demon_emergence"
    case demonEyeIgnite = "demon_eye_ignite"

    case demonHit1 = "demon_hit_1"
    case demonHit2 = "demon_hit_2"

    case demonPhase2 = "demon_phase_2"
    case demonPhase3 = "demon_phase_3"

    case demonDeathStart = "demon_death_start"
    case demonDeathAsh = "demon_death_ash"
    case demonSwordFall = "demon_sword_fall"

    // Rewards
    case coinFly1 = "coin_fly_1"
    case coinFly2 = "coin_fly_2"
    case coinReward = "coin_reward"
    case bossReward = "boss_reward"

    // Progression
    case cycleTransition = "cycle_transition"

    // UI
    case uiTap = "ui_tap"
    case uiOpen = "ui_open"
    case uiClose = "ui_close"
    case uiToggleOn = "ui_toggle_on"
    case uiToggleOff = "ui_toggle_off"
    case uiPause = "ui_pause"
    case uiResume = "ui_resume"
    case uiComingSoon = "ui_coming_soon"

    var group: AudioGroup {
        switch self {

        case .forestMusic,
             .bossMusicLayer:
            return .music

        case .forestWind,
             .forestBranches,
             .forestLeaves,
             .bossAmbience:
            return .ambience

        case .uiTap,
             .uiOpen,
             .uiClose,
             .uiToggleOn,
             .uiToggleOff,
             .uiPause,
             .uiResume,
             .uiComingSoon:
            return .ui

        default:
            return .combat
        }
    }

    var poolSize: Int {
        switch self {

        case .hunterSlash1,
             .hunterSlash2,
             .hunterSlash3,
             .hitLight1,
             .hitLight2,
             .hitLight3,
             .hitStrong1,
             .hitStrong2,
             .coinFly1,
             .coinFly2:
            return 3

        case .uiTap:
            return 2

        default:
            return 1
        }
    }
}

// MARK: - Audio Manager

@MainActor
final class AudioManager: NSObject, ObservableObject {

    static let shared = AudioManager()

    // MARK: - Settings

    @Published private(set) var musicEnabled = true
    @Published private(set) var sfxEnabled = true

    // MARK: - Players

    private var playerPools: [
        AudioCue: [AVAudioPlayer]
    ] = [:]

    private var poolIndexes: [
        AudioCue: Int
    ] = [:]

    private var forestMusicPlayer: AVAudioPlayer?
    private var bossMusicPlayer: AVAudioPlayer?

    private var forestWindPlayer: AVAudioPlayer?
    private var forestBranchesPlayer: AVAudioPlayer?
    private var forestLeavesPlayer: AVAudioPlayer?
    private var bossAmbiencePlayer: AVAudioPlayer?

    // MARK: - Runtime

    private var isBossMode = false
    private var isConfigured = false

    private override init() {
        super.init()

        configureAudioSession()
        preloadCommonSounds()
    }

    // MARK: - Session

    private func configureAudioSession() {
        guard !isConfigured else {
            return
        }

        do {
            let session =
                AVAudioSession.sharedInstance()

            try session.setCategory(
                .ambient,
                mode: .default,
                options: [
                    .mixWithOthers
                ]
            )

            try session.setActive(
                true
            )

            isConfigured = true
        } catch {
            print(
                "Audio session error:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Settings sync

    func applySettings(
        musicEnabled: Bool,
        sfxEnabled: Bool
    ) {
        self.musicEnabled =
            musicEnabled

        self.sfxEnabled =
            sfxEnabled

        updateLoopVolumes()
    }

    func applySettings(
        from progress: GameProgress
    ) {
        applySettings(
            musicEnabled:
                progress.musicEnabled,
            sfxEnabled:
                progress.sfxEnabled
        )
    }

    func setMusicEnabled(
        _ enabled: Bool
    ) {
        musicEnabled = enabled

        updateLoopVolumes()
    }

    func setSFXEnabled(
        _ enabled: Bool
    ) {
        sfxEnabled = enabled

        updateLoopVolumes()
    }

    // MARK: - Main menu audio

    func startMenuAudio() {
        isBossMode = false

        ensureForestMusic()
        ensureForestAmbience()

        stopBossLayers(
            fade: true
        )

        forestMusicPlayer?.volume =
            musicEnabled ? 0.34 : 0

        forestWindPlayer?.volume =
            sfxEnabled ? 0.32 : 0

        forestBranchesPlayer?.volume =
            sfxEnabled ? 0.10 : 0

        forestLeavesPlayer?.volume =
            sfxEnabled ? 0.08 : 0
    }

    // MARK: - Normal combat audio

    func startCombatAudio() {
        isBossMode = false

        ensureForestMusic()
        ensureForestAmbience()

        stopBossLayers(
            fade: true
        )

        forestMusicPlayer?.volume =
            musicEnabled ? 0.42 : 0

        forestWindPlayer?.volume =
            sfxEnabled ? 0.28 : 0

        forestBranchesPlayer?.volume =
            sfxEnabled ? 0.08 : 0

        forestLeavesPlayer?.volume =
            sfxEnabled ? 0.11 : 0
    }

    // MARK: - Boss audio

    func startBossAudio() {
        isBossMode = true

        ensureForestMusic()
        ensureForestAmbience()

        ensureBossMusic()
        ensureBossAmbience()

        forestMusicPlayer?.volume =
            musicEnabled ? 0.34 : 0

        bossMusicPlayer?.volume =
            musicEnabled ? 0.42 : 0

        forestWindPlayer?.volume =
            sfxEnabled ? 0.18 : 0

        bossAmbiencePlayer?.volume =
            sfxEnabled ? 0.30 : 0
    }

    func endBossAudio() {
        isBossMode = false

        stopBossLayers(
            fade: true
        )

        startCombatAudio()
    }

    // MARK: - Hunter attacks

    func playHunterAttack(
        _ resolution: CombatResolution
    ) {
        guard sfxEnabled else {
            return
        }

        switch resolution.animation {

        case .attack1:
            play(
                .hunterSlash1,
                volume: 0.70,
                rateRange: 0.97...1.03
            )

        case .attack2:
            play(
                .hunterSlash2,
                volume: 0.72,
                rateRange: 0.97...1.03
            )

        case .attack3:
            play(
                .hunterSlash3,
                volume: 0.74,
                rateRange: 0.97...1.03
            )

        case .strong:
            play(
                .hunterStrongWindup,
                volume: 0.74,
                rateRange: 0.98...1.02
            )

            play(
                .hunterStrongSlash,
                volume: 0.84,
                rateRange: 0.98...1.02
            )

        case .critical:
            play(
                .hunterCriticalEye,
                volume: 0.72
            )

            play(
                .hunterCriticalDash,
                volume: 0.80
            )

            play(
                .hunterCriticalSlash,
                volume: 0.94
            )
        }
    }

    // MARK: - Sword contact

    func playImpact(
        attackKind: AttackKind
    ) {
        guard sfxEnabled else {
            return
        }

        switch attackKind {

        case .normal:
            playRandom(
                [
                    .hitLight1,
                    .hitLight2,
                    .hitLight3
                ],
                volume: 0.67,
                rateRange: 0.96...1.04
            )

        case .strong:
            playRandom(
                [
                    .hitStrong1,
                    .hitStrong2
                ],
                volume: 0.84,
                rateRange: 0.97...1.03
            )

        case .critical:
            play(
                .hitCritical,
                volume: 1.0,
                rateRange: 0.98...1.02
            )
        }
    }

    // MARK: - Enemy spawn

    func playEnemySpawn(
        _ enemy: EnemyDefinition
    ) {
        guard sfxEnabled else {
            return
        }

        switch enemy.id {

        case .graveSkeleton:
            play(
                .skeletonSpawn,
                volume: 0.62
            )

        case .cursedHound:
            play(
                .houndSpawn,
                volume: 0.68
            )

        case .fallenKnight:
            play(
                .knightSpawn,
                volume: 0.76
            )

        case .swampGhoul:
            play(
                .ghoulSpawn,
                volume: 0.66
            )

        case .shadowCultist:
            play(
                .cultistSpawn,
                volume: 0.70
            )

        case .abyssDemon:
            playBossIntro()
        }
    }

    // MARK: - Enemy reaction

    func playEnemyHit(
        _ enemy: EnemyDefinition,
        attackKind: AttackKind
    ) {
        guard sfxEnabled else {
            return
        }

        playImpact(
            attackKind: attackKind
        )

        let volume: Float =
            attackKind == .critical
            ? 0.82
            : 0.62

        switch enemy.id {

        case .graveSkeleton:
            playRandom(
                [
                    .skeletonHit1,
                    .skeletonHit2
                ],
                volume: volume,
                rateRange: 0.96...1.04
            )

        case .cursedHound:
            playRandom(
                [
                    .houndHit1,
                    .houndHit2
                ],
                volume: volume,
                rateRange: 0.97...1.03
            )

        case .fallenKnight:
            playRandom(
                [
                    .knightHit1,
                    .knightHit2
                ],
                volume: volume,
                rateRange: 0.97...1.03
            )

        case .swampGhoul:
            playRandom(
                [
                    .ghoulHit1,
                    .ghoulHit2
                ],
                volume: volume,
                rateRange: 0.97...1.03
            )

        case .shadowCultist:
            playRandom(
                [
                    .cultistHit1,
                    .cultistHit2
                ],
                volume: volume,
                rateRange: 0.97...1.03
            )

        case .abyssDemon:
            playRandom(
                [
                    .demonHit1,
                    .demonHit2
                ],
                volume: 0.82,
                rateRange: 0.97...1.02
            )
        }
    }

    // MARK: - Enemy death

    func playEnemyDeath(
        _ enemy: EnemyDefinition
    ) {
        guard sfxEnabled else {
            return
        }

        switch enemy.id {

        case .graveSkeleton:
            play(
                .skeletonDeath,
                volume: 0.78
            )

        case .cursedHound:
            play(
                .houndDeath,
                volume: 0.78
            )

        case .fallenKnight:
            play(
                .knightDeath,
                volume: 0.86
            )

        case .swampGhoul:
            play(
                .ghoulDeath,
                volume: 0.78
            )

        case .shadowCultist:
            play(
                .cultistDeath,
                volume: 0.82
            )

        case .abyssDemon:
            play(
                .demonDeathStart,
                volume: 1.0
            )
        }
    }

    // MARK: - Boss

    func playBossIntro() {
        guard sfxEnabled else {
            return
        }

        play(
            .demonIntroLow,
            volume: 0.92
        )

        play(
            .demonEmergence,
            volume: 0.88
        )

        play(
            .demonEyeIgnite,
            volume: 0.84
        )
    }

    func playBossPhase(
        _ phase: BossVisualPhase
    ) {
        guard sfxEnabled else {
            return
        }

        switch phase {

        case .calm:
            break

        case .angry:
            play(
                .demonPhase2,
                volume: 0.82
            )

        case .enraged:
            play(
                .demonPhase3,
                volume: 0.96
            )
        }
    }

    func playBossAsh() {
        play(
            .demonDeathAsh,
            volume: 0.86
        )
    }

    func playBossSwordFall() {
        play(
            .demonSwordFall,
            volume: 0.94
        )
    }

    // MARK: - Rewards

    func playCoinFlight() {
        guard sfxEnabled else {
            return
        }

        playRandom(
            [
                .coinFly1,
                .coinFly2
            ],
            volume: 0.48,
            rateRange: 0.98...1.05
        )
    }

    func playReward(
        boss: Bool
    ) {
        guard sfxEnabled else {
            return
        }

        play(
            boss
                ? .bossReward
                : .coinReward,
            volume:
                boss
                ? 0.95
                : 0.72
        )
    }

    func playCycleTransition() {
        play(
            .cycleTransition,
            volume: 0.82
        )
    }

    // MARK: - UI

    func playUITap() {
        play(
            .uiTap,
            volume: 0.56
        )
    }

    func playUIOpen() {
        play(
            .uiOpen,
            volume: 0.58
        )
    }

    func playUIClose() {
        play(
            .uiClose,
            volume: 0.54
        )
    }

    func playToggle(
        enabled: Bool
    ) {
        play(
            enabled
                ? .uiToggleOn
                : .uiToggleOff,
            volume: 0.58
        )
    }

    func playPause() {
        play(
            .uiPause,
            volume: 0.60
        )
    }

    func playResume() {
        play(
            .uiResume,
            volume: 0.60
        )
    }

    func playComingSoon() {
        play(
            .uiComingSoon,
            volume: 0.58
        )
    }

    // MARK: - Hunter idle details

    func playHunterCloth() {
        play(
            .hunterCloth,
            volume: 0.22,
            rateRange: 0.98...1.02
        )
    }

    func playHunterArmor() {
        play(
            .hunterArmor,
            volume: 0.18,
            rateRange: 0.98...1.02
        )
    }

    // MARK: - Play helpers

    private func play(
        _ cue: AudioCue,
        volume: Float,
        rateRange: ClosedRange<Float>? = nil
    ) {
        guard shouldPlay(
            cue
        ) else {
            return
        }

        var pool =
            playerPools[cue]
            ?? []

        if pool.isEmpty {
            preload(
                cue
            )

            pool =
                playerPools[cue]
                ?? []
        }

        guard !pool.isEmpty else {
            return
        }

        let currentIndex =
            poolIndexes[cue] ?? 0

        let safeIndex =
            currentIndex % pool.count

        let player =
            pool[safeIndex]

        player.stop()
        player.currentTime = 0
        player.volume = volume

        if let rateRange {
            player.enableRate = true

            player.rate =
                Float.random(
                    in: rateRange
                )
        } else {
            player.enableRate = false
            player.rate = 1.0
        }

        player.prepareToPlay()
        player.play()

        poolIndexes[cue] =
            (safeIndex + 1)
            % pool.count
    }

    private func playRandom(
        _ cues: [AudioCue],
        volume: Float,
        rateRange: ClosedRange<Float>? = nil
    ) {
        guard let cue =
                cues.randomElement() else {
            return
        }

        play(
            cue,
            volume: volume,
            rateRange: rateRange
        )
    }

    private func shouldPlay(
        _ cue: AudioCue
    ) -> Bool {
        switch cue.group {

        case .music:
            return musicEnabled

        case .ambience,
             .combat,
             .ui:
            return sfxEnabled
        }
    }

    // MARK: - Preload

    private func preloadCommonSounds() {
        let common: [AudioCue] = [
            .hunterSlash1,
            .hunterSlash2,
            .hunterSlash3,
            .hunterStrongWindup,
            .hunterStrongSlash,
            .hunterCriticalEye,
            .hunterCriticalDash,
            .hunterCriticalSlash,
            .hitLight1,
            .hitLight2,
            .hitLight3,
            .hitStrong1,
            .hitStrong2,
            .hitCritical,
            .coinFly1,
            .coinFly2,
            .coinReward,
            .bossReward,
            .uiTap,
            .uiOpen,
            .uiClose,
            .uiToggleOn,
            .uiToggleOff,
            .uiPause,
            .uiResume,
            .uiComingSoon
        ]

        for cue in common {
            preload(
                cue
            )
        }
    }

    private func preload(
        _ cue: AudioCue
    ) {
        guard playerPools[cue] == nil else {
            return
        }

        guard let url =
                audioURL(
                    named: cue.rawValue
                ) else {
            return
        }

        var players: [AVAudioPlayer] = []

        for _ in 0..<cue.poolSize {
            do {
                let player =
                    try AVAudioPlayer(
                        contentsOf: url
                    )

                player.prepareToPlay()

                players.append(
                    player
                )
            } catch {
                print(
                    "Audio load error:",
                    cue.rawValue,
                    error.localizedDescription
                )
            }
        }

        if !players.isEmpty {
            playerPools[cue] = players
            poolIndexes[cue] = 0
        }
    }

    // MARK: - Loop creation

    private func ensureForestMusic() {
        guard forestMusicPlayer == nil else {
            if forestMusicPlayer?.isPlaying == false {
                forestMusicPlayer?.play()
            }

            return
        }

        forestMusicPlayer =
            createLoopPlayer(
                cue: .forestMusic,
                volume: 0.42
            )

        forestMusicPlayer?.play()
    }

    private func ensureBossMusic() {
        guard bossMusicPlayer == nil else {
            if bossMusicPlayer?.isPlaying == false {
                bossMusicPlayer?.play()
            }

            return
        }

        bossMusicPlayer =
            createLoopPlayer(
                cue: .bossMusicLayer,
                volume: 0.42
            )

        bossMusicPlayer?.play()
    }

    private func ensureForestAmbience() {
        if forestWindPlayer == nil {
            forestWindPlayer =
                createLoopPlayer(
                    cue: .forestWind,
                    volume: 0.28
                )

            forestWindPlayer?.play()
        }

        if forestBranchesPlayer == nil {
            forestBranchesPlayer =
                createLoopPlayer(
                    cue: .forestBranches,
                    volume: 0.08
                )

            forestBranchesPlayer?.play()
        }

        if forestLeavesPlayer == nil {
            forestLeavesPlayer =
                createLoopPlayer(
                    cue: .forestLeaves,
                    volume: 0.10
                )

            forestLeavesPlayer?.play()
        }
    }

    private func ensureBossAmbience() {
        guard bossAmbiencePlayer == nil else {
            if bossAmbiencePlayer?.isPlaying == false {
                bossAmbiencePlayer?.play()
            }

            return
        }

        bossAmbiencePlayer =
            createLoopPlayer(
                cue: .bossAmbience,
                volume: 0.30
            )

        bossAmbiencePlayer?.play()
    }

    private func createLoopPlayer(
        cue: AudioCue,
        volume: Float
    ) -> AVAudioPlayer? {
        guard let url =
                audioURL(
                    named: cue.rawValue
                ) else {
            return nil
        }

        do {
            let player =
                try AVAudioPlayer(
                    contentsOf: url
                )

            player.numberOfLoops = -1
            player.volume = volume
            player.prepareToPlay()

            return player
        } catch {
            print(
                "Loop audio error:",
                cue.rawValue,
                error.localizedDescription
            )

            return nil
        }
    }

    // MARK: - Resource lookup

    private func audioURL(
        named name: String
    ) -> URL? {
        let extensions = [
            "wav",
            "m4a",
            "caf",
            "mp3"
        ]

        for ext in extensions {
            if let url =
                Bundle.main.url(
                    forResource: name,
                    withExtension: ext
                ) {
                return url
            }
        }

        return nil
    }

    // MARK: - Volume state

    private func updateLoopVolumes() {
        forestMusicPlayer?.volume =
            musicEnabled
            ? (isBossMode ? 0.34 : 0.42)
            : 0

        bossMusicPlayer?.volume =
            musicEnabled && isBossMode
            ? 0.42
            : 0

        forestWindPlayer?.volume =
            sfxEnabled
            ? (isBossMode ? 0.18 : 0.28)
            : 0

        forestBranchesPlayer?.volume =
            sfxEnabled
            ? 0.08
            : 0

        forestLeavesPlayer?.volume =
            sfxEnabled
            ? 0.10
            : 0

        bossAmbiencePlayer?.volume =
            sfxEnabled && isBossMode
            ? 0.30
            : 0
    }

    // MARK: - Boss layer stop

    private func stopBossLayers(
        fade: Bool
    ) {
        if fade {
            bossMusicPlayer?.setVolume(
                0,
                fadeDuration: 0.35
            )

            bossAmbiencePlayer?.setVolume(
                0,
                fadeDuration: 0.35
            )
        } else {
            bossMusicPlayer?.volume = 0
            bossAmbiencePlayer?.volume = 0
        }

        bossMusicPlayer?.stop()
        bossMusicPlayer = nil

        bossAmbiencePlayer?.stop()
        bossAmbiencePlayer = nil
    }

    // MARK: - App lifecycle

    func applicationDidEnterBackground() {
        forestMusicPlayer?.pause()
        bossMusicPlayer?.pause()

        forestWindPlayer?.pause()
        forestBranchesPlayer?.pause()
        forestLeavesPlayer?.pause()
        bossAmbiencePlayer?.pause()
    }

    func applicationDidBecomeActive() {
        configureAudioSession()

        if forestMusicPlayer != nil {
            forestMusicPlayer?.play()
        }

        if forestWindPlayer != nil {
            forestWindPlayer?.play()
        }

        if forestBranchesPlayer != nil {
            forestBranchesPlayer?.play()
        }

        if forestLeavesPlayer != nil {
            forestLeavesPlayer?.play()
        }

        if isBossMode {
            bossMusicPlayer?.play()
            bossAmbiencePlayer?.play()
        }

        updateLoopVolumes()
    }

    // MARK: - Stop

    func stopAll() {
        for pool in playerPools.values {
            for player in pool {
                player.stop()
            }
        }

        forestMusicPlayer?.stop()
        bossMusicPlayer?.stop()

        forestWindPlayer?.stop()
        forestBranchesPlayer?.stop()
        forestLeavesPlayer?.stop()
        bossAmbiencePlayer?.stop()

        forestMusicPlayer = nil
        bossMusicPlayer = nil

        forestWindPlayer = nil
        forestBranchesPlayer = nil
        forestLeavesPlayer = nil
        bossAmbiencePlayer = nil

        isBossMode = false
    }
}
