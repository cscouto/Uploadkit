//
//  ViewController.swift
//  UploadKitExample
//
//  Created by COUTO, TIAGO [AG-Contractor/1000] on 2/1/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//

import UIKit
import UploadKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var selectedIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        RequestInteractor.shared.delegate = self
    }

    @IBAction func filter(_ sender: UISegmentedControl) {
        selectedIndex = sender.selectedSegmentIndex
        tableView.reloadData()
    }
    
    @IBAction func request(_ sender: UIBarButtonItem) {
        RequestInteractor.shared.addRequest(name: "Weather", url: "https://opentdb.com/api.php?amount=10", method: .get, parameters: nil, headers: nil)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedIndex == 0 ? RequestInteractor.shared.pendingObjects.count : RequestInteractor.shared.failedObjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = selectedIndex == 0 ? RequestInteractor.shared.pendingObjects[indexPath.row] : RequestInteractor.shared.failedObjects[indexPath.row]
        cell.textLabel?.text = item.url
        return cell
    }
}

extension ViewController: UploadRequestDelegate {
    func successfulRequest(with response: [String: Any]) {
        tableView.reloadData()
        print(response)
    }
    
    func failedRequest(with error: String) {
        tableView.reloadData()
        print(error)
    }
}

