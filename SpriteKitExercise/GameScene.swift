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
    case landmine = 32
    case explosion = 64
}
enum NodesZPosition: CGFloat {
    case background,landmine, bullet, playerMelee, hero, enemy, enemyMelee, joystick
}
class GameScene: SKScene, SKPhysicsContactDelegate {
    var velocityMultiplier: CGFloat = 0.06
    
    let displaySize: CGRect = UIScreen.main.bounds
    var gameSpace: CGRect
    var timer = Timer()
    var enemies = [SKSpriteNode]()
    var zombieCounter = 0
    var turrets: SKSpriteNode?
    var landmines = 1
    let maxZombie = 5
    var zombieCanAttackPlayer = true
    var zombieMissileCanHitPlayer = true
    var playerCanAttack = true
    var playerCanShoot = true
    var explosion = true
    var playerLife = 200
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
    lazy var healthBar: SKSpriteNode = {
        let sprite = SKSpriteNode(color:SKColor.yellow, size: CGSize(width: 30, height: playerLife))
        sprite.alpha = 0.75
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        sprite.zRotation = 3.14
        sprite.position = CGPoint(x: displaySize.width/2.5, y: displaySize.height/2.15)
        sprite.zPosition = NodesZPosition.joystick.rawValue
        return sprite
    }()
    lazy var player: SKSpriteNode = {
       let sprite = SKSpriteNode(imageNamed: "survivor-idle_handgun_0")
        sprite.position = CGPoint.zero
        sprite.zPosition = NodesZPosition.hero.rawValue
        let presetTexture = SKTexture(imageNamed: "survivor-idle_handgun_0")
        sprite.physicsBody = SKPhysicsBody(texture: presetTexture, size: presetTexture.size())
        sprite.physicsBody?.usesPreciseCollisionDetection = true
        sprite.physicsBody?.affectedByGravity = false
        sprite.physicsBody?.categoryBitMask = BodyType.player.rawValue
        sprite.physicsBody?.contactTestBitMask = BodyType.enemy.rawValue
        sprite.physicsBody?.collisionBitMask = BodyType.enemy.rawValue | BodyType.zombieHit.rawValue
        sprite.physicsBody?.isDynamic = true
        sprite.zRotation = 1.5
        sprite.setScale(0.2)
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
        let shader = SKShader(fileNamed: "shader1.fsh")
        shader.uniforms = [
            SKUniform(name: "u_gradient", texture: SKTexture(imageNamed: "jSubstrate")),
            SKUniform(name: "u_health", float: 0.55)
        ]
        sprite.shader = shader
        sprite.setScale(0.6)
        sprite.zRotation = 4.75
        sprite.position = CGPoint(x: -displaySize.width/4 , y: -displaySize.height/2.4)
        sprite.zPosition = NodesZPosition.joystick.rawValue
        sprite.alpha = 1
        return sprite
    }()
    lazy var meleeButton: SKSpriteNode = {
        let sprite = SKSpriteNode(imageNamed: "Knife")
        // Adding circle
        let shader = SKShader(fileNamed: "shader1.fsh")
        shader.uniforms = [
            SKUniform(name: "u_gradient", texture: SKTexture(imageNamed: "jSubstrate")),
            SKUniform(name: "u_health", float: 0.5)
        ]
        sprite.shader = shader
        
        sprite.setScale(0.1)
        sprite.position = CGPoint(x: -displaySize.width/2.5 , y: -displaySize.height/3)
        sprite.zPosition = NodesZPosition.joystick.rawValue
        sprite.alpha = 1
        return sprite
    }()
    lazy var landmineButton: SKSpriteNode = {
        let sprite = SKSpriteNode(imageNamed: "landmine")
        sprite.setScale(0.175)
        sprite.position = CGPoint(x: -displaySize.width/10, y: -displaySize.height/2.2)
        sprite.zPosition = NodesZPosition.joystick.rawValue
        sprite.alpha = 1
        return sprite
    }()
    //MARK: Declare Object Settings
    var moveSpeed: TimeInterval = 0.3
    
    //MARK: Declare Object Actions
    let tapRec = UITapGestureRecognizer()
    
    // spawning outside frame
    func randomPosition(spriteSize:CGSize) -> CGPoint {
        let angle = (CGFloat(arc4random_uniform(360)) * CGFloat.pi) / 180.0
        let radius = (size.width >= size.height ? (size.width + spriteSize.width) : (size.height + spriteSize.height)) / 2
        return CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
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
        let xPos = randomPosition(spriteSize: gameSpace.size)
        let zombie = SKSpriteNode(imageNamed: "skeleton-idle_0")
        zombie.position = CGPoint(x: -1 * xPos.x, y: -1 * xPos.y)
        zombie.name = "Zombie\(zombieCounter)"
        zombie.zPosition = NodesZPosition.enemy.rawValue
        let presetTexture = SKTexture(imageNamed: "skeleton-idle_0.png")
        zombie.physicsBody = SKPhysicsBody(texture: presetTexture, size: presetTexture.size())
        zombie.physicsBody?.usesPreciseCollisionDetection = true
        zombie.physicsBody?.isDynamic = true
        zombie.physicsBody?.affectedByGravity = false
        zombie.physicsBody?.categoryBitMask = BodyType.enemy.rawValue
        zombie.physicsBody?.contactTestBitMask = BodyType.bullet.rawValue
        zombie.physicsBody?.collisionBitMask = BodyType.player.rawValue
        zombie.zRotation = 1.5
        zombie.setScale(0.2)
        enemies.append(zombie)
        zombieCounter += 1
        run(SKAction.playSoundFileNamed("ZombieSpawn", waitForCompletion: false))
        addChild(zombie)
    }
    
    //MARK: Delays
    private func zombieAttackTimer() {
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(attackPlayerTrue), userInfo: nil, repeats: false)
    }
    @objc func attackPlayerTrue() {
        zombieCanAttackPlayer = true
    }
    
    private func zombieMissileTimer() {
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(zombieMissileTrue), userInfo: nil, repeats: false)
    }
    @objc func zombieMissileTrue() {
        zombieMissileCanHitPlayer = true
    }
    private func playerShootTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(playerShootTrue), userInfo: nil, repeats: false)
    }
    @objc func playerShootTrue() {
        playerCanShoot = true
    }
    private func playerAttackTimer() {
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(playerAttackTrue), userInfo: nil, repeats: false)
    }
    @objc func playerAttackTrue() {
        playerCanAttack = true
    }
    @objc func zombieAttack() {
        let location = player.position
        for node in enemies {
            let followPlayer = SKAction.move(to: player.position, duration: 3)
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
        addChild(healthBar)
        addChild(landmineButton)
    }
    private func setupJoyStick() {
        addChild(analogJoystick)
        analogJoystick.trackingHandler = { [unowned self] data in
            self.player.position = CGPoint(x: self.player.position.x + (data.velocity.x * self.velocityMultiplier), y: self.player.position.y + (data.velocity.y * self.velocityMultiplier))
            self.player.zRotation = data.angular + 1.5
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if enemies.count < maxZombie {
            spawnZombie()
        }
        healthBar.size.height = CGFloat(playerLife)
        zombieAttack()
        if self.player.position.x > self.gameSpace.maxX - self.player.size.width * 4.25{
            self.player.position.x = self.gameSpace.maxX - self.player.size.width * 4.25
        }
        if self.player.position.x < self.gameSpace.minX + self.player.size.width * -4 {
            self.player.position.x = self.gameSpace.minX + self.player.size.width * -4
        }
        if self.player.position.y > self.gameSpace.maxY - self.player.size.height * 8.75 {
            self.player.position.y = self.gameSpace.maxY - self.player.size.height * 8.75

        }
        if self.player.position.y < self.gameSpace.minY + self.player.size.height * -8.25 {
            self.player.position.y = self.gameSpace.minY + self.player.size.height * -8.25
        }
    }
    func meleeAttack() {
        let meleeAttackAnimation: SKAction = SKAction(named: "MeleeAttack", duration: 0.5)!
        let melee = SKSpriteNode(imageNamed: "PlayerHit")
        
        player.run(meleeAttackAnimation)
        melee.setScale(0.1)
        melee.size.height = melee.size.height + 90
        melee.position = player.position
        melee.zPosition = NodesZPosition.playerMelee.rawValue
        melee.zRotation = player.zRotation
        let action = SKAction.move(to: CGPoint(x: 40 * cos(melee.zRotation) + melee.position.x, y: 40 * sin(melee.zRotation) + melee.position.y), duration: 0.1)
        let actionDone = SKAction.removeFromParent()
        melee.run(SKAction.sequence([action,actionDone]))
        melee.zRotation = player.zRotation + 3
//        melee.physicsBody = SKPhysicsBody(rectangleOf: melee.size)
        let presetTexture = SKTexture(imageNamed: "PlayerHit")
        melee.physicsBody = SKPhysicsBody(texture: presetTexture, size: melee.size)
        melee.physicsBody?.affectedByGravity = false
        melee.physicsBody?.isDynamic = true
        melee.physicsBody?.usesPreciseCollisionDetection = false
        melee.physicsBody?.categoryBitMask = BodyType.playerHit.rawValue
        melee.physicsBody?.contactTestBitMask = BodyType.enemy.rawValue | BodyType.zombieHit.rawValue
        melee.physicsBody?.collisionBitMask = BodyType.enemy.rawValue | BodyType.zombieHit.rawValue
        run(SKAction.playSoundFileNamed("Knife.wav", waitForCompletion: false))
        addChild(melee)
    }
    func shootAttack() {
        let shootAttackAnimation: SKAction = SKAction(named: "ShootAttack", duration: 0.5)!
        let bullet = SKSpriteNode(imageNamed: "Bullet")

        bullet.setScale(0.05)
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
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        bullet.physicsBody?.categoryBitMask = BodyType.bullet.rawValue
        bullet.physicsBody?.contactTestBitMask = BodyType.enemy.rawValue
        bullet.physicsBody?.collisionBitMask = BodyType.enemy.rawValue
        run(SKAction.playSoundFileNamed("GunShot.flac", waitForCompletion: false))
        player.run(shootAttackAnimation)
        addChild(bullet)
        characterIdle()
    }
    func dropLandmine() {
        let landmine = SKSpriteNode(imageNamed: "landmine")
        
        landmine.setScale(0.1)
        landmine.position = player.position
        landmine.zPosition = NodesZPosition.landmine.rawValue
        landmine.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        landmine.physicsBody?.affectedByGravity = false
        landmine.physicsBody?.isDynamic = false
        landmine.physicsBody?.categoryBitMask = BodyType.landmine.rawValue
        landmine.physicsBody?.contactTestBitMask = BodyType.enemy.rawValue
        landmine.physicsBody?.collisionBitMask = BodyType.enemy.rawValue
        addChild(landmine)
        landmines -= 1
    }

    func landmineExplode(landmineNode: SKNode) {
        let explosion = SKSpriteNode(imageNamed: "LandmineExplode")
        explosion.position = landmineNode.position
        explosion.zPosition = NodesZPosition.joystick.rawValue
        explosion.setScale(0.1)
        explosion.zRotation = -1.5
//        explosion.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        let presetTexture = SKTexture(imageNamed: "LandmineExplode")
        explosion.physicsBody = SKPhysicsBody(texture: presetTexture, size: explosion.size)
        explosion.physicsBody?.categoryBitMask = BodyType.explosion.rawValue
        explosion.physicsBody?.contactTestBitMask = BodyType.enemy.rawValue
        explosion.physicsBody?.collisionBitMask = BodyType.enemy.rawValue
        explosion.physicsBody?.affectedByGravity = false
        explosion.physicsBody?.isDynamic = false
        run(SKAction.playSoundFileNamed("Explosion.flac", waitForCompletion: false))
        addChild(explosion)
        let scale = SKAction.scale(by: 7, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let delete = SKAction.removeFromParent()
        let explosionSequence = SKAction.sequence([scale, fadeOut, delete])
        explosion.run(explosionSequence)
        
    }
    func zombieAttackProjectile(zombieNode: SKNode) {
        let zombieAttackAction: SKAction = SKAction(named: "ZombieAttack", duration: 1)!
        let melee = SKSpriteNode(imageNamed: "ZombieHit")
        
        zombieNode.run(zombieAttackAction)
        melee.setScale(0.1)
        melee.size.width = melee.size.width + 30
        melee.size.height += 10
        melee.position = zombieNode.position
//        melee.position = CGPoint.zero
        melee.zPosition = NodesZPosition.enemyMelee.rawValue
        melee.zRotation = zombieNode.zRotation
        melee.alpha = 0
        let action = SKAction.move(to: CGPoint(x: 80 * cos(melee.zRotation) + melee.position.x, y: 80 * sin(melee.zRotation) + melee.position.y), duration: 0.1)
        let actionDone = SKAction.removeFromParent()
        let actionDelay = SKAction.wait(forDuration: 0.3)
        let actionFadeIn = SKAction.fadeIn(withDuration: 0.1)
        melee.run(SKAction.sequence([actionDelay,actionFadeIn,action,actionDone]))
        melee.zRotation = zombieNode.zRotation + 1.5
//        melee.physicsBody = SKPhysicsBody(rectangleOf: melee.size)
        let presetTexture = SKTexture(imageNamed: "ZombieHit")
        melee.physicsBody = SKPhysicsBody(texture: presetTexture, size: melee.size)
        melee.physicsBody?.affectedByGravity = false
        melee.physicsBody?.isDynamic = true
        melee.physicsBody?.usesPreciseCollisionDetection = true
        melee.physicsBody?.categoryBitMask = BodyType.zombieHit.rawValue
        melee.physicsBody?.contactTestBitMask = BodyType.player.rawValue | BodyType.playerHit.rawValue
        melee.physicsBody?.collisionBitMask = BodyType.player.rawValue | BodyType.playerHit.rawValue
        run(SKAction.playSoundFileNamed("ZombieAttack", waitForCompletion: false))

        addChild(melee)
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
                if playerCanShoot {
                    shootAttack()
                    playerCanShoot = false
                    playerShootTimer()
                }
            }
            if meleeButton.contains(t.location(in: self)) {
                if playerCanAttack {
                    meleeAttack()
                    playerCanAttack = false
                    playerAttackTimer()
                }
            }
            if landmineButton.contains(t.location(in: self)) {
                if landmines > 0 {
                    explosion = true
                    dropLandmine()
                }
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
            if let index = enemies.index(where: {$0.name == contact.bodyA.node?.name}) {
                contact.bodyA.node?.removeFromParent()
                contact.bodyB.node?.removeFromParent()
                print("Zombie hit")
                run(SKAction.playSoundFileNamed("ZombieDeath", waitForCompletion: false))
                enemies.remove(at: index)
            }
        } else if (contact.bodyB.categoryBitMask == BodyType.enemy.rawValue && contact.bodyA.categoryBitMask == BodyType.bullet.rawValue) {
            if let index = enemies.index(where: {$0.name == contact.bodyB.node?.name}) {
                contact.bodyA.node?.removeFromParent()
                contact.bodyB.node?.removeFromParent()
                print("Zombie hit")
                run(SKAction.playSoundFileNamed("ZombieDeath", waitForCompletion: false))
                enemies.remove(at: index)
            }
        }
        if (contact.bodyA.categoryBitMask == BodyType.enemy.rawValue && contact.bodyB.categoryBitMask == BodyType.playerHit.rawValue) {
            if let index = enemies.index(where: {$0.name == contact.bodyA.node?.name}) {
                contact.bodyA.node?.removeFromParent()
                contact.bodyB.node?.removeFromParent()
                print("Zombie hit")
                run(SKAction.playSoundFileNamed("ZombieDeath", waitForCompletion: false))

                enemies.remove(at: index)
            }
        } else if (contact.bodyB.categoryBitMask == BodyType.enemy.rawValue && contact.bodyA.categoryBitMask == BodyType.playerHit.rawValue) {
            if let index = enemies.index(where: {$0.name == contact.bodyB.node?.name}) {
                contact.bodyB.node?.removeFromParent()
                contact.bodyA.node?.removeFromParent()
                print("Zombie hit")
                run(SKAction.playSoundFileNamed("ZombieDeath", waitForCompletion: false))
                enemies.remove(at: index)
            }
        }

        
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue && contact.bodyB.categoryBitMask == BodyType.enemy.rawValue) {
            // Add timer to prevent spam
            if zombieCanAttackPlayer {
                zombieAttackProjectile(zombieNode: contact.bodyB.node!)
                zombieCanAttackPlayer = false
                zombieAttackTimer()
            }
        } else if (contact.bodyA.categoryBitMask == BodyType.enemy.rawValue && contact.bodyB.categoryBitMask == BodyType.player.rawValue) {
            // Add timer to prevent spam
            if zombieCanAttackPlayer {
                zombieAttackProjectile(zombieNode: contact.bodyA.node!)
                zombieCanAttackPlayer = false
                zombieAttackTimer()
            }
        }
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue && contact.bodyB.categoryBitMask == BodyType.zombieHit.rawValue) {
            if zombieMissileCanHitPlayer {
                print("Human hit")
                run(SKAction.playSoundFileNamed("PlayerHit.wav", waitForCompletion: false))
                playerLife -= 20
                if playerLife <= 0 {
                    contact.bodyA.node?.removeFromParent()
                    run(SKAction.playSoundFileNamed("PlayerDeath.mp3", waitForCompletion: false))

                    self.view?.scene?.isUserInteractionEnabled = false
                }
                zombieMissileCanHitPlayer = false
                zombieMissileTimer()
            }
        } else if (contact.bodyA.categoryBitMask == BodyType.zombieHit.rawValue && contact.bodyB.categoryBitMask == BodyType.player.rawValue) {
            if zombieMissileCanHitPlayer {
                print("Human hit but 2nd line")
                playerLife -= 20
                if playerLife <= 0 {
                    contact.bodyB.node?.removeFromParent()
                    run(SKAction.playSoundFileNamed("PlayerHit.wav", waitForCompletion: false))
                    self.view?.scene?.isUserInteractionEnabled = false
                }
                zombieMissileCanHitPlayer = false
                zombieMissileTimer()
            }
        }
        if (contact.bodyA.categoryBitMask == BodyType.playerHit.rawValue && contact.bodyB.categoryBitMask == BodyType.zombieHit.rawValue) {
            print("Counter!")
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.zombieHit.rawValue && contact.bodyB.categoryBitMask == BodyType.playerHit.rawValue) {
            print("Counter!")
            contact.bodyA.node?.removeFromParent()
        }
        if (contact.bodyA.categoryBitMask == BodyType.landmine.rawValue && contact.bodyB.categoryBitMask == BodyType.enemy.rawValue) {
            if explosion {
                landmineExplode(landmineNode: contact.bodyA.node!)
                explosion = false
            }
            contact.bodyA.node?.removeFromParent()
            if landmines == 0 {
                landmines += 1
            }
        } else if (contact.bodyB.categoryBitMask == BodyType.landmine.rawValue && contact.bodyA.categoryBitMask == BodyType.enemy.rawValue) {
            if explosion {
                landmineExplode(landmineNode: contact.bodyB.node!)
                explosion = false
            }
            contact.bodyB.node?.removeFromParent()
            if landmines == 0 {
                landmines += 1
            }
        }
        if (contact.bodyA.categoryBitMask == BodyType.enemy.rawValue && contact.bodyB.categoryBitMask == BodyType.explosion.rawValue) {
            if let index = enemies.index(where: {$0.name == contact.bodyA.node?.name}) {
                contact.bodyA.node?.removeFromParent()
                print("\(contact.bodyA.node!.name) exploded")
                enemies.remove(at: index)
            }
        } else if (contact.bodyB.categoryBitMask == BodyType.enemy.rawValue && contact.bodyA.categoryBitMask == BodyType.explosion.rawValue) {
            if let index = enemies.index(where: {$0.name == contact.bodyB.node?.name}) {
                contact.bodyB.node?.removeFromParent()
                print("\(contact.bodyB.node!.name) exploded")
                enemies.remove(at: index)
            }
        }
    }
}
