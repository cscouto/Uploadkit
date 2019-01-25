//
//  BaseAPI.swift
//  UploadKit
//
//  Created by COUTO, TIAGO on 1/25/19.
//  Copyright © 2019 Couto Code. All rights reserved.
//

import Alamofire

enum RequestResult {
    case success([String: Any])
    case failure(String)
}

struct BaseAPI {
    
    static func request(url: String,
                        method: HTTPMethod,
                        parameters: Any? = nil,
                        headers: [String: String]? = nil,
                        completion: @escaping (RequestResult) -> Void) {
        
        guard let params = parameters else {
            Alamofire
                .request(url, method: method, headers: headers)
                .responseJSON { response in
                    processResponse(response: response, completion: completion)
            }
            return
        }
        
        if params is [String: Any] {
            Alamofire
                .request(url,
                         method: method,
                         parameters: params as? [String: Any],
                         headers: headers)
                .responseJSON { response in
                processResponse(response: response, completion: completion)
            }
        } else {
            Alamofire
                .request(
                    createRequest(urlString: url,
                                  method: method,
                                  headers: headers))
                .responseJSON { response in
                processResponse(response: response, completion: completion)
            }
        }
    }
    
    private static func createRequest(urlString: String,
                                      method: HTTPMethod,
                                      body: Data? = nil,
                                      timeout: TimeInterval = 30,
                                      headers: [String: String]? = nil) -> URLRequest {
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.timeoutInterval = timeout
        request.allHTTPHeaderFields = headers
        return request
    }
    
    private static func processResponse(response: DataResponse<Any>, completion: @escaping (RequestResult) -> Void) {
        switch response.result {
        case .success(let value):
            if let json = value as? [String : Any] {
                completion(.success(json))
            }else{
                completion(.failure(ErrorMessages.data_not_available.rawValue))
            }
        case .failure(let error):
            completion(.failure(error.localizedDescription))
        }
    }
}
