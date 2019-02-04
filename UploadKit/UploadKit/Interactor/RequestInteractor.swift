//
//  RequestInteractor.swift
//  UploadKit
//
//  Created by COUTO, TIAGO on 1/25/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//

import Foundation
import Alamofire
import CoreData

public protocol UploadRequestDelegate {
    func successfulRequest(with response: [String: Any])
    func failedRequest(with error: String)
}

class RequestInteractor {
    
    public static let shared = RequestInteractor()
    
    let internetReachability = NetWorkManager.reachabilityForInternetConnection()
    
    var delegate: UploadRequestDelegate?
    
    private var lastStatus: NetworkStatus = .NotReachable
    
    var requests: [RequestObject] {
        didSet {
            if lastStatus != .NotReachable {
                requestPendingObjects()
            } else {
                for i in 0..<requests.count {
                    requests[i].status = .failed
                }
                DispatchQueue.main.async {
                    self.delegate?.failedRequest(with: ErrorMessages.no_internet)
                }
            }
        }
    }
    
    init() {
        requests = [RequestObject]()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: NSNotification.Name.reachabilityChanged, object: nil)
        internetReachability?.startNotifier()
        updateInterfaceWithReachability(reachability: self.internetReachability!)
        
        loadRequests()
    }
    
    func addRequest(name: String, url: String, method: HTTPMethod, parameters: Any?, headers: [String: String]?) {
        let request = RequestObject(name: name,
                                    url: url,
                                    method: method,
                                    parameters: parameters,
                                    headers: headers)
        add(request: request)
    }
    
    private func add(request: RequestObject) {
        DataStore.performBackgroundTask { (context) in
            self.createObjectInDatabase(request: request, context: context)
            try? context.save()
            self.requests.append(request)
        }
    }
    
    private func loadRequests() {
        DataStore.performBackgroundTask({ (context) in
            let fetchRequest = NSFetchRequest<RequestObjectDB>(entityName: "RequestObjectDB")
            do {
               let objects = try context.fetch(fetchRequest)
                for requestDB in objects {
                    let request = RequestObject(requestDB: requestDB)
                    self.requests.append(request)
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        })
    }
    
    private func remove(request: RequestObject) {
        DataStore.performBackgroundTask({ (context) in
            let fetchRequest = NSFetchRequest<RequestObjectDB>(entityName: "RequestObjectDB")
            fetchRequest.predicate = NSPredicate(format: "id == %@", request.id)
            fetchRequest.fetchLimit = 1
            do {
                if let fetchedRequest = try context.fetch(fetchRequest).first {
                    context.delete(fetchedRequest)
                    try context.save()
                }
            }catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        })
    }
    
    private func update(request: RequestObject) {
        DataStore.performBackgroundTask({ (context) in
            let fetchRequest = NSFetchRequest<RequestObjectDB>(entityName: "RequestObjectDB")
            fetchRequest.predicate = NSPredicate(format: "id == %@", request.id)
            fetchRequest.fetchLimit = 1
            do {
                if let fetchedRequest = try context.fetch(fetchRequest).first {
                    fetchedRequest.status = request.status.rawValue
                    try? context.save()
                }
            }catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        })
    }
    
    private func addFailed(request: RequestObject) {
        var req = request
        req.status = .failed
        requests.append(request)
    }
    
    private func requestPendingObjects() {
        while requests.count > 0 {
            make(request: requests.removeFirst())
        }
    }
    
    private func make(request: RequestObject) {
        BaseAPI.request(object: request) { [weak self] result in
            switch result {
            case .success(let json):
                DispatchQueue.main.async {
                    self?.delegate?.successfulRequest(with: json)
                }
                self?.remove(request: request)
            case .failure(let error):
                var requestReturn = request
                requestReturn.status = .failed
                self?.addFailed(request: requestReturn)
                self?.update(request: requestReturn)
                DispatchQueue.main.async {
                    self?.delegate?.failedRequest(with: error)
                }
            }
        }
    }
    
    func updateInterfaceWithReachability(reachability: NetWorkManager){
        let netStatus : NetworkStatus = reachability.currentReachabilityStatus()
        lastStatus = netStatus
        switch (netStatus) {
        case .NotReachable:
            break
        default:
            requestPendingObjects()
        }
    }
    
    @objc func reachabilityChanged(sender : NSNotification!){
        let curReach: NetWorkManager = sender.object as! NetWorkManager
        self.updateInterfaceWithReachability(reachability: curReach)
    }
    
    private func createObjectInDatabase(request: RequestObject, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "RequestObjectDB", in: context)
        let requestDB = RequestObjectDB(entity: entity!, insertInto: context)
        requestDB.createdOn = request.createdOn
        requestDB.method = request.method.rawValue
        requestDB.id = request.id
        requestDB.name = request.name
        requestDB.status = request.status.rawValue
        requestDB.url = request.url
        if let headers = request.headers {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: headers, requiringSecureCoding: false)
            requestDB.headers = data
        }
        if let parameters = request.parameters {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: parameters, requiringSecureCoding: false)
            requestDB.parameters = data
        }
    }
}
