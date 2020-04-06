//
//  ProximityService.swift
//  Beacon Sample
//
//  Created by Mahmoud Eldesouky on 21.03.20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

class ProximityService {

	static var shared = ProximityService()

	private var centralManager: CentralManager?
	private var peripheralManager: PeripheralManager?
	private var locationService: LocationService!


	init(){

		locationService = LocationService(delegate: self)
	}

	func startIfPossible(userID: String){
		if Defaults.getServiceState() {
			start(userID: userID)
		}
	}

	func start(userID: String){

		Defaults.set(serviceState: true)

		if centralManager == nil {
			centralManager = CentralManager()
		}
		if peripheralManager == nil {
			peripheralManager = PeripheralManager()

		}
		locationService.startLocationListening()
		peripheralManager?.startBroadcasting(userID: userID)
		centralManager?.startScanning()
	}

	func stop(){
		Defaults.set(serviceState: false)

		peripheralManager?.stopBroadcasting()
		centralManager?.stopScanning()
		locationService.stopLocationListening()
	}

	func setCentral(delegate: CentralManagerDelegate){
		centralManager?.delegate = delegate
	}

	func prepareBLEForSendingData(){
		centralManager?.cleanupForSendingData()
	}
}


extension ProximityService: LocationServiceDelegate {
	func didExitGeofence() {
		if let userID = Defaults.getUserID() {
			startIfPossible(userID: userID)
		}
		print("Exit")
	}


	func didUpdateLocation(){
		//centralManager.startScanning()

		//startBoradcasting(isPeripheralMode: self.isPeripheralMode)
	}

	func isBroadcasting() -> Bool {
		return peripheralManager?.isAdvertising() ?? false
	}
}

