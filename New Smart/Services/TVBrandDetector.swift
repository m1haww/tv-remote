//
//  TVBrandDetector.swift
//  Smart TV
//
//  Created by Mihail Ozun on 25.10.2025.
//

import Foundation

class TVBrandDetector {
    
    static func detectTVBrand(ip: String, completion: @escaping (DetectedTV?) -> Void) {
        print("🔍 Starting advanced TV brand detection for \(ip)")
        
        // Try multiple detection methods in parallel
        let group = DispatchGroup()
        var detectedTV: DetectedTV?
        
        // Method 1: Check for LG WebOS
        group.enter()
        checkLGWebOS(ip: ip) { result in
            if let lg = result {
                detectedTV = lg
                print("✅ LG WebOS detected via dedicated check")
            }
            group.leave()
        }
        
        // Method 2: Check for Samsung SmartThings/Tizen
        group.enter()
        checkSamsungTizen(ip: ip) { result in
            if detectedTV == nil, let samsung = result {
                detectedTV = samsung
                print("✅ Samsung Tizen detected via dedicated check")
            }
            group.leave()
        }
        
        // Method 3: Check for Sony Bravia
        group.enter()
        checkSonyBravia(ip: ip) { result in
            if detectedTV == nil, let sony = result {
                detectedTV = sony
                print("✅ Sony Bravia detected via dedicated check")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(detectedTV)
        }
    }
    
    private static func checkLGWebOS(ip: String, completion: @escaping (DetectedTV?) -> Void) {
        // LG WebOS typically runs on port 3000 or 3001
        let lgPorts = [3000, 3001]
        
        for port in lgPorts {
            let url = URL(string: "http://\(ip):\(port)/")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 2.0
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    
                    if let data = data, let content = String(data: data, encoding: .utf8) {
                        if content.lowercased().contains("webos") {
                            let tv = DetectedTV(
                                manufacturer: "LG",
                                name: "webOS TV",
                                model: "LG webOS Smart TV",
                                ip: ip,
                                port: port
                            )
                            completion(tv)
                            return
                        }
                    }
                }
                completion(nil)
            }.resume()
        }
    }
    
    private static func checkSamsungTizen(ip: String, completion: @escaping (DetectedTV?) -> Void) {
        // Samsung typically runs on ports 8001, 8002, or 80
        let samsungPorts = [8001, 8002, 80]
        
        for port in samsungPorts {
            let url = URL(string: "http://\(ip):\(port)/")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 2.0
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse,
                   (httpResponse.statusCode == 200 || httpResponse.statusCode == 404) {
                    
                    // Check for Samsung-specific headers or content
                    let headers = httpResponse.allHeaderFields
                    let headersString = "\(headers)".lowercased()
                    
                    if headersString.contains("samsung") || headersString.contains("tizen") {
                        let tv = DetectedTV(
                            manufacturer: "Samsung",
                            name: "Smart TV",
                            model: "Samsung Tizen Smart TV",
                            ip: ip,
                            port: port
                        )
                        completion(tv)
                        return
                    }
                    
                    if let data = data, let content = String(data: data, encoding: .utf8) {
                        if content.lowercased().contains("samsung") || content.lowercased().contains("tizen") {
                            let tv = DetectedTV(
                                manufacturer: "Samsung",
                                name: "Smart TV",
                                model: "Samsung Tizen Smart TV",
                                ip: ip,
                                port: port
                            )
                            completion(tv)
                            return
                        }
                    }
                    
                    // Samsung often responds on port 80 with basic HTTP
                    if port == 80 {
                        let tv = DetectedTV(
                            manufacturer: "Samsung",
                            name: "Smart TV",
                            model: "Samsung Smart TV (Port 80)",
                            ip: ip,
                            port: port
                        )
                        completion(tv)
                        return
                    }
                }
                completion(nil)
            }.resume()
        }
    }
    
    private static func checkSonyBravia(ip: String, completion: @escaping (DetectedTV?) -> Void) {
        // Sony Bravia typically runs on port 80 or 8080
        let sonyPorts = [80, 8080]
        
        for port in sonyPorts {
            let url = URL(string: "http://\(ip):\(port)/sony/")!
            var request = URLRequest(url: url)
            request.timeoutInterval = 2.0
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    
                    if let data = data, let content = String(data: data, encoding: .utf8) {
                        if content.lowercased().contains("sony") || content.lowercased().contains("bravia") {
                            let tv = DetectedTV(
                                manufacturer: "Sony",
                                name: "Bravia TV",
                                model: "Sony Bravia Smart TV",
                                ip: ip,
                                port: port
                            )
                            completion(tv)
                            return
                        }
                    }
                }
                completion(nil)
            }.resume()
        }
    }
}

struct DetectedTV {
    let manufacturer: String
    let name: String
    let model: String
    let ip: String
    let port: Int
}