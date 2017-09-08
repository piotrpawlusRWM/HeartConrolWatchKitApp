//
//  InterfaceController.swift
//  Heart Control WatchKit Extension
//
//  Created by Thomas Paul Mann on 01/08/16.
//  Copyright © 2016 Thomas Paul Mann. All rights reserved.
//

import WatchKit
import CoreMotion
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    // MARK: - Outlets

    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    
    @IBOutlet var xAccelLabel: WKInterfaceLabel!
    @IBOutlet var yAccelLabel: WKInterfaceLabel!
    @IBOutlet var zAccelLabel: WKInterfaceLabel!
    
    @IBAction func startWorkoutAction() {
        workoutManager.start()
    }

    @IBAction func stopWorkoutAction() {
        workoutManager.stop()
    }
    // MARK: - Properties

    private let workoutManager = WorkoutManager()
    private let motionManager = CMMotionManager()
    
    private var session: WCSession!
    private var accelerationArray: [AccelerationData] = []
    
    var accelerometerObservers = [(Double, Double, Double) -> Void]()
    
    private var isActivationComplete = false
    
    // MARK: - Lifecycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        motionManager.accelerometerUpdateInterval = 0.5
    }

    override func willActivate() {
        super.willActivate()
        
        // Configure session
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self
            session.activate()
            
            workoutManager.delegate = self
            workoutManager.start()
            print("WC session supported")
        } else {
            print("WC session not supported")
        }
        
        // Get accel data
        if motionManager.isAccelerometerAvailable {
            
            guard let operation = OperationQueue.current else { return }
            motionManager.startAccelerometerUpdates()
            
            motionManager.startAccelerometerUpdates(to: operation, withHandler: { (data, error) in
                if self.isActivationComplete {
                    guard let dataAccelX = data?.acceleration.x, let dataAccelY = data?.acceleration.y, let dataAccelZ = data?.acceleration.z else { return }
                    self.xAccelLabel.setText(String(format: "%.3f", dataAccelX))
                    self.yAccelLabel.setText(String(format: "%.3f", dataAccelY))
                    self.zAccelLabel.setText(String(format: "%.3f", dataAccelZ))
                    self.notifyAccelerometerObservers(x: dataAccelX, y: dataAccelY, z: dataAccelZ)
                }
            })
        }
        else {
            xAccelLabel.setText("not available")
            yAccelLabel.setText("not available")
            zAccelLabel.setText("not available")
        }
    }
    
    private func notifyAccelerometerObservers(x: Double, y: Double, z: Double) {
        let d = Date()
        self.sendAccelerationToIphone(x: "\(x)", y: "\(y)", z: "\(z)", date: d)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith")
        isActivationComplete = true
        self.session?.sendMessage(["heartRate": "100"], replyHandler: { (_) in
            print("message send success")
        }, errorHandler: { (_) in
            print("sending message failed")
        })
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("sessionReachabilityDidChange")
    }
    
    func sendHeartRateToIphone(heartRate: Double) {
        let applicationData = ["heartRate": "\(heartRate)"]
        session?.sendMessage(applicationData, replyHandler: nil, errorHandler: nil)
    }
    
    func sendAccelerationToIphone(x: String, y: String, z: String, date: Date) {
        
        let accelerationData: [String:Any] = [
            "x": x,
            "y": y,
            "z": z,
            "date": date
        ]
        
        accelerationArray.append(AccelerationData(x: x, y: y, z: z, date: date))
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//            self?.session.sendMessage(["data": self?.accelerationArray as Any], replyHandler: nil, errorHandler: nil)
//            self?.accelerationArray = []
//        }
        
        session.sendMessage(accelerationData, replyHandler: nil, errorHandler: nil)
    }
}

// MARK: - Workout Manager Delegate

extension InterfaceController: WorkoutManagerDelegate {

    func workoutManager(_ manager: WorkoutManager, didChangeStateTo newState: WorkoutState) {
    }

    func workoutManager(_ manager: WorkoutManager, didChangeHeartRateTo newHeartRate: HeartRate) {
        heartRateLabel.setText(String(format: "%.0f", newHeartRate.bpm))
//        sendHeartRateToIphone(heartRate: newHeartRate.bpm)
    }

}

struct AccelerationData {
    let x: String
    let y: String
    let z: String
    let date: Date
}
