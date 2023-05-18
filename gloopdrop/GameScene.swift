//
//  GameScene.swift
//  gloopdrop
//
//  Created by Tammy Coron on 1/24/2020.
//  Copyright © 2020 Just Write Code LLC. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {
  
  let player = Player()
  let playerSpeed: CGFloat = 1.5
  
  // Player movement
  var movingPlayer = false
  var lastPosition: CGPoint?
  
  var level: Int = 1 {
    didSet {
      levelLabel.text = "Level: \(level)"
    }
  }
  
  var score: Int = 0 {
    didSet {
      scoreLabel.text = "Score: \(score)"
    }
  }
  
  var numberOfDrops: Int = 10
  
  var dropsExpected = 10
  var dropsCollected = 0
  
  var dropSpeed: CGFloat = 1.0
  var minDropSpeed: CGFloat = 0.12 // (fastest drop)
  var maxDropSpeed: CGFloat = 1.0 // (slowest drop)
  var prevDropLocation: CGFloat = 0.0
  
  // Labels
  lazy var scoreLabel: SKLabelNode = {
    let node = SKLabelNode()
    node.name = "score"
    node.fontName = "Nosifer"
    node.fontColor = .yellow
    node.fontSize = 35.0
    node.horizontalAlignmentMode = .right
    node.verticalAlignmentMode = .center
    node.zPosition = Layer.ui.rawValue
    node.position = CGPoint(x: frame.maxX - 50, y: viewTop() - 100)
    node.text = "Score: 0"
    addChild(node)
    return node
  }()
  lazy var levelLabel: SKLabelNode = {
    let node = SKLabelNode()
    node.name = "level"
    node.fontName = "Nosifer"
    node.fontColor = .yellow
    node.fontSize = 35.0
    node.horizontalAlignmentMode = .left
    node.verticalAlignmentMode = .center
    node.zPosition = Layer.ui.rawValue
    node.position = CGPoint(x: frame.minX + 50, y: viewTop() - 100)
    node.text = "Level: \(level)"
    addChild(node)
    return node
  }()
  
  // Audio nodes
  let musicAudioNode = SKAudioNode(fileNamed: "music.mp3")
  let bubblesAudioNode = SKAudioNode(fileNamed: "bubbles.mp3")
  
  var gameInProgress = false
  
  override func didMove(to view: SKView) {
    
    // Decrease the audio engine's volume
    // 為了一開始不聽見 musicAudioNode
    audioEngine.mainMixerNode.outputVolume = 0.0
    
    musicAudioNode.autoplayLooped = true
    musicAudioNode.isPositional = false   //根據node的位置進行更改
    
    addChild(musicAudioNode)
    
    // Use an action to adjust the audio node's volume to 0
    musicAudioNode.run(.changeVolume(to: 0.0, duration: 0.0))
    
    run(.wait(forDuration: 1.0)) { [unowned self] in
      audioEngine.mainMixerNode.outputVolume = 1.0
      musicAudioNode.run(.changeVolume(to: 0.75, duration: 2.0))
    }
    
    run(.wait(forDuration: 1.5)) { [unowned self] in
      bubblesAudioNode.autoplayLooped = true
      addChild(bubblesAudioNode)
    }
    
    // Set up the physics world contact delegate
    physicsWorld.contactDelegate = self
    
    // Set up background
    let background = SKSpriteNode(imageNamed: "background_1")
    background.name = "background"
    background.anchorPoint = CGPoint(x: 0, y: 0)
    background.zPosition = Layer.background.rawValue
    background.position = CGPoint(x: 0, y: 0)
    addChild(background)
    
    // Set up foreground
    let foreground = SKSpriteNode(imageNamed: "foreground_1")
    foreground.name = "foreground"
    foreground.anchorPoint = CGPoint(x: 0, y: 0)
    foreground.zPosition = Layer.foreground.rawValue
    foreground.position = CGPoint(x: 0, y: 0)
    
    // Add physics body
    foreground.physicsBody = SKPhysicsBody(edgeLoopFrom: foreground.frame)
    foreground.physicsBody?.affectedByGravity = false
    
    // Set up physics categories for contacts
    foreground.physicsBody?.categoryBitMask = PhysicsCategory.foreground
    foreground.physicsBody?.contactTestBitMask = PhysicsCategory.collectible
    foreground.physicsBody?.collisionBitMask = PhysicsCategory.none
    
    addChild(foreground)
    
    // Set up the banner
    let banner = SKSpriteNode(imageNamed: "banner")
    banner.zPosition = Layer.foreground.rawValue
    banner.position = CGPoint(x: frame.midX, y: viewTop() - 20)
    banner.anchorPoint = CGPoint(x: 0.5, y: 1.0)
    addChild(banner)
    
    // Set up player
    player.position = CGPoint(x: size.width/2, y: foreground.frame.maxY)
    player.setupConstraints(floor: foreground.frame.maxY)
    addChild(player)
    
    showMessage("Tap to start game")
    
    setUpGloopFlow()
  }
  
  func showMessage(_ message: String) {
    let messageLabel = SKLabelNode()
    messageLabel.name = "message"
    messageLabel.position = CGPoint(x: frame.midX, y: player.frame.maxY + 100)
    messageLabel.zPosition = Layer.ui.rawValue
    messageLabel.numberOfLines = 2
    
    // Set up attributed text
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    
    let attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: SKColor(red: 251.0/255.0, green: 155.0/255.0,
                                blue: 24.0/255.0, alpha: 1.0),
      .backgroundColor: UIColor.clear,
      .font: UIFont(name: "Nosifer", size: 45.0)!,
      .paragraphStyle: paragraph
    ]
    
    messageLabel.attributedText = NSAttributedString(string: message,
                                                     attributes: attributes)
    
    // Run a fade action and add the label to the scene
    messageLabel.run(SKAction.fadeIn(withDuration: 0.25))
    addChild(messageLabel)
  }
  
  func hideMessage() {
    // Remove message label if it exists
    #warning("childNode(withName: ) 沒使用過")
    if let messageLabel = childNode(withName: "//message") as? SKLabelNode {
      messageLabel.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.25),
                                          SKAction.removeFromParent()]))
    }
  }
  
  // MARK: - Gloop Flow & Particle Effects
  
  func setUpGloopFlow() {
    let gloopFlow = SKNode()
    gloopFlow.name = "gloopFlow"
    gloopFlow.zPosition = Layer.foreground.rawValue
    gloopFlow.position = .init(x: 0.0, y: -60)
    
    gloopFlow.setUpScrollingView(imageNamed: "flow_1",
                                 layer: Layer.foreground,
                                 emitterNamed: "GloopFlow.sks",
                                 blocks: 3, speed: 30)
    addChild(gloopFlow)
  }
}
  

extension GameScene {
  // MARK: - GAME FUNCTIONS

  /* ############################################################ */
  /*                 GAME FUNCTIONS STARTS HERE                   */
  /* ############################################################ */

  func spawnMultipleGloops() {
    
    hideMessage()
    
    player.walk()
    player.mumble()
    
    if gameInProgress == false {
      score = 0
      level = 1
    }
    
    // Set number of drops based on the level
    switch level {
    case 1, 2, 3, 4, 5:
      numberOfDrops = level * 10
    case 6:
      numberOfDrops = 75
    case 7:
      numberOfDrops = 100
    case 8:
      numberOfDrops = 150
    default:
      numberOfDrops = 150
    }
    
    // Reset and update the collected and expected drop count
    dropsCollected = 0
    dropsExpected = numberOfDrops
    
#warning("想一下 為什麼這樣做？")
    // Set up drop speed
    dropSpeed = 1 / (CGFloat(level) + (CGFloat(level) / CGFloat(numberOfDrops)))
    if dropSpeed < minDropSpeed {
      dropSpeed = minDropSpeed
    } else if dropSpeed > maxDropSpeed {
      dropSpeed = maxDropSpeed
    }
    
    // Set up repeating action
    let wait = SKAction.wait(forDuration: TimeInterval(dropSpeed))
    let spawn = SKAction.run { [unowned self] in self.spawnGloop() }
    let sequence = SKAction.sequence([wait, spawn])
    let repeatAction = SKAction.repeat(sequence, count: numberOfDrops)

    // Run action
    run(repeatAction, withKey: "gloop")
    
    // Update game states
    gameInProgress = true
  }
  
  func spawnGloop() {
    let collectible = Collectible(collectibleType: CollectibleType.gloop)

    // set random position
    let margin = collectible.size.width * 2
    let dropRange = SKRange(lowerLimit: frame.minX + margin, upperLimit: frame.maxX - margin)
    var randomX = CGFloat.random(in: dropRange.lowerLimit...dropRange.upperLimit)
    
    
    /* START ENHANCED DROP MOVEMENT
     this helps to create a "snake-like" pattern */
    
    let randomModifier = SKRange(lowerLimit: 50 + CGFloat(level),
                                 upperLimit: 60 * CGFloat(level))
    var modifier = CGFloat.random(in: randomModifier.lowerLimit...randomModifier.upperLimit)
    if modifier > 400 { modifier = 400 }
    
    // Set the previous drop location
    if prevDropLocation == 0.0 {
      prevDropLocation = randomX
    }
    
    // Clamp its x-position
    if prevDropLocation < randomX {
      randomX = prevDropLocation + modifier
    } else {
      randomX = prevDropLocation - modifier
    }
    
    if randomX <= (frame.minX + margin) {
      randomX = frame.minX + margin
    } else if randomX >= (frame.maxX - margin) {
      randomX = frame.maxX - margin
    }
    
    // Store the location
    prevDropLocation = randomX
    
    /* END ENHANCED DROP MOVEMENT */
    
    // Add the number tag to the collectible drop
    let xLabel = SKLabelNode()
    xLabel.name = "dropNumber"
    xLabel.fontName = "AvenirNext-DemiBold"
    xLabel.fontColor = UIColor.yellow
    xLabel.fontSize = 22.0
    xLabel.text = "\(numberOfDrops)"
    xLabel.position = CGPoint(x: 0, y: 2)
    collectible.addChild(xLabel)
    numberOfDrops -= 1 // decrease drop count by 1
    
    collectible.position = CGPoint(x: randomX, y: player.position.y * 2.5)
    addChild(collectible)

    collectible.drop(dropSpeed: TimeInterval(1.0), floorLevel: player.frame.minY)
  }
  
  func checkForRemainingDrops() {
      if dropsCollected == dropsExpected {
        nextLevel()
      }
  }
  
  func nextLevel() {
    showMessage("Get Ready!")
    
    let wait = SKAction.wait(forDuration: 2.25)
    run(wait, completion:{[unowned self] in self.level += 1
                           self.spawnMultipleGloops()})
  }
  
  func gameOver() {
    showMessage("Game Over\nTap to try again")
    
    gameInProgress = false
    
    player.die()
    
    // Remove repeatable action on main scene
    removeAction(forKey: "gloop")
    
    // Loop through child nodes and stop actions on collectibles
    enumerateChildNodes(withName: "//co_*") {
      (node, stop) in
      
      // Stop and remove drops
      node.removeAction(forKey: "drop") // remove action
      node.physicsBody = nil // remove body so no collisions occur
    }
    
    // Reset game
    resetPlayerPosition()
    popRemainingDrops()
  }
  
  func resetPlayerPosition() {
    let resetPoint = CGPoint(x: frame.midX, y: player.position.y)
    #warning("不太確定")
    let distance = hypot(resetPoint.x-player.position.x, 0)
    let calculatedSpeed = TimeInterval(distance / (playerSpeed * 2)) / 255

    if player.position.x > frame.midX {
      player.moveToPosition(pos: resetPoint, direction: "L", speed: calculatedSpeed)
    } else {
      player.moveToPosition(pos: resetPoint, direction: "R", speed: calculatedSpeed)
    }
  }
  
  func popRemainingDrops() {
    var i = 0
    enumerateChildNodes(withName: "//co_*") {
      (node, stop) in
      
      // Pop remaining drops in sequence
      let initialWait = SKAction.wait(forDuration: 1.0)
      let wait = SKAction.wait(forDuration: TimeInterval(0.15 * CGFloat(i)))
      
      let removeFromParent = SKAction.removeFromParent()
      let actionSequence = SKAction.sequence([initialWait, wait, removeFromParent])

      node.run(actionSequence)
      
      i += 1
    }
  }
  
  
  // MARK: - TOUCH HANDLING
  
  /* ############################################################ */
  /*                 TOUCH HANDLERS STARTS HERE                   */
  /* ############################################################ */
  
  func touchDown(atPoint pos: CGPoint) {
    if gameInProgress == false {
      spawnMultipleGloops()
      return
    }
    
#warning("很棒的fun")
//    let touchedNode = atPoint(pos)
    let touchedNodes = nodes(at: pos)
    for touchedNode in touchedNodes {
      print("touchedNode: \(String(describing: touchedNode.name))")
      if touchedNode.name == "player" {
        movingPlayer = true
      }
    }
  }
  
  func touchMoved(toPoint pos: CGPoint) {
    if movingPlayer == true {
      // Clamp position
      let newPos = CGPoint(x: pos.x, y: player.position.y)
      player.position = newPos

      // Check last position; if empty set it
      let recordedPosition = lastPosition ?? player.position
      if recordedPosition.x > newPos.x {
        player.xScale = -abs(xScale)
      } else {
        player.xScale = abs(xScale)
      }

      // Save last known position
      lastPosition = newPos
    }
  }

  func touchUp(atPoint pos: CGPoint) {
    movingPlayer = false
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchDown(atPoint: t.location(in: self)) }
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
}


// MARK: - COLLISION DETECTION

/* ############################################################ */
/*         COLLISION DETECTION METHODS START HERE               */
/* ############################################################ */

extension GameScene: SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    // Check collision bodies
    let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
    
    // Did the [PLAYER] collide with the [COLLECTIBLE]?
    if collision == PhysicsCategory.player | PhysicsCategory.collectible {
      print("player hit collectible")

      // Find out which body is attached to the collectible node
      let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ?
        contact.bodyA.node :
        contact.bodyB.node

      // Verify the object is a collectible
      if let sprite = body as? Collectible {
        sprite.collected()
        dropsCollected += 1
        score += level
        checkForRemainingDrops()
        
        // Add the 'chomp' text at the player's position
        let chomp = SKLabelNode(fontNamed: "Nosifer")
        chomp.name = "chomp"
        chomp.alpha = 0.0
        chomp.fontSize = 22.0
        chomp.text = "gloop"
        chomp.horizontalAlignmentMode = .center
        chomp.verticalAlignmentMode = .bottom
        chomp.position = CGPoint(x: player.position.x, y: player.frame.maxY + 25)
        chomp.zRotation = CGFloat.random(in: -0.15...0.15)
        addChild(chomp)
        
        // Add actions to fade in, rise up, and fade out
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.05)
        let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.45)
        let moveUp = SKAction.moveBy(x: 0.0, y: 45, duration: 0.45)
        let groupAction = SKAction.group([fadeOut, moveUp])
        let removeFromParent = SKAction.removeFromParent()
        let chompAction = SKAction.sequence([fadeIn, groupAction, removeFromParent])
        chomp.run(chompAction)
      }
    }

    // Or did the [COLLECTIBLE] collide with the [FOREGROUND]?
    if collision == PhysicsCategory.foreground | PhysicsCategory.collectible {
      print("collectible hit foreground")
      
      // Find out which body is attached to the collectible node
      let body = contact.bodyA.categoryBitMask == PhysicsCategory.collectible ?
        contact.bodyA.node :
        contact.bodyB.node

      // Verify the object is a collectible
      if let sprite = body as? Collectible {
        sprite.missed()
        gameOver()
      }
    }
  }
}
