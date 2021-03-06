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
    
    static func request(object: RequestObject, completion: @escaping (RequestResult) -> Void) {
        
        guard isConnectedToInternet() else {
            completion(.failure(ErrorMessages.no_internet))
            return
        }
        
        guard let params = object.parameters else {
            Alamofire
                .request(object.url, method: object.method, headers: object.headers)
                .responseJSON { response in
                    processResponse(response: response, completion: completion)
            }
            return
        }
        
        if params is [String: Any] {
            Alamofire
                .request(object.url,
                         method: object.method,
                         parameters: params as? [String: Any],
                         headers: object.headers)
                .responseJSON { response in
                processResponse(response: response, completion: completion)
            }
        } else {
            Alamofire
                .request(
                    createRequest(urlString: object.url,
                                  method: object.method,
                                  headers: object.headers))
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
                completion(.failure(ErrorMessages.data_not_available))
            }
        case .failure(let error):
            completion(.failure(error.localizedDescription))
        }
    }
    
    private static func isConnectedToInternet() -> Bool {
        return NetworkReachabilityManager()!.isReachable
    }
}
