//
//  SignificantLocationManager.swift
//  novid20
//
//  Created by Mahmoud Eldesouky on 03.04.20.
//  Copyright © 2020 novid20. All rights reserved.
//

import Foundation
import CoreLocation

public protocol SignificantLocationSubscriber: class {
	func didUpdate(significantLocation: CLLocation)
}

public class SignificantLocationManager: NSObject, CLLocationManagerDelegate {
	public var anotherLocationManager: CLLocationManager?

	weak var delegate: SignificantLocationSubscriber?

	init(delegate: SignificantLocationSubscriber) {
		super.init()
		self.delegate = delegate
	}

	public func startSignificantLocation() {
		print("startSignificantLocation")

		if let locationManager = anotherLocationManager {
			locationManager.stopMonitoringSignificantLocationChanges()
			locationManager.startMonitoringSignificantLocationChanges()
		} else {
			let locationManager = CLLocationManager()
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.activityType = CLActivityType.fitness
			locationManager.allowsBackgroundLocationUpdates = true
			locationManager.delegate = self
			locationManager.startMonitoringSignificantLocationChanges()
			anotherLocationManager = locationManager
		}
	}

	public func restartMonitoringLocation() {
		if anotherLocationManager == nil {
			startSignificantLocation()
		} else {
			anotherLocationManager?.stopMonitoringSignificantLocationChanges()
			anotherLocationManager?.startMonitoringSignificantLocationChanges()
		}
	}

	public func stopSignificantLocation() {
		print("stopSignificantLocation")

		if anotherLocationManager != nil {
			anotherLocationManager?.stopMonitoringSignificantLocationChanges()
			anotherLocationManager = nil
		}
	}

	/* CLLocationManagerDelegate */

	public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let location = locations.last {
			delegate?.didUpdate(significantLocation: location)
		}
	}
}
