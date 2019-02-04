//
//  RequestObject.swift
//  UploadKit
//
//  Created by COUTO, TIAGO on 1/25/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//
import Alamofire
import CoreData

public enum StatusRequest: String {
    case pending
    case failed
}

public struct RequestObject {
    public var id: String = UUID().uuidString
    public var name: String
    public var url: String
    public var method: HTTPMethod
    public var parameters: Any? = nil
    public var headers: [String: String]? = nil
    public var createdOn: Date? = Date()
    public var status: StatusRequest = .pending
    
    init(name: String, url: String, method: HTTPMethod, parameters: Any?, headers: [String: String]?) {
        self.name = name
        self.url = url
        self.method = method
        self.parameters = parameters
        self.headers = headers
    }
    
    init(requestDB: RequestObjectDB) {
        id = requestDB.id!
        name = requestDB.name!
        url = requestDB.url!
        method = HTTPMethod(rawValue: requestDB.method!)!
        if let data = requestDB.parameters {
            parameters = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)!
        }
        if let headersData = requestDB.headers {
            headers = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(headersData) as! [String: String]
        }
        createdOn = requestDB.createdOn
        status = StatusRequest(rawValue: requestDB.status!)!
    }
}
