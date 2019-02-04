//
//  UploadKit.swift
//  UploadKit
//
//  Created by COUTO, TIAGO [AG-Contractor/1000] on 2/4/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//
import Alamofire

public class UploadKit {
    
    public static var delegate: UploadRequestDelegate? {
        get { return RequestInteractor.shared.delegate }
        set { RequestInteractor.shared.delegate = newValue }
    }
    
    public static var pendingObjects: [RequestObject] {
        return RequestInteractor.shared.requests.filter{ $0.status == .pending }
    }
    
    public static var failedObjects: [RequestObject] {
        return RequestInteractor.shared.requests.filter{ $0.status == .failed }
    }
    
    public static func addRequest(name: String, url: String, method: HTTPMethod, parameters: Any?, headers: [String: String]?) {
        RequestInteractor.shared.addRequest(name: name, url: url, method: method, parameters: parameters, headers: headers)
    }
}
