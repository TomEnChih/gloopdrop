//
//  SpriteKitHelper.swift
//  gloopdrop
//
//  Created by user on 2023/5/17.
//  Copyright © 2023 Just Write Code LLC. All rights reserved.
//

import Foundation
import SpriteKit

// Setup shared z-positions
enum Layer: CGFloat {
  case background
  case foreground
  case player
  case collectible
}

extension SKSpriteNode {
  
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
