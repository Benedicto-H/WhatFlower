//
//  APICaller.swift
//  WhatFlower
//
//  Created by 홍진표 on 1/15/24.
//

import Foundation
import Alamofire
import SwiftyJSON

final class APICaller {
    
    // MARK: - Singleton Instance
    static let shared: APICaller = APICaller()
    
    // MARK: - Property
    let wikipediaURL: String = "https://en.wikipedia.org/w/api.php"
    
    // MARK: - (PRIVATE) Initialize
    private init() {}
    
    // MARK: - Method
    func performRequest(flowerName: String, completion: @escaping (String?, String?) -> Void?) -> Void {
        
        let parameters: [String: String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts|pageimages",
            "exintro": "",
            "explaintext": "",
            "titles": flowerName,
            "indexpageids": "",
            "redirects": "1",
            "pithumbsize": "500"
        ]
        
        AF.request(wikipediaURL, method: .get, parameters: parameters)
            .validate(statusCode: 200 ..< 300)
            .response(queue: .global()) { response in
                switch response.result {
                case .success(let data):
                    guard let safeData: Data = data else { return }
                    
                    do {
                        let jsonData: JSON = try JSON(data: safeData)
                        let pageid: String = jsonData["query"]["pageids"][0].stringValue
                        let extract: String = jsonData["query"]["pages"][pageid]["extract"].stringValue
                        let image: String = jsonData["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                        
                        print(jsonData)
                        
                        completion(extract, image)
                    } catch {
                        print(error.localizedDescription)
                    }
                    break;
                case .failure(let error):
                    print("err: \(error.localizedDescription)")
                    completion(nil, nil)
                    break;
                }
            }
    }
}
