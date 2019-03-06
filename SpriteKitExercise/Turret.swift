//
//  Turret.swift
//  SpriteKitExercise
//
//  Created by Biron Su on 3/5/19.
//  Copyright © 2019 Pursuit. All rights reserved.
//

import SpriteKit

class Turret: SKSpriteNode {
    
    static let playerTurret = "Player Turret"
    
    var closestZombie: SKSpriteNode!
    
    func updateClosestZombie() {
        let gameScene = (self.scene! as! GameScene)
        let zombieArray = gameScene.enemies
        
        var prevDistance:CGFloat = 1000000
        var closestZombie = zombieArray[0]
        
        for zombie in zombieArray {
            
            let distance = hypot(zombie.position.x - self.position.x, zombie.position.y - self.position.y)
            if distance < prevDistance {
                prevDistance = distance
                closestZombie = zombie
            }
        }
        self.closestZombie = closestZombie
    }
    
    func turnTowardsClosestZombie() {
        let angle = atan2(closestZombie.position.x - self.position.x , closestZombie.position.y - self.position.y)
        let actionTurn = SKAction.rotate(toAngle: -(angle - CGFloat(Double.pi/2)), duration: 0.2)
        self.run(actionTurn)
    }
    
    private func makeTurretBullet() -> SKSpriteNode {
        let turretBullet = SKSpriteNode(imageNamed: "Bullet")
        turretBullet.position = self.position
        turretBullet.zPosition = 20
        turretBullet.size = CGSize(width: 20, height: 20)
        //turretBullet.setScale (frame.size.height / 5000)
        
        turretBullet.physicsBody = SKPhysicsBody(circleOfRadius: max(turretBullet.size.width / 2, turretBullet.size.height / 2))
        turretBullet.physicsBody?.affectedByGravity = false
        turretBullet.physicsBody?.categoryBitMask = BodyType.bullet.rawValue
        turretBullet.physicsBody?.collisionBitMask = BodyType.enemy.rawValue
        turretBullet.physicsBody?.contactTestBitMask = BodyType.enemy.rawValue
        return turretBullet
    }
    
    private func fire(turretBullet: SKSpriteNode) {
        var dx = CGFloat(closestZombie.position.x - self.position.x)
        var dy = CGFloat(closestZombie.position.y - self.position.y)
        let magnitude = sqrt(dx * dx + dy * dy)
        dx /= magnitude
        dy /= magnitude
        
        let vector = CGVector(dx: 4.0 * dx, dy: 4.0 * dy)
        
        turretBullet.physicsBody?.applyImpulse(vector)
    }
    
    func addBulletThenShootAtClosestZOmbie() {
        let bullet = makeTurretBullet()
        scene!.addChild(bullet)
        fire(turretBullet: bullet)
    }
}
