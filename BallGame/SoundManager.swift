//
//  SoundManager.swift
//  Drop The Ball
//
//  Created by Alec Rodgers on 7/8/16.
//  Copyright © 2016 Alec Rodgers. All rights reserved.
//

import UIKit
import SpriteKit

enum SoundEffect {
	case MenuClick
	case LoseBeep
	case BallInCup
	case GravDown
	case GravUp
	case InVortex
	case OutVortrex
	case Pop
	case StarCollect
	case BallDrop
	case ButtonPressed
}

class SoundManager: SKNode {

	
	func playSound(sound: SoundEffect) {
		
		var soundName: String
		
		switch sound {
		case .MenuClick:
			soundName = "menuButtonPress.mp3"
		case .LoseBeep:
			soundName = "loseBeep.wav"
		case .BallInCup:
			soundName = "ballInCup.mp3"
		case .GravUp:
			soundName = "gravUp.mp3"
		case .GravDown:
			soundName = "gravDown.wav"
		case .InVortex:
			soundName = "inVortex.wav"
		case .OutVortrex:
			soundName = "outVortex.wav"
		case .Pop:
			soundName = "pop.wav"
		case .StarCollect:
			soundName = "starCollect.mp3"
		case .BallDrop:
			soundName = "ballDrop.mp3"
		case .ButtonPressed:
			soundName = "buttonPressed.mp3"
		}
		
		if(userSettings.valueForKey("soundEnabled") as! Bool == true) {
			runAction(SKAction.playSoundFileNamed(soundName, waitForCompletion: false))
		}
		
	}

}
