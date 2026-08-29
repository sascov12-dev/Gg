import Foundation

final class SaveManager {

    static let shared = SaveManager()

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private let saveFileName = "the_last_hunter_v3_save.json"
    private let currentSaveVersion = 1

    private init(
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys
        ]

        self.decoder = JSONDecoder()
    }

    // MARK: - Save wrapper

    private struct SaveEnvelope: Codable {
        let version: Int
        let savedAt: Date
        let progress: GameProgress
    }

    // MARK: - Save location

    private var saveDirectoryURL: URL? {
        do {
            let directory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            let gameDirectory = directory
                .appendingPathComponent(
                    "TheLastHunter",
                    isDirectory: true
                )

            if !fileManager.fileExists(
                atPath: gameDirectory.path
            ) {
                try fileManager.createDirectory(
                    at: gameDirectory,
                    withIntermediateDirectories: true
                )
            }

            return gameDirectory
        } catch {
            print(
                "SaveManager directory error:",
                error.localizedDescription
            )

            return nil
        }
    }

    private var saveFileURL: URL? {
        saveDirectoryURL?
            .appendingPathComponent(
                saveFileName,
                isDirectory: false
            )
    }

    // MARK: - Save

    @discardableResult
    func save(
        _ progress: GameProgress
    ) -> Bool {
        guard let url = saveFileURL else {
            return false
        }

        let envelope = SaveEnvelope(
            version: currentSaveVersion,
            savedAt: Date(),
            progress: sanitized(
                progress
            )
        )

        do {
            let data = try encoder.encode(
                envelope
            )

            try data.write(
                to: url,
                options: .atomic
            )

            return true
        } catch {
            print(
                "SaveManager save error:",
                error.localizedDescription
            )

            return false
        }
    }

    // MARK: - Load

    func load() -> GameProgress? {
        guard let url = saveFileURL else {
            return nil
        }

        guard fileManager.fileExists(
            atPath: url.path
        ) else {
            return nil
        }

        do {
            let data = try Data(
                contentsOf: url
            )

            let envelope = try decoder.decode(
                SaveEnvelope.self,
                from: data
            )

            guard envelope.version <= currentSaveVersion else {
                print(
                    "SaveManager: unsupported save version",
                    envelope.version
                )

                return nil
            }

            return sanitized(
                envelope.progress
            )
        } catch {
            print(
                "SaveManager load error:",
                error.localizedDescription
            )

            backupBrokenSave()

            return nil
        }
    }

    // MARK: - Delete

    @discardableResult
    func deleteSave() -> Bool {
        guard let url = saveFileURL else {
            return false
        }

        guard fileManager.fileExists(
            atPath: url.path
        ) else {
            return true
        }

        do {
            try fileManager.removeItem(
                at: url
            )

            return true
        } catch {
            print(
                "SaveManager delete error:",
                error.localizedDescription
            )

            return false
        }
    }

    // MARK: - Status

    var hasSave: Bool {
        guard let url = saveFileURL else {
            return false
        }

        return fileManager.fileExists(
            atPath: url.path
        )
    }

    // MARK: - Corrupted save backup

    private func backupBrokenSave() {
        guard let sourceURL = saveFileURL else {
            return
        }

        guard fileManager.fileExists(
            atPath: sourceURL.path
        ) else {
            return
        }

        let backupURL = sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent(
                "broken_save_backup.json"
            )

        do {
            if fileManager.fileExists(
                atPath: backupURL.path
            ) {
                try fileManager.removeItem(
                    at: backupURL
                )
            }

            try fileManager.moveItem(
                at: sourceURL,
                to: backupURL
            )
        } catch {
            print(
                "SaveManager backup error:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Safety

    private func sanitized(
        _ progress: GameProgress
    ) -> GameProgress {
        var result = progress

        result.coins = max(
            0,
            result.coins
        )

        result.cycle = max(
            1,
            result.cycle
        )

        result.enemyIndex = min(
            max(
                result.enemyIndex,
                0
            ),
            EnemyDefinition.roster.count - 1
        )

        result.comboCounter = max(
            0,
            result.comboCounter
        )

        let enemy = EnemyDefinition.enemy(
            at: result.enemyIndex
        )

        let multiplier =
            1.0
            + Double(
                result.cycle - 1
            )
            * GameConstants.cycleGrowthStep

        let maximumHP = max(
            1,
            Int(
                (
                    Double(enemy.baseHP)
                    * multiplier
                )
                .rounded()
            )
        )

        if result.hasStartedGame {
            result.enemyHP = min(
                max(
                    1,
                    result.enemyHP
                ),
                maximumHP
            )
        } else {
            result.enemyIndex = 0
            result.cycle = 1
            result.comboCounter = 0

            result.enemyHP =
                EnemyDefinition.roster[0].baseHP
        }

        return result
    }
}
