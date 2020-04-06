//
//  ProximityConfig.swift
//  novid20
//
//  Created by Mahmoud Eldesouky on 06.04.20.
//  Copyright © 2020 novid20. All rights reserved.
//

import Foundation
import CoreBluetooth

struct ProximityConfig {
	static let AppUUID = CBUUID(string: "8b9b6576-6db7-11ea-bc55-0242ac130003")
	static let ServiceUUID = CBUUID(string: "b16efb34-6c34-11ea-bc55-0242ac130003")
	static let CharacteristicUUID = CBUUID(string: "1d45dc00-6db7-11ea-bc55-0242ac130003")
	static let AppUserIDPrefix = "nov20-"
}
