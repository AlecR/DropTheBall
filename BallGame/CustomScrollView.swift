//
//  CustomScrollView.swift
//  BallGame
//
//  Created by Alec Rodgers on 5/9/16.
//  Copyright © 2016 Alec Rodgers. All rights reserved.
//

import SpriteKit
import GoogleMobileAds

var nodesTouched: [AnyObject] = [] // global

class CustomScrollView: UIScrollView {
    
    // MARK: - Static Properties
    
    /// Touches allowed
    static var disabledTouches = false
    
    /// Scroll view
    private static var scrollView: UIScrollView!
    
    // MARK: - Properties
    
    /// Current scene
    private var currentScene: SKScene?
    
    /// Moveable node
    private var moveableNode: SKNode?
    
    // MARK: - Init
    init(frame: CGRect, scene: SKScene, moveableNode: SKNode) {
        super.init(frame: frame)
        
        CustomScrollView.scrollView = self
        currentScene = scene
        self.moveableNode = moveableNode
        self.frame = frame
        indicatorStyle = .White
        scrollEnabled = true
        canCancelContentTouches = false
        userInteractionEnabled = true
        delegate = self
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Touches
extension CustomScrollView {
    
    /// began
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard !CustomScrollView.disabledTouches else { return }
        currentScene?.touchesBegan(touches, withEvent: event)
	
    }
    
    /// moved
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard !CustomScrollView.disabledTouches else { return }
        currentScene?.touchesMoved(touches, withEvent: event)
		
    }
    
    /// ended
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
        guard !CustomScrollView.disabledTouches else { return }
        currentScene?.touchesEnded(touches, withEvent: event)
        
        guard let touch = touches.first else { return }
        let location = touch.locationInNode(self.moveableNode!)
        
        if moveableNode?.nodeAtPoint(location).name == "level node" {
            let level = Int((moveableNode!.nodeAtPoint(location).childNodeWithName("level node text") as! SKLabelNode).text!)!
            let node = moveableNode!.nodeAtPoint(location) as! SKSpriteNode
            node.colorBlendFactor = 0
			
            if let scene = GameScene(fileNamed: "GameScene") {
				for view in (self.currentScene!.view?.subviews)! {
					if(!view.isKindOfClass(GADBannerView)) {
						view.removeFromSuperview()
					}
				}
                scene.size = CGSize(width: 375, height: 667)
				if(UIScreen.mainScreen().bounds.height == 480) {
					scene.scaleMode = .Fill
				} else {
					scene.scaleMode = .AspectFill
				}
                self.currentScene!.view!.presentScene(scene, transition: SKTransition.fadeWithDuration(1))
                scene.loadLevel(level)
            }
            
        } else if moveableNode?.nodeAtPoint(location).name == "level node text" || moveableNode?.nodeAtPoint(location).name == "star label" {
			var level: Int!
			
			if (moveableNode?.nodeAtPoint(location).name == "level node text") {
				level = Int((moveableNode!.nodeAtPoint(location) as! SKLabelNode).text!)!
			} else if (moveableNode?.nodeAtPoint(location).name == "star label") {
				level = Int((moveableNode!.nodeAtPoint(location).parent!.childNodeWithName("level node text") as! SKLabelNode).text!)!
			}
			
            let node = moveableNode!.nodeAtPoint(location).parent as! SKSpriteNode
            node.colorBlendFactor = 0

            if let scene = GameScene(fileNamed: "GameScene") {
                for view in (self.currentScene!.view?.subviews)! {
					if(!view.isKindOfClass(GADBannerView)) {
						view.removeFromSuperview()
					}
                }
                scene.size = CGSize(width: 375, height: 667)
				if(UIScreen.mainScreen().bounds.height == 480) {
					scene.scaleMode = .Fill
				} else {
					scene.scaleMode = .AspectFill
				}
                self.currentScene!.view!.presentScene(scene, transition: SKTransition.fadeWithDuration(1))
                scene.loadLevel(level)
            }
				
		} else if moveableNode?.nodeAtPoint(location).name == "back button" {

			if let scene = MainMenu(fileNamed: "MainMenu") {
				for view in (self.currentScene!.view?.subviews)! {
					if(!view.isKindOfClass(GADBannerView)) {
						view.removeFromSuperview()
					}
				}
				
				scene.size = CGSize(width: 375, height: 667)
				if(UIScreen.mainScreen().bounds.height == 480) {
					scene.scaleMode = .Fill
				} else {
					scene.scaleMode = .AspectFill
				}
				self.currentScene?.view!.presentScene(scene, transition: SKTransition.fadeWithDuration(1))
				
			}
		} else if moveableNode?.nodeAtPoint(location).name == "unlock all levels button" {
			let node = moveableNode!.nodeAtPoint(location) as! SKSpriteNode
			node.colorBlendFactor = 0
		} else if moveableNode?.nodeAtPoint(location).name == "unlock all levels button text" {
			let node = moveableNode!.nodeAtPoint(location).parent as! SKSpriteNode
			node.colorBlendFactor = 0
		}
    }
	
    /// cancelled
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        
        guard !CustomScrollView.disabledTouches else { return }
        currentScene?.touchesCancelled(touches, withEvent: event)
    }
	
}

// MARK: - Delegates
extension CustomScrollView: UIScrollViewDelegate {
    
    /// did scroll
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        //moveableNode!.position.x = scrollView.contentOffset.x // Left/Right
        
        moveableNode!.position.y = scrollView.contentOffset.y // Up/Dowm
    }
}
