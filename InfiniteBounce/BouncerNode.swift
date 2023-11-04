//
//  BouncerNode.swift
//  InfiniteBounce
//
//  Created by Robert Martinez on 8/30/22.
//

import SpriteKit

class BouncerNode: SKSpriteNode {
    let label = SKLabelNode(fontNamed: "Helvetica")
    
    var bounceCount: Int {
        didSet {
            label.text = String(bounceCount)
            setColor()
        }
    }
    
    init(bounceCount: Int) {
        self.bounceCount = bounceCount
        
        let texture = SKTexture(imageNamed: "ball")
        super.init(texture: texture, color: .white, size: texture.size())
        
        label.text = String(bounceCount)
        label.fontSize = 32
        label.verticalAlignmentMode = .center
        label.fontColor = .white
        label.zPosition = 1
        addChild(label)
        
        setColor()
        colorBlendFactor = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Nope")
    }
    
    func hit() {
        bounceCount -= 1
        
        if bounceCount == 0 {
            removeFromParent()
        } else {
            let up = SKAction.scale(to: 1.2, duration: 0.05)
            let down = SKAction.scale(to: 1, duration: 0.05)
            run(SKAction.sequence([up, down]))
        }
    }
    
    func setColor() {
        switch bounceCount {
        case 1...2:
            color = .systemRed
        case 3...4:
            color = .systemOrange
        case 5...6:
            color = .systemYellow
        case 7...8:
            color = .systemGreen
        case 9...10:
            color = .systemCyan
        case 11...12:
            color = .systemBlue
        default:
            color = .systemIndigo
        }
    }
}
