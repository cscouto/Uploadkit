//
//  RequestInteractor.swift
//  UploadKit
//
//  Created by COUTO, TIAGO on 1/25/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//

import Foundation

class RequestInteractor {
    
    var pendingObjects: [RequestObject] {
        didSet {
            request()
        }
    }
    
    var failedObjects: [RequestObject]
    
    init() {
        pendingObjects = [RequestObject]()
        failedObjects = [RequestObject]()
    }
    
    func add(request: RequestObject) {
        pendingObjects.append(request)
    }
    
    private func request() {
        for request in pendingObjects {
            
        }
    }
}
