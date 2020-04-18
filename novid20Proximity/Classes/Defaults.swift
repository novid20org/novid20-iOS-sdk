//
//  Defaults.swift
//  novid20
//
//  Created by Mahmoud Eldesouky on 23.03.20.
//  Copyright © 2020 novid20. All rights reserved.
//

import Foundation
import CoreLocation

public var AppLanguage = "ka"

extension ProximityService {
	public class Defaults {

		enum Keys: String {
			case defaultsPrefix = "novid20.sdk."
			case serviceStateOff
			case lastTriggerGeofenceNotification
			case getGeofenceRegion

			var value: String {
				return Keys.defaultsPrefix.rawValue + self.rawValue
			}
		}

		//MARK:- Service

		public static func getServiceState() -> Bool {
			let isOff = UserDefaults.standard.bool(forKey: Keys.serviceStateOff.value)
			return !isOff
		}

		public static func set(serviceState: Bool){
			UserDefaults.standard.set(!serviceState , forKey: Keys.serviceStateOff.value)
		}

		//MARK:- Location Geofence

		static func getLastTriggerGeofenceNotification() -> Date? {
			let date = UserDefaults.standard.object(forKey: Keys.lastTriggerGeofenceNotification.value) as? Date
			return date
		}

		static func set(lastTriggerGeofenceNotification: Date){
			UserDefaults.standard.set(lastTriggerGeofenceNotification , forKey: Keys.lastTriggerGeofenceNotification.value)
		}

		static func getGeofenceRegion() -> CLRegion? {
			if let unarchivedObject = UserDefaults.standard.object(forKey: Keys.getGeofenceRegion.value) as? Data {
				return NSKeyedUnarchiver.unarchiveObject(with: unarchivedObject as Data) as? CLRegion
			}
			return nil
		}

		static func set(getGeofenceRegion: CLRegion?){
			if let origin = getGeofenceRegion {
				let archive = NSKeyedArchiver.archivedData(withRootObject: origin as CLRegion) as NSData
				UserDefaults.standard.set(archive , forKey: Keys.getGeofenceRegion.value)
			}
			else {
				UserDefaults.standard.set(nil , forKey: Keys.getGeofenceRegion.value)
			}
		}
	}
}
