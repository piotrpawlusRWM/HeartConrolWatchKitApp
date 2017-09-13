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
import CoreBluetooth

private let groupName = "group.org.railwaymen.healthkitdev"
fileprivate let BEAN_NAME = "Apple Watch"
fileprivate let BEAN_PIPE_UUID = CBUUID(string: "BE1F5591-4AB0-42E7-9438-33D411AE4093")
fileprivate let BEAN_SERVICE_UUID = CBUUID(string: "ABF616AE-21F3-412B-B5F0-34F4A3D49666")

class InterfaceController: WKInterfaceController {

    @IBOutlet var heartRateLabel: WKInterfaceLabel!
    @IBOutlet var xAccelLabel: WKInterfaceLabel!
    @IBOutlet var yAccelLabel: WKInterfaceLabel!
    @IBOutlet var zAccelLabel: WKInterfaceLabel!
    
    private var session: WCSession!
    private let workoutManager = WorkoutManager()
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    
    fileprivate var centralManager: CBCentralManager?
    fileprivate var connectedPeripheral: CBPeripheral?
    fileprivate var connectedService: CBService?
    
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
        motionManager.gyroUpdateInterval = 1 / 30
    }

    override func willActivate() {
        super.willActivate()
        
        // Configure session
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            session.activate()
            
            workoutManager.delegate = self
            workoutManager.start()
            print("WC session supported")
        } else {
            print("WC session not supported")
        }
        
        // Get accel data
        print("isGyroAvailable --- \(motionManager.isGyroAvailable)")
        if motionManager.isGyroAvailable {
            motionManager.startGyroUpdates(to: OperationQueue.current!, withHandler: { (data, error) -> Void in
                guard let data = data else { return }
                let rotationX = data.rotationRate.x
                let rotationY = data.rotationRate.y
                let rotationZ = data.rotationRate.z
                // do you want to want to do with the data
                print(rotationX)
                print(rotationY)
                print(rotationZ)
            })
        }
        
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
    }
    
    @IBAction func startWorkoutAction() {
        workoutManager.start()
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                self.sendDataToParentApp()
            }
        }
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    @IBAction func stopWorkoutAction() {
        workoutManager.stop()
        motionManager.stopAccelerometerUpdates()
        
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
        
        if let centralManager = centralManager {
            centralManager.stopScan()
            self.centralManager = nil
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
        
        if session.isReachable {
            session.sendMessage(data, replyHandler: { reply in
                print(reply)
            }, errorHandler: nil)
        }
    }
}

//MARK: - CBCentralManagerDelegate

extension InterfaceController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth not avaiable.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print(peripheral)
        
        guard let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString else { return }
        
        if device.contains(BEAN_NAME) {
            self.centralManager?.stopScan()
            
            self.connectedPeripheral = peripheral
            self.connectedPeripheral?.delegate = self
            
            centralManager?.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
}

//MARK: - CBPeripheralDelegate

extension InterfaceController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        for service in services {
            
            if service.uuid == BEAN_SERVICE_UUID {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == BEAN_SERVICE_UUID {
                self.connectedPeripheral?.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
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
