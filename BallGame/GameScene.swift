//
//  GameScene.swift
//  BallGame
//
//  Created by Alec Rodgers on 4/25/16.
//  Copyright (c) 2016 Alec Rodgers. All rights reserved.
//

import SpriteKit

enum Obstacle {
    case Circle
    case Block
    case LeftTriangle
    case RightTriangle
    case Cup
    case Star
    case MovingBlock
    case ReverseMovingBlock
    case Triangle
    case ULeftTriangle
    case URightTriangle
    case StationaryCup
    case DestroyerBlock
    case Button
    case OpenBarrier
    case ClosedBarrier
    case InVortex
    case OutVortex
    case GravityUp
    case GravityDown
	case Destroyer
}

enum MenuButtons {
	case Resume
	case TryAgain
	case MainMenu
	case TryAgainExtraLife
	case NextLevel
}

enum CollisionTypes: UInt32 {
    case Player = 1
    case Star = 2
    case Cup = 4
    case Obstacle = 8
    case CupBottom = 16
    case DestroyerCup = 32
    case Button = 64
    case Vortex = 128
    case GravityUp = 256
    case GravityDown = 512
	case Destroyer = 1024
}

class GameScene: SKScene, SKPhysicsContactDelegate {
	
    // === LABEL VARIABLES ===
    
    var starLabel: SKSpriteNode!
    var ballLabel: SKSpriteNode!
    var activeButton: SKSpriteNode!
    
    // === MENU VARIABLES ===
    
    var winMenu: SKSpriteNode!
    var loseMenu: SKSpriteNode!
    var pauseMenu: SKSpriteNode!
    
    // === BUTTON VARIABLES ===
    
    var resumeButton: SKSpriteNode!
    var mainMenuButton: SKSpriteNode!
    var tryAgainButton: SKSpriteNode!
    var nextLevelButton: SKSpriteNode!
    var tryAgainWithExtraButton: SKSpriteNode!
	
	var pauseButton: SKSpriteNode!
	var pauseTapNode: SKSpriteNode!
	var retryButton: SKSpriteNode!
	var retryTapNode: SKSpriteNode!
	
    
    var buttonsDisplayed: [SKSpriteNode]!
    
    // === GAME STATE VARIABLES ===
	
	var extraBallGame = false
	var totalBalls = 3
	
    var gamePaused = false
    var gameOver = false
    var contactDone = true
    
    var inVortex: SKSpriteNode!
    var outVortex: SKSpriteNode!
    var nodesWaitingForVortex: [SKSpriteNode] = []
    var nodeInVortex: SKSpriteNode!
    var vortexAnimating = false
    
    var activeBalls: [SKSpriteNode] = []
    var reverseGravityBalls: [SKSpriteNode] = []
    var rightMovingObstacles: [SKSpriteNode] = []
    var leftMovingObstacles: [SKSpriteNode] = []
    var obstacleSpeeds: NSDictionary = ["cup": 30, "moving block": 50, "reverse moving block": -50]
    var barriers: [SKSpriteNode] = []
	
	var gravityUpArrows: [SKSpriteNode] = []
	var gravityDownArrows: [SKSpriteNode] = []
    
    var ballsRemoved = 0
	
	var loseTimerSequence: SKAction!
	
	var winLoseMenusDisplayed = 0
    
    // Tracks moving blocks for repositioning
    var lastMovedByRow: NSMutableDictionary = [:]
    
    var currentLevel = 1
    
    // === LABEL DATA VARIABLES ===
    
    var starsCollected: Int = 0 {
        didSet {
			if(!gameOver) {
				configueStarLabel(starsCollected)
			}
        }
    }
    
    var ballsRemaining: Int = 3 {
        didSet {
            configureBallLabel(ballsRemaining)
        }
    }
	
	// === COLOR & FONT VARIABLES ===
	
	let obstacleColor = UIColor(red:0.86, green:0.89, blue:0.88, alpha:1.0)
	let barrierButtonColor = UIColor(red:0.00, green:0.48, blue:1.00, alpha:1.0)
	let bgColor = UIColor(red:0.15, green:0.46, blue:0.80, alpha:1.0)
	
	let textFont = "Helvetica Neue"
	
	
	// === SOUND MANAGER ===
	
	let soundPlayer = SoundManager()
	
    
    // ===============================================================================================================================================
    // ======== didMoveToView ========================================================================================================================
    // ===============================================================================================================================================
    
    override func didMoveToView(view: SKView) {
        backgroundColor = bgColor
        configurePhysics()
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameScene.retryWithExtraBall) , name: "load level extra ball", object: nil)
		addChild(soundPlayer)
    }
    
    // ===============================================================================================================================================
    // ======== TOUCHES ==============================================================================================================================
    // ===============================================================================================================================================
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        
        
        if ballsRemaining > 0 && !gameOver && !gamePaused && touch.locationInNode(self).y < frame.size.height - 40 {
            let location = touch.locationInNode(self)
            createBall(location)
        }
        
        for touch in touches {
            let location = touch.locationInNode(self)
            
            let nodeName = self.nodeAtPoint(location).name
            
            if nodeName == "pause tap node" {
                pauseButton.color = UIColor.grayColor()
                pauseButton.colorBlendFactor = 0.8
                activeButton = pauseButton
            } else if nodeName == "try again button" {
                tryAgainButton.color = UIColor.grayColor()
                tryAgainButton.colorBlendFactor = 0.8
                activeButton = tryAgainButton
            } else if nodeName == "next level button" {
                nextLevelButton.color = UIColor.grayColor()
                nextLevelButton.colorBlendFactor = 0.8
                activeButton = nextLevelButton
            } else if nodeName == "main menu button" {
                mainMenuButton.color = UIColor.grayColor()
                mainMenuButton.colorBlendFactor = 0.8
                activeButton = mainMenuButton
            } else if nodeName == "resume button" {
                resumeButton.color = UIColor.grayColor()
                resumeButton.colorBlendFactor = 0.8
                activeButton = resumeButton
            } else if nodeName == "try again extra button" {
                tryAgainWithExtraButton.color = UIColor.grayColor()
                tryAgainWithExtraButton.colorBlendFactor = 0.8
                activeButton = tryAgainWithExtraButton
			} else if nodeName == "retry tap node" {
				retryButton.color = UIColor.grayColor()
				retryButton.colorBlendFactor = 0.8
				activeButton = retryButton
			}
        }
    }
	
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let buttonsDisplayed: [SKSpriteNode]
        
        if childNodeWithName("win menu") != nil {
            buttonsDisplayed = [nextLevelButton, tryAgainButton, mainMenuButton]
        } else if childNodeWithName("lose menu") != nil {
            buttonsDisplayed = [tryAgainButton, mainMenuButton, tryAgainWithExtraButton]
        } else if childNodeWithName("pause menu") != nil {
            buttonsDisplayed = [resumeButton, tryAgainButton, tryAgainWithExtraButton, mainMenuButton]
        } else {
            buttonsDisplayed = [pauseButton]
        }
		
        for touch in touches {
            for button in buttonsDisplayed {
                let location = touch.locationInNode(self)
                if self.nodeAtPoint(location).name == button.name {
                    button.color = UIColor.grayColor()
                    button.colorBlendFactor = 0.8
                }else{
                    button.colorBlendFactor = 0
                }
                
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if activeButton != nil {
            activeButton.colorBlendFactor = 0
        }
        
        for touch in touches {
            let location = touch.locationInNode(self)
            let node = self.nodeAtPoint(location)

			if node.name == "pause tap node" || node.name == "resume button" || node.name == "try again button" || node.name == "next level button" || node.name == "main menu button" || node.name == "retry tap node" {
				soundPlayer.playSound(.MenuClick)
			}
            
            if node.name == "pause tap node" {
                displayPauseMenu()
                gamePaused = true
                
            }else if node.name == "resume button" {
                pauseMenu.removeFromParent()
                gamePaused = false
				
				if ballsRemaining == 0 {
					runAction(loseTimerSequence, withKey: "lose timer")
				}
				
				// Renaming tap nodes to detect taps
				retryTapNode.name = "retry tap node"
				pauseTapNode.name = "pause tap node"
                
            }else if node.name == "try again button" || node.name == "retry tap node"{
                // Remove All Nodes & Actions
                self.removeAllChildren()
				self.removeAllActions()
				
				// Renaming tap nodes to detect taps
				retryTapNode.name = "retry tap node"
				pauseTapNode.name = "pause tap node"
                
                // Ball / Star Managment
                ballsRemaining = 3
                ballsRemoved = 0
                starsCollected = 0
				activeBalls.removeAll()
                
                // Vortex Managment
                nodeInVortex = nil
                vortexAnimating = false
                nodesWaitingForVortex.removeAll()
                nodesThroughVortex = 0
                
                // Reset Misc. Arrays
                lastMovedByRow.removeAllObjects()
                barriers.removeAll()
                
                // Game State Managment
                gamePaused = false
                gameOver = false
				
				// Extra Game Settings Reset
				extraBallGame = false
				totalBalls = 3
                
                // Level Config
                loadLevel(currentLevel)
				addChild(soundPlayer)
                
            } else if node.name == "next level button" {
				
				if(currentLevel < levelData.count) {
					// Remove All Nodes
					self.removeAllChildren()
                
					// Ball / Star Managment
					ballsRemaining = 3
					starsCollected = 0
					ballsRemoved = 0
					activeBalls.removeAll()
                
					// Vortex Managment
					nodeInVortex = nil
					vortexAnimating = false
					nodesWaitingForVortex.removeAll()
					nodesThroughVortex = 0
                
					// Reset Misc. Arrays
					lastMovedByRow.removeAllObjects()
					barriers.removeAll()
                
					// Menu Managment
					winMenu.removeFromParent()
                
					// Game State Managment
					gameOver = false
					
					// Extra Game Settings Reset
					extraBallGame = false
					totalBalls = 3
                
					// Level Config
					currentLevel += 1
					loadLevel(currentLevel)
					addChild(soundPlayer)
				}
				
			} else if node.name == "try again extra button" {
				IAPManager.sharedInstance.createPaymentRequestForProduct(Product.RetryWithExtraBall)
			}else if node.name == "main menu button" {
                if let scene = MainMenu(fileNamed: "MainMenu") {
                    scene.size = CGSize(width: 375, height: 667)
					if(UIScreen.mainScreen().bounds.height == 480) {
						scene.scaleMode = .Fill
					} else {
						scene.scaleMode = .AspectFill
					}
                    self.view?.presentScene(scene, transition: SKTransition.fadeWithDuration(1))
                }
            }
            
        }
    }
    
    // ===============================================================================================================================================
    // ===== LEVEL CONFIG ============================================================================================================================
    // ===============================================================================================================================================
    
    func configueStarLabel(stars: Int) {
        
        pauseButton = SKSpriteNode(imageNamed: "pause button")
        pauseButton.name = "pause button"
        pauseButton.position = CGPoint(x: frame.size.width - 20, y: frame.size.height - 20)
        pauseButton.zPosition = 1
		
        
        pauseTapNode = SKSpriteNode(color: .clearColor(), size: CGSize(width: 40, height: 40))
        pauseTapNode.name = "pause tap node"
        pauseTapNode.zPosition = 2
        pauseTapNode.position = CGPoint(x: 0, y: 0)
		
		pauseButton.addChild(pauseTapNode)
        addChild(pauseButton)
		
		retryButton = SKSpriteNode(imageNamed: "retry button")
		retryButton.name = "retry button"
		retryButton.position = CGPoint(x: frame.size.width - 60, y: frame.size.height - 20)
		retryButton.zPosition = 1
		
		
		retryTapNode = SKSpriteNode(color: .clearColor(), size: CGSize(width: 40, height: 40))
		retryTapNode.name = "retry tap node"
		retryTapNode.zPosition = 2
		retryTapNode.position = CGPoint(x: 0, y: 0)
		
		retryButton.addChild(retryTapNode)
		addChild(retryButton)
		
        if(childNodeWithName("star label") != nil) {
            starLabel.removeFromParent()
        }
        
        starLabel = SKSpriteNode(imageNamed: "\(starsCollected) star")
        
        starLabel.position = CGPoint(x: frame.size.width - 130, y: frame.size.height - 20)
        starLabel.name = "star label"
        starLabel.zPosition = 1
        addChild(starLabel)
    }
    
    func configureBallLabel(balls: Int) {
        
        if(childNodeWithName("ball label") != nil) {
            ballLabel.removeFromParent()
        }
		if(!extraBallGame) {
			ballLabel = SKSpriteNode(imageNamed: "\(ballsRemaining) ball shiny")
			ballLabel.position = CGPoint(x: 50, y: frame.size.height - 20)
		} else {
			ballLabel = SKSpriteNode(imageNamed: "\(ballsRemaining) ball extra shiny")
			ballLabel.position = CGPoint(x: 65, y: frame.size.height - 20)
		}
	
        ballLabel.name = "ball label"
        ballLabel.zPosition = 1
        addChild(ballLabel)
    }
    
    func loadLevel(level: Int) {
        currentLevel = level
        // Loads the labels at the top of the scene
        configueStarLabel(0)
        configureBallLabel(3)

        if let levelPath = NSBundle.mainBundle().pathForResource("level\(level)", ofType: "txt") {
            if let levelString = try? String(contentsOfFile: levelPath, usedEncoding: nil) {
                let lines = levelString.componentsSeparatedByString("\n")
                
                for (row, line) in lines.reverse().enumerate() {
                    for (column, letter) in line.characters.enumerate() {
                        if letter == "x" {
                            // This is a blank space
                        } else if letter == "b" {
                            createObstable(type: .Block, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "B" {
                            createObstable(type: .DestroyerBlock, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "l"{
                            createObstable(type: .LeftTriangle, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "r" {
                            createObstable(type: .RightTriangle, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "c" {
                            createObstable(type: .Cup, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)-15))
                        } else if letter == "s" {
                            createObstable(type: .Star, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "m" {
                            createObstable(type: .MovingBlock, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "M" {
                            createObstable(type: .ReverseMovingBlock, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "t" {
                            createObstable(type: .Triangle, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "L" {
                            createObstable(type: .ULeftTriangle, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "R" {
                            createObstable(type: .URightTriangle, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "C" {
                            createObstable(type: .StationaryCup, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "o" {
                            createObstable(type: .Circle, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "p" {
                            createObstable(type: .Button, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "-" {
                            createObstable(type: .OpenBarrier, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "=" {
                            createObstable(type: .ClosedBarrier, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "v" {
                            createObstable(type: .InVortex, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "V" {
                            createObstable(type: .OutVortex, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        }else if letter == "g" {
                            createObstable(type: .GravityUp, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
                        } else if letter == "G" {
                            createObstable(type: .GravityDown, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
						} else if letter == "d" {
							createObstable(type: .Destroyer, location: CGPoint(x: Double(column*25)+12.5, y: Double(row*25)+12.5))
						}
							
                    }
                }
            }
        }
		NSNotificationCenter.defaultCenter().postNotificationName("show banner", object: nil)
    }
    
    func configurePhysics() {
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRect(x: 0, y: -50, width: frame.size.width, height: frame.size.height + 100))
        self.physicsBody = physicsBody
        
        physicsWorld.contactDelegate = self
    }
	
	func retryWithExtraBall() {
		// Remove All Nodes
		self.removeAllChildren()
		
		// Renaming tap nodes to detect taps
		retryTapNode.name = "retry tap node"
		pauseTapNode.name = "pause tap node"
		
		// Config Extra Ball
		extraBallGame = true
		totalBalls = 4
		
		// Ball / Star Managment
		ballsRemaining = 4
		ballsRemoved = 0
		starsCollected = 0
		
		// Vortex Managment
		nodeInVortex = nil
		vortexAnimating = false
		nodesWaitingForVortex.removeAll()
		nodesThroughVortex = 0
		
		// Reset Misc. Arrays
		lastMovedByRow.removeAllObjects()
		barriers.removeAll()
		
		// Game State Managment
		gamePaused = false
		gameOver = false
		
		// Level Config
		loadLevel(currentLevel)
		addChild(soundPlayer)
	}
	
    // ===============================================================================================================================================
    // ==== SPRITE CREATION ==========================================================================================================================
    // ===============================================================================================================================================
    
    func createBall(location: CGPoint) {
        
        if(nodeAtPoint(CGPoint(x: location.x, y: self.frame.height-50)).name != "block") {
            let ballSprite = SKSpriteNode(imageNamed: "ball")
            ballSprite.zPosition = 1
            ballSprite.name = "ball"
        
            ballSprite.physicsBody = SKPhysicsBody(circleOfRadius: 10)
            ballSprite.physicsBody?.dynamic = true
            ballSprite.physicsBody?.restitution = 0.2
        
            ballSprite.physicsBody?.categoryBitMask = CollisionTypes.Player.rawValue
            ballSprite.physicsBody?.contactTestBitMask = CollisionTypes.Star.rawValue | CollisionTypes.CupBottom.rawValue | CollisionTypes.DestroyerCup.rawValue | CollisionTypes.Vortex.rawValue | CollisionTypes.GravityUp.rawValue | CollisionTypes.GravityDown.rawValue
            ballSprite.physicsBody?.collisionBitMask = CollisionTypes.Obstacle.rawValue | CollisionTypes.Player.rawValue
        
            ballSprite.position = CGPoint(x: location.x, y: self.frame.height-50)
            activeBalls.append(ballSprite)
            
            ballsRemaining -= 1
            soundPlayer.playSound(.BallDrop)
            addChild(ballSprite)
        } else {
            // Can't place ball
        }
    }
    
    func createObstable(type type: Obstacle, location: CGPoint) {
    
        var obstacleNode: SKSpriteNode
    
        switch type {
        case .Block:
            obstacleNode = SKSpriteNode(imageNamed: "box")
            obstacleNode.name = "block"
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(rectangleOfSize: obstacleNode.size)
			obstacleNode.physicsBody?.dynamic = false
            obstacleNode.zPosition = 1
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
			obstacleNode.physicsBody?.contactTestBitMask = CollisionTypes.Destroyer.rawValue
        case .Circle:
            obstacleNode = SKSpriteNode(color: UIColor.clearColor(), size: CGSize(width: 25, height: 25))
            obstacleNode.position = location
            obstacleNode.zPosition = 1
			
			let circle = SKSpriteNode(imageNamed: "circle")
			circle.physicsBody = SKPhysicsBody(circleOfRadius: 12.5)
			circle.physicsBody?.dynamic = false
            
            circle.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
			
			obstacleNode.addChild(circle)
        case .RightTriangle:
            obstacleNode = SKSpriteNode(imageNamed: "right triangle")
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleNode.texture!, size: obstacleNode.size)
			obstacleNode.physicsBody?.dynamic = false
            obstacleNode.zPosition = 1
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
        case .LeftTriangle:
            obstacleNode = SKSpriteNode(imageNamed: "left triangle")
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleNode.texture!, size: obstacleNode.size)
			obstacleNode.physicsBody?.dynamic = false
            obstacleNode.zPosition = 1
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
            
        case .Cup:
            obstacleNode = SKSpriteNode(imageNamed: "cup")
            obstacleNode.name = "cup"
            obstacleNode.position = location
            obstacleNode.zPosition = 0
            
            obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleNode.texture!, size: obstacleNode.size)
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
			obstacleNode.physicsBody?.dynamic = false
            
            rightMovingObstacles.append(obstacleNode)
            
            // Cup bottom detects a ball has fallen into the cup
            let cupBottom = SKSpriteNode(imageNamed: "cup bottom")
            cupBottom.name = "cup bottom"
            cupBottom.position = CGPoint(x: 0, y: (-obstacleNode.size.height/2)+2)
            obstacleNode.addChild(cupBottom)
            
            cupBottom.physicsBody = SKPhysicsBody(rectangleOfSize: cupBottom.size)
            cupBottom.physicsBody?.categoryBitMask = CollisionTypes.CupBottom.rawValue
            cupBottom.physicsBody?.collisionBitMask = CollisionTypes.Player.rawValue
            cupBottom.physicsBody?.dynamic = false
            
        case .StationaryCup:
            obstacleNode = SKSpriteNode(imageNamed: "cup")
            obstacleNode.name = "stationary cup"
            obstacleNode.position = location
            obstacleNode.zPosition = 0
            
            obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleNode.texture!, size: obstacleNode.size)
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
			obstacleNode.physicsBody?.dynamic = false
            
            // Cup bottom detects a ball has fallen into the cup
            let cupBottom = SKSpriteNode(imageNamed: "cup bottom")
            cupBottom.name = "cup bottom"
            cupBottom.position = CGPoint(x: 0, y: (-obstacleNode.size.height/2)+2)
            obstacleNode.addChild(cupBottom)
            
            cupBottom.physicsBody = SKPhysicsBody(rectangleOfSize: cupBottom.size)
            cupBottom.physicsBody?.categoryBitMask = CollisionTypes.CupBottom.rawValue
            cupBottom.physicsBody?.collisionBitMask = CollisionTypes.Player.rawValue
            cupBottom.physicsBody?.dynamic = false

        case .Star:
            obstacleNode = SKSpriteNode(imageNamed: "star")
            obstacleNode.name = "star"
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleNode.texture!, size: obstacleNode.size)
            obstacleNode.zPosition = -2
            obstacleNode.physicsBody?.dynamic = false
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Star.rawValue
            obstacleNode.physicsBody?.contactTestBitMask = CollisionTypes.Player.rawValue
         
        case .MovingBlock:
            obstacleNode = SKSpriteNode(imageNamed: "box")
            obstacleNode.name = "moving block"
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(rectangleOfSize: obstacleNode.size)
			obstacleNode.physicsBody?.dynamic = false
            obstacleNode.zPosition = 0
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
            rightMovingObstacles.append(obstacleNode)
            
        case .ReverseMovingBlock:
            obstacleNode = SKSpriteNode(imageNamed: "box")
            obstacleNode.name = "reverse moving block"
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(rectangleOfSize: obstacleNode.size)
			obstacleNode.physicsBody?.dynamic = false
            obstacleNode.zPosition = 0
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
            leftMovingObstacles.append(obstacleNode)
            
        case .DestroyerBlock:
            obstacleNode = SKSpriteNode(color: UIColor.clearColor(), size: CGSize(width: 25, height: 25))
            obstacleNode.name = "destroyer block"
            obstacleNode.position = location
            obstacleNode.zPosition = 1
			
			let spikes = SKSpriteNode(imageNamed: "spikes")
			spikes.name = "spikes"
			spikes.physicsBody = SKPhysicsBody(texture: spikes.texture!, size: spikes.size)
			spikes.physicsBody?.dynamic = false
			spikes.position = CGPoint(x: 0, y: -3)
			
			let bottom = SKSpriteNode(imageNamed: "spikes bottom")
			bottom.position = CGPoint(x: 0, y: -10)
			
			obstacleNode.addChild(spikes)
			obstacleNode.addChild(bottom)
            
            spikes.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
            spikes.physicsBody?.contactTestBitMask = CollisionTypes.Player.rawValue
            
        case .Triangle:
            obstacleNode = SKSpriteNode(imageNamed: "triangle")
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleNode.texture!, size: obstacleNode.size)
			obstacleNode.physicsBody?.dynamic = false
            obstacleNode.zPosition = 1
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
        
        case .ULeftTriangle:
            obstacleNode = SKSpriteNode(imageNamed: "upside down left triangle")
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleNode.texture!, size: obstacleNode.size)
			obstacleNode.physicsBody?.dynamic = false
            obstacleNode.zPosition = 1
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
            
        case .URightTriangle:
            obstacleNode = SKSpriteNode(imageNamed: "upside down right triangle")
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleNode.texture!, size: obstacleNode.size)
			obstacleNode.physicsBody?.dynamic = false
            obstacleNode.zPosition = 1
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
			
        case .Button:
            obstacleNode = SKSpriteNode(imageNamed: "button holder")
            obstacleNode.position = location
            obstacleNode.physicsBody = SKPhysicsBody(texture: obstacleNode.texture!, size: obstacleNode.size)
			obstacleNode.physicsBody?.dynamic = false
            obstacleNode.zPosition = 1
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
            
            let button = SKSpriteNode(imageNamed: "barrier button")
            button.position = CGPoint(x: 0, y: -5)
            button.name = "button"
            button.zPosition = -1
            
            button.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 9, height: 10))
            button.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
            button.physicsBody?.contactTestBitMask = CollisionTypes.Player.rawValue
            button.physicsBody?.dynamic = false
            
            obstacleNode.addChild(button)
            
        case .ClosedBarrier:
            obstacleNode = SKSpriteNode(color: UIColor.clearColor(), size: CGSize(width: 25, height: 25))
            obstacleNode.position = location
            obstacleNode.color = UIColor.clearColor()
            obstacleNode.zPosition = 0
            
            let barrier = SKSpriteNode(imageNamed: "barrier")
            barrier.position = CGPoint(x: 0, y: 7.5)
            barrier.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 25, height: 10))
            barrier.physicsBody?.dynamic = false
            
            barriers.append(barrier)
            obstacleNode.addChild(barrier)
        
        case .OpenBarrier:
            obstacleNode = SKSpriteNode(color: UIColor.clearColor(), size: CGSize(width: 25, height: 25))
            obstacleNode.position = location
            obstacleNode.color = UIColor.clearColor()
            obstacleNode.zPosition = 0
            
            let barrier = SKSpriteNode(imageNamed: "barrier")
            barrier.position = CGPoint(x: -23, y: 7.5)
            barrier.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 25, height: 10))
            barrier.physicsBody?.dynamic = false
            
            barriers.append(barrier)
            obstacleNode.addChild(barrier)
        
        case .InVortex:
            obstacleNode = SKSpriteNode(imageNamed: "vortex")
            obstacleNode.position = location
            obstacleNode.zPosition = 0
			
            obstacleNode.name = "inVortex"
            obstacleNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 20, height: 20))
            obstacleNode.physicsBody?.dynamic = false
            obstacleNode.runAction((SKAction.repeatActionForever(SKAction.rotateByAngle(CGFloat(M_PI), duration: 0.5))))
            
            obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.Obstacle.rawValue
            obstacleNode.physicsBody?.contactTestBitMask = CollisionTypes.Player.rawValue
            
            inVortex = obstacleNode
            
        case .OutVortex:
			obstacleNode = SKSpriteNode(imageNamed: "vortex")
			obstacleNode.position = location
			obstacleNode.zPosition = 0
			
			obstacleNode.name = "outVortex"
			obstacleNode.physicsBody?.dynamic = false
			obstacleNode.runAction((SKAction.repeatActionForever(SKAction.rotateByAngle(CGFloat(M_PI), duration: 0.5))))
			
            outVortex = obstacleNode
			
        case .GravityUp:
            obstacleNode = SKSpriteNode(color: UIColor.clearColor(), size: CGSize(width: 25, height: 25))
            obstacleNode.position = location
            obstacleNode.color = UIColor.clearColor()
            obstacleNode.zPosition = 1
			
			obstacleNode.name = "gravity up"
			obstacleNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 25, height: 25))
			obstacleNode.physicsBody?.dynamic = false
			obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.GravityUp.rawValue
			obstacleNode.physicsBody?.contactTestBitMask = CollisionTypes.Player.rawValue
            
            let arrows = SKSpriteNode(imageNamed: "gravity up")
			arrows.position = CGPoint(x: 0, y: 0)
			arrows.zPosition = -3
			arrows.runAction(SKAction.repeatActionForever(SKAction.moveBy(CGVector(dx: 0,dy: 10), duration: 0.5)))
			gravityUpArrows.append(arrows)
			
			// Hides the top / bottom of the arrows
			let topCutoff = SKSpriteNode(color: backgroundColor, size: CGSize(width: 25, height: 40))
			let bottomCutoff = SKSpriteNode(color: backgroundColor, size: CGSize(width: 25, height: 25))
			topCutoff.position = CGPoint(x: 0, y: 32.5)
			bottomCutoff.position = CGPoint(x: 0, y: -25)
			topCutoff.zPosition = -2
			bottomCutoff.zPosition = -2
			
			obstacleNode.addChild(arrows)
			obstacleNode.addChild(topCutoff)
			obstacleNode.addChild(bottomCutoff)
            
        case .GravityDown:
			obstacleNode = SKSpriteNode(color: UIColor.clearColor(), size: CGSize(width: 25, height: 25))
			obstacleNode.position = location
			obstacleNode.color = UIColor.clearColor()
			obstacleNode.zPosition = 1
			
			obstacleNode.name = "gravity down"
			obstacleNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 25, height: 25))
			obstacleNode.physicsBody?.dynamic = false
			obstacleNode.physicsBody?.categoryBitMask = CollisionTypes.GravityDown.rawValue
			obstacleNode.physicsBody?.contactTestBitMask = CollisionTypes.Player.rawValue
			
			let arrows = SKSpriteNode(imageNamed: "gravity down")
			arrows.position = CGPoint(x: 0, y: 0)
			arrows.zPosition = -3
			arrows.runAction(SKAction.repeatActionForever(SKAction.moveBy(CGVector(dx: 0,dy: -10), duration: 0.5)))
			gravityDownArrows.append(arrows)
			
			// Hides the top / bottom of the arrows
			let topCutoff = SKSpriteNode(color: backgroundColor, size: CGSize(width: 25, height: 40))
			let bottomCutoff = SKSpriteNode(color: backgroundColor, size: CGSize(width: 25, height: 30))
			topCutoff.position = CGPoint(x: 0, y: 32.5)
			bottomCutoff.position = CGPoint(x: 0, y: -27.5)
			topCutoff.zPosition = -2
			bottomCutoff.zPosition = -2
			
			obstacleNode.addChild(arrows)
			obstacleNode.addChild(topCutoff)
			obstacleNode.addChild(bottomCutoff)
			
		case .Destroyer:
			obstacleNode = SKSpriteNode(imageNamed: "box")
			obstacleNode.name = "destroyer"
			obstacleNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 25, height: 25))
			obstacleNode.physicsBody?.dynamic = false
			obstacleNode.position = location
			obstacleNode.zPosition = 1
			
			let moveDown = SKAction.moveBy(CGVector(dx: 0, dy: -100), duration: 0.1)
			let moveUp = SKAction.moveBy(CGVector(dx: 0, dy: 100), duration: 1)
			let sequence = SKAction.sequence([SKAction.waitForDuration(1.5), moveDown, SKAction.waitForDuration(0.5), moveUp])
			
			let block = SKSpriteNode(color: UIColor(red:0.38, green:0.38, blue:0.38, alpha:1.0), size: CGSize(width: 25, height: 25))
			block.position = CGPoint(x: 0, y: 0)
			
			let spikes = SKSpriteNode(imageNamed: "spikes")
			spikes.name = "spikes"
			spikes.zRotation = CGFloat(M_PI)
			spikes.zPosition = -2
			spikes.position = CGPoint(x: 0, y: -17)
			spikes.physicsBody = SKPhysicsBody(texture: spikes.texture!, size: spikes.size)
			spikes.physicsBody?.dynamic = false
			
			obstacleNode.addChild(spikes)
			obstacleNode.addChild(block)
			obstacleNode.runAction(SKAction.repeatActionForever(sequence))
        }
		
		
        addChild(obstacleNode)
        
    }
    
    // ===============================================================================================================================================
    // == COLLISION FUNCTIONS ========================================================================================================================
    // ===============================================================================================================================================
	
    
    func didBeginContact(contact: SKPhysicsContact) {
        if(contact.bodyA.node?.name == "star") {
            ballHitStar(contact.bodyA.node as! SKSpriteNode)
        } else if(contact.bodyB.node?.name == "star") {
            ballHitStar(contact.bodyB.node as! SKSpriteNode)
        }else if(contact.bodyA.node?.name == "cup bottom") {
            ballHitCupBottom(contact.bodyB.node as! SKSpriteNode)
        }else if(contact.bodyB.node?.name == "cup bottom") {
            ballHitCupBottom(contact.bodyA.node as! SKSpriteNode)
        }else if(contact.bodyA.node?.name == "spikes") {
            if let node = contact.bodyB.node as? SKSpriteNode {
                ballHitDestroyer(node)
            }
        }else if(contact.bodyB.node?.name == "destroyer block") {
            if let node = contact.bodyA.node as? SKSpriteNode {
                ballHitDestroyer(node)
            }
        }else if(contact.bodyA.node?.name == "button") {
            ballHitButton(contact.bodyA.node as! SKSpriteNode)
        } else if(contact.bodyB.node?.name == "button") {
            ballHitButton(contact.bodyB.node as! SKSpriteNode)
        }else if(contact.bodyA.node?.name == "inVortex") {
            if nodeInVortex == nil {
                ballHitVortex(contact.bodyB.node as! SKSpriteNode)
            } else {
                if(!nodesWaitingForVortex.contains(contact.bodyB.node as! SKSpriteNode)) {
                    nodesWaitingForVortex.append(contact.bodyB.node as! SKSpriteNode)
                    (contact.bodyB.node as! SKSpriteNode).alpha = 0
                    contact.bodyB.node?.physicsBody?.dynamic = false
                    contact.bodyB.node?.physicsBody = nil
                }
            }
        } else if(contact.bodyB.node?.name == "inVortex") {
            if nodeInVortex == nil {
                ballHitVortex(contact.bodyA.node as! SKSpriteNode)
            } else {
                if(!nodesWaitingForVortex.contains(contact.bodyA.node as! SKSpriteNode)) {
                    nodesWaitingForVortex.append(contact.bodyA.node as! SKSpriteNode)
                    (contact.bodyA.node as! SKSpriteNode).alpha = 0
                    contact.bodyA.node?.physicsBody?.dynamic = false
                    contact.bodyA.node?.physicsBody = nil
                }
            }
        } else if(contact.bodyA.node?.name == "gravity up") {
            gravityHit(contact.bodyA.node as! SKSpriteNode, ball: contact.bodyB.node as! SKSpriteNode)
        } else if(contact.bodyB.node?.name == "gravity up") {
            gravityHit(contact.bodyB.node as! SKSpriteNode, ball: contact.bodyA.node as! SKSpriteNode)
        } else if(contact.bodyA.node?.name == "gravity down") {
            gravityHit(contact.bodyA.node as! SKSpriteNode, ball: contact.bodyB.node as! SKSpriteNode)
        } else if(contact.bodyB.node?.name == "gravity down") {
            gravityHit(contact.bodyB.node as! SKSpriteNode, ball: contact.bodyA.node as! SKSpriteNode)
		}
    }
	
    func gravityHit(node: SKSpriteNode, ball: SKSpriteNode) {
        if(node.name == "gravity up") {
			let xVelocity = ball.physicsBody?.velocity.dx
			if(!reverseGravityBalls.contains(ball)) {
				ball.physicsBody?.velocity = CGVector(dx: xVelocity!, dy: 0)
				soundPlayer.playSound(.GravUp)
				reverseGravityBalls.append(ball)
			}
			
        } else if(node.name == "gravity down") {
            if reverseGravityBalls.contains(ball) {
				soundPlayer.playSound(.GravDown)
                reverseGravityBalls.removeAtIndex(reverseGravityBalls.indexOf(ball)!)
            }
        }
    }
    
    func ballHitVortex(ball: SKSpriteNode) {
        nodeInVortex = ball
        configBallPhyisics(nodeInVortex)
        let changeDynamic = SKAction.runBlock({ self.nodeInVortex.physicsBody!.dynamic = !self.nodeInVortex.physicsBody!.dynamic })
        let moveToInVortex = SKAction.runBlock({ self.nodeInVortex.position = self.inVortex.position })
		let makeBallVisible = SKAction.runBlock({ ball.alpha = 1 })
        let moveToOutVortex = SKAction.runBlock({ self.nodeInVortex.position = self.outVortex.position })
        let scaleDown = SKAction.scaleBy(0.1, duration: 0.5)
        let scaleUp = SKAction.scaleBy(10, duration: 0.5)
        let removeNode = SKAction.runBlock({  self.nodeInVortex = nil })
        let checkWaiting = SKAction.runBlock({ self.checkWaitingNodes() })
		let playInSound = SKAction.playSoundFileNamed("inVortex.wav", waitForCompletion: false)
		let playOutSound = SKAction.playSoundFileNamed("outVortex.wav", waitForCompletion: false)

		
        let vortexSequence = SKAction.sequence([changeDynamic, moveToInVortex, makeBallVisible, playInSound, scaleDown, moveToOutVortex, playOutSound, scaleUp, changeDynamic, removeNode, checkWaiting])
            
        nodeInVortex.runAction(vortexSequence)
        vortexAnimating = false
        
    }
    
    func configBallPhyisics(ball: SKSpriteNode) {
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        ball.physicsBody?.dynamic = true
        ball.physicsBody?.categoryBitMask = CollisionTypes.Player.rawValue
        ball.physicsBody?.contactTestBitMask = CollisionTypes.Star.rawValue | CollisionTypes.CupBottom.rawValue | CollisionTypes.DestroyerCup.rawValue | CollisionTypes.Vortex.rawValue | CollisionTypes.GravityUp.rawValue | CollisionTypes.GravityDown.rawValue
        ball.physicsBody?.collisionBitMask = CollisionTypes.Obstacle.rawValue | CollisionTypes.Player.rawValue
    }
    
    // Tracks how many nodes have gone through vortex 
    // to avoid a problem where collisions would register
    // twice and result in a nil error
    var nodesThroughVortex = 0
    
    func checkWaitingNodes() {
        if(nodesWaitingForVortex.count > 0 && nodesThroughVortex <= nodesWaitingForVortex.count - 1) {
            let nextNode = nodesWaitingForVortex[nodesThroughVortex]
            ballHitVortex(nextNode)
            nodesThroughVortex += 1
        }
    }
    
    func ballHitButton(button: SKSpriteNode) {
        button.runAction(SKAction.moveToY(button.position.y - 10, duration: 0.1))
		soundPlayer.playSound(.ButtonPressed)
        for barrier in barriers {
            if !barrier.hasActions() {
                if barrier.position.x < -1 {
                    barrier.runAction(SKAction.moveByX(23, y: 0, duration: 1))
                } else {
                    barrier.runAction(SKAction.moveByX(-23, y: 0, duration: 1))
                }
            }
        }
    }
    
    func ballHitDestroyer(ball: SKSpriteNode) {
        if ball.parent != nil {
            activeBalls.removeAtIndex(activeBalls.indexOf(ball)!)
            ball.removeFromParent()
            ballsRemoved += 1
			soundPlayer.playSound(.Pop)
        }
        
    }
    
    func ballHitCupBottom(ball: SKSpriteNode) {
        gameOver = true
		soundPlayer.playSound(.BallInCup)
		for obstacle in rightMovingObstacles {
			if obstacle.name == "cup" {
				obstacle.removeAllActions()
			}
		}
        if (childNodeWithName("win menu") == nil) {
            displayWinMenu()
            PropertyListManager.sharedInstance.modifyLevelData(level: currentLevel, stars: starsCollected)
        }
    }
    
    func ballHitStar(star: SKSpriteNode) {
        if(star.parent != nil) {
			soundPlayer.playSound(.StarCollect)
            starsCollected += 1
        }
        star.removeFromParent()
    }

    
    // ===============================================================================================================================================
    // ========= MENUS ===============================================================================================================================
    // ===============================================================================================================================================
    
    func displayWinMenu() {
        winMenu = SKSpriteNode(imageNamed: "4 button menu")
        winMenu.name = "win menu"
        winMenu.zPosition = 2
        winMenu.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
		
		let titleLineOne = SKLabelNode(fontNamed: textFont)
		titleLineOne.text = "LEVEL \(currentLevel)"
		titleLineOne.fontColor = UIColor.blackColor()
		titleLineOne.position = CGPoint(x: 0, y: 150)
		titleLineOne.zPosition = 1
		
		let titleLineTwo = SKLabelNode(fontNamed: textFont)
		titleLineTwo.text = "COMPLETED"
		titleLineTwo.fontColor = UIColor.blackColor()
		titleLineTwo.position = CGPoint(x: 0, y: 120)
		titleLineTwo.zPosition = 1
		
        let menuStars = SKSpriteNode(imageNamed: "\(starsCollected) star big")
        menuStars.position = CGPoint(x: 0, y: 75)
        menuStars.zPosition = 1
		
		
		nextLevelButton = createMenuButton(.NextLevel)
		nextLevelButton.name = "next level button"
		nextLevelButton.position = CGPoint(x: 0, y: 0)
		nextLevelButton.zPosition = 1
		
		tryAgainButton = createMenuButton(.TryAgain)
		tryAgainButton.name = "try again button"
		tryAgainButton.position = CGPoint(x: 0, y: -70)
		tryAgainButton.zPosition = 1
		
		mainMenuButton = createMenuButton(.MainMenu)
		mainMenuButton.name = "main menu button"
		mainMenuButton.position = CGPoint(x: 0, y: -140)
		mainMenuButton.zPosition = 1
		
		// Removing names from nodes so they are disalbed
		// while the menu is shown
		retryTapNode.name = ""
		pauseTapNode.name = ""
		
		winMenu.addChild(titleLineOne)
		winMenu.addChild(titleLineTwo)
        winMenu.addChild(menuStars)
        winMenu.addChild(nextLevelButton)
        winMenu.addChild(tryAgainButton)
        winMenu.addChild(mainMenuButton)
        addChild(winMenu)
		
		winLoseMenusDisplayed += 1
		
		if(winLoseMenusDisplayed > 4) {
			NSNotificationCenter.defaultCenter().postNotificationName("display interstatial", object: nil)
			winLoseMenusDisplayed = 0
		}
    }
    
    func displayLoseMenu() {
        loseMenu = SKSpriteNode(imageNamed: "3 button menu")
        loseMenu.name = "lose menu"
        loseMenu.zPosition = 2
        loseMenu.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
		
		let titleLineOne = SKLabelNode(fontNamed: textFont)
		titleLineOne.text = "OUT OF"
		titleLineOne.fontColor = UIColor.blackColor()
		titleLineOne.position = CGPoint(x: 0, y: 120)
		titleLineOne.zPosition = 1
		
		let titleLineTwo = SKLabelNode(fontNamed: textFont)
		titleLineTwo.text = "BALLS"
		titleLineTwo.fontColor = UIColor.blackColor()
		titleLineTwo.position = CGPoint(x: 0, y: 90)
		titleLineTwo.zPosition = 1
        
		tryAgainButton = createMenuButton(.TryAgain)
		tryAgainButton.name = "try again button"
		tryAgainButton.position = CGPoint(x: 0, y: 20)
        tryAgainButton.zPosition = 1
		
		tryAgainWithExtraButton = createMenuButton(.TryAgainExtraLife)
		tryAgainWithExtraButton.name = "try again extra button"
		tryAgainWithExtraButton.position = CGPoint(x: 0, y: -50)
		tryAgainWithExtraButton.zPosition = 1
		
		mainMenuButton = createMenuButton(.MainMenu)
		mainMenuButton.name = "main menu button"
        mainMenuButton.position = CGPoint(x: 0, y: -120)
        mainMenuButton.zPosition = 1
		
		// Removing names from nodes so they are disalbed
		// while the menu is shown
		retryTapNode.name = ""
		pauseTapNode.name = ""
		
        loseMenu.addChild(titleLineOne)
		loseMenu.addChild(titleLineTwo)
        loseMenu.addChild(tryAgainButton)
		loseMenu.addChild(tryAgainWithExtraButton)
        loseMenu.addChild(mainMenuButton)
        addChild(loseMenu)
		
		winLoseMenusDisplayed += 1
		
		if(winLoseMenusDisplayed > 4) {
			NSNotificationCenter.defaultCenter().postNotificationName("display interstatial", object: nil)
			winLoseMenusDisplayed = 0
		}
    }
    
    func displayPauseMenu() {
        pauseMenu = SKSpriteNode(imageNamed: "4 button menu")
        pauseMenu.name = "pause menu"
        pauseMenu.zPosition = 2
        pauseMenu.position = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
		
		let titleLineOne = SKLabelNode(fontNamed: textFont)
		titleLineOne.text = "PAUSED"
		titleLineOne.fontColor = UIColor.blackColor()
		titleLineOne.position = CGPoint(x: 0, y: 150)
		titleLineOne.zPosition = 1
		
		let titleLineTwo = SKLabelNode(fontNamed: textFont)
		titleLineTwo.text = "LEVEL \(currentLevel)"
		titleLineTwo.fontColor = UIColor.blackColor()
		titleLineTwo.position = CGPoint(x: 0, y: 110)
		titleLineTwo.zPosition = 1
		
        resumeButton = createMenuButton(.Resume)
        resumeButton.name = "resume button"
        resumeButton.position = CGPoint(x: 0, y: 60)
        resumeButton.zPosition = 1
        
        tryAgainButton = createMenuButton(.TryAgain)
        tryAgainButton.name = "try again button"
        tryAgainButton.position = CGPoint(x: 0, y: -10)
        tryAgainButton.zPosition = 1
		
		tryAgainWithExtraButton = createMenuButton(.TryAgainExtraLife)
		tryAgainWithExtraButton.name = "try again extra button"
		tryAgainWithExtraButton.position = CGPoint(x: 0, y: -80)
		tryAgainWithExtraButton.zPosition = 1
        
        mainMenuButton = createMenuButton(.MainMenu)
        mainMenuButton.name = "main menu button"
        mainMenuButton.position = CGPoint(x: 0, y: -150)
        mainMenuButton.zPosition = 1
		
		// Removing names from nodes so they are disalbed
		// while the menu is shown
		retryTapNode.name = ""
		pauseTapNode.name = ""
		
		pauseMenu.addChild(titleLineOne)
		pauseMenu.addChild(titleLineTwo)
        pauseMenu.addChild(resumeButton)
        pauseMenu.addChild(tryAgainButton)
		pauseMenu.addChild(tryAgainWithExtraButton)
        pauseMenu.addChild(mainMenuButton)
        addChild(pauseMenu)
    }
	
	func createMenuButton(buttonType: MenuButtons) -> SKSpriteNode {
		
		let button = SKSpriteNode(imageNamed: "button")
		
		
		let buttonText = SKLabelNode(fontNamed: textFont)
		buttonText.position = CGPoint(x: 0, y: -10)
		buttonText.fontColor = UIColor.blackColor()
		buttonText.zPosition = 1
		buttonText.name = button.name
		
		switch buttonType {
		case .MainMenu:
			buttonText.text = "MAIN MENU"
			buttonText.name = "main menu button"
		case .NextLevel:
			buttonText.text = "NEXT LEVEL"
			buttonText.name = "next level button"
		case .Resume:
			buttonText.text = "RESUME"
			buttonText.name = "resume button"
		case .TryAgain:
			buttonText.text = "TRY AGAIN"
			buttonText.name = "try again button"
		case .TryAgainExtraLife:
			buttonText.text = "TRY AGAIN WITH"
			buttonText.name = "try again extra button"
			buttonText.fontSize = 20
			buttonText.position = CGPoint(x: 0, y: 0)
			
			let buttonTextLineTwo = SKLabelNode(fontNamed: textFont)
			buttonTextLineTwo.name = "try again extra button"
			buttonTextLineTwo.text = "EXTRA BALL ($0.99)"
			buttonTextLineTwo.fontSize = 20
			buttonTextLineTwo.fontColor = UIColor.blackColor()
			buttonTextLineTwo.position = CGPoint(x: 0, y: -20)
			buttonTextLineTwo.zPosition = 1
			
			button.addChild(buttonTextLineTwo)
			
		}
		
		button.addChild(buttonText)
		
		return button
	}

    // ===============================================================================================================================================
    // ========= UPDATE ==============================================================================================================================
    // ===============================================================================================================================================
    
    override func update(currentTime: CFTimeInterval) {
		
		let lossTimer = SKAction.waitForDuration(2)
		let activateGameOver = SKAction.runBlock({
			self.gameOver = true
			self.gamePaused = true
			self.displayLoseMenu()
			self.soundPlayer.playSound(.LoseBeep)
		})
		loseTimerSequence = SKAction.sequence([lossTimer, activateGameOver])
		
		if(ballsRemaining == 0) {
			for ball in activeBalls {
				if ball.physicsBody != nil {
					if (ball.physicsBody!.velocity.dx < 0.01 && ball.physicsBody?.velocity.dx > -0.01) && (ball.physicsBody!.velocity.dy < 0.01 && ball.physicsBody?.velocity.dy > -0.01) {
						
					} else {
						runAction(loseTimerSequence, withKey: "lose timer")
					}
				}
			}
			
			if gameOver || gamePaused {
				removeActionForKey("lose timer")
			}
			
		}
		
        for obstacle in rightMovingObstacles {
            
            let speed = obstacleSpeeds.valueForKey("\(obstacle.name!)") as! Int
            
            if gamePaused {
                physicsWorld.speed = 0
                if obstacle.hasActions() {
                    obstacle.removeAllActions()
                }
            } else {
                physicsWorld.speed = 1.0
                if !obstacle.hasActions() {
					if(gameOver && obstacle.name == "cup") {
						continue
					} else {
						obstacle.runAction(SKAction.repeatActionForever(SKAction.moveBy(CGVector(dx: speed, dy: 0) , duration: 0.25)))
					}
                }
            }
        }
        
        for obstacle in leftMovingObstacles {
            
            let speed = obstacleSpeeds.valueForKey("\(obstacle.name!)") as! Int
            
            if gamePaused {
                physicsWorld.speed = 0
                if obstacle.hasActions() {
                    obstacle.removeAllActions()
                }
            } else {
                physicsWorld.speed = 1.0
                if !obstacle.hasActions() {
                    obstacle.runAction(SKAction.repeatActionForever(SKAction.moveBy(CGVector(dx: speed, dy: 0) , duration: 0.25)))
                }
            }
        }
        
        // Removes balls that go out of play
        
        if activeBalls.count > 0 {
            for ball in activeBalls {
                if ball.position.y < -20 || ball.position.y > frame.size.height + 20 {
                    if ball.parent != nil {
                        ballsRemoved += 1
						activeBalls.removeAtIndex(activeBalls.indexOf(ball)!)
                    }
                    ball.removeFromParent()
                }
            }
        }
        
        // Check if all balls have been used and game is over
        
        if ballsRemoved == totalBalls && childNodeWithName("lose menu") == nil && childNodeWithName("win menu") == nil {
            gameOver = true
            gamePaused = true
            displayLoseMenu()
			soundPlayer.playSound(.LoseBeep)
        }
    }
    
    
    
    override func didEvaluateActions() {
		
		for arrow in gravityUpArrows {
			if(arrow.position.y > 16.5) {
				arrow.position.y = -12.5
			}
		}
		
		for arrow in gravityDownArrows {
			if(arrow.position.y < -16.5) {
				arrow.position.y =	12.5
			}
		}
        
        for ball in reverseGravityBalls {
            ball.physicsBody?.applyForce(CGVector(dx: 0, dy: 25))
        }

        
        for obstacle in rightMovingObstacles {
            if obstacle.position.x > 391 {
                if(obstacle.name == "moving block") {
                    let yPos = Int(obstacle.position.y)
                    if(lastMovedByRow.valueForKey("\(yPos)") != nil) {
                        if((lastMovedByRow.valueForKey("\(yPos)") as! SKSpriteNode).position.x > 25) {
                            obstacle.position.x = -12.5
                            lastMovedByRow.setObject(obstacle, forKey: ("\(yPos)"))
                        } else {
                            obstacle.position.x = (lastMovedByRow.valueForKey("\(yPos)") as! SKSpriteNode).position.x - 25
                        }
                    } else {
                        obstacle.position.x = -12.5
                        lastMovedByRow.setObject(obstacle, forKey: "\(yPos)")
                    }
                } else {
                    obstacle.position.x = -12.5
                }
            }
        }
        
        
        for obstacle in leftMovingObstacles {
            if obstacle.position.x < -16 {
                if(obstacle.name == "moving block") {
                    let yPos = Int(obstacle.position.y)
                    if(lastMovedByRow.valueForKey("\(yPos)") != nil) {
                        if((lastMovedByRow.valueForKey("\(yPos)") as! SKSpriteNode).position.x < 350) {
                            obstacle.position.x = 387.5
                            lastMovedByRow.setObject(obstacle, forKey: ("\(yPos)"))
                        } else {
                            obstacle.position.x = (lastMovedByRow.valueForKey("\(yPos)") as! SKSpriteNode).position.x + 25
                        }
                    } else {
                        obstacle.position.x = 387.5
                        lastMovedByRow.setObject(obstacle, forKey: "\(yPos)")
                    }
                } else {
                    obstacle.position.x = 387.5
                }
            }
        }
        
        
        
    }
}
