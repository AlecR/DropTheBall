//
//  MainMenu.swift
//  BallGame
//
//  Created by Alec Rodgers on 5/6/16.
//  Copyright © 2016 Alec Rodgers. All rights reserved.
//

import SpriteKit
import StoreKit

var levelData: NSMutableDictionary!
var userSettings: NSMutableDictionary!

class MainMenu: SKScene, SKPhysicsContactDelegate {
    
    var playButton: SKSpriteNode!
	var reviewButton: SKSpriteNode!
	var removeAdsButton: SKSpriteNode!
	var activeButton: SKSpriteNode!
	var settingsButton: SKSpriteNode!
	
	var settingsMenu: SKSpriteNode!
	var restorePurchasesButton: SKSpriteNode!
	var reportBugButton: SKSpriteNode!
	
	var buttons: [SKSpriteNode] = []
	
    var score: SKLabelNode!
    var activeBalls: [SKSpriteNode]!
	
	var soundPlayer = SoundManager()
	
	let textFont = "Helvetica Neue"
	
	// Settings menu button textures
	let checkedBox = SKTexture(imageNamed: "checked box")
	let uncheckedBox = SKTexture(imageNamed: "unchecked box")
    
    
    
    var ballScore: Int = 0 {
        didSet {
            score.text = "\(ballScore)"
        }
    }
	

    override func didMoveToView(view: SKView) {
		configMainMenu()
		getProperyListData()
        activeBalls = []
		buttons = [removeAdsButton, reviewButton, settingsButton]
        configurePhysics()
        createCup()
    }
	
	func getProperyListData() {
		
		if levelData == nil {
			levelData = PropertyListManager.sharedInstance.getPropertyListData("LevelData")
		}
		
		if userSettings == nil {
			userSettings = PropertyListManager.sharedInstance.getPropertyListData("UserSettings")
		}
		
	}
	
	func configMainMenu() {
		self.backgroundColor = UIColor(red:0.13, green:0.14, blue:0.15, alpha:1.0)
		
		let backgroundImage = SKSpriteNode(imageNamed: "main menu background")
		backgroundImage.position = CGPoint(x: frame.midX, y: frame.midY)
		backgroundImage.zPosition = -1
		addChild(backgroundImage)
		
		score = SKLabelNode(fontNamed: textFont)
		score.text = "\(ballScore)"
		score.fontSize = 100
		score.position = CGPoint(x: frame.midX, y: frame.midY-175)
		addChild(score)
		
		playButton = SKSpriteNode(imageNamed: "play button")
		playButton.name = "play button"
		playButton.position = CGPoint(x: frame.midX, y: frame.midY)
		playButton.physicsBody = SKPhysicsBody(circleOfRadius: 75.5)
		playButton.physicsBody?.dynamic = false
		addChild(playButton)
		
		removeAdsButton = SKSpriteNode(imageNamed: "remove ads button")
		removeAdsButton.name = "remove ads button"
		removeAdsButton.position = CGPoint(x: frame.midX / 2, y: 200)
		removeAdsButton.physicsBody = SKPhysicsBody(circleOfRadius: 25)
		removeAdsButton.physicsBody?.dynamic = false
		addChild(removeAdsButton)
		
		reviewButton = SKSpriteNode(imageNamed: "review button")
		reviewButton.name = "review button"
		reviewButton.position = CGPoint(x: frame.midX * 1.5, y: 200)
		reviewButton.physicsBody = SKPhysicsBody(circleOfRadius: 25)
		reviewButton.physicsBody?.dynamic = false
		addChild(reviewButton)
		
		settingsButton = SKSpriteNode(imageNamed: "gear")
		settingsButton.name = "settings button"
		settingsButton.position = CGPoint(x: frame.size.width - 20, y: frame.size.height - 20)
		addChild(settingsButton)
		
		addChild(soundPlayer)
	}
	
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        let location = touch.locationInNode(self)
		let node = nodeAtPoint(location)
		
        if nodeAtPoint(location).name == "play button" {
			soundPlayer.playSound(SoundEffect.MenuClick)
            if let scene = LevelSelectionMenu(fileNamed: "LevelSelectionMenu") {
                scene.size = CGSize(width: 375, height: 667)
				if(UIScreen.mainScreen().bounds.height == 480) {
					scene.scaleMode = .Fill
				} else {
					scene.scaleMode = .AspectFill
				}
                view?.presentScene(scene, transition: SKTransition.fadeWithDuration(1))
            }
		} else if (node.name == "remove ads button" || node.name == "settings button" || node.name == "review button" || node.name == "restore purchases button" || node.name == "report bug button") {
			if (buttons.contains(node as! SKSpriteNode)) {
				(node as! SKSpriteNode).color = UIColor.grayColor()
				(node as! SKSpriteNode).colorBlendFactor = 0.8
				activeButton = (node as! SKSpriteNode)
			}
		}else if node.name == "restore purchases button text" || node.name == "report bug button text" {
			if(buttons.contains(node.parent as! SKSpriteNode)) {
				(node.parent as! SKSpriteNode).color = UIColor.grayColor()
				(node.parent as! SKSpriteNode).colorBlendFactor = 0.8
				activeButton = (node.parent as! SKSpriteNode)
			}
		}else if node.name == "quit button" {
			(node as! SKSpriteNode).color = UIColor.grayColor()
			(node as! SKSpriteNode).colorBlendFactor = 0.8
			activeButton = (node as! SKSpriteNode)
			reviewButton.name = "review button"
			removeAdsButton.name = "remove ads button"
		}else {
			if(childNodeWithName("settings menu") == nil) {
				createBall(location)
			}
        }
			
    }
	
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		for touch in touches {
			for button in buttons {
				let location = touch.locationInNode(self)
				if self.nodeAtPoint(location).name == button.name {
					button.color = UIColor.grayColor()
					button.colorBlendFactor = 0.8
				} else {
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
			
			if  node.name == "quit button" || node.name == "sound box" || node.name == "report bug button" || node.name == "report bug button text" || node.name == "restore purchases button" || node.name == "restore purchases button text"  {
				soundPlayer.playSound(SoundEffect.MenuClick)
			} else if node.name == "reivew button" || node.name == "remove ads button" || node.name == "settings button" {
				if(buttons.contains(node as! SKSpriteNode)) {
					soundPlayer.playSound(SoundEffect.MenuClick)
				}
			}
			
			if node.name == "review button"{
				if(buttons.contains(node as! SKSpriteNode)) {
					UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/app/id1130841389")!)
				}
			} else if node.name == "remove ads button" {
				if(buttons.contains(node as! SKSpriteNode)) {
					IAPManager.sharedInstance.createPaymentRequestForProduct(Product.RemoveAds)
				}
			}else if node.name == "settings button" {
				if(buttons.contains(node as! SKSpriteNode)) {
					displaySettings()
					buttons = [reportBugButton, restorePurchasesButton]
				}
			}else if node.name == "quit button" {
				buttons = [removeAdsButton, reviewButton, settingsButton]
				childNodeWithName("settings menu")?.removeFromParent()
			}else if node.name == "sound box" {
				soundBoxTapped()
			}else if node.name == "report bug button" || node.name == "report bug button text" {
				let email = "DropTheBallApp@gmail.com"
				let url = NSURL(string: "mailto:\(email)")!
				UIApplication.sharedApplication().openURL(url)
			}else if node.name == "resotre purchases button" || node.name == "restore purchases button text" {
				SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
			}
		
		}
		
	}
	
	func soundBoxTapped() {
		let checkedBox = SKTexture(imageNamed: "checked box")
		let uncheckedBox = SKTexture(imageNamed: "unchecked box")
		let soundBox = settingsMenu.childNodeWithName("sound box") as! SKSpriteNode
		
		if(soundBox.texture!.description == checkedBox.description) {
			PropertyListManager.sharedInstance.modifyUserSettings("soundEnabled", newValue: false)
			soundBox.texture = uncheckedBox
		}else if(soundBox.texture!.description == uncheckedBox.description) {
			PropertyListManager.sharedInstance.modifyUserSettings("soundEnabled", newValue: true)
			soundBox.texture = checkedBox
		}
		
		userSettings = PropertyListManager.sharedInstance.getPropertyListData("UserSettings")
		
	}
	
	func displaySettings() {
		settingsMenu = SKSpriteNode(imageNamed: "2 button menu")
		settingsMenu.name = "settings menu"
		settingsMenu.position = CGPoint(x: frame.midX, y: frame.midY)
		settingsMenu.zPosition = 2
	
		// TITLE AND QUIT BUTTON
		
		let title = SKLabelNode(fontNamed: textFont)
		title.text = "SETTINGS"
		title.position = CGPoint(x: 0, y: 90)
		title.fontColor = UIColor.blackColor()
		title.zPosition = 1
		settingsMenu.addChild(title)
		
		let quitButton = SKSpriteNode(imageNamed: "quit button")
		quitButton.name = "quit button"
		quitButton.position = CGPoint(x: 110, y: 102)
		quitButton.zPosition = 1
		settingsMenu.addChild(quitButton)
		
		
		// RESTORE PURCHASES BUTTON
		
		restorePurchasesButton = SKSpriteNode(imageNamed: "button")
		restorePurchasesButton.name = "restore purchases button"
		restorePurchasesButton.position = CGPoint(x: 0, y: -80)
		restorePurchasesButton.zPosition = 1
		
		let restoreButtonText = SKLabelNode(fontNamed: textFont)
		restoreButtonText.text = "RESTORE PURCHASES"
		restoreButtonText.position = CGPoint(x: 0, y: -10)
		restoreButtonText.fontColor = UIColor.blackColor()
		restoreButtonText.fontSize = 20
		restoreButtonText.zPosition = 2
		restoreButtonText.name = "restore purchases button text"
		restorePurchasesButton.addChild(restoreButtonText)
		
		settingsMenu.addChild(restorePurchasesButton)
		
		// REPORT BUG BUTTON
		
		reportBugButton = SKSpriteNode(imageNamed: "button")
		reportBugButton.name = "report bug button"
		reportBugButton.position = CGPoint(x: 0, y: -10)
		reportBugButton.zPosition = 1
		
		let reportBugText = SKLabelNode(fontNamed: textFont)
		reportBugText.name = "report bug button text"
		reportBugText.text = "REPORT A BUG"
		reportBugText.position = CGPoint(x: 0, y: -10)
		reportBugText.fontColor = UIColor.blackColor()
		reportBugText.fontSize = 22
		reportBugText.zPosition = 2
		reportBugButton.addChild(reportBugText)
		
		settingsMenu.addChild(reportBugButton)
		
		// SOUND LABEL
		
		let soundLabel = SKLabelNode(fontNamed: textFont)
		soundLabel.text = "SOUND"
		soundLabel.fontColor = UIColor.blackColor()
		soundLabel.position = CGPoint(x: -70, y: 40)
		soundLabel.zPosition = 2
		soundLabel.fontSize = 25
	
		settingsMenu.addChild(soundLabel)
		
		// SOUND CHECKBOX
		
		let checkBox: SKSpriteNode!
		
		if(userSettings.valueForKey("soundEnabled") as! Bool == true) {
			checkBox = SKSpriteNode(texture: checkedBox)
		} else {
			checkBox = SKSpriteNode(texture: uncheckedBox)
		}
		
		checkBox.name = "sound box"
		checkBox.position = CGPoint(x: 90, y: 50)
		checkBox.zPosition = 2
		settingsMenu.addChild(checkBox)
		
		
		
		
		
		addChild(settingsMenu)
	}
	
    func createBall(location: CGPoint) {
        let ballSprite = SKSpriteNode(imageNamed: "ball")
        ballSprite.zPosition = 2
        ballSprite.name = "ball"
        
        ballSprite.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        ballSprite.physicsBody?.dynamic = true
        ballSprite.physicsBody?.restitution = 0.2
        
        ballSprite.physicsBody?.categoryBitMask = CollisionTypes.Player.rawValue
        ballSprite.physicsBody?.contactTestBitMask = CollisionTypes.CupBottom.rawValue
        
        ballSprite.position = CGPoint(x: location.x, y: self.frame.height-100)
        activeBalls.append(ballSprite)
        addChild(ballSprite)
		
		soundPlayer.playSound(SoundEffect.BallDrop)
    }
    
    func createCup() {
        let cupSprite = SKSpriteNode(imageNamed: "cup")
        cupSprite.name = "cup"
        cupSprite.position = CGPoint(x: frame.midX, y: 90)
        
        cupSprite.physicsBody = SKPhysicsBody(texture: cupSprite.texture!, size: cupSprite.size)
        cupSprite.physicsBody?.dynamic = false
		
		cupSprite.runAction(SKAction.sequence([SKAction.waitForDuration(1), SKAction.repeatActionForever(SKAction.moveBy(CGVector(dx: 30, dy: 0) , duration: 0.25))]))

		
        let cupBottom = SKSpriteNode(imageNamed: "cup bottom")
        cupBottom.name = "cup bottom"
        cupBottom.position = CGPoint(x: 0, y: (-cupSprite.size.height/2)+2)
        cupSprite.addChild(cupBottom)
        
        cupBottom.physicsBody = SKPhysicsBody(rectangleOfSize: cupBottom.size)
        cupBottom.physicsBody?.categoryBitMask = CollisionTypes.CupBottom.rawValue
        cupBottom.physicsBody?.collisionBitMask = CollisionTypes.Player.rawValue
        cupBottom.physicsBody?.dynamic = false

        addChild(cupSprite)
    }
    
    func configurePhysics() {
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRect(x: 0, y: -30, width: frame.size.width, height: frame.size.height))
        physicsWorld.contactDelegate = self
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if(contact.bodyA.node!.name == "cup bottom") {
            ballHitCupBottom(contact.bodyB.node as! SKSpriteNode)
        } else if (contact.bodyB.node!.name == "cup bottom") {
            ballHitCupBottom(contact.bodyA.node as! SKSpriteNode)
        }
    }
    
    func ballHitCupBottom(ball: SKSpriteNode) {
        ballScore += 1
        ball.removeFromParent()
		soundPlayer.playSound(SoundEffect.BallInCup)
		
    }
    
    override func update(currentTime: CFTimeInterval) {
        if activeBalls.count != 0 {
            for ball in activeBalls {
                if ball.position.y < 0 {
                    activeBalls.removeAtIndex(activeBalls.indexOf(ball)!)
                    ball.removeFromParent()
                }
            }
        }
        
        // Track the cup and position it on the left side of the screen when it goes off the right edge
        if let cup: SKSpriteNode = childNodeWithName("cup") as? SKSpriteNode {
            if cup.position.x > 391 {
                cup.position.x = -16
            }
        }
    }
    
    
}
