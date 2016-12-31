//
//  PropertyListManager.swift
//  Drop The Ball
//
//  Created by Alec Rodgers on 7/7/16.
//  Copyright © 2016 Alec Rodgers. All rights reserved.
//

import UIKit

class PropertyListManager: NSObject {
	
	static let sharedInstance = PropertyListManager()

	func getPropertyListData(plistName: String) -> NSMutableDictionary {
		
		// getting path to GameData.plist
		let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! as NSString
		let path = documentsDirectory.stringByAppendingPathComponent("\(plistName).plist")
		
		let fileManager = NSFileManager.defaultManager()
		
		//check if file exists
		if(!fileManager.fileExistsAtPath(path)) {
			// If it doesn't, copy it from the default file in the Bundle
			if let bundlePath = NSBundle.mainBundle().pathForResource("\(plistName)", ofType: "plist") {
				do {
					try fileManager.copyItemAtPath(bundlePath, toPath: path)
				} catch {
					print(path)
				}
				
			}
		}
		return NSMutableDictionary(contentsOfFile: path)!
		
	}
	
	func modifyUserSettings(setting: String, newValue: Bool) {
		
		let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! as NSString
		let path = documentsDirectory.stringByAppendingPathComponent("UserSettings.plist")
		let dict: NSMutableDictionary = NSMutableDictionary(contentsOfFile: path)!
		
		dict.setObject(newValue, forKey: setting)
		dict.writeToFile(path, atomically: true)
		
	}
	
	func modifyLevelData(level level: Int, stars: Int) {
		
		let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first! as NSString
		let path = documentsDirectory.stringByAppendingPathComponent("LevelData.plist")
		let dict: NSMutableDictionary = NSMutableDictionary(contentsOfFile: path)!
		
		if stars > dict.valueForKey("\(level)") as! Int {
			//saving values
			dict.setObject(stars, forKey: "\(level)")
			
			if(level < 50 && dict.valueForKey("\(level+1)") as! Int == -1) {
				dict.setObject(0, forKey: "\(level+1)")
			}
			
			//writing to LevelData.plist
			dict.writeToFile(path, atomically: true)
		}
	}
}
