/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller that illustrates how to start and stop ranging for a beacon region.
*/

import UIKit
import CoreData

class ProximityViewController: UIViewController {
    
	@IBOutlet weak var peripheralsTableView: UITableView!
	@IBOutlet weak var userIDLabel: UILabel!
	@IBOutlet weak var tokenField: UITextField!

	var peripherals = [Peripheral]()

	var userID: String

	private lazy var dataProvider: Database = {

		let provider = Database.shared
		provider.bleFetchedResultsControllerDelegate = self
        provider.locationFetchedResultsControllerDelegate = self
		return provider
	}()

	init(userID: String) {
		self.userID = userID
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		userIDLabel.text = "UserID: \(userID)"
		tokenField.delegate = self
		peripheralsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		ProximityService.shared.setCentral(delegate: self)

        //        ApiConnection.sharedConnection.uploadUserData { (success) in
        //            debugPrint("Uploaded: ", success)
        //        }
		if let token = Defaults.getDevicetoken() {
			tokenField.text = token
		}
	}
}


// MARK: - Table View Data Source
extension ProximityViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return nil
	}

	func numberOfSections(in tableView: UITableView) -> Int {
	   return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
	   return dataProvider.bleFetchedResultsController.fetchedObjects?.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		let cell: UITableViewCell = {
			  guard let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell") else {
				return UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "UITableViewCell")
			  }
			  return cell
		  }()


//	   let peripheral = peripherals[indexPath.row]

		guard let peripheral = dataProvider.bleFetchedResultsController.fetchedObjects?[indexPath.row] else { return cell }

//		let end = peripheral.interactionEnded == 0 ? Date().timeIntervalSince1970 : peripheral.interactionEnded

//		let duration = Int(end - peripheral.interactionStarted)
//		var userID = "N.A"
//		if let id = peripheral.userID {
//			userID = id
//		}
//
//		var durationString = "\(duration)"
//		if duration < 0 {
//			durationString = "-"
//		}


		cell.textLabel?.text = "UserID: \(userID)"
		cell.detailTextLabel?.text = "Duration: \(peripheral.duration), Conntection open: \(!peripheral.isValid) "

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
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
		return true
	}
}

//MARK:- CentralManagerDelegate
extension ProximityViewController: CentralManagerDelegate {
	func didUpdateDiscovered(peripherals: [Peripheral]) {
		DispatchQueue.main.async {
			//self.peripherals = peripherals
			self.peripheralsTableView.reloadData()
		}
	}
}

//MARK:- NSFetchedResultsControllerDelegate

extension ProximityViewController: NSFetchedResultsControllerDelegate {

//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        peripheralsTableView.beginUpdates()
//    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        peripheralsTableView.endUpdates()
//
//        updateView()
//    }


	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		peripheralsTableView.reloadData()
	}

}
