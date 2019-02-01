//
//  RequestObject.swift
//  UploadKit
//
//  Created by COUTO, TIAGO on 1/25/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//
import Alamofire
import CoreData

enum StatusRequest: String {
    case pending
    case failed
}

struct RequestObject {
    var id: String = UUID().uuidString
    var name: String
    var url: String
    var method: HTTPMethod
    var parameters: Any? = nil
    var headers: [String: String]? = nil
    var createdOn: Date? = Date()
    var status: StatusRequest = .pending
    
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
