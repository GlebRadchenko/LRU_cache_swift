//
//  main.swift
//  LRUCache
//
//  Created by Gleb on 9/6/17.
//  Copyright © 2017 Gleb. All rights reserved.
//

import Foundation

struct Response {
    var data: Data?
    var error: Error?
}

let dataLoadClosure: (URL, @escaping (Response) -> Void) -> Void = { (url, completion) in
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let task = URLSession.shared.dataTask(with: request) { (data, responce, error) in
        completion(Response(data: data, error: error))
    }
    
    DispatchQueue.global().async {
        task.resume()
    }
}

let asyncCache = AsyncLRUCache<URL, Response>(size: 3, dataLoadClosure)

let url1 = URL(string: "https://gokulkrishh.github.io/images/performance/https/http2vshttps.jpg")!
let url2 = URL(string: "https://www.proxyswitcher.com/img/test-target-yahoo-details.png")!
let url3 = URL(string: "https://www.cdc.gov/nceh/lead/images/blood_lead_tests_flowchart.jpg")!
let url4 = URL(string: "https://www.eff.org/files/styles/resized_banner/public/tor-info-og-image.png?itok=cZmhkQ7y")!

let urls = [url1, url2, url3, url4,
            url1, url2, url3, url4,
            url1, url2, url3, url4,
            url1, url2, url3, url4,
            url1, url2, url3, url4,
            url1, url2, url3, url4,
            url1, url2, url3, url4,
            url1, url2, url3, url4]

func testRequest(_ delay: TimeInterval, urls: [URL], asyncCache: AsyncLRUCache<URL, Response>) {
    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
        urls.forEach { (url) in
            asyncCache.value(for: url) { (responce) in
                print(responce)
            }
        }
    }
}

//testRequest(0, urls: urls, asyncCache: asyncCache)
//testRequest(2, urls: urls, asyncCache: asyncCache)

let syncCache = LRUCache<Int, Int>(size: 2) { (value) -> Int in
    return value * value
}

let numbers = [1, 2, 3, 4,
               4, 3, 2, 1,
               1, 2, 3, 4,
               4, 3, 2, 1,
               1, 2, 3, 4,
               4, 3, 2, 1,
               1, 2, 3, 4,
               4, 3, 2, 1]

numbers.forEach { print(syncCache.value(for: $0)) }

RunLoop.main.run()
