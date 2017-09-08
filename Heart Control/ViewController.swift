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

class ViewController: UIViewController, WCSessionDelegate {
    
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var xAccelerationLabel: UILabel!
    @IBOutlet weak var yAccelerationLabel: UILabel!
    @IBOutlet weak var zAccelerationLabel: UILabel!
    @IBOutlet weak var latencyLabel: UILabel!
    
    var session: WCSession!
    var helthStore: HKHealthStore!
    override func viewDidLoad() {
        super.viewDidLoad()
    
        helthStore = HKHealthStore()
        if (WCSession.isSupported()) {
            session = WCSession.default()
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("didReceiveMessageData")
        DispatchQueue.main.async { [weak self] in
            
            if let accelerationData = message["accelerator"] as? [String: Any] {
                if let x = accelerationData["x"] as? Double {
                    self?.xAccelerationLabel.text = "\(x)"
                }
                
                if let y = accelerationData["y"] as? Double {
                    self?.yAccelerationLabel.text = "\(y)"
                }
                
                if let z = accelerationData["z"] as? Double {
                    self?.zAccelerationLabel.text = "\(z)"
                }
            }
            
            if let date = message["date"] as? Date {
                let interval = Date().timeIntervalSince(date)
                let intervalString = String(format: "%.2f", interval)
                self?.latencyLabel.text = "latency: \(intervalString)"
            }
            
            if let heartRate = message["heartRate"] as? Double {
                self?.heartRateLabel.text = "\(heartRate)"
            }
        }
    }
}

