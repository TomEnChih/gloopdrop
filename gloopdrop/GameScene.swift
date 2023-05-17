//
//  GameScene.swift
//  gloopdrop
//
//  Created by Tammy Coron on 1/24/2020.
//  Copyright © 2020 Just Write Code LLC. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
  
  let player = Player()
  let playerSpeed: CGFloat = 1.5
  
  override func didMove(to view: SKView) {
    
    // Set up background
    let background = SKSpriteNode(imageNamed: "background_1")
    background.anchorPoint = CGPoint(x: 0, y: 0)
    background.position = CGPoint(x: 0, y: 0)
    addChild(background)
    
    // Set up foreground
    let foreground = SKSpriteNode(imageNamed: "foreground_1")
    foreground.anchorPoint = CGPoint(x: 0, y: 0)
    foreground.position = CGPoint(x: 0, y: 0)
    addChild(foreground)
    
    // Set up player
    player.position = CGPoint(x: size.width/2, y: foreground.frame.maxY)
    player.setupConstraints(floor: foreground.frame.maxY)
    addChild(player)
    player.walk()
  }
  
  // MARK: - TOUCH HANDLING
  
  /* ############################################################ */
  /*                 TOUCH HANDLERS STARTS HERE                   */
  /* ############################################################ */
  
  func touchDown(atPoint pos: CGPoint) {
    // Calculate the speed based on current position and tap location
    #warning("這裡還是有點不太懂")
    let distance = hypot(pos.x-player.position.x, pos.y-player.position.y)
    let calculatedSpeed = TimeInterval(distance/playerSpeed) / 255
    
    if pos.x < player.position.x {
      player.moveToPosition(pos: pos, direction: "L", speed: calculatedSpeed)
    } else {
      player.moveToPosition(pos: pos, direction: "R", speed: calculatedSpeed)
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchDown(atPoint: t.location(in: self)) }
  }
}
