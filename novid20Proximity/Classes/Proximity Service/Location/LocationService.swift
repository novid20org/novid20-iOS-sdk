//
//  LocationService.swift
//  Beacon Sample
//
//  Created by Mahmoud Eldesouky on 20.03.20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServiceDelegate: class {
	func didUpdateLocation()
	func didExitGeofence()
}

class LocationService: NSObject {

	enum RegionIdentifiers: String {
		case defaultsPrefix = "location_geofence_"
		case userMovement

		var value: String {
			return RegionIdentifiers.defaultsPrefix.rawValue + self.rawValue
		}
	}

	private var geofenceRegion: CLRegion? {
		didSet {
			Defaults.set(getGeofenceRegion: geofenceRegion)
		}
	}

	private var geofenceLastTrigger: Date? {
		didSet {
			if let trigger = geofenceLastTrigger {
				Defaults.set(lastTriggerGeofenceNotification: trigger)
			}
		}
	}


	private var continousLocationManager: CLLocationManager?
	private var significantLocationManager: SignificantLocationManager!

	weak var delegate: LocationServiceDelegate?

    private let GEOFENCE_NOTIFICATION_INTERVAL_LIMIT: Double = 7200 //sec = 1h
    private let GEOFENCE_RADIUS: Double = 300.0 // meters
    private let DISTANCE_FOR_LOCATION_UPDATE: Double = 20.0 // meters
    private var lastLocation: CLLocation?
    private let TIMEOUT_FOR_LOCATION_UPDATE: Double = 30.0 // seconds

	let database = Database.shared

	init(delegate: LocationServiceDelegate) {
		super.init()
		self.delegate = delegate
		significantLocationManager = SignificantLocationManager(delegate: self)
		geofenceRegion = Defaults.getGeofenceRegion()
		geofenceLastTrigger = Defaults.getLastTriggerGeofenceNotification()
	}

	func startLocationListening(){
		significantLocationManager.startSignificantLocation()
		startContinousLocation()
	}

	func stopLocationListening(){
		significantLocationManager.stopSignificantLocation()
		stopContinousLocation()
		resetMonitoredRegions(identifier: .userMovement)
	}

	private func setupLocationManager() {
		if continousLocationManager == nil {
			continousLocationManager = CLLocationManager()
			continousLocationManager?.distanceFilter = DISTANCE_FOR_LOCATION_UPDATE
			continousLocationManager?.desiredAccuracy = kCLLocationAccuracyHundredMeters
			continousLocationManager?.allowsBackgroundLocationUpdates = true
			continousLocationManager?.pausesLocationUpdatesAutomatically = true
			continousLocationManager?.activityType = CLActivityType.fitness
			continousLocationManager?.delegate = self
		}

		//make sure the our stored geofenceRegion is actually being monitored
		if let currentRegion = geofenceRegion {
			if let monitoredRegions = continousLocationManager?.monitoredRegions {
				if !monitoredRegions.contains(currentRegion){
					resetMonitoredRegions(identifier: .userMovement)
				}
			}
		}
	}

	private func startContinousLocation(){
		print("startContinousLocation")
		setupLocationManager()
		continousLocationManager?.startUpdatingLocation()
	}

	private func stopContinousLocation(){
		print("stopContinousLocation")
		continousLocationManager?.stopUpdatingLocation()
		continousLocationManager = nil
	}

    // MARK: Store location

    private func saveLocation(location: CLLocation) {
        database.storeLocation(location: location)
    }

	private func geofenceUserLocation(identifier: RegionIdentifiers) {
		// Make sure the app is authorized.
		if CLLocationManager.authorizationStatus() == .authorizedAlways {
			// Make sure region monitoring is supported.
			if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
				// Make sure location present
				if let coordinate = self.lastLocation?.coordinate {
					resetMonitoredRegions(identifier: identifier)

					// Register the region.
					let radius = GEOFENCE_RADIUS // meters
					let region = CLCircularRegion(center: coordinate,
												  radius: radius, identifier: identifier.value)
					region.notifyOnEntry = false
					region.notifyOnExit = true

					continousLocationManager?.startMonitoring(for: region)
					geofenceRegion = region
				}
			}
		}
	}

	private func resetMonitoredRegions(identifier: RegionIdentifiers) {

		if let regions = continousLocationManager?.monitoredRegions {
			for region in regions where region.identifier == identifier.value {
				continousLocationManager?.stopMonitoring(for: region)
			}
		}
		geofenceRegion = nil
	}

 }

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
	public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if let location = locations.last {

            if let lastLoc = lastLocation {

                // distance is filtered anyway by .distanceFilter - just for verification
                let distance = location.distance(from: lastLoc)
                let timePassed = location.timestamp.timeIntervalSince(lastLoc.timestamp)
                if (timePassed > TIMEOUT_FOR_LOCATION_UPDATE) {
                    debugPrint("Distance (m): ", distance)
                    lastLocation = location
                    saveLocation(location: location)
                }
            } else {
				debugPrint("first location: ", location)
                lastLocation = location
				saveLocation(location: location)
            }
			if geofenceRegion == nil {
				geofenceUserLocation(identifier: .userMovement)
			}
        }
		delegate?.didUpdateLocation()
	}

	public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
		print("locationManagerDidPauseLocationUpdates")
		geofenceUserLocation(identifier: .userMovement)
	}

	public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
		print("continouslocationManager didStartMonitoringFor")
	}

	public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError _: Error) {
		print("continouslocationManager monitoringDidFailFor")

		guard let region = region else {
			return
		}
		if let identifier = RegionIdentifiers(rawValue: region.identifier) {
			resetMonitoredRegions(identifier: identifier)
		}
	}

	public func locationManager(_: CLLocationManager, didExitRegion region: CLRegion) {
		print("continouslocationManager didExitRegion")

		let now = Date()

		if let lastTrigger = geofenceLastTrigger {
			if now.timeIntervalSince(lastTrigger) > GEOFENCE_NOTIFICATION_INTERVAL_LIMIT {
				delegate?.didExitGeofence()
				geofenceLastTrigger = now
			}
		}
		else {
			delegate?.didExitGeofence()
			geofenceLastTrigger = now
		}

		geofenceUserLocation(identifier: .userMovement)
	}

	public func locationManager(_: CLLocationManager, didEnterRegion region: CLRegion) {
		print("continouslocationManager didEnterRegion")
	}
}

// MARK: - SignificantLocationSubscriber

extension LocationService: SignificantLocationSubscriber {
	public func didUpdate(significantLocation _: CLLocation) {
		self.startContinousLocation()
	}
}


