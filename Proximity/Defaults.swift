//
//  Defaults.swift
//  novid20
//
//  Created by Mahmoud Eldesouky on 23.03.20.
//  Copyright © 2020 novid20. All rights reserved.
//

import Foundation
import CoreLocation

class Defaults {

	enum Keys: String {
		case defaultsPrefix = "novid20.mobile."
		case userID
		case deviceToken
        case firebaseUID
        case firebaseToken
		case serviceStateOff
		case lastTriggerGeofenceNotification
		case getGeofenceRegion

		var value: String {
			return Keys.defaultsPrefix.rawValue + self.rawValue
		}
	}

	//MARK:- Auth
	static func getUserID() -> String? {
		if let id = UserDefaults.standard.string(forKey: Keys.userID.value) {
			return id
		}
		return nil
	}

	static func set(userID: String){
		UserDefaults.standard.set(userID, forKey: Keys.userID.value)
	}

    static func getDevicetoken() -> String? {
        if let token = UserDefaults.standard.string(forKey: Keys.deviceToken.value) {
            return token
        }
        return nil
    }

    static func set(deviceToken: String){
        UserDefaults.standard.set(deviceToken, forKey: Keys.deviceToken.value)
    }

    static func getFirebaseUID() -> String? {
        if let token = UserDefaults.standard.string(forKey: Keys.firebaseUID.value) {
            return token
        }
        return nil
    }

	static func getFirebaseToken() -> String? {
		 if let token = UserDefaults.standard.string(forKey: Keys.firebaseToken.value) {
			 return token
		 }
		 return nil
	 }

    static func set(firebaseUID: String){
        UserDefaults.standard.set(firebaseUID, forKey: Keys.firebaseUID.value)
    }

	static func set(firebaseToken: String){
		 UserDefaults.standard.set(firebaseToken, forKey: Keys.firebaseToken.value)
	 }


	//MARK:- Service

    static func getServiceState() -> Bool {
		let isOff = UserDefaults.standard.bool(forKey: Keys.serviceStateOff.value)
        return !isOff
    }

    static func set(serviceState: Bool){
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
			return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(unarchivedObject as Data) as? CLRegion
		}
		return nil
	}

	static func set(getGeofenceRegion: CLRegion?){
		if let origin = getGeofenceRegion {
			let archive =  try? NSKeyedArchiver.archivedData(withRootObject: origin as CLRegion, requiringSecureCoding: true) as NSData
			UserDefaults.standard.set(archive , forKey: Keys.getGeofenceRegion.value)
		}
		else {
			UserDefaults.standard.set(nil , forKey: Keys.getGeofenceRegion.value)
		}
	}
}
