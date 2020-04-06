//
//
//  Created by Mahmoud Eldesouky on 21.03.20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit
import CoreBluetooth
import UserNotifications
import CoreLocation

import CoreData

protocol CentralManagerDelegate: class {
	func didUpdateDiscovered(peripherals: [Peripheral])
}

class CentralManager: NSObject {

    var peripherals = [Peripheral]()
	var centralManagerQueue = DispatchQueue(label: "centralManagerQueue")

	var centralManager: CBCentralManager!
	private var cleanOldDevices: Timer?
	private var peripheralDiscoveryTimespan: Double = 16

	var connectedPeripheral: CBPeripheral?

	weak var delegate: CentralManagerDelegate?

	let database = Database()

	override init() {
		super.init()
		database.cleanUnClosedDetections()
	}

	func startScanning(){
		centralManager = CBCentralManager(delegate: self, queue: nil)//centralManagerQueue //ble peripheral listener
		setupDiscoveryExpiryValidator()

		if centralManager.state == .poweredOn {
			centralManager.scanForPeripherals(withServices: [ProximityConfig.AppUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true ,CBCentralManagerOptionShowPowerAlertKey: false])
		}
	}

	func stopScanning(){
		print("stopScanning")
		centralManager.stopScan()
	}

	/* Close all open conections before sending */
	func cleanupForSendingData(){
		peripherals = []
		if let peripheral = connectedPeripheral {
			self.centralManager.cancelPeripheralConnection(peripheral)
			self.connectedPeripheral = nil
		}
	}

	private func scan(){
		print("startScanning")
		centralManager.stopScan()
		centralManager.scanForPeripherals(withServices: [ProximityConfig.AppUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber.init(booleanLiteral: true)
			,CBCentralManagerOptionShowPowerAlertKey: false
		])

	}

	//periodically checking and validates if each of the discovered peripherals were detected in the timespan of "peripheralDiscoveryTimespan".
	// then remove the peripherals that were not detected in the last "peripheralDiscoveryTimespan" time period
	private func setupDiscoveryExpiryValidator(){
		cleanOldDevices = Timer.scheduledTimer(withTimeInterval: peripheralDiscoveryTimespan, repeats: true, block: { _ in

			if let peripheral = self.connectedPeripheral { //make sure that connectedPeripheral is not jammed
				self.centralManager.cancelPeripheralConnection(peripheral)
				self.connectedPeripheral = nil
			}

			let referenceDate = Date()
			for peripheral in self.peripherals {
				if peripheral.shouldStore {
					// Store in DB
					self.database.store(peripheral: peripheral)
				}

				if peripheral.didExpire(referenceDate) {
					DispatchQueue.main.async {
						//NotificationService.shared.sendLocalNotification(title: "Disappear", body: "Disappear \(peripheral.userID)")
						if peripheral.hasBeenStored {
							// update removal date
							self.database.update(peripheral: peripheral)
						}
						self.peripherals.removeAll(where: { $0.uuid == peripheral.uuid })
						self.delegate?.didUpdateDiscovered(peripherals: self.peripherals)
					}
				}
			}
		})
	}



	private func isAnApp(userID: String) -> Bool {
		return userID.hasPrefix(ProximityConfig.AppUserIDPrefix)
	}

	/*
	Handles adding or updating discovered peripherals into the "peripherals" array.
	setupDiscoveryExpiryValidator() is then periodically called to validate the discovered peripherals found in the "peripherals" array
	*/
	private func addOrUpdate(peripheral: CBPeripheral, distance: Double , userID: String, appState: Peripheral.AppState = .background, rssi: Double){

		//check if this peripheral is already added/tracked in our list
		if !peripherals.contains(where: { $0.userID == userID}) {

			peripherals.append(Peripheral(uuid: peripheral.identifier.uuidString, userID: userID, distance: distance, appState: appState, rssi: rssi))
			delegate?.didUpdateDiscovered(peripherals: self.peripherals)
			DispatchQueue.main.async{
				//NotificationService.shared.sendLocalNotification(title: "Discovery", body: "Discovered \(userID)")
			}
		}
		//as peripheral is already added/tracked, we will update its values
		else if let idx = peripherals.firstIndex(where: { $0.userID == userID}) {

			peripherals[idx].date = Date()
			peripherals[idx].distance = distance
			peripherals[idx].rssi = rssi


			print("id: \(peripherals[idx].userID), lastseen: \(peripherals[idx].date.timeIntervalSince1970), date: \(peripherals[idx].date)")
			if peripherals[idx].appState != appState {
				peripherals[idx].appState = appState
				DispatchQueue.main.async{
					//NotificationService.shared.sendLocalNotification(title: "Discovery Update", body: "Updated \(userID) state: \(appState.rawValue)")
					self.delegate?.didUpdateDiscovered(peripherals: self.peripherals)
				}
			}
		}
		else {
			assertionFailure("We have the peripheral but can't find it")
		}
	}

	private func getProximityFrom(rssi proximity: Double) -> Double {

		var result = 16
		if proximity < -57 {
			result =  16
		}
		if proximity < -53 {
			result =  8
		}
		if proximity < -47 {
			result =  4
		}
		if proximity < -41 {
			result =  2
		}
		if proximity < 0 {
			result =  1
		}
		print("proximity: \(result)")
		return Double(result)
	}

}

// MARK: - CBCentralManagerDelegate
extension CentralManager: CBCentralManagerDelegate {
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		var msg = ""

		switch central.state {

		case .poweredOff:
			msg = "Bluetooth is Off"
		case .poweredOn:
			msg = "Bluetooth is On"
			scan()
		case .unsupported:
			msg = "Not Supported"
		default:
			msg = "😔"

		}

		print("CBCentralManager STATE: " + msg)
	}



	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		print("didDiscover peripheral: \(peripheral)")
//		print("advertisementData: \(advertisementData)")
//		print("advertisementDataName: \(String(describing: advertisementData[CBAdvertisementDataLocalNameKey])))")

 		var appState: Peripheral.AppState = .background

		var userID = "N.A userID"
		// discovered peripheral is advertising in foreground
		if let _ = ((advertisementData[CBAdvertisementDataServiceUUIDsKey] as? NSArray)?.firstObject as? CBUUID)?.uuidString {
			appState = .foreground

		}
		// discovered peripheral is advertising in background
		else if let _ = ((advertisementData["kCBAdvDataHashedServiceUUIDs"] as? NSArray)?.firstObject as? CBUUID)?.uuidString {
			appState = .background
		}

		//our userID must be have the appUserIDPrefix, to make sure it is not the BLE GAT name
		if let id = (advertisementData[CBAdvertisementDataLocalNameKey] as? String), isAnApp(userID: id){
			userID = id
		}
		else if let id = peripheral.name, isAnApp(userID: id) {
			userID = id
		}
		else {
			let device = peripherals.first { $0.uuid == peripheral.identifier.uuidString }
			if let device = device {
				print("didn't need connection, already connected before: \(device.userID)")
				userID = device.userID
			}
			else {
				//we can't get the name/userID so we will connect to fetch it
				if connectedPeripheral == nil { //we can only connect to one peripheral at a time
					print("First discovery, will try to connect")
					connectedPeripheral = peripheral
					central.connect(peripheral, options: nil)
				}
				return
			}
		}

		print("proximity: \(getProximityFrom(rssi: RSSI.doubleValue))")

		let distance = getProximityFrom(rssi: RSSI.doubleValue)
		addOrUpdate(peripheral: peripheral, distance: distance, userID: userID, appState: appState, rssi: RSSI.doubleValue)

		print("---------------------------------------------------------------")
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		peripheral.delegate = self
		print("connect")
		peripheral.discoverServices([])
	}

	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		print("didFailToConnect, connectedPeripheral = nil")
		centralManager.cancelPeripheralConnection(peripheral)
		connectedPeripheral = nil
		print("disconnect N.A")
	}
}

extension CentralManager: CBPeripheralDelegate {

	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		print("didDiscoverServices")
		print("services: \(String(describing: peripheral.services))")

		for service in peripheral.services ?? [] {
			if service.uuid == ProximityConfig.ServiceUUID {
				print("found service")
				peripheral.discoverCharacteristics([], for: service)
				return
			}
		}
		centralManager.cancelPeripheralConnection(peripheral)
		connectedPeripheral = nil
		print("disconnect N.A")
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		print("didDiscoverCharacteristicsFor")
		print("characteristics: \(String(describing: service.characteristics))")

		for char in service.characteristics ?? [] {
			if char.uuid == ProximityConfig.CharacteristicUUID {
				print("found characteristic")
				peripheral.readValue(for: char)
				return
			}
		}
		centralManager.cancelPeripheralConnection(peripheral)
		connectedPeripheral = nil
		print("disconnect N.A")
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		if let value = characteristic.value, let id = String(bytes: value, encoding: .utf8), isAnApp(userID: id) {
			addOrUpdate(peripheral: peripheral, distance: 4, userID: id, rssi: -48) //todo: should be optional
			print("disconnect \(id)")
		}
		else {
			print("disconnect N.A")
		}
		centralManager.cancelPeripheralConnection(peripheral)
		connectedPeripheral = nil
	}
}

