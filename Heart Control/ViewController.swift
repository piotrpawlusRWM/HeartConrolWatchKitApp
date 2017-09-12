//
//  ViewController.swift
//  Heart Control
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity
import CoreDataProxy

private let groupName = "group.org.railwaymen.healthkitdev"

class ViewController: UIViewController, WCSessionDelegate {
    
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var xAccelerationLabel: UILabel!
    @IBOutlet weak var yAccelerationLabel: UILabel!
    @IBOutlet weak var zAccelerationLabel: UILabel!
    @IBOutlet weak var latencyLabel: UILabel!
    
    var session: WCSession!
    var helthStore: HKHealthStore!
    
    var fileManager: FileManager!
    var sharedFilePath: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        fileManager = FileManager.default
    
        let sharedContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupName)
        let dirPath = sharedContainer?.path
        
        sharedFilePath = dirPath?.appending("sharedText.doc")
//        if let path = sharedFilePath, fileManager.fileExists(atPath: path) {
//            
//        }
    
        helthStore = HKHealthStore()
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    @IBAction func startWatchApp(_ sender: Any) {
     
        if session.isWatchAppInstalled && session.activationState == .activated {
     
            helthStore.startWatchApp(with: HKWorkoutConfiguration(), completion: { isLunched, error in
                
                if isLunched {
                    print("Succeed")
                } else if let error = error {
                    print("error -- \(error)")
                } else {
                    print("Unsupported")
                }
            })
        }
    }
    
    private func createSharedFile() {
        
//        let sharedContainer =
    }
    
    // MARK: - WCSessionDelegate
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
        session.activate()
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith")
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async { [weak self] in
            
            if let dataArray = userInfo["data"] as? [[String: Any]] {
                
                for dictionary in dataArray {
                    if let accelerationData = dictionary["accelerator"] as? [String: Any] {
                        if let x = accelerationData["x"] as? Double {
                            self?.xAccelerationLabel.text = "x: \(x)"
                        } else {
                            self?.xAccelerationLabel.text = "not available"
                        }
                        
                        if let y = accelerationData["y"] as? Double {
                            self?.yAccelerationLabel.text = "y: \(y)"
                        } else {
                            self?.yAccelerationLabel.text = "not available"
                        }
                        
                        if let z = accelerationData["z"] as? Double {
                            self?.zAccelerationLabel.text = "z: \(z)"
                        } else {
                            self?.zAccelerationLabel.text = "not available"
                        }
                    }
                    
                    if let heartRate = dictionary["heartRate"] as? Double {
                        self?.heartRateLabel.text = "\(heartRate)"
                    } else {
                        self?.heartRateLabel.text = "-"
                    }
                }
            }
            
            if let date = userInfo["date"] as? Date {
                let interval = Date().timeIntervalSince(date)
                let intervalString = String(format: "%.2f", interval)
                self?.latencyLabel.text = "latency: \(intervalString)"
            }
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        print("didReceiveFile")
        
        if let message = NSDictionary(contentsOf: file.fileURL) as? Dictionary<String, Any> {
            DispatchQueue.main.async { [weak self] in
                
                if let dataArray = message["data"] as? [[String: Any]] {
                    
                    for dictionary in dataArray {
                        if let accelerationData = dictionary["accelerator"] as? [String: Any] {
                            if let x = accelerationData["x"] as? Double {
                                self?.xAccelerationLabel.text = "x: \(x)"
                            } else {
                                self?.xAccelerationLabel.text = "not available"
                            }
                            
                            if let y = accelerationData["y"] as? Double {
                                self?.yAccelerationLabel.text = "y: \(y)"
                            } else {
                                self?.yAccelerationLabel.text = "not available"
                            }
                            
                            if let z = accelerationData["z"] as? Double {
                                self?.zAccelerationLabel.text = "z: \(z)"
                            } else {
                                self?.zAccelerationLabel.text = "not available"
                            }
                        }
                        
                        if let heartRate = dictionary["heartRate"] as? Double {
                            self?.heartRateLabel.text = "\(heartRate)"
                        } else {
                            self?.heartRateLabel.text = "-"
                        }
                    }
                }
                
                if let date = message["date"] as? Date {
                    let interval = Date().timeIntervalSince(date)
                    let intervalString = String(format: "%.2f", interval)
                    self?.latencyLabel.text = "latency: \(intervalString)"
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("didReceiveMessageData")
        
        replyHandler(["Works": "well"])
        print(message)
        
        DispatchQueue.main.async { [weak self] in
            
            if let accelerationData = message["accelerator"] as? [String: Any] {
                if let x = accelerationData["x"] as? Double {
                    self?.xAccelerationLabel.text = "x: \(x)"
                } else {
                    self?.xAccelerationLabel.text = "not available"
                }
                
                if let y = accelerationData["y"] as? Double {
                    self?.yAccelerationLabel.text = "y: \(y)"
                } else {
                    self?.yAccelerationLabel.text = "not available"
                }
                
                if let z = accelerationData["z"] as? Double {
                    self?.zAccelerationLabel.text = "z: \(z)"
                } else {
                    self?.zAccelerationLabel.text = "not available"
                }
            }
            
            if let heartRate = message["heartRate"] as? Double {
                self?.heartRateLabel.text = "\(heartRate)"
            } else {
                self?.heartRateLabel.text = "-"
            }
            
            if let date = message["date"] as? Date {
                print("\(date) -- \(Date())")
                let interval = Date().timeIntervalSince(date)
                let intervalString = String(format: "%.2f", interval)
                self?.latencyLabel.text = "latency: \(intervalString)"
            }
//
//            
//            if let dataArray = message["data"] as? [[String: Any]] {
//                
//                for dictionary in dataArray {
//                    if let accelerationData = dictionary["accelerator"] as? [String: Any] {
//                        if let x = accelerationData["x"] as? Double {
//                            self?.xAccelerationLabel.text = "x: \(x)"
//                        } else {
//                            self?.xAccelerationLabel.text = "not available"
//                        }
//                        
//                        if let y = accelerationData["y"] as? Double {
//                            self?.yAccelerationLabel.text = "y: \(y)"
//                        } else {
//                            self?.yAccelerationLabel.text = "not available"
//                        }
//                        
//                        if let z = accelerationData["z"] as? Double {
//                            self?.zAccelerationLabel.text = "z: \(z)"
//                        } else {
//                            self?.zAccelerationLabel.text = "not available"
//                        }
//                    }
//                    
//                    if let heartRate = dictionary["heartRate"] as? Double {
//                        self?.heartRateLabel.text = "\(heartRate)"
//                    } else {
//                        self?.heartRateLabel.text = "-"
//                    }
//                }
//            }
//            
//            if let date = message["date"] as? Date {
//                let interval = Date().timeIntervalSince(date)
//                let intervalString = String(format: "%.2f", interval)
//                self?.latencyLabel.text = "latency: \(intervalString)"
//            }
        }
    }
}

