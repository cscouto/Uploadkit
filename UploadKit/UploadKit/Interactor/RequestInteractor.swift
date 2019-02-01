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


protocol UploadRequestDelegate {
    func successfulRequest(with response: [String: Any])
    func failedRequest(with error: String)
}

class RequestInteractor {
    
    static let shared = RequestInteractor()
    
    let internetReachability = NetWorkManager.reachabilityForInternetConnection()
    
    var delegate: UploadRequestDelegate?
    
    var pendingObjects: [RequestObject] {
        didSet { requestPendingObjects() }
    }
    
    var failedObjects: [RequestObject]
    
    init() {
        pendingObjects = [RequestObject]()
        failedObjects = [RequestObject]()
        
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
            self.pendingObjects.append(request)
        }
    }
    
    private func loadRequests() {
        DataStore.performBackgroundTask({ (context) in
            let fetchRequest = NSFetchRequest<RequestObjectDB>()
            do {
               let objects = try context.fetch(fetchRequest)
                for requestDB in objects {
                    let request = RequestObject(requestDB: requestDB)
                    request.status == .pending ? self.pendingObjects.append(request) : self.failedObjects.append(request)
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        })
    }
    
    private func remove(request: RequestObject) {
        DataStore.performBackgroundTask({ (context) in
            let fetchRequest = NSFetchRequest<RequestObjectDB>()
            fetchRequest.predicate = NSPredicate(format: "id == %@", request.id)
            fetchRequest.fetchLimit = 1
            do {
                if let fetchedRequest = try context.fetch(fetchRequest).first {
                    context.delete(fetchedRequest)
                }
            }catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        })
    }
    
    private func update(request: RequestObject) {
        DataStore.performBackgroundTask({ (context) in
            let fetchRequest = NSFetchRequest<RequestObjectDB>()
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
        failedObjects.append(request)
    }
    
    private func requestPendingObjects() {
        while pendingObjects.count > 0 {
            make(request: pendingObjects.removeFirst())
        }
    }
    
    private func requestFailedObjects() {
        while failedObjects.count > 0 {
            make(request: failedObjects.removeFirst())
        }
    }
    
    private func make(request: RequestObject) {
        BaseAPI.request(object: request) { [weak self] result in
            switch result {
            case .success(let json):
                self?.delegate?.successfulRequest(with: json)
                self?.remove(request: request)
            case .failure(let error):
                var requestReturn = request
                requestReturn.status = .failed
                self?.addFailed(request: requestReturn)
                self?.update(request: requestReturn)
                self?.delegate?.failedRequest(with: error)
            }
        }
    }
    
    func updateInterfaceWithReachability(reachability: NetWorkManager){
        let netStatus : NetworkStatus = reachability.currentReachabilityStatus()
        switch (netStatus) {
        case .NotReachable:
            break
        default:
            requestFailedObjects()
        }
    }
    
    @objc func reachabilityChanged(sender : NSNotification!){
        let curReach: NetWorkManager = sender.object as! NetWorkManager
        self.updateInterfaceWithReachability(reachability: curReach)
    }
    
    private func createObjectInDatabase(request: RequestObject, context: NSManagedObjectContext) {
        let requestDB = RequestObjectDB(context: context)
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
