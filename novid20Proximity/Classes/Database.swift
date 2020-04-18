//
//  Database.swift
//  novid20
//
//  Created by Mahmoud Eldesouky on 24.03.20.
//  Copyright © 2020 novid20. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

public class Database {

	public static var shared = Database()
    public weak var bleFetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
    public weak var locationFetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?

	/* 	maximum interval allowed for the data to be presisted.
		after this period, data is deleted */
	let collectedDataTimeLimit = -300 //5days
	private var managedObjectContext: NSManagedObjectContext?


	private init() {
	  managedObjectContext = persistentContainer?.viewContext

	  guard managedObjectContext != nil else {
		preconditionFailure("Can't get right managed object context.")
	  }
	}


	//MARK:- PersistentContainer
	class TriggerPersistentContainer: NSPersistentContainer {
	   override open class func defaultDirectoryURL() -> URL {
		 let urlForApplicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

		let url = urlForApplicationSupportDirectory.appendingPathComponent("Novid20DB")

		 if FileManager.default.fileExists(atPath: url.path) == false {
		   do {
			 try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
		   } catch {
			 print("Can not create storage folder!")
		   }
		 }

		 return url
	   }
	 }


	private lazy var persistentContainer: NSPersistentContainer? = {
		let modelURL = Bundle(for: Database.self).url(forResource: "Proximity", withExtension: "momd")


	  var container: TriggerPersistentContainer

	  guard let model = modelURL.flatMap(NSManagedObjectModel.init) else {
		print("Fail to load the trigger model!")
		return nil
	  }

	  container = TriggerPersistentContainer(name: "Proximity", managedObjectModel: model)
	  container.loadPersistentStores(completionHandler: { (storeDescription, error) in
		if let error = error as NSError? {
		  print("Unresolved error \(error), \(error.userInfo)")
		}
	  })

	  return container
	}()
    

//    private func combineDurationOfConnections(contacts: [InfectedUser]) -> [InfectedUser] {
//
//        var reducedConnection: [InfectedUser] = []
//
//        let connectionsDict = Dictionary(grouping: contacts, by: { (element: InfectedUser) in
//            return element.userId
//        })
//
//        connectionsDict.forEach { (connectionGroup) in
//
//            let (_, value) = connectionGroup
//            var duration: Int64 = 0
//            if let combinedInfected = value.first {
//                value.forEach { (infected) in
//                    duration += infected.duration!
//                }
//                combinedInfected.duration = duration
//
//                reducedConnection.append(combinedInfected)
//            }
//        }
//x
//        return reducedConnection
//    }

	public func cleanUnClosedDetections(now: Bool = false) {

		guard let context = managedObjectContext else { return}


		let fetchrequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DetectedBLE")
		fetchrequest.predicate = NSPredicate(format: "isValid = false")
		do {

			if let unClosedDetections = (try? context.fetch(fetchrequest)) {
				for detection in unClosedDetections {
					guard let detection = detection as? DetectedBLE else {return}
					if detection.interactionEnded == 0 { //incase app died before we close the detection object, we will just say the duration was "BleExpiryThreshold" and close this detection entry

						if now {
							let dateNow = Date().timeIntervalSince1970
							detection.setValue(dateNow , forKey: "interactionEnded")
							detection.setValue(dateNow - detection.interactionStarted, forKey: "duration")
						}
						else {
							detection.setValue(detection.interactionStarted + BleExpiryThreshold, forKey: "interactionEnded")
							detection.setValue(BleExpiryThreshold, forKey: "duration")
						}
					}
					else {
						detection.setValue(detection.interactionEnded - detection.interactionStarted, forKey: "duration")
					}
					detection.setValue(true, forKey: "isValid")
					try context.save()
				}
			}
		} catch {
			print("Failed saving")
		}

	}
    
     //MARK:- ADD
	internal func store(peripheral:Peripheral) {
		guard let context = managedObjectContext else { return}

		let entity = NSEntityDescription.entity(forEntityName: "DetectedBLE", in: context)
		let newUser = NSManagedObject(entity: entity!, insertInto: context)

        newUser.setValue(peripheral.userID, forKey: "userID")
        newUser.setValue(peripheral.createdAt, forKey: "timestamp")
		newUser.setValue(peripheral.createdAt.timeIntervalSince1970, forKey: "interactionStarted")
        newUser.setValue(peripheral.distance, forKey: "distance")
        newUser.setValue(peripheral.rssi, forKey: "rssi")

		var background = true
		if peripheral.appState == .foreground{
			background = false
		}
		newUser.setValue(background, forKey: "isBackground")

		do {
		   try context.save()
			print("Added \(peripheral.userID) to DB")
		  } catch {
		   print("Failed saving")
		}
	}


    internal func storeLocation(location: CLLocation) {
   		guard let context = managedObjectContext else { return}

        
        let entity = NSEntityDescription.entity(forEntityName: "UserLocation", in: context)
        let newLocation = NSManagedObject(entity: entity!, insertInto: context)
        
        newLocation.setValue(location.coordinate.latitude, forKey: "latitude")
        newLocation.setValue(location.coordinate.longitude, forKey: "longitude")
        newLocation.setValue(location.timestamp, forKey: "timestamp")
        
        do {
           try context.save()
          } catch {
           print("Failed saving location")
        }
    }

	//MARK:- UPDATE
	internal func update(peripheral:Peripheral) {

		guard let context = managedObjectContext else { return}


		let fetchrequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DetectedBLE")
		fetchrequest.predicate = NSPredicate(format: "userID = %@ AND isValid = false AND interactionStarted = %lf", peripheral.userID, peripheral.createdAt.timeIntervalSince1970)
		do {
			let result = try? context.fetch(fetchrequest)
			guard let objectUpdate = result?.first as? DetectedBLE else {return}
			objectUpdate.setValue(peripheral.date.timeIntervalSince1970, forKey: "interactionEnded")
			objectUpdate.setValue(peripheral.date.timeIntervalSince(peripheral.createdAt), forKey: "duration")
			objectUpdate.setValue(true, forKey: "isValid")

			if peripheral.distance < objectUpdate.distance {
				objectUpdate.setValue(peripheral.distance, forKey: "distance")
			}

			if peripheral.rssi < objectUpdate.rssi {
				objectUpdate.setValue(peripheral.rssi, forKey: "rssi")
			}

			try context.save()
			print("Disconnected from \(peripheral.userID), with duration: \(peripheral.date.timeIntervalSince(peripheral.createdAt)) sec")
		} catch {
			print("Failed saving")
		}

	}

	//MARK:- GET

	public func fetchBLEConnectoins() -> [DetectedContact]? {

		   guard let context = managedObjectContext else {return []}

		   // Create a fetch request for the Quake entity sorted by time.
		   let fetchRequest = NSFetchRequest<DetectedBLE>(entityName: "DetectedBLE")
		   // fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

		   do {
			   let result = try context.fetch(fetchRequest)
			   let connections = result.map {
				   DetectedContact(bleEntity: $0)
			   }
			   return connections
			   // return combineDurationOfConnections(contacts: connections)
		   } catch {
			   print("Failed loading ble connections")
			   return nil
		   }

	   }


    public func fetchLocations() -> [CLLocation]? {

		guard let context = managedObjectContext else { return []}


        // Create a fetch request for the Quake entity sorted by time.
        let fetchRequest = NSFetchRequest<UserLocation>(entityName: "UserLocation")
        // fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let result = try context.fetch(fetchRequest)
            let locations = result.map {
                CLLocation(coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: $0.timestamp!)
            }
            return locations
        } catch {
            print("Failed loading locations")
            return nil
        }
        
    }

	//MARK:- DELETE
    public func deleteOldBLEConnections() {

		guard let context = managedObjectContext else { return}


        let fetchRequest = NSFetchRequest<DetectedBLE>(entityName: "DetectedBLE")

        let calendar = Calendar.current
        let date = calendar.date(byAdding: .hour, value: collectedDataTimeLimit, to: Date())!

        fetchRequest.predicate = NSPredicate(format: "timestamp < %@", date as NSDate)

        do {
            let result = try context.fetch(fetchRequest)
            result.forEach { (connection) in
                context.delete(connection)
            }
        } catch {
            print("Failed deleting old connections")
        }

    }

	public func deleteOldLocations() {

		guard let context = managedObjectContext else { return}


        let fetchRequest = NSFetchRequest<UserLocation>(entityName: "UserLocation")
        
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .hour, value: collectedDataTimeLimit, to: Date())!
        
        fetchRequest.predicate = NSPredicate(format: "timestamp < %@", date as NSDate)
        
        do {
            let result = try context.fetch(fetchRequest)
            result.forEach { (userLocation) in
                context.delete(userLocation)
            }
        } catch {
            print("Failed deleting locations")
        }
        
    }

	public func deleteAllData() {

   		guard let context = managedObjectContext else { return}


        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserLocation")
		let locationsDeleteRequest = NSBatchDeleteRequest( fetchRequest: locationsFetchRequest)

        let bleFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DetectedBLE")
		let bleDeleteRequest = NSBatchDeleteRequest(fetchRequest: bleFetchRequest)


        do {
			try context.execute(locationsDeleteRequest)
			try context.execute(bleDeleteRequest)
        } catch {
            print("Failed deleting locations")
        }
    }


	//MARK:- FetchedResultsController
    public lazy var locationFetchedResultsController: NSFetchedResultsController<UserLocation> = {

  		guard let context = managedObjectContext else { {preconditionFailure("failed")}()}


        // Create a fetch request for the Quake entity sorted by time.
        let fetchRequest = NSFetchRequest<UserLocation>(entityName: "UserLocation")
        // fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        // Create a fetched results controller and set its fetch request, context, and delegate.
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: context,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        
        controller.delegate = locationFetchedResultsControllerDelegate

        // Perform the fetch.
        do {
            try controller.performFetch()
        } catch {
            fatalError("Unresolved error \(error)")
        }

        return controller
    }()

	public lazy var bleFetchedResultsController: NSFetchedResultsController<DetectedBLE> = {

			guard let context = managedObjectContext else { {preconditionFailure("failed")}()}


			let fetchRequest = NSFetchRequest<DetectedBLE>(entityName: "DetectedBLE")
			fetchRequest.sortDescriptors = [NSSortDescriptor(key: "interactionStarted", ascending: false), NSSortDescriptor(key: "isValid", ascending: false)]


			let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
														managedObjectContext: context,
														sectionNameKeyPath: nil, cacheName: nil)
			controller.delegate = bleFetchedResultsControllerDelegate

			// Perform the fetch.
			do {
				try controller.performFetch()
			} catch {
				fatalError("Unresolved error \(error)")
			}

			return controller
		}()
}
