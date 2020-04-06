//
//  BeaconManager.swift
//  Beacon Sample
//
//  Created by Mahmoud Eldesouky on 20.03.20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation

let BleExpiryThreshold = 15.0

public class Peripheral {
	public enum AppState: String {
		case foreground = "active", background = "passive"
	}

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

class PeripheralManager: NSObject {


    var peripheralManager: CBPeripheralManager!
    var region: CLBeaconRegion!
	var userID: String = "No user id set"

	override init() {
		super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
		userID = Defaults.getUserID() ?? "No user id set"
	}


	func startBroadcasting(userID: String) {
		self.userID = userID
		if peripheralManager.state == .poweredOn {
			if !peripheralManager.isAdvertising {
				start(userID: self.userID)
			}
		}
	}

	private func start(userID: String){
		print("startAdvertising")

		peripheralManager.stopAdvertising()

		var peripheralData: [String: Any]? = [:]

		peripheralData?[CBAdvertisementDataLocalNameKey] = userID
		peripheralData?[CBAdvertisementDataServiceUUIDsKey] = [ProximityConfig.AppUUID]// BLE Adv.

		let characteristic = CBMutableCharacteristic(type: ProximityConfig.CharacteristicUUID, properties: [.read], value: userID.data(using: .utf8), permissions: [.readable])

		let service:CBMutableService = CBMutableService(type: ProximityConfig.ServiceUUID, primary: true)
		service.characteristics = [characteristic]

		peripheralManager.add(service)

		peripheralManager.startAdvertising(peripheralData)
	}


	func stopBroadcasting() {
		print("stopBroadcasting")
		peripheralManager.stopAdvertising()
	}


	func isAdvertising() -> Bool {
		return peripheralManager.isAdvertising
	}
}

// MARK: - Bluetooth Manager Delegate

extension PeripheralManager: CBPeripheralManagerDelegate  {

   func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
	   print("peripheralManagerDidUpdateState: \(peripheral.state.rawValue)")

		if peripheral.state == .poweredOn {
			start(userID: self.userID)
		} else if peripheral.state == .poweredOff {
		   stopBroadcasting()
	   }
   }

   func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
	   print("peripheralManagerDidStartAdvertising")
   }
//
//	func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
//		DispatchQueue.main.async {
//			NotificationService.shared.sendLocalNotification(title: "didAddService", body: "\(service)")
//		}
//	}
//
//	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
//		DispatchQueue.main.async {
//			var id = "N.A"
//			if let idData = request.value {
//				id = String(bytes: idData, encoding: .utf8) ?? "N.A"
//			}
//			NotificationService.shared.sendLocalNotification(title: "didReceiveRead", body: "id:\(id) \(request)")
//		}
//		peripheral.respond(to: request, withResult: .success)
//		if let userID = Defaults.getUserID() {
//			start(userID: userID)
//		}
//	}

}
