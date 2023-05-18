//
//  Player.swift
//  gloopdrop
//
//  Created by user on 2023/5/17.
//  Copyright © 2023 Just Write Code LLC. All rights reserved.
//

import SpriteKit

// This enum lets you easily switch between animations
enum PlayerAnimationType: String {
  case walk
  case die
}

class Player: SKSpriteNode {
  
  // MARK: - PROPERTIES
  
  // Textures (Animation)
  private var walkTextures: [SKTexture]?
  private var dieTextures: [SKTexture]?
  
  // MARK: - INIT
  
  init() {
    let texture = SKTexture(imageNamed: "blob-walk_0")
    
    super.init(texture: texture, color: .clear, size: texture.size())
    
    self.walkTextures = self.loadTextures(atlas: "blob", prefix: "blob-walk_",
                                          startsAt: 0, stopsAt: 2)
    self.dieTextures = self.loadTextures(atlas: "blob", prefix: "blob-die_",
                                         startsAt: 0, stopsAt: 0)
    
    /* The call to the `loadTextures` extension essentially does this:
    self.walkTextures = [SKTexture(imageNamed: "blob-walk_0"),
                         SKTexture(imageNamed: "blob-walk_1"),
                         SKTexture(imageNamed: "blob-walk_2")] */
    
    // Setup other properties after init
    self.name = "player"
    self.setScale(1.0) //比例
    self.anchorPoint = CGPoint(x: 0.5, y: 0.0) // center-bottom
    self.zPosition = Layer.player.rawValue
    
    #warning("想一下body")
    // Add physics body
    self.physicsBody = SKPhysicsBody(rectangleOf: self.size, center: CGPoint(x: 0.0, y: self.size.height/2))
    self.physicsBody?.affectedByGravity = false
    
    // Set up physics categories for contacts
    self.physicsBody?.categoryBitMask = PhysicsCategory.player
    self.physicsBody?.contactTestBitMask = PhysicsCategory.collectible
    self.physicsBody?.collisionBitMask = PhysicsCategory.none
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - METHODS
  
  /*
   可以用rubio的忍者做參照
   */
  func setupConstraints(floor: CGFloat) {
    let range = SKRange(lowerLimit: floor, upperLimit: floor)
    let lockToPlatform = SKConstraint.positionY(range)
    constraints = [lockToPlatform]
  }
  
  func mumble() {
    let random = Int.random(in: 1...3)
    let playSound = SKAction.playSoundFileNamed("blob_mumble-\(random)", waitForCompletion: true)
    
    run(playSound, withKey: "mumble")
  }
  
  func walk() {
    guard let walkTextures = walkTextures else {
      preconditionFailure("Could not find textures!")
    }
    
    // Stop the die animation
    removeAction(forKey: PlayerAnimationType.die.rawValue)
    
    startAnimation(textures: walkTextures, speed: 0.25,
                   name: PlayerAnimationType.walk.rawValue, count: 0,
                   resize: true, restore: true)
  }
  
  func die() {
    
    guard let dieTextures = dieTextures else {
      preconditionFailure("Could not find textures!")
    }
    
    // Stop the walk animation
    removeAction(forKey: PlayerAnimationType.walk.rawValue)
    
    startAnimation(textures: dieTextures, speed: 0.25,
                   name: PlayerAnimationType.die.rawValue,
                   count: 0, resize: true, restore: true)
  }
  
  func moveToPosition(pos: CGPoint, direction: String, speed: TimeInterval) {
    switch direction {
    case "L":
      xScale = -abs(xScale)
    default:
      xScale = abs(xScale)
    }
    
    let moveAction = SKAction.move(to: pos, duration: speed)
    run(moveAction)
  }
}

