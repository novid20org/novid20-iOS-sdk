//
//  ProximityService.swift
//  Beacon Sample
//
//  Created by Mahmoud Eldesouky on 21.03.20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

public class ProximityService {

	public static var shared = ProximityService()

	private var centralManager: CentralManager?
	private var peripheralManager: PeripheralManager?
	private var locationService: LocationService!

	var geofenceTriggerCallback: (()->())?
	var userID: String?

	public init(){

		locationService = LocationService(delegate: self)
		Database.shared.deleteOldLocations()
		Database.shared.deleteOldBLEConnections()
	}

	public func startIfPossible(userID: String){
		if self.userID == nil {
			self.userID = userID
		}
		if Defaults.getServiceState() {
			start(userID: userID)
		}
	}

	public func start(userID: String){
		if self.userID == nil {
			self.userID = userID
		}
		Defaults.set(serviceState: true)

		if centralManager == nil {
			centralManager = CentralManager()
		}
		if peripheralManager == nil {
			peripheralManager = PeripheralManager(userID: userID)

		}
		locationService.startLocationListening()
		peripheralManager?.startBroadcasting()
		centralManager?.startScanning()
	}

	public func stop(){
		Defaults.set(serviceState: false)

		peripheralManager?.stopBroadcasting()
		centralManager?.stopScanning()
		locationService.stopLocationListening()
	}

	public func set(config: ProximitySDKConfiguration){
		ProximityConfig.AppUUID = config.appUUID
		ProximityConfig.ServiceUUID = config.serviceUUID
		ProximityConfig.CharacteristicUUID = config.characteristicUUID
		ProximityConfig.AppUserIDPrefix = config.appUserIDPrefix
	}

	public func setCentral(delegate: CentralManagerDelegate){
		centralManager?.delegate = delegate
	}

	public func setGeofenceTrigger(callback: @escaping ()->()){
		geofenceTriggerCallback = callback
	}

	public func prepareBLEForSendingData(){
		centralManager?.cleanupForSendingData()
	}
}


extension ProximityService: LocationServiceDelegate {
	func didExitGeofence() {
		if let userID = self.userID {
			startIfPossible(userID: userID)
		}
		geofenceTriggerCallback?()
	}


	func didUpdateLocation(){
		//centralManager.startScanning()
		//startBoradcasting(isPeripheralMode: self.isPeripheralMode)
	}

	func isBroadcasting() -> Bool {
		return peripheralManager?.isAdvertising() ?? false
	}
}

