//
//  MenuScene.swift
//  SpriteKitExercise
//
//  Created by Biron Su on 3/14/19.
//  Copyright © 2019 Pursuit. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    
    let playButton = SKLabelNode()
    let background = SKSpriteNode(imageNamed: "DontOpenDeadInside")
    
    override init(size: CGSize) {
        super.init(size: size)
        background.zRotation = -1.55
        background.alpha = 0.3
        background.setScale(0.6)
        background.zPosition = 1
        background.position = CGPoint(x: size.width / 2, y: size.height / 1.95)

        addChild(background)
        playButton.zPosition = 10
        playButton.zRotation = -1.55
        playButton.fontColor = SKColor.black
        playButton.text = "p l a y"
        playButton.position = CGPoint(x: size.width / 2, y: size.height / 2)
        
        addChild(playButton)
        
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchLocation = touch!.location(in: self)
        if playButton.contains(touchLocation) {
            let displaySize: CGRect = UIScreen.main.bounds
            let displayWidth = displaySize.width
            let displayHeight = displaySize.height
            let scene = GameScene.init(size: CGSize(width: displayWidth, height: displayHeight))
            scene.scaleMode = .aspectFill
            let reveal = SKTransition.doorsOpenVertical(withDuration: 0.5)
            self.view?.presentScene(scene, transition: reveal)
        }
    }
}
