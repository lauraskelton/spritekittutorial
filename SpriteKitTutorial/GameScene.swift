//
//  GameScene.swift
//  SpriteKitTutorial
//
//  Created by Laura Skelton on 6/25/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

import SpriteKit

enum ColliderType: UInt32 {
    case Projectile = 1
    case Monster = 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var lastSpawnTimeInterval:NSTimeInterval
    var lastUpdateTimeInterval:NSTimeInterval
    var player: SKSpriteNode
    var monstersDestroyed = 0
    
    func rwAdd(a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPoint(x: a.x + b.x, y: a.y + b.y)
    }
    
    func rwSub(a: CGPoint, b: CGPoint) -> CGPoint {
        return CGPoint(x: a.x - b.x, y: a.y - b.y)
    }
    
    func rwMult(a: CGPoint, b: CGFloat) -> CGPoint {
        return CGPoint(x: a.x * b, y: a.y * b)
    }
    
    func rwLength(a: CGPoint) -> CGFloat {
        return CGFloat(sqrtf( Float(a.x * a.x) + Float(a.y * a.y)))
    }
    
    func rwNormalize(a: CGPoint) -> CGPoint {
        
        let length = rwLength(a)
        
        return CGPoint(x: a.x/length, y: a.y/length)
        
    }
    
    init(size:CGSize) {
        self.lastSpawnTimeInterval = 0
        self.lastUpdateTimeInterval = 0
        self.player = SKSpriteNode(imageNamed:"Player")
        
        super.init(size: size)
    }
    
    init(coder aDecoder: NSCoder!)
    {
        self.lastSpawnTimeInterval = 0
        self.lastUpdateTimeInterval = 0
        self.player = SKSpriteNode(imageNamed:"Player")
        
        super.init(coder: aDecoder)
    }
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        self.backgroundColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Ninja Fight!";
        myLabel.fontSize = 60;
        myLabel.fontColor = UIColor.blackColor()
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMaxY(self.frame) - 80)
        
        self.addChild(myLabel)
        
        player.position = CGPoint(x:CGRectGetMinX(self.frame) + 350, y:CGRectGetMidY(self.frame))
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = self
        
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        
        // play pew pew sound
        self.runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
        // 1 - Choose one of the touches to work with
        let touch : UITouch = touches.anyObject() as UITouch
        let location: CGPoint = touch.locationInNode(self)
        //println(location)
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed:"projectile")
        projectile.position = self.player.position
        
        // add projectile physics body to detect collisions with monsters
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody.dynamic = true
        projectile.physicsBody.categoryBitMask = ColliderType.Projectile.toRaw()
        projectile.physicsBody.contactTestBitMask = ColliderType.Monster.toRaw()
        projectile.physicsBody.collisionBitMask = 0
        projectile.physicsBody.usesPreciseCollisionDetection = true
        
        // 3- Determine offset of location to projectile
        let offset : CGPoint = rwSub(location, b: projectile.position)
        
        // 4 - Bail out if you are shooting down or backwards
        if offset.x <= 0 {
            return
        }
        
        // 5 - OK to add now - we've double checked position
        self.addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        let direction = rwNormalize(offset)
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = rwMult(direction, b: 1000)
        
        // 8 - Add the shoot amount to the current position
        let realDest = rwAdd(shootAmount, b: projectile.position)
        
        // 9 - Create the actions
        let velocity : CGFloat = 480.0/1.0
        let realMoveDuration = NSTimeInterval(self.size.width / velocity)
        let actionMove = SKAction.moveTo(realDest, duration: realMoveDuration)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.runAction(SKAction.sequence([actionMove,actionMoveDone]))
        
    }
    
    func projectileCollidedWithMonster(projectile: SKNode, monster: SKNode) {
        println("Hit!")
        projectile.removeFromParent()
        monster.removeFromParent()
        
        self.monstersDestroyed++
        if self.monstersDestroyed > 30 {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won:true)
            self.view.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact!) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask & ColliderType.Projectile.toRaw() != 0 &&
            secondBody.categoryBitMask & ColliderType.Monster.toRaw() != 0 {
                self.projectileCollidedWithMonster(firstBody.node, monster: secondBody.node)
        }
    }
    
    
    /*
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    /* Called when a touch begins */
    
    for touch: AnyObject in touches {
    let location = touch.locationInNode(self)
    
    let sprite = SKSpriteNode(imageNamed:"Player")
    
    sprite.xScale = 1.0
    sprite.yScale = 1.0
    sprite.position = location
    
    let action = SKAction.rotateByAngle(CGFloat(M_PI), duration:1)
    
    sprite.runAction(SKAction.repeatActionForever(action))
    
    self.addChild(sprite)
    }
    }
    */
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        // Handle time delta.
        // If we drop below 60fps, we still want everything to move the same distance.
        
        var timeSinceLast: CFTimeInterval = currentTime - lastUpdateTimeInterval
        lastUpdateTimeInterval = timeSinceLast
        if timeSinceLast > 1 { // more than a second since last update
            timeSinceLast = 1.0 / 60.0
            lastUpdateTimeInterval = currentTime
        }
        
        self.updateWithTimeSinceLastUpdate(timeSinceLast)
    }
    
    
    func addMonster() {
        // create sprite
        
        let monster = SKSpriteNode(imageNamed:"Monster")
        
        // add monster physics body
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size)
        monster.physicsBody.dynamic = true
        monster.physicsBody.categoryBitMask = ColliderType.Monster.toRaw()
        monster.physicsBody.contactTestBitMask = ColliderType.Projectile.toRaw()
        monster.physicsBody.collisionBitMask = 0
        
        // determine where to spawn the monster
        let minY: Int = Int(monster.size.height / 2)
        let maxY: Int = Int(self.frame.size.height - monster.size.height / 2)
        let rangeY: Int = maxY - minY
        let actualY: Int = (Int(arc4random()) % rangeY) + minY
        
        // Create the monster slightly off-screen along the right edge,
        // and along a random position along the Y axis as calculated above
        monster.position = CGPoint(x: Int(self.frame.size.width) as Int, y: actualY)
        self.addChild(monster)
        
        // Determine speed of the monster
        let minDuration: Int = 4
        let maxDuration: Int = 8
        let rangeDuration: Int = maxDuration - minDuration
        let actualDuration: Int = (Int(arc4random()) % rangeDuration) + minDuration
        
        // Create the actions
        let actionMove = SKAction.moveTo(CGPoint(x: Int(-monster.size.width/2), y: actualY), duration: NSTimeInterval(actualDuration))
        let actionLose = SKAction.runBlock({
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameOverScene(size: self.size, won:false)
            self.view.presentScene(gameOverScene, transition: reveal)
            })
        
        let actionMoveDone = SKAction.removeFromParent()
        
        monster.runAction(SKAction.sequence([actionMove, actionLose, actionMoveDone]))
        
    }
    
    func updateWithTimeSinceLastUpdate(timeSinceLast: CFTimeInterval) {
        lastSpawnTimeInterval += timeSinceLast
        if lastSpawnTimeInterval > 1 {
            lastSpawnTimeInterval = 0
            self.addMonster()
        }
    }
}