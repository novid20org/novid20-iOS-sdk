/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller that illustrates how to start and stop ranging for a beacon region.
*/

import UIKit
import CoreData
import novid20Proximity
import CoreLocation

public class ProximityViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
	@IBOutlet weak var peripheralsTableView: UITableView!
	@IBOutlet weak var userIDLabel: UILabel!
	@IBOutlet weak var tokenField: UITextField!

	var peripherals = [Peripheral]()

	var userID: String

	private lazy var dataProvider: Database = {

		let provider = Database.shared
		provider.bleFetchedResultsControllerDelegate = self
		return provider
	}()

	public init(userID: String) {
		self.userID = userID
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override public func viewDidLoad() {
        super.viewDidLoad()

		let manager =  CLLocationManager()
		manager.requestAlwaysAuthorization()

		userIDLabel.text = "UserID: \(userID)"
		tokenField.delegate = self
		peripheralsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
    }

	override public func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		ProximityService.shared.setCentral(delegate: self)
		if let token = Defaults.getDevicetoken() {
			tokenField.text = token
		}
	}

	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		peripheralsTableView.reloadData()
	}
	public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		print("x")
	}

	public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		print("y")
	}
}


// MARK: - Table View Data Source
extension ProximityViewController: UITableViewDelegate, UITableViewDataSource {
	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return nil
	}

	public func numberOfSections(in tableView: UITableView) -> Int {
	   return 1
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataProvider.bleFetchedResultsController.fetchedObjects?.count ?? 0
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell: UITableViewCell = {
			  guard let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell") else {
				return UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "UITableViewCell")
			  }
			  return cell
		  }()


		guard let peripheral = dataProvider.bleFetchedResultsController.fetchedObjects?[indexPath.row] else { return cell }


		var durationString = "\(peripheral.duration)"
		if peripheral.duration == 0 {
			let end = peripheral.interactionEnded == 0 ? Date().timeIntervalSince1970 : peripheral.interactionEnded
			let duration = Int(end - peripheral.interactionStarted)
			durationString = "\(duration)"
		}

		var userId = "N.A"
		if let id = peripheral.userID {
			userId = id
		}

		cell.detailTextLabel?.numberOfLines = 0

		cell.textLabel?.text = "UserID: \(userId)"
		cell.detailTextLabel?.text = "Duration: \(durationString), Conntection open: \(!peripheral.isValid) \nCreated at: \(Date(timeIntervalSince1970: peripheral.interactionStarted)), Distance: \(peripheral.distance), background: \(peripheral.isBackground)"


		if peripheral.isValid {
			cell.textLabel?.textColor = .white
			cell.detailTextLabel?.textColor = .white
			cell.backgroundColor = .black

		}
		else {
			cell.textLabel?.textColor = .black
			cell.detailTextLabel?.textColor = .black
			cell.backgroundColor = .white
		}

	   return cell
	}
}

extension ProximityViewController: UITextFieldDelegate {
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
		return true
	}
}

//MARK:- CentralManagerDelegate
extension ProximityViewController: CentralManagerDelegate {
	public func didUpdateDiscovered(peripherals: [Peripheral]) {
		DispatchQueue.main.async {
			//self.peripherals = peripherals
			//self.peripheralsTableView.reloadData()
		}
	}
}

//MARK:- NSFetchedResultsControllerDelegate

//extension ProximityViewController: NSFetchedResultsControllerDelegate {



//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        peripheralsTableView.beginUpdates()
//    }

//	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//		<#code#>
//	}

//	public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//		peripheralsTableView.reloadData()
//	}

//}
