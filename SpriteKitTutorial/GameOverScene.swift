//
//  GameOverScene.swift
//  SpriteKitTutorial
//
//  Created by Laura Skelton on 6/25/14.
//  Copyright (c) 2014 Laura Skelton. All rights reserved.
//

import SpriteKit

class GameOverScene: SKScene {
    
    init(size:CGSize, won:Bool) {
        super.init(size:size)
        
        self.backgroundColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        var message: NSString
        if won {
            message = "You Won!"
        } else {
            message = "You Lose :["
        }
        
        var label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.blackColor()
        label.position = CGPointMake(self.size.width/2, self.size.height/2)
        self.addChild(label)
        
        let waitAction = SKAction.waitForDuration(3.0)
        let blockAction = SKAction.runBlock({
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let myScene = GameScene(size: self.size)
            self.view.presentScene(myScene, transition: reveal)
            })
    }
}
