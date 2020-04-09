//
//  AppDelegate.swift
//  novid20Proximity
//
//  Created by mahmoud@eldesouky.com on 04/06/2020.
//  Copyright (c) 2020 mahmoud@eldesouky.com. All rights reserved.
//

import UIKit
import novid20Proximity
import CoreLocation
import CoreBluetooth

let GeorgiaAppUUID = CBUUID(string: "de65c482-7a45-11ea-bc55-0242ac130003")
let GeorgiaServiceUUID = CBUUID(string: "e9143e04-7a45-11ea-bc55-0242ac130003")
let GeorgiaCharacteristicUUID = CBUUID(string: "f0626dc0-7a45-11ea-bc55-0242ac130003")
let GeorgiaAppUserIDPrefix = "nvSDK-"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

	var userID: String?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.


		let sdkConfig = ProximitySDKConfiguration(appUUID: GeorgiaAppUUID, serviceUUID: GeorgiaServiceUUID, characteristicUUID: GeorgiaCharacteristicUUID, appUserIDPrefix: GeorgiaAppUserIDPrefix)
		ProximityService.shared.set(config: sdkConfig)

		userID = "\(sdkConfig.appUserIDPrefix)123456"

		if let id = userID {
			self.window!.rootViewController = ProximityViewController(userID: id)
		}
		self.window!.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		if let id = userID {
			ProximityService.shared.start(userID: id)
		}
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

