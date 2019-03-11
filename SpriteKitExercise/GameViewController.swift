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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    func setupViews() {
        view.addSubview(skView)
        let displaySize: CGRect = UIScreen.main.bounds
        let displayWidth = displaySize.width
        let displayHeight = displaySize.height
        skView.frame = CGRect(x: 0.0, y: 0.0, width: displayWidth, height: displayHeight)
        
        let scene = GameScene.init(size: CGSize(width: displayWidth, height: displayHeight))
        scene.scaleMode = .aspectFill
        skView.ignoresSiblingOrder = true
//        skView.showsPhysics = true
        skView.presentScene(scene)
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
