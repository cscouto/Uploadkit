//
//  RequestObject.swift
//  UploadKit
//
//  Created by COUTO, TIAGO on 1/25/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//
import Alamofire

enum StatusRequest {
    case pending
    case failed
}

struct RequestObject {
    let requestId: String = UUID().uuidString
    var requestName: String
    var url: String
    var method: HTTPMethod
    var parameters: Any? = nil
    var headers: [String: String]? = nil
    let createdOn: Date = Date()
    var status: StatusRequest = .pending
}
