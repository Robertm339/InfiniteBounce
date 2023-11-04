//
//  GameScene.swift
//  InfiniteBounce
//
//  Created by Robert Martinez on 8/30/22.
//

import CoreMotion
import SpriteKit

enum GameState {
    case waiting, bouncing, advancing, gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    let motionManager = CMMotionManager()
    
    let ballLauncher = SKSpriteNode(imageNamed: "ball")
    var state = GameState.waiting
    
    let sounds = (1...22).map { SKAction.playSoundFileNamed("\($0).wav", waitForCompletion: false) }
    var scoreFromCurrentBall = 0
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    let extraBallPoints = Set([10, 50, 100, 150, 250, 350, 500, 750, 1000, 1250, 1500, 2000, 2500, 3500, 5000])
    
    var numberOfBalls = 1 {
        didSet {
            numberOfBallsLabel.text = "Balls: \(numberOfBalls)"
        }
    }
    
    let topBar = SKSpriteNode(color: SKColor(white: 0.8, alpha: 1), size: CGSize(width: 500, height: 100))
    let numberOfBallsLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    let scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    
    override func didMove(to view: SKView) {
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame.insetBy(dx: 0, dy: -200))
        physicsWorld.contactDelegate = self
        motionManager.startAccelerometerUpdates()
        
        ballLauncher.xScale = 0.5
        ballLauncher.yScale = 0.5
        ballLauncher.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
        addChild(ballLauncher)
        
        topBar.position.y = frame.maxY - 50
        addChild(topBar)
        
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .black
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.text = "Score: 0"
        addChild(scoreLabel)
        
        scoreLabel.position = CGPoint(x: frame.maxX - 20, y: frame.maxY - 70)
        scoreLabel.zPosition = 1
        
        numberOfBallsLabel.fontSize = 24
        numberOfBallsLabel.fontColor = .black
        numberOfBallsLabel.horizontalAlignmentMode = .left
        numberOfBallsLabel.text = "Balls: 1"
        addChild(numberOfBallsLabel)
        
        numberOfBallsLabel.position = CGPoint(x: frame.minX + 20, y: frame.maxY - 70)
        numberOfBallsLabel.zPosition = 1
        
        advance()
    }
    
    func launchBall(towards location: CGPoint) {
        let angle = atan2(location.y - ballLauncher.position.y, location.x - ballLauncher.position.x)
        let x = cos(angle) * 1000
        let y = sin(angle) * 1000
        
        let ball = ballLauncher.copy() as! SKSpriteNode
        ball.name = "Ball"
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 16)
        ball.physicsBody?.velocity = CGVector(dx: x, dy: y)
        ball.physicsBody?.linearDamping = 0
        ball.isHidden = false
        addChild(ball)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch state {
        case .waiting:
            guard let location = touches.first?.location(in: self) else { return }
            scoreFromCurrentBall = 0
            launchBall(towards: location)
            ballLauncher.isHidden = true
            state = .bouncing
            
            var sequence = [SKAction]()
            
            for _ in 1..<numberOfBalls {
                sequence.append(.wait(forDuration: 0.25))
                sequence.append(SKAction.run {
                    self.launchBall(towards: location)
                })
            }
            
            run(SKAction.sequence(sequence))
        
        case .gameOver:
            if let scene = SKScene(fileNamed: "GameScene") {
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .doorway(withDuration: 1))
            }
            
        default:
            break
        }
    }
    
    func resetLaucher() {
        ballLauncher.isHidden = false
        state = .waiting
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard state == .bouncing else { return }
        
        for child in children {
            if child.position.y < frame.minY - 50 {
                child.removeFromParent()
            }
        }
        
        let hasActiveBalls = children.contains { $0.name == "Ball" }
        
        if hasActiveBalls == false {
            advance()
        }
        
        if let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 15, dy: -9.8)
        }
    }
    
    func createBouncer() {
        let positions = [-110, -55, 0.0, 55, 110]
        let numberToCreate: Int
        let positionsToCreate: [Double]
        
        if score < 5 {
            numberToCreate = 1
        } else if score < 200 {
            numberToCreate = Int.random(in: 1...2)
        } else {
            numberToCreate = Int.random(in: 1...3)
        }
        
        switch numberToCreate {
        case 1:
            positionsToCreate = [positions.randomElement() ?? 0]
            
        case 2:
            let first = Int.random(in: 0..<positions.count)
            var second = first + Int.random(in: 2...3)
            if second >= positions.count { second -= positions.count }
            positionsToCreate = [positions[first], positions[second]]
            
        default:
            positionsToCreate = [positions[0], positions[2], positions[4]]
        }
        
        for i in 0..<numberToCreate {
            let bounceCount: Int
            
            if score < 2 {
                bounceCount = 1
            } else if score == 3 {
                bounceCount = 2
            } else if score < 5 {
                bounceCount = Int.random(in: 2...3)
            } else if score < 10 {
                bounceCount = Int.random(in: 2...4)
            } else if score < 50 {
                bounceCount = Int.random(in: 3...5)
            } else {
                bounceCount = Int.random(in: (score / 30)...(score / 25))
            }
            
            let bouncer = BouncerNode(bounceCount: bounceCount)
            bouncer.position = CGPoint(x: positionsToCreate[i], y: frame.minY - 50)
            bouncer.physicsBody = SKPhysicsBody(circleOfRadius: 32)
            bouncer.physicsBody?.contactTestBitMask = 1
            bouncer.physicsBody?.restitution = 0.75
            bouncer.physicsBody?.isDynamic = false
            bouncer.name = "Bouncer"
            addChild(bouncer)
                
        }
    }
    
    func advance() {
        state = .advancing
        createBouncer()
        
        let bouncers = children.filter { $0.name == "Bouncer" }
        
        let movement = SKAction.moveBy(x: 0, y: 100, duration: 0.5)
        movement.timingMode = .easeInEaseOut
        
        for child in bouncers {
            child.run(movement)
        }
        
        let checkForEnd = SKAction.run {
            let hasOverlappingBouncers = self.children.contains { $0.name == "Bouncer" && $0.intersects(self.topBar) }
            
            if hasOverlappingBouncers {
                self.gameOver()
            } else {
                self.resetLaucher()
            }
        }
        
        run(SKAction.sequence([.wait(forDuration: 0.5), checkForEnd]))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA.name == "Ball" {
            collision(between: nodeA, and: nodeB)
        } else if nodeB.name == "Ball" {
            collision(between: nodeB, and: nodeA)
        }
    }
    
    func collision(between ball: SKNode, and bouncer: SKNode) {
        guard let bouncer = bouncer as? BouncerNode else { return }
        
        bouncer.hit()
        score += 1
        
        if extraBallPoints.contains(score) {
            bonusBall()
        }
        
        if scoreFromCurrentBall < 22 {
            scoreFromCurrentBall += 1
        }
        
        run(sounds[scoreFromCurrentBall - 1])
    }
    
    func bonusBall() {
        numberOfBalls += 1
        
        let node = SKSpriteNode(imageNamed: "extraBall")
        node.zPosition = 10
        node.xScale = 2
        node.yScale = 2
        node.alpha = 0
        addChild(node)
        
        let appear = SKAction.group([SKAction.fadeIn(withDuration: 0.2), SKAction.scale(to: 1, duration: 0.2)])
        let disappear = SKAction.group([SKAction.fadeOut(withDuration: 0.2), SKAction.scale(to: 0.5, duration: 0.2)])
        node.run(SKAction.sequence([appear, .wait(forDuration: 0.5), disappear, .removeFromParent()]))
    }
    
    func gameOver() {
        guard state != .gameOver else { return }
        state = .gameOver
        
        let bouncers = children.filter { $0.name == "Bouncer" }
        
        for bouncer in bouncers {
            bouncer.run(SKAction.fadeOut(withDuration: 0.5))
        }
        
        let node = SKSpriteNode(imageNamed: "gameOver")
        node.zPosition = 100
        node.xScale = 2
        node.yScale = 2
        node.alpha = 0
        addChild(node)
        
        let appear = SKAction.group([SKAction.fadeIn(withDuration: 0.2), SKAction.scale(to: 1, duration: 0.2)])
        node.run(appear)
    }
}
