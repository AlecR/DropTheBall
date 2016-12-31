//
//  LevelSelectionMenu.swift
//  BallGame
//
//  Created by Alec Rodgers on 5/9/16.
//  Copyright © 2016 Alec Rodgers. All rights reserved.
//

import SpriteKit

class LevelSelectionMenu: SKScene {
    
    var scrollView: CustomScrollView!
    var moveableNode = SKNode()
	var totalStars = 0
	
	var levelButtons: [SKSpriteNode] = []
	var activeButton: SKSpriteNode!
	
	let soundPlayer = SoundManager()
	
	let textFont = "Helvetica Neue"
    
    override func didMoveToView(view: SKView) {
		self.backgroundColor = UIColor(red:0.13, green:0.14, blue:0.15, alpha:1.0)
        addChild(moveableNode)
        scrollView = CustomScrollView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), scene: self, moveableNode: moveableNode)
        scrollView.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height * 2.35)
        view.addSubview(scrollView)
        addCells()
		
		scene!.name = "level selection menu"
		
		let title = SKLabelNode(text: "LEVELS")
		title.fontName = textFont
		title.fontSize = 35
		title.position = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height - 55)
        moveableNode.addChild(title)
		
		let backButton = SKSpriteNode(imageNamed: "back button")
		backButton.name = "back button"
		backButton.position = CGPoint(x: 40, y: self.frame.size.height - 40)
		moveableNode.addChild(backButton)
		levelButtons.append(backButton)
		
		let starImage = SKSpriteNode(imageNamed: "star")
		starImage.position = CGPoint(x: 270, y: self.frame.size.height - 40)
		moveableNode.addChild(starImage)
		
		let starCount = SKLabelNode(text: "\(totalStars)/150")
		starCount.position = CGPoint(x: 320, y: self.frame.size.height - 51)
		starCount.fontName = textFont
		starCount.fontSize = 25
		moveableNode.addChild(starCount)
		
		let unlockAllLevelsButton = SKSpriteNode(imageNamed: "button")
		unlockAllLevelsButton.name = "unlock all levels button"
		unlockAllLevelsButton.position = CGPoint(x: self.frame.size.width / 2, y: -frame.size.height * 1.18)
		levelButtons.append(unlockAllLevelsButton)
		
		let buttonText = SKLabelNode(fontNamed: textFont)
		buttonText.name = "unlock all levels button text"
		buttonText.position = CGPoint(x: 0, y: -10)
		buttonText.fontSize = 20
		buttonText.fontColor = UIColor.blackColor()
		buttonText.zPosition = 1
		buttonText.text = "UNLOCK ALL LEVELS"
		unlockAllLevelsButton.addChild(buttonText)
	
		moveableNode.addChild(unlockAllLevelsButton)
		
		moveableNode.addChild(soundPlayer)
		
    }
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		guard let touch = touches.first else { return }
		let location = touch.locationInNode(self)
		let node = self.nodeAtPoint(location)
		
		if node.name == "level node" || node.name == "back button" || node.name == "unlock all levels button"  {
			let node = node as! SKSpriteNode
			node.color = UIColor.grayColor()
			node.colorBlendFactor = 0.75
			activeButton = node
		} else if node.name == "level node text" || node.name == "star label" || node.name == "unlock all levels button text"   {
			let node = node.parent as! SKSpriteNode
			node.color = UIColor.grayColor()
			node.colorBlendFactor = 0.75
			activeButton = node
		}
	}
	
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		for _ in touches {
			for button in levelButtons {
					button.colorBlendFactor = 0
			}
		}
		
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		if activeButton != nil {
			activeButton.colorBlendFactor = 0
		}
		
		guard let touch = touches.first else { return }
		let location = touch.locationInNode(self)
		
		if (self.nodeAtPoint(location).name == "level node" || self.nodeAtPoint(location).name == "level node text" || self.nodeAtPoint(location).name == "star label" || self.nodeAtPoint(location).name == "back button") {
			soundPlayer.playSound(.MenuClick)
		} else if self.nodeAtPoint(location).name == "unlock all levels button" || self.nodeAtPoint(location).name == "unlock all levels button text" {
			soundPlayer.playSound(.MenuClick)
			IAPManager.sharedInstance.createPaymentRequestForProduct(Product.UnlockLockedLevels)
		}
	}
	
    func addCells() {
        var level = 1
        var cellsCreated = 0
        for row in (0 ..< 13).reverse() {
            for column in (0 ..< 4) {
				if (cellsCreated < 50) {
					createCell(xPos: (Double(column) * 87.5) + 56.25, yPos: ((Double(row) * 104) + 170) - Double(self.frame.height * 1.3), level: level)
					cellsCreated += 1
					level += 1
				} else {
					break
				}
            }
        }
        
    }
    
	func createCell(xPos xPos: Double, yPos: Double, level:Int) {
		
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent("LevelData.plist")
	
        if let levelData = NSMutableDictionary(contentsOfFile: path)  {
            var cell: SKSpriteNode!
	
            
            if (levelData.valueForKey("\(level)") as! Int > -1) {

                cell = SKSpriteNode(imageNamed: "blank level")
                cell.name = "level node"
                cell.position = CGPoint(x: xPos, y: yPos)
				cell.zPosition = 1
				
                let levelLabel = SKLabelNode(fontNamed: textFont)
				levelLabel.zPosition = 2
                levelLabel.name = "level node text"
                levelLabel.text = "\(level)"
                levelLabel.fontSize = 45
                levelLabel.position = CGPoint(x: 0, y: -10)
                cell.addChild(levelLabel)
                
                let stars = levelData.valueForKey("\(level)") as! Int
				totalStars += stars
                
                let starLabel = SKSpriteNode(imageNamed: "\(stars) star")
				starLabel.name = "star label"
				starLabel.zPosition = 2
                starLabel.position = CGPoint(x: 0, y: -25)
                starLabel.xScale = 0.85
                starLabel.yScale = 0.85
                cell.addChild(starLabel)
            } else {
                cell = SKSpriteNode(imageNamed: "locked level")
                cell.position = CGPoint(x: xPos, y: yPos)
                cell.userInteractionEnabled = false
                
            }
            levelButtons.append(cell)
            moveableNode.addChild(cell)
        }
        
    }
	
}


