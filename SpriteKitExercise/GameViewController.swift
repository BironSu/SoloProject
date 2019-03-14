//
//  GameViewController.swift
//  SpriteKitExercise
//
//  Created by Biron Su on 2/4/19.
//  Copyright © 2019 Pursuit. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    lazy var skView: SKView = {
        let view = SKView()
        view.isMultipleTouchEnabled = true
        return view
    }()
    let displaySize: CGRect = UIScreen.main.bounds
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMenuScene()
    }
    func setupMenuScene() {
        view.addSubview(skView)
        let displayWidth = displaySize.width
        let displayHeight = displaySize.height
        let menuScene = MenuScene(size: CGSize(width: displayWidth, height: displayHeight))
        skView.frame = CGRect(x: 0.0, y: 0.0, width: displayWidth, height: displayHeight)
        menuScene.scaleMode = .aspectFill
        skView.ignoresSiblingOrder = true
        skView.presentScene(menuScene)
    }
    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
