//
//  GameScene.swift
//  SpriteKitExercise
//
//  Created by Biron Su on 2/4/19.
//  Copyright © 2019 Pursuit. All rights reserved.
//

import SpriteKit
import GameplayKit

enum BodyType: UInt32 {
    case player = 1
    case tree = 2
    case wall = 4
    case chest = 8
    case enemy = 16
}
enum NodesZPosition: CGFloat {
    case background, hero, joystick
}
class GameScene: SKScene, SKPhysicsContactDelegate {
    var velocityMultiplier: CGFloat = 0.12
    var heroDirection: CGFloat = 0.0
    var heroPosition = CGPoint.zero
    let displaySize: CGRect = UIScreen.main.bounds
    //MARK: Adding Objects
    lazy var player: SKSpriteNode = {
       let sprite = SKSpriteNode(imageNamed: "survivor-idle_handgun_0")
        sprite.position = CGPoint.zero
        sprite.zPosition = NodesZPosition.hero.rawValue
        sprite.zRotation = 1.5
        sprite.setScale(0.3)
        return sprite
    }()
    
    lazy var background: SKSpriteNode = {
        let sprite = SKSpriteNode(imageNamed: "Grass_Background_cropped")
        sprite.position = CGPoint.zero
        sprite.zPosition = NodesZPosition.background.rawValue
        sprite.setScale(2)
        return sprite
    }()
    lazy var analogJoystick: AnalogJoystick = {
       let js = AnalogJoystick(diameter: 100, colors: nil, images: (substrate: UIImage(named: "jSubstrate"), stick: UIImage(named: "jStick")))
        js.position = CGPoint(x: -displaySize.width/3.5, y: -displaySize.height/3)
        return js
    }()
    lazy var shootButton: SKSpriteNode = {
       let sprite = SKSpriteNode(imageNamed: "pistolButton")
            sprite.setScale(0.8)
            sprite.position = CGPoint(x: displaySize.width/3 , y: -displaySize.height/4)
            sprite.zPosition = NodesZPosition.joystick.rawValue
        return sprite
    }()
    lazy var meleeButton: SKSpriteNode = {
        let sprite = SKSpriteNode(imageNamed: "Knife")
        sprite.setScale(0.15)
        sprite.position = CGPoint(x: displaySize.width/3 , y: -displaySize.height/2.5)
        sprite.zPosition = NodesZPosition.joystick.rawValue
        return sprite
    }()
    var lastDirection = "Down"
    //MARK: Declare Object Settings
    var moveSpeed: TimeInterval = 0.3
    
    //MARK: Declare Object Actions
    let swipeRightRec = UISwipeGestureRecognizer()
    let swipeLeftRec = UISwipeGestureRecognizer()
    let swipeUpRec = UISwipeGestureRecognizer()
    let swipeDownRec = UISwipeGestureRecognizer()
    let tapRec = UITapGestureRecognizer()
    
    private func characterIdle() {
        player.removeAllActions()
        let playerIdle = SKAction(named: "PlayerIdle")!
        player.run(SKAction.repeatForever(playerIdle))
    }
    private func characterWalk() {
        player.removeAllActions()
        let playerWalk = SKAction(named: "PlayerWalking")!
        player.run(SKAction.repeatForever(playerWalk))
    }
    override func didMove(to view: SKView) {
        setupNode()
        setupJoyStick()
        characterIdle()
        //setupSwipeMovement()
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector.init(dx: 1, dy: 0)
        
        for possibleChest in self.children {
            if (possibleChest.name == "Chest") {
                if (possibleChest is SKSpriteNode) {
                    possibleChest.physicsBody?.categoryBitMask = BodyType.chest.rawValue
                    print("found chest")
                }
            }
        }
    }
    //MARK: Adding View
    private func setupView() {
        
    }
    //MARK: Adding Objects

    private func setupNode() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(background)
        addChild(player)
        addChild(shootButton)
        addChild(meleeButton)
    }
    private func setupJoyStick() {
        addChild(analogJoystick)
        analogJoystick.trackingHandler = { [unowned self] data in
            self.player.position = CGPoint(x: self.player.position.x + (data.velocity.x * self.velocityMultiplier), y: self.player.position.y + (data.velocity.y * self.velocityMultiplier))
            self.player.zRotation = data.angular + 1.5
            self.heroDirection = self.player.zRotation
            self.heroPosition = self.player.position
        }
    }
    // SWIPE MOVEMENTS
    private func setupSwipeMovement() {
        swipeRightRec.addTarget(self, action: #selector(GameScene.swipedRight))
        swipeRightRec.direction = .right
        self.view!.addGestureRecognizer(swipeRightRec)
        
        swipeLeftRec.addTarget(self, action: #selector(GameScene.swipedLeft))
        swipeLeftRec.direction = .left
        self.view!.addGestureRecognizer(swipeLeftRec)
        
        swipeUpRec.addTarget(self, action: #selector(GameScene.swipedUp))
        swipeUpRec.direction = .up
        self.view!.addGestureRecognizer(swipeUpRec)
        
        swipeDownRec.addTarget(self, action: #selector(GameScene.swipedDown))
        swipeDownRec.direction = .down
        self.view!.addGestureRecognizer(swipeDownRec)
    }
    // TAP GESTURE
    private func setupTapGesture() {
        tapRec.addTarget(self, action: #selector(GameScene.tappedView))
        tapRec.numberOfTouchesRequired = 2
        tapRec.numberOfTapsRequired = 3
        self.view!.addGestureRecognizer(tapRec)
    }
    private func setupChest() {
        for possibleChest in self.children {
            if (possibleChest.name == "Chest") {
                if (possibleChest is SKSpriteNode) {
                    possibleChest.physicsBody?.categoryBitMask = BodyType.chest.rawValue
                    possibleChest.zPosition = 1
                    print("found chest")
                }
            }
        }
    }
    private func setupTree() {
        
    }
    private func setupRock() {
        
    }
    private func setupEnemy() {
        
    }
    //MARK: ================== Gesture Recognizers
    @objc func tappedView() {
        print("Tapped Three Times")
    }
    @objc func swipedRight() {
        player.removeAllActions()
        lastDirection = "Right"
        move(theXAmount: 50, theYAmount: 0, theAnimation: "WalkRight")
    }
    @objc func swipedLeft() {
        player.removeAllActions()
        lastDirection = "Left"
        move(theXAmount: -50, theYAmount: 0, theAnimation: "WalkLeft")
    }
    @objc func swipedUp() {
        player.removeAllActions()
        lastDirection = "Up"
        move(theXAmount: 0, theYAmount: 50, theAnimation: "WalkUp")
    }
    @objc func swipedDown() {
        player.removeAllActions()
        lastDirection = "Down"
        move(theXAmount: 0, theYAmount: -50, theAnimation: "WalkDown")
    }
    func cleanUp() {
        // only need to call when presenting a different scene class
        for gesture in (self.view?.gestureRecognizers)! {
            self.view?.removeGestureRecognizer(gesture)
        }
    }
    override func update(_ currentTime: TimeInterval) {
//        for node in self.children {
//            if (node.name == "Chest") {
//                if (node.position.y > player.position.y) {
//                    node.zPosition = -100
//                }
//            }
//        }
    }
    func move(theXAmount: CGFloat, theYAmount: CGFloat, theAnimation: String){
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.isDynamic = true
        let wait: SKAction = SKAction.wait(forDuration: 2)
        let walkAnimation: SKAction = SKAction(named: theAnimation, duration: moveSpeed)!
        let moveAction: SKAction = SKAction.moveBy(x: theXAmount, y: theYAmount, duration: moveSpeed)
        let finish: SKAction = SKAction.run {
            self.player.physicsBody?.affectedByGravity = false
            self.player.physicsBody?.isDynamic = true
            
        }
        player.run(SKAction.group([wait, walkAnimation, moveAction, finish, wait]))
    }
    func meleeAttack() {
        let meleeAttackAnimation: SKAction = SKAction(named: "MeleeAttack", duration: 1)!
        player.run(meleeAttackAnimation)
    }
    func shootAttack(direction: CGFloat, position: CGPoint) {
        player.removeAllActions()
        let shootAttackAnimation: SKAction = SKAction(named: "ShootAttack", duration: 0.5)!
//            lazy var bullet: SKSpriteNode = {
//                let sprite = SKSpriteNode(imageNamed: "Coin")
//                sprite.position = player.position
//                sprite.zPosition = NodesZPosition.hero.rawValue
//                sprite.setScale(2)
//                return sprite
//            }()
        let bullet = SKSpriteNode(imageNamed: "Coin")
        bullet.setScale(2)
        bullet.position = position
        bullet.zPosition = player.zPosition
        bullet.zRotation = player.zRotation
        
        let action = SKAction.move(to: CGPoint(x: 1000 * cos(bullet.zRotation) + bullet.position.x, y: 1000 * sin(bullet.zRotation) + bullet.position.y), duration: 0.8)
        let actionDone = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([action,actionDone]))
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.isDynamic = false
        addChild(bullet)
        player.run(shootAttackAnimation)
        characterIdle()
    }
    
    func touchDown(atPoint pos : CGPoint) {
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            
            self.touchDown(atPoint: t.location(in: self))
            if shootButton.contains(t.location(in: self)) {
                shootAttack(direction: heroDirection, position: heroPosition)
            }
            if meleeButton.contains(t.location(in: self)) {
                meleeAttack()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    //MARK: Physics Contacts
    func didBegin(_ contact: SKPhysicsContact) {
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue && contact.bodyB.categoryBitMask == BodyType.chest.rawValue) {
            print("hit chest")
            
        } else if (contact.bodyB.categoryBitMask == BodyType.player.rawValue && contact.bodyA.categoryBitMask == BodyType.chest.rawValue) {
            print("hit chest")
        }
    }
}
