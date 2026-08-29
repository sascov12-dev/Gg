import SwiftUI
import SpriteKit

@MainActor
struct HunterMenuSpriteView: View {

    private let scene: HunterMenuScene

    init() {
        let scene =
            HunterMenuScene(
                size:
                    CGSize(
                        width: 180,
                        height: 290
                    )
            )

        scene.scaleMode = .resizeFill
        self.scene = scene
    }

    var body: some View {
        SpriteView(
            scene: scene,
            options: [
                .allowsTransparency
            ]
        )
        .background(
            Color.clear
        )
        .allowsHitTesting(false)
    }
}

@MainActor
private final class HunterMenuScene:
    SKScene {

    private var didBuild = false

    override func didMove(
        to view: SKView
    ) {
        super.didMove(
            to: view
        )

        backgroundColor = .clear
        view.allowsTransparency = true

        guard !didBuild else {
            return
        }

        didBuild = true
        buildHunter()
    }

    private func buildHunter() {
        let frames =
            HunterSpriteAssets
                .idleFrames

        guard
            let first =
                frames.first
        else {
            return
        }

        let sprite =
            SKSpriteNode(
                texture: first
            )

        sprite.texture?
            .filteringMode =
            .nearest

        sprite.size =
            CGSize(
                width: 180,
                height: 180
            )

        sprite.position =
            CGPoint(
                x: size.width * 0.5,
                y: size.height * 0.43
            )

        sprite.zPosition = 2

        addChild(
            sprite
        )

        if frames.count > 1 {
            sprite.run(
                .repeatForever(
                    .animate(
                        with: frames,
                        timePerFrame: 0.11,
                        resize: false,
                        restore: false
                    )
                ),
                withKey:
                    "menuHunterIdle"
            )
        }
    }
}
