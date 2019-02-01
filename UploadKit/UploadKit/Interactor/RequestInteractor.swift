//
//  RequestInteractor.swift
//  UploadKit
//
//  Created by COUTO, TIAGO on 1/25/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//

import Foundation
import Alamofire


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
    }
    
    func addRequest(name: String, url: String, method: HTTPMethod, parameters: Any?, headers: [String: String]?) {
        let request = RequestObject(requestName: name,
                                    url: url,
                                    method: method,
                                    parameters: parameters,
                                    headers: headers,
                                    status: .pending)
        add(request: request)
    }
    
    private func add(request: RequestObject) {
        pendingObjects.append(request)
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
            case .failure(let error):
                var requestReturn = request
                requestReturn.status = .failed
                self?.addFailed(request: requestReturn)
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
        let curReach : NetWorkManager = sender.object as! NetWorkManager
        self.updateInterfaceWithReachability(reachability: curReach)
    }
}
