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
    case bullet = 2
    case enemy = 4
    case playerHit = 8
    case zombieHit = 16
}
enum NodesZPosition: CGFloat {
    case background, bullet, hero, enemy, joystick
}
class GameScene: SKScene, SKPhysicsContactDelegate {
    var velocityMultiplier: CGFloat = 0.12
    var heroDirection: CGFloat = 0.0
    var heroPosition = CGPoint.zero
    
    let displaySize: CGRect = UIScreen.main.bounds
    var gameSpace: CGRect
    var timer = Timer()
    var enemies = [SKSpriteNode]()
    var turrets: SKSpriteNode?
    override init(size: CGSize) {
        let maxRatio: CGFloat = 16.0/9.0
        let gameWidth = size.height/maxRatio
        let gameSide = (size.width - gameWidth) / 2
        
        gameSpace = CGRect(x: gameSide, y: 0, width: gameWidth, height: size.height)
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //MARK: Adding Objects
    lazy var player: SKSpriteNode = {
       let sprite = SKSpriteNode(imageNamed: "survivor-idle_handgun_0")
        sprite.position = CGPoint.zero
        sprite.zPosition = NodesZPosition.hero.rawValue
//        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        sprite.physicsBody = SKPhysicsBody(circleOfRadius: 100)
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.categoryBitMask = BodyType.player.rawValue
        sprite.physicsBody?.contactTestBitMask = BodyType.enemy.rawValue
        sprite.physicsBody?.collisionBitMask = BodyType.enemy.rawValue
        sprite.zRotation = 1.5
        sprite.setScale(0.3)
        return sprite
    }()
    
    lazy var background: SKSpriteNode = {
        let sprite = SKSpriteNode(imageNamed: "PostApocalypticMap")
        sprite.position = CGPoint.zero
        sprite.zPosition = NodesZPosition.background.rawValue
        sprite.setScale(2)
        return sprite
    }()
    lazy var analogJoystick: AnalogJoystick = {
       let js = AnalogJoystick(diameter: 100, colors: nil, images: (substrate: UIImage(named: "jSubstrate"), stick: UIImage(named: "jStick")))
        js.position = CGPoint(x: -displaySize.width/3.5, y: displaySize.height/2.75)
        js.zPosition = NodesZPosition.joystick.rawValue
        js.alpha = 0.5
        return js
    }()
    lazy var shootButton: SKSpriteNode = {
       let sprite = SKSpriteNode(imageNamed: "pistolButton")
        sprite.setScale(0.6)
        sprite.zRotation = 4.75
        sprite.position = CGPoint(x: -displaySize.width/4 , y: -displaySize.height/2.4)
        sprite.zPosition = NodesZPosition.joystick.rawValue
        sprite.alpha = 1
        return sprite
    }()
    lazy var meleeButton: SKSpriteNode = {
        let sprite = SKSpriteNode(imageNamed: "Knife")
        sprite.setScale(0.1)
        sprite.position = CGPoint(x: -displaySize.width/2.5 , y: -displaySize.height/3.5)
        sprite.zPosition = NodesZPosition.joystick.rawValue
        sprite.alpha = 1
        return sprite
    }()
    //MARK: Declare Object Settings
    var moveSpeed: TimeInterval = 0.3
    
    //MARK: Declare Object Actions
    let tapRec = UITapGestureRecognizer()
    
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
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
    private func spawnZombie() {
        let xPos = randomBetweenNumbers(firstNum: 0, secondNum: frame.width )

        let zombie = SKSpriteNode(imageNamed: "skeleton-idle_0")
//        zombie.position = CGPoint.zero
        zombie.position = CGPoint(x: CGFloat(xPos), y: self.frame.size.height/2)
        zombie.name = "Zombie"
        zombie.zPosition = NodesZPosition.enemy.rawValue
//        zombie.physicsBody = SKPhysicsBody(rectangleOf: zombie.frame.size)
        zombie.physicsBody = SKPhysicsBody(circleOfRadius: 100)
//        let presetTexture = SKTexture(imageNamed: "skeleton-idle_0.png")
//        zombie.physicsBody = SKPhysicsBody(texture: presetTexture, size: presetTexture.size())
        zombie.physicsBody?.usesPreciseCollisionDetection = true
        zombie.physicsBody?.isDynamic = true
        zombie.physicsBody?.affectedByGravity = false
        zombie.physicsBody?.categoryBitMask = BodyType.enemy.rawValue
        zombie.physicsBody?.contactTestBitMask = BodyType.bullet.rawValue
        zombie.physicsBody?.collisionBitMask = BodyType.player.rawValue | BodyType.enemy.rawValue
        zombie.zRotation = 1.5
        zombie.setScale(0.3)
        enemies.append(zombie)
        addChild(zombie)
    }
    private func zombieAttackTimer() {
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(zombieAttack), userInfo: nil, repeats: true)
    }
    @objc func zombieAttack() {
        let location = player.position
        for node in self.children {
            if (node.name == "Zombie") {
                let followPlayer = SKAction.move(to: player.position, duration: 2)
                node.run(followPlayer)
                //Aim
                let dx = (location.x) - node.position.x
                let dy = (location.y) - node.position.y
                let angle = atan2(dy, dx)

                node.zRotation = angle

                //Seek
                let velocityX =  cos(angle) * 1
                let velocityY =  sin(angle) * 1

                node.position.x += velocityX
                node.position.y += velocityY
            }
        }
    }
    override func didMove(to view: SKView) {
        setupNode()
        setupJoyStick()
        characterIdle()
        //setupSwipeMovement()
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector.init(dx: 1, dy: 0)
        
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
    
    func cleanUp() {
        // only need to call when presenting a different scene class
        for gesture in (self.view?.gestureRecognizers)! {
            self.view?.removeGestureRecognizer(gesture)
        }
    }
    override func update(_ currentTime: TimeInterval) {
        if enemies.count < 3 {
            //spawnZombie()
        }
        zombieAttack()
        if self.player.position.x > self.gameSpace.maxX - self.player.size.width * 3.5{
            self.player.position.x = self.gameSpace.maxX - self.player.size.width * 3.5
        }
        if self.player.position.x < self.gameSpace.minX + self.player.size.width * -2 {
            self.player.position.x = self.gameSpace.minX + self.player.size.width * -2
        }
        if self.player.position.y > self.gameSpace.maxY - self.player.size.height * 7.8 {
            self.player.position.y = self.gameSpace.maxY - self.player.size.height * 7.8
        }
        if self.player.position.y < self.gameSpace.minY + self.player.size.height * -6.5 {
            self.player.position.y = self.gameSpace.minY + self.player.size.height * -6.5
        }
    }
    func meleeAttack() {
        let meleeAttackAnimation: SKAction = SKAction(named: "MeleeAttack", duration: 1)!
        player.run(meleeAttackAnimation)
    }
    func shootAttack(direction: CGFloat, position: CGPoint) {
        player.removeAllActions()
        let shootAttackAnimation: SKAction = SKAction(named: "ShootAttack", duration: 0.5)!
        let bullet = SKSpriteNode(imageNamed: "Bullet")

        bullet.setScale(0.1)
        bullet.position = player.position
        bullet.zPosition = NodesZPosition.bullet.rawValue
        bullet.zRotation = player.zRotation
        let action = SKAction.move(to: CGPoint(x: 1000 * cos(bullet.zRotation) + bullet.position.x, y: 1000 * sin(bullet.zRotation) + bullet.position.y), duration: 0.8)
        let actionDone = SKAction.removeFromParent()
        bullet.run(SKAction.sequence([action,actionDone]))
        bullet.zRotation = player.zRotation + 4.75
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody?.affectedByGravity = false
        bullet.physicsBody?.isDynamic = false
        bullet.physicsBody?.categoryBitMask = BodyType.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = 1
        bullet.physicsBody?.collisionBitMask = 0
        player.run(shootAttackAnimation)
        addChild(bullet)
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
            if (turrets == nil) {
                let turret = SKSpriteNode(imageNamed: "turret")
                turret.position.x = t.location(in: self).x
                turret.position.y = t.location(in: self).y
                turret.zPosition = NodesZPosition.hero.rawValue
                turrets = turret
                addChild(turret)
            }
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
//        for t in touches {
////            self.touchMoved(toPoint: t.location(in: self))
////            let touchPoint = t.location(in: self)
////            let previousTouchPoint = t.previousLocation(in: self)
////            let aDX = touchPoint.x - previousTouchPoint.x
////            let aDY = touchPoint.y - previousTouchPoint.y
////
////            player.position.x += aDX
////            player.position.y += aDY
//            
//        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    //MARK: Physics Contacts
    func didBegin(_ contact: SKPhysicsContact) {
        if (contact.bodyA.categoryBitMask == BodyType.enemy.rawValue && contact.bodyB.categoryBitMask == BodyType.bullet.rawValue) {
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            print("Zombie hit")
            enemies.removeFirst()
        } else if (contact.bodyB.categoryBitMask == BodyType.enemy.rawValue && contact.bodyA.categoryBitMask == BodyType.bullet.rawValue) {
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            print("Zombie hit but 2nd line")
            enemies.removeFirst()
        }
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue && contact.bodyB.categoryBitMask == BodyType.enemy.rawValue) {
            print("Human hit")
            let zombieAttack: SKAction = SKAction(named: "ZombieAttack", duration: 1)!
            let attackDelay: SKAction = SKAction.wait(forDuration: 3)
            contact.bodyB.node?.run(SKAction.sequence([zombieAttack,attackDelay]))
        } else if (contact.bodyB.categoryBitMask == BodyType.enemy.rawValue && contact.bodyA.categoryBitMask == BodyType.player.rawValue) {
            print("Human hit but 2nd line")
        }
    }
}

extension SKSpriteNode {
    func drawBorder(color: UIColor, width: CGFloat) {
        let shapeNode = SKShapeNode(rect: frame)
        shapeNode.fillColor = .clear
        shapeNode.strokeColor = color
        shapeNode.lineWidth = width
        addChild(shapeNode)
    }
}
