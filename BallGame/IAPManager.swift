//
//  IAPManager.swift
//  Drop The Ball
//
//  Created by Alec Rodgers on 7/4/16.
//  Copyright © 2016 Alec Rodgers. All rights reserved.
//

import UIKit
import StoreKit
import SpriteKit

protocol IAPManagerDelegate {
	func managerDidRestorePurchases()
}

enum Product {
	case UnlockLockedLevels
	case RetryWithExtraBall
	case RemoveAds
}

class IAPManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate{

	static let sharedInstance = IAPManager()
	
	var request: SKProductsRequest!
	var products: NSArray!
	
	var delegate: IAPManagerDelegate?
	
	func setupInAppPurchases() {
		self.validateProductIds(self.getProductIdsFromMainBundle())
		SKPaymentQueue.defaultQueue().addTransactionObserver(self)
	}
	
	func getProductIdsFromMainBundle() -> NSArray {
		var identifiers = NSArray()
		if let url = NSBundle.mainBundle().URLForResource("IAPProductIds", withExtension: ".plist") {
			identifiers = NSArray(contentsOfURL: url)!
		}
		return identifiers
	}
	
	func validateProductIds(identifiers: NSArray) {
		let productIds = NSSet(array: identifiers as [AnyObject])
		let productRequest = SKProductsRequest(productIdentifiers: productIds as! Set<String>)
		self.request = productRequest
		productRequest.delegate = self
		productRequest.start()
	}
	
	func createPaymentRequestForProduct(product: Product) {
		
		let productId: String!
		
		switch product {
		case .UnlockLockedLevels:
			productId = "com.dropTheBall.unlockAllLevels"
		case .RetryWithExtraBall:
			productId = "com.dropTheBall.retryWithExtraBall"
		case .RemoveAds:
			productId = "com.dropTheBall.removeAds"
		}
		
		for p in products {
			if p.productIdentifier == productId {
				SKPaymentQueue.defaultQueue().addPayment(SKPayment(product: p as! SKProduct))
			}
		}
	}
	
	func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		
		for transaction in transactions as [SKPaymentTransaction] {
			
			switch transaction.transactionState {
			case .Purchasing:
				print("Purchasing")
			case .Deferred:
				print("Deferred")
			case .Failed:
				print("Failed")
				print(transaction.error?.localizedDescription)
				SKPaymentQueue.defaultQueue().finishTransaction(transaction)
			case .Purchased:
				print("Purchased")
				self.verifyReceipt(transaction)
			case .Restored:
				print("Restored")
				self.verifyReceipt(transaction)
			}
			
		}
	}
	
	func restorePurchases() {
		let request = SKReceiptRefreshRequest()
		request.delegate = self
		request.start()
	}
	
	func requestDidFinish(request: SKRequest) {
		self.verifyReceipt(nil)
	}
	
	func verifyReceipt(transaction: SKPaymentTransaction?) {
		let receiptURL = NSBundle.mainBundle().appStoreReceiptURL!
		if let receipt = NSData(contentsOfURL: receiptURL) {
			// exists
			let requestContents = ["receipt-data" : receipt.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))]
			
			//Perform request
			do {
				let requestData = try NSJSONSerialization.dataWithJSONObject(requestContents, options: NSJSONWritingOptions(rawValue: 0))
				
				// Build URL request
				let storeURL = NSURL(string: "https://buy.itunes.apple.com/verifyReceipt")
				let request = NSMutableURLRequest(URL: storeURL!)
				request.HTTPMethod = "Post"
				request.HTTPBody = requestData
				
				let session = NSURLSession.sharedSession()
				let task = session.dataTaskWithRequest(request, completionHandler: {(responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
					do {
						let json = try NSJSONSerialization.JSONObjectWithData(responseData!, options: .MutableLeaves) as! NSDictionary
						//print(json)
						if(json.objectForKey("status") as! NSNumber) == 0 {
							let receiptDictionary = json["receipt"] as! NSDictionary
							if let purchases = receiptDictionary["in_app"] as? NSArray {
								self.validatePurchaseArray(purchases)
							}
							if transaction != nil {
								SKPaymentQueue.defaultQueue().finishTransaction(transaction!)
							}
							
							if transaction?.transactionState == .Restored {
								dispatch_sync(dispatch_get_main_queue(), { () -> Void in
									self.delegate?.managerDidRestorePurchases()
								})
							}
							
						} else {
							//print(json.objectForKey("status") as! NSNumber)
						}
					} catch {
						//print(error)
					}
				})
				task.resume()
			} catch {
				//print("error")
			}
		} else {
			//print("no receipt")
		}
	}
	
	func validatePurchaseArray(purchases: NSArray) {
		for purchase in purchases as! [NSDictionary] {
			
			let id = purchase["product_id"] as! String
			
			if id == "com.dropTheBall.removeAds" {
				if(userSettings["adsEnabled"] as! Bool == true) {
					unlockPurchasedFunctionalityForProductId(Product.RemoveAds)
				}
			}else if id == "com.dropTheBall.unlockAllLevels" {
				for level in 1...levelData.count {
					if (levelData.valueForKey("\(level)") as! Int == -1) {
						unlockPurchasedFunctionalityForProductId(Product.UnlockLockedLevels)
						break;
					}
				}
			}else if id == "com.dropTheBall.retryWithExtraBall" {
				unlockPurchasedFunctionalityForProductId(Product.RetryWithExtraBall)
			}
		}
	}
	
	
	func unlockPurchasedFunctionalityForProductId(product: Product) {
		switch product {
		case .RemoveAds:
			PropertyListManager.sharedInstance.modifyUserSettings("adsEnabled", newValue: false)
			userSettings = PropertyListManager.sharedInstance.getPropertyListData("UserSettings")
			NSNotificationCenter.defaultCenter().postNotificationName("hide banner", object: nil)
			
		case .RetryWithExtraBall:
			NSNotificationCenter.defaultCenter().postNotificationName("load level extra ball", object: nil)
			print("tried")
			break
			
		case .UnlockLockedLevels:
			for level in 1...levelData.count {
				if (levelData.valueForKey("\(level)") as! Int == -1) {
					PropertyListManager.sharedInstance.modifyLevelData(level: level, stars: 0)
				}
			}
			levelData = PropertyListManager.sharedInstance.getPropertyListData("LevelData")
		}
	}
	
	func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
		self.products = response.products 
	
	}
	
	
}
