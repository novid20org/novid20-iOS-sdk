//
//  DiscoveredPeripheral.swift
//  novid20
//
//  Created by Mahmoud Eldesouky on 07.04.20.
//  Copyright © 2020 novid20. All rights reserved.
//

import Foundation

public enum AppState: String {
	case foreground = "active", background = "passive"
}

public class Peripheral {

	let createdAt: Date = Date()
	var hasBeenStored: Bool = false
	let uuid: String
	var userID: String
	var distance: Double
	var rssi: Double
	var date: Date = Date()
	var appState: AppState

	public init(uuid: String, userID: String, distance: Double, appState: AppState, rssi: Double) {
		self.uuid = uuid
		self.userID = userID
		self.distance = distance
		self.appState = appState
		self.rssi = rssi
	}

	public var shouldStore: Bool {
		//let x = Date().timeIntervalSince(createdAt)
		if !hasBeenStored {
			hasBeenStored = true
			return true
		}
		return false
	}

	func didExpire(_ refrence: Date) -> Bool {
		let x = refrence.timeIntervalSince(date)
		return x > BleExpiryThreshold
	}
}
