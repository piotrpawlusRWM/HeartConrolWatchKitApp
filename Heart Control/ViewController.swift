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
import CoreBluetooth

private let groupName = "group.org.railwaymen.healthkitdev"

class ViewController: UIViewController {
    
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var xAccelerationLabel: UILabel!
    @IBOutlet weak var yAccelerationLabel: UILabel!
    @IBOutlet weak var zAccelerationLabel: UILabel!
    @IBOutlet weak var latencyLabel: UILabel!
    
    private var session: WCSession!
    private var helthStore: HKHealthStore!
    
    fileprivate var peripheralManager: CBPeripheralManager!
    fileprivate var watchService: CBMutableService!
    fileprivate var watchCharacterisitc: CBMutableCharacteristic!
    
    fileprivate let BEAN_NAME = "Apple Watch"
    fileprivate let BEAN_PIPE_UUID = CBUUID(string: "BE1F5591-4AB0-42E7-9438-33D411AE4093")
    fileprivate let BEAN_SERVICE_UUID = CBUUID(string: "ABF616AE-21F3-412B-B5F0-34F4A3D49666")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        helthStore = HKHealthStore()
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    @IBAction func startWatchApp(_ sender: Any) {
        
        if session.isWatchAppInstalled && session.activationState == .activated {
            if session.isReachable {
                helthStore.startWatchApp(with: HKWorkoutConfiguration()) { isLunched, error in
                    if isLunched {
                        print("Succeed")
                    } else if let error = error {
                        print("error -- \(error)")
                    } else {
                        print("Unsupported")
                    }
                }
            } else {
                print("Please unlock iPhone")
            }
        } else {
            print("Watch App not installed!")
        }
    }
    
    fileprivate func setupService() {
        watchCharacterisitc = CBMutableCharacteristic(type: BEAN_PIPE_UUID, properties: .notify, value: nil, permissions: .readable)
        watchService = CBMutableService(type: BEAN_SERVICE_UUID, primary: true)
        watchService.characteristics = [watchCharacterisitc]
        peripheralManager.add(watchService)
    }
    
    fileprivate func advertise() {
        
        let services = [BEAN_SERVICE_UUID]
        let advertisingDictionary = [CBAdvertisementDataServiceUUIDsKey: services]
        
        peripheralManager.startAdvertising(advertisingDictionary)
    }
}

// MARK: - CBPeripheralManagerDelegate

extension ViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        switch peripheral.state {
        case .poweredOn:
            self.setupService()
        default:
            print("Bluetooth not avaiable.")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
        DispatchQueue.main.async {
            let data = "Works well".data(using: .utf8)!
            self.peripheralManager.updateValue(data, for: self.watchCharacterisitc, onSubscribedCentrals: nil)
        }
    }
}

// MARK: - WCSessionDelegate
extension ViewController: WCSessionDelegate {
    
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
}
