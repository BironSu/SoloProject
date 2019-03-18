//
//  EndScene.swift
//  SpriteKitExercise
//
//  Created by Biron Su on 3/14/19.
//  Copyright © 2019 Pursuit. All rights reserved.
//

import SpriteKit
class EndScene: SKScene {
    let highscore = UserDefaults.standard.object(forKey: "Highest Score") as! Int
    lazy var endSceneBackground: SKSpriteNode = {
        let background = SKSpriteNode(imageNamed: "ZombiePauseBackground")
        background.setScale(0.75)
        background.zRotation = -1.55
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = NodesZPosition.pauseMenuBackground.rawValue
        return background
    }()
    lazy var highScoreLabel: SKLabelNode = {
        let label = SKLabelNode(text: "Highest Score: \(highscore) zombies killed")
        label.zRotation = -1.55
        label.position = CGPoint(x: size.width / 1.3, y: size.height / 2)
        label.zPosition = NodesZPosition.pauseMenuBackground.rawValue
        return label
    }()
    lazy var restartButton: SKSpriteNode = {
        let sprite = SKSpriteNode(imageNamed: "Restart")
        sprite.setScale(0.3)
        sprite.zRotation = -1.55
        sprite.zPosition = NodesZPosition.pauseMenuButton.rawValue
        sprite.position = CGPoint(x: size.width / 3, y: size.height / 2)
        return sprite
    }()
    lazy var gameOverLogo: SKSpriteNode = {
        let sprite = SKSpriteNode(imageNamed: "You'veDied")
        sprite.zRotation = -1.55
        sprite.zPosition = NodesZPosition.pauseMenuButton.rawValue
        sprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        return sprite
    }()
    override init(size: CGSize) {
        super.init(size: size)
        addChild(endSceneBackground)
        addChild(gameOverLogo)
        addChild(restartButton)
        addChild(highScoreLabel)
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        if restartButton.contains(touchLocation) {
            let displaySize: CGRect = UIScreen.main.bounds
            let displayWidth = displaySize.width
            let displayHeight = displaySize.height
            let scene = MenuScene.init(size: CGSize(width: displayWidth, height: displayHeight))
            scene.scaleMode = .aspectFill
            let reveal = SKTransition.doorsOpenVertical(withDuration: 0.5)
            self.view?.presentScene(scene, transition: reveal)
        }
    }
}

