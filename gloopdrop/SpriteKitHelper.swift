//
//  SpriteKitHelper.swift
//  gloopdrop
//
//  Created by user on 2023/5/17.
//  Copyright © 2023 Just Write Code LLC. All rights reserved.
//

import Foundation
import SpriteKit

// SpriteKit Physics Categories
enum PhysicsCategory {
  static let none:        UInt32 = 0
  static let player:      UInt32 = 0b1   // 1
  static let collectible: UInt32 = 0b10  // 2
  static let foreground:  UInt32 = 0b100 // 4
}

// Setup shared z-positions
enum Layer: CGFloat {
  case background
  case foreground
  case player
  case collectible
  case ui
}


extension SKNode {
  
  // Used to set up an endless scroller
  func setUpScrollingView(imageNamed name: String, layer: Layer,
                          emitterNamed: String?, blocks: Int, speed: TimeInterval) {
    
    for i in 0..<blocks {
      let spriteNode = SKSpriteNode(imageNamed: name)
      spriteNode.anchorPoint = .zero
      spriteNode.position = .init(x: CGFloat(i) * spriteNode.size.width, y: 0)
      spriteNode.zPosition = layer.rawValue
      spriteNode.name = name
      
      spriteNode.endlessScroll(speed: speed)
      
      if let emitterNamed = emitterNamed,
          let particles = SKEmitterNode(fileNamed: emitterNamed) {
        particles.name = "particles"
        spriteNode.addChild(particles)
      }
      
      addChild(spriteNode)
    }
  }
}

/*
 SKAction.moveBy vs SKAction.moveTo
 
 - SKAction.moveBy: 用於在當前位置的基礎上進行相對移動
 ex. SKAction.moveBy(x: 100, y: 0, duration: 1)
 表示將 SpriteNode 在 X 軸上向右移動 100 個單位，而 Y 軸上不變
 
 - SKAction.moveTo：用於直接將 SpriteNode 移動到指定的目標位置。需要指定目標位置的絕對座標
 ex. SKAction.moveTo(x: 200, duration: 1)
 表示將 SpriteNode 移動到 X 軸上的絕對位置 200
 
 */

extension SKSpriteNode {
  
  // Used to create an endless scrolling background
  func endlessScroll(speed: TimeInterval) {
    
    // Set up actions to move and reset nodes
    let moveAction = SKAction.moveBy(x: -self.size.width, y: 0, duration: speed)
    let resetAction = SKAction.moveBy(x: self.size.width, y: 0, duration: 0.0)
    
    let sequenceAction = SKAction.sequence([moveAction, resetAction])
    let repeatAction = SKAction.repeatForever(sequenceAction)
    run(repeatAction)
  }
  
  func loadTextures(atlas: String, prefix: String,
                    startsAt: Int, stopsAt: Int) -> [SKTexture] {
    var textureArray = [SKTexture]()
    /*
     SKTextureAtlas:
     用於將多個圖像資源打包成一個單獨的資源集合，透過一個識別符號來引用這個資源集合，可提高遊戲開發的效能，特別是在處理多個紋理(textures)時。
     可以享受到 SpriteKit 在載入資源時的優化機制，例如紋理壓縮和緩存等。
     */
    let textureAtlas = SKTextureAtlas(named: atlas)
    for i in startsAt...stopsAt {
      let textureName = "\(prefix)\(i)"
      let temp = textureAtlas.textureNamed(textureName)
      textureArray.append(temp)
    }
    
    return textureArray
  }
  
  
  
  // Start the animation using a name and a count (0 = repeat forever)
  // resize: 若為Yes，每次變換新的texture，會調整sprite大小
  // restore: 若為Yes，當action完成後，sprite's texture恢復為action完成前的texture
  func startAnimation(textures: [SKTexture], speed: Double, name: String,
                      count: Int, resize: Bool, restore: Bool) {
    
    // Run animation only if animation key doesn't already exist
    if action(forKey: name) == nil {
      let animation = SKAction.animate(with: textures, timePerFrame: speed, resize: resize, restore: restore)
      
      if count == 0 {
        let repeatAction = SKAction.repeatForever(animation)
        run(repeatAction, withKey: name)
      }
      else if count == 1 {
        run(animation, withKey: name)
      }
      else {
        let repeatAction = SKAction.repeat(animation, count: count)
        run(repeatAction, withKey: name)
      }
    }
  }
}


extension SKScene {
  
  // Top of view
  func viewTop() -> CGFloat {
    return convertPoint(fromView: CGPoint(x: 0.0, y: 0)).y
  }

  // Bottom of view
  func viewBottom() -> CGFloat {
    guard let view = view else { return 0.0 }
    return convertPoint(fromView: CGPoint(x: 0.0, y: view.bounds.size.height)).y
  }
}
