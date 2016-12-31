//
//  GameViewController.swift
//  BallGame
//
//  Created by Alec Rodgers on 4/25/16.
//  Copyright (c) 2016 Alec Rodgers. All rights reserved.
//

import UIKit
import SpriteKit
import GoogleMobileAds

class GameViewController: UIViewController, GADBannerViewDelegate, GADInterstitialDelegate, IAPManagerDelegate {
	
	var banner: GADBannerView!
	var interstitial: GADInterstitial!
	
	var randomNumber = 5
	
	// ===============================================================================================================================================
	// ==== VIEW DID LOAD ============================================================================================================================
	// ===============================================================================================================================================
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		banner = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
		banner.hidden = true
		banner.delegate = self
		banner.adUnitID = "ca-app-pub-6459733432839906/4796737876"
		banner.rootViewController = self
		banner.frame = CGRectMake(0, view.bounds.height - banner.frame.size.height, banner.frame.size.width, banner.frame.size.height)
		view.addSubview(banner)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameViewController.hideBanner) , name: "hide banner", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameViewController.showBanner) , name: "show banner", object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GameViewController.displayInterstatial) , name: "display interstatial", object: nil)
		
		
		
        if let scene = MainMenu(fileNamed: "MainMenu") {
            // Configure the view.
            let skView = self.view as! SKView
			scene.size = CGSize(width: 375, height: 667)
			if(UIScreen.mainScreen().bounds.height == 480) {
				scene.scaleMode = .Fill
			} else {
				scene.scaleMode = .AspectFill
			}
			
            skView.ignoresSiblingOrder = true
            skView.presentScene(scene)
        }else{
            print("didnt work")
        }
		
		showBanner()
		prepareInterstitial()
		interstitial.delegate = self
		IAPManager.sharedInstance.delegate = self
    }
	
	// ===============================================================================================================================================
	// ==== INTERSTATIAL AD CONFIG ===================================================================================================================
	// ===============================================================================================================================================
	
	func prepareInterstitial() -> GADInterstitial {
		interstitial = GADInterstitial(adUnitID: "ca-app-pub-6459733432839906/7213650679")
		interstitial.loadRequest(GADRequest())
		return interstitial
		
	}
	
	func displayInterstatial() {
		if userSettings["adsEnabled"] as! Bool {
			if(interstitial.isReady) {
				interstitial.presentFromRootViewController(self)
				interstitial = prepareInterstitial()
			}
		}
	}
	
	func interstitialDidReceiveAd(ad: GADInterstitial!) {
		
	}

	// ===============================================================================================================================================
	// ==== BANNER AD CONFIG =========================================================================================================================
	// ===============================================================================================================================================
	
	func adViewDidReceiveAd(bannerView: GADBannerView!) {
		banner.hidden = false
	}
	
	func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
		banner.hidden = true
	}
	
	func showBanner() {
		if userSettings["adsEnabled"] as! Bool {
			banner.hidden = false
			let request = GADRequest()
			banner.loadRequest(request)
		}
	}
	
	func hideBanner() {
		banner.hidden = true
	}
	
	// ===============================================================================================================================================
	// ==== MISC FUNCTIONS ===========================================================================================================================
	// ===============================================================================================================================================

	func managerDidRestorePurchases() {
		let alertController = UIAlertController(title: "In-App Purchase", message: "Your purchases have been restored", preferredStyle: .Alert)
		let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
		alertController.addAction(okAction)
		self.presentViewController(alertController, animated: true, completion: nil)
	}
    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
