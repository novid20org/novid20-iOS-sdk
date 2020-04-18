//
//  ProximityConfig.swift
//  novid20
//
//  Created by Mahmoud Eldesouky on 06.04.20.
//  Copyright © 2020 novid20. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct ProximitySDKConfiguration {
	public init(appUUID: CBUUID, serviceUUID: CBUUID, characteristicUUID: CBUUID, appUserIDPrefix: String){
		
		self.appUUID = appUUID
		self.serviceUUID = serviceUUID
		self.characteristicUUID = characteristicUUID
		self.appUserIDPrefix = appUserIDPrefix
	}
	public var appUUID: CBUUID
	public var serviceUUID: CBUUID
	public var characteristicUUID: CBUUID
	public var appUserIDPrefix: String
}

internal struct ProximityConfig {
	public static var AppUUID = CBUUID(string: "de65c482-7a45-11ea-bc55-0242ac130003")
	public static var ServiceUUID = CBUUID(string: "e9143e04-7a45-11ea-bc55-0242ac130003")
	public static var CharacteristicUUID = CBUUID(string: "f0626dc0-7a45-11ea-bc55-0242ac130003")
	public static var AppUserIDPrefix = "nvSDK-"
	public static var AppUserIDLLengthCount = 23
}
