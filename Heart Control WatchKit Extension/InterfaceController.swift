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

class InterfaceController: WKInterfaceController {

    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var xAccelLabel: WKInterfaceLabel!
    @IBOutlet var yAccelLabel: WKInterfaceLabel!
    @IBOutlet var zAccelLabel: WKInterfaceLabel!
    
    private var session: WCSession!
    private let workoutManager = WorkoutManager()
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    
    fileprivate var isActivationComplete = false
    fileprivate var accelerationData: AccelerationData? {
        
        didSet {
            
            if let accelerationData = accelerationData {
                xAccelLabel.setText(String(format: "%.3f", accelerationData.x))
                yAccelLabel.setText(String(format: "%.3f", accelerationData.y))
                zAccelLabel.setText(String(format: "%.3f", accelerationData.z))
            }
        }
    }
    
    fileprivate var heartRate: Double? {
        didSet {
            if let heartRate = heartRate {
                heartRateLabel.setText(String(format: "%.0f", heartRate))
            }
        }
    }
    
    private var dataArray: [Any] = []
    
    // MARK: - Lifecycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        motionManager.accelerometerUpdateInterval = 1 / 30
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
            motionManager.startAccelerometerUpdates(to: operation) { [unowned self] (data, error) in
                
                if self.isActivationComplete {
                    guard let data = data else { return }
                    self.accelerationData = AccelerationData(x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z)
                }
            }
        } else {
            xAccelLabel.setText("not available")
            yAccelLabel.setText("not available")
            zAccelLabel.setText("not available")
        }
        
        Timer.scheduledTimer(withTimeInterval: 1 / 30, repeats: true) { _ in
            self.appendNewInfo()
        }
    }
    
    @IBAction func startWorkoutAction() {
        workoutManager.start()
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                self.sendDataToParentApp()
            }
        }
    }
    
    @IBAction func stopWorkoutAction() {
        workoutManager.stop()
        motionManager.stopAccelerometerUpdates()
        
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    private func appendNewInfo() {
        
        let accelerationData: [String: Any] = [
            "x": self.accelerationData?.x ?? "not available",
            "y": self.accelerationData?.y ?? "not available",
            "z": self.accelerationData?.z ?? "not available"
        ]
        
        let data: [String: Any] = [
            "accelerator": accelerationData,
            "date": Date(),
            "heartRate": heartRate ?? "-"
        ]
        
        dataArray.append(data)
    }
    
    private func sendDataToParentApp() {
        
        let data: [String: Any] = [
            "data": dataArray,
            "date": Date()
        ]
        
        session.sendMessage(data, replyHandler: { reply in
            print(reply)
            self.dataArray = []
        }) { error in
            print(error)
        }
    }
}

//MARK: - WKSessionDelegate

extension InterfaceController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith")
        isActivationComplete = true
    }
}

//MARK: - Workout Manager Delegate

extension InterfaceController: WorkoutManagerDelegate {

    func workoutManager(_ manager: WorkoutManager, didChangeStateTo newState: WorkoutState) {
    }

    func workoutManager(_ manager: WorkoutManager, didChangeHeartRateTo newHeartRate: HeartRate) {
        self.heartRate = newHeartRate.bpm
    }
}

struct AccelerationData {
    let x: Double
    let y: Double
    let z: Double
}
