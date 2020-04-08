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

public struct DetectedContact {
    public var userId: String?
    public var timestamp: Int?
    public var duration: Int64?
	public var distance: Double?
	public var rssi: Double?
	public var isBackground: Bool?

    init(bleEntity: DetectedBLE) {
        userId = bleEntity.userID
        if let date = bleEntity.timestamp {
            timestamp = Int(date.timeIntervalSince1970)
        }
		distance = bleEntity.distance
        duration = bleEntity.duration
        rssi = bleEntity.rssi
		isBackground = bleEntity.isBackground
    }
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
