//
//  AppDelegate.swift
//  Advertiser
//
//  Created by David G. Young on 4/3/20.
//  Copyright © 2020 davidgyoungtech. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CBPeripheralManagerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager!
    var service:CBMutableService? = nil
    var service2:CBMutableService? = nil
    var peripheralInitialzed = false
    let SERVICE_UUID = CBUUID(string: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6")
    var uniqueIdentifier: Int {
        get {
            var ident = UserDefaults.standard.integer(forKey: "UNIQUE_IDENTIFIER")
            if ident == 0 {
                ident = Int.random(in: 1 ..< Int(UInt32.max))
                UserDefaults.standard.set(ident, forKey: "UNIQUE_IDENTIFIER")
            }
            return ident
        }
    }
    let identifierUuidPrefix = "BBBBBBBB-BBBB-BBBB-BBBB-BBCC"
    var identifierUuid: CBUUID {
        get  {
            return CBUUID(string: String(format:"\(identifierUuidPrefix)%08X", uniqueIdentifier))
        }
    }
    class PeripheralStatus {
        public var peripheral: CBPeripheral?
        public var state: String?
        public var connectStartDate: Date?
        public var readRssiStartDate: Date?
        public var uniqueId: String?
        public var connectionRetries = 0
    }
    
    
    var peripheralManager: CBPeripheralManager? = nil
    var centralManager: CBCentralManager? = nil
    var peripherals: [String:PeripheralStatus] = [:]
    var uniqueIdentifierPerifpheralIds: [String:String] = [:]
    let centralQueue = DispatchQueue.global(qos: .userInitiated)
    let peripheralQueue = DispatchQueue.global(qos: .userInitiated)
    let connectionQueue = DispatchQueue.global(qos: .userInitiated)
    let rssiReadQueue = DispatchQueue.global(qos: .userInitiated)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        var peripheralManagerRestorationIdentifier = "new"
        if let peripheralManagerIdentifiers = launchOptions?[UIApplication.LaunchOptionsKey.bluetoothPeripherals] as? [String] {
             for peripheralManagerIdentifier in peripheralManagerIdentifiers {
                peripheralManagerRestorationIdentifier = peripheralManagerIdentifier
            }
         }

        self.centralManager = CBCentralManager(delegate: self, queue: centralQueue)

        self.peripheralManager = CBPeripheralManager(delegate: self, queue: peripheralQueue, options: [CBPeripheralManagerOptionRestoreIdentifierKey: peripheralManagerRestorationIdentifier])
                
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.distanceFilter = 3000.0
        if #available(iOS 9.0, *) {
          locationManager.allowsBackgroundLocationUpdates = true
        } else {
          // not needed on earlier versions
        }
        // start updating location at beginning just to give us unlimited background running time
        self.locationManager.startUpdatingLocation()
        
        extendBackgroundRunningTime()

        return true
    }
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error {
            NSLog("Failed to read RSSI: \(error)")
            if let peripheralState = peripherals[peripheral.identifier.uuidString] {
                peripheralState.state = "identified"
            }
        }
        else {
            if let peripheralState = peripherals[peripheral.identifier.uuidString] {
                peripheralState.state = "identified"
                NSLog("Read RSSI: \(RSSI) for \(peripheralState.uniqueId ?? "unknown")")
            }
        }
    }
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        // nothing so far
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            centralManager?.scanForPeripherals(withServices: [SERVICE_UUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let state = peripherals[peripheral.identifier.uuidString]?.state ?? ""
        if state == "" || state == "failed" {
            NSLog("Discovered peripheral: \(peripheral.identifier) Services: \(peripheral.services?.first?.uuid.uuidString ?? "none") ")
            NSLog("Connecting.  State is \(state)")
            if let peripheralState = peripherals[peripheral.identifier.uuidString] {
                peripheralState.state = "connecting"
                peripheralState.connectStartDate = Date()
            }
            else {
                let peripheralState = PeripheralStatus()
                peripheralState.peripheral = peripheral
                peripheralState.state = "connecting"
                peripheralState.connectStartDate = Date()
                peripherals[peripheral.identifier.uuidString] = peripheralState
            }
            connectionQueue.sync {
                centralManager?.connect(peripheral, options: nil)
            }
        }
        else {
            //NSLog("Discovered peripheral: \(peripheral.identifier) our state is: \(state)")
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("Connected")
        var needToDiscover = true
        if let peripheralState = peripherals[peripheral.identifier.uuidString] {
            peripheralState.state = "connected"
            peripheralState.connectionRetries = 0
            peripheralState.connectStartDate = nil
            if peripheralState.uniqueId != nil {
                peripheralState.state = "identified"
                needToDiscover = false // we already know who this is
            }
        }
        if needToDiscover {
            NSLog("Discovering services")
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }

        DispatchQueue.main.async {
            self.extendBackgroundRunningTime()
        }
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let peripheralState = peripherals[peripheral.identifier.uuidString] {
            if peripheralState.state != "unconnectable" && peripheralState.state != "no app running" {
                peripheralState.state = "disconnected"
            }
            else {
                NSLog("ignoring disconnect event for peripheral in state \(peripheralState.state ?? "--")")
            }
            peripheralState.connectStartDate = nil
        }
        NSLog("Disconnected")
        DispatchQueue.main.async {
            self.extendBackgroundRunningTime()
        }
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let peripheralState = peripherals[peripheral.identifier.uuidString] {
            peripheralState.state = "failed"
            peripheralState.connectStartDate = nil
        }
        NSLog("Failed to connect")
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            NSLog("Error discovering services")
            if let peripheralState = peripherals[peripheral.identifier.uuidString] {
                peripheralState.state = "service discovery error"
            }
        }
        else {
            NSLog("Discovered services")
            if let services = peripheral.services {
                var deviceUniqueIdentifier: String? = nil
                for service in services {
                    let uuidString = service.uuid.uuidString
                    if (uuidString.lowercased() == "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6".lowercased()) {
                        NSLog("Found the service uuid")
                    }
                    else {
                        if uuidString.uppercased().starts(with: identifierUuidPrefix) {
                            NSLog("Found an device unique identifier service uuid: %@", uuidString)
                            deviceUniqueIdentifier = String(uuidString.uppercased().replacingOccurrences(of: identifierUuidPrefix, with: ""))
                        }
                        else {
                            NSLog("Found another service uuid we don't care about \(uuidString)")
                        }
                    }
                }
                if let deviceUniqueIdentifier = deviceUniqueIdentifier {
                    // we found it!
                    NSLog("Found device unique identifier: \(deviceUniqueIdentifier)")
                    if let existingPeripheralId =  uniqueIdentifierPerifpheralIds[deviceUniqueIdentifier] {
                        if existingPeripheralId != peripheral.identifier.uuidString {
                            NSLog("Peripheral Id change detected for \(deviceUniqueIdentifier).  From: \(existingPeripheralId) to \(peripheral.identifier.uuidString)")
                            peripherals.removeValue(forKey: existingPeripheralId)
                        }
                    }
                    uniqueIdentifierPerifpheralIds[deviceUniqueIdentifier] = peripheral.identifier.uuidString
                    if let peripheralState = peripherals[peripheral.identifier.uuidString] {
                        peripheralState.state = "identified"
                        peripheralState.uniqueId = deviceUniqueIdentifier
                    }
                }
                else {
                    NSLog("Device not advertising our service.  Ignoring it.")
                    if let peripheralState = peripherals[peripheral.identifier.uuidString] {
                        peripheralState.state = "no app running"
                    }
                    centralManager?.cancelPeripheralConnection(peripheral)
                }
            }
            else {
                NSLog("services are nil")
                if let peripheralState = peripherals[peripheral.identifier.uuidString] {
                    peripheralState.state = "services are nil"
                }
            }
 
        }
    
    }


    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == CBManagerState.poweredOn {
            if !peripheralInitialzed {
                NSLog("My personal identity service is \(identifierUuid.uuidString)")
                
                //peripheralManager?.removeAllServices()
                service = CBMutableService.init(type: SERVICE_UUID, primary: true)
                service2 = CBMutableService.init(type: identifierUuid, primary: true)
                peripheralManager?.add(service!)
                peripheralManager?.add(service2!)
                peripheralInitialzed = true
            }
            let adData = [CBAdvertisementDataServiceUUIDsKey : [SERVICE_UUID]] as [String : Any]
            peripheralManager?.startAdvertising(adData)
        }
        else{
            NSLog("Bluetooth power state changed to \(peripheral.state)")
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print(peripheral.isAdvertising)
    }
    
    // MARK: UISceneSession Lifecycle

    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    var threadStarted = false
    var threadShouldExit = false
    func extendBackgroundRunningTime() {
      if (threadStarted) {
        // if we are in here, that means the background task is already running.
        // don't restart it.
        return
      }
      threadStarted = true
      NSLog("Attempting to extend background running time")
      
      self.backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "DummyTask", expirationHandler: {
        NSLog("Background task expired by iOS.")
        UIApplication.shared.endBackgroundTask(self.backgroundTask)
      })

    
        var lastDumpTime = 0.0
      var lastLogTime = 0.0
      DispatchQueue.global().async {
        let startedTime = Int(Date().timeIntervalSince1970) % 10000000
        NSLog("*** STARTED BACKGROUND THREAD")
        while(!self.threadShouldExit) {
            let now = Date().timeIntervalSince1970
            if now - lastDumpTime > 15.0 {
                lastDumpTime = now
                for key in self.peripherals.keys {
                    if let peripheralState = self.peripherals[key] {
                        NSLog("\(key) (\(peripheralState.uniqueId ?? "unknown")) \(peripheralState.state ?? "nil")")
                    }
                }
            }
            DispatchQueue.main.async {
                let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
                if abs(now - lastLogTime) >= 2.0 {
                    lastLogTime = now
                    if backgroundTimeRemaining < 10.0 {
                      NSLog("About to suspend based on background thread running out.")
                    }
                    if (backgroundTimeRemaining < 200000.0) {
                     NSLog("Thread \(startedTime) background time remaining: \(backgroundTimeRemaining)")
                    }
                    else {
                      NSLog("Thread \(startedTime) background time remaining: INFINITE")
                    }
                }
            }
            for peripheralId in self.peripherals.keys {
                if let state = self.peripherals[peripheralId]?.state {
                    if state == "identified" {
                        if let peripheralState = self.peripherals[peripheralId] {
                            peripheralState.state = "rssi_requested"
                            self.connectionQueue.sync {
                                self.rssiReadQueue.sync {
                                    peripheralState.readRssiStartDate = Date()
                                    peripheralState.peripheral?.readRSSI()
                                }
                            }
                        }
                    }
                    else if state == "rssi_requested" {
                        if let peripheralState = self.peripherals[peripheralId] {
                            if let startDate = peripheralState.readRssiStartDate {
                                let now = Date()
                                let rssiReadDuration = now.timeIntervalSince1970 - startDate.timeIntervalSince1970
                                if rssiReadDuration > 5 {
                                    NSLog("Timeout reading Rssi for \(peripheralState.uniqueId ?? "-").  Retrying.")
                                    self.rssiReadQueue.sync {
                                        peripheralState.readRssiStartDate = Date()
                                        peripheralState.peripheral?.readRSSI()
                                    }
                                }
                            }
                        }
                    }
                    else if state == "disconnected" {
                        if let peripheralState = self.peripherals[peripheralId] {
                            if peripheralState.peripheral?.state == CBPeripheralState.connected {
                                NSLog("state was incorrectly marked as disconnected.  But we are connected.  Correcting that")
                                peripheralState.state = "connected"
                            }
                            else {
                                NSLog("Reconnecting")
                                peripheralState.state = "connecting"
                                peripheralState.connectStartDate = Date()
                                self.connectionQueue.sync {
                                    if let peripheral = peripheralState.peripheral {
                                        self.centralManager?.connect(peripheral, options: nil)
                                    }
                                }
                            }
                        }
                    }
                    else if state == "connecting" {
                        if let peripheralState = self.peripherals[peripheralId] {
                            if let startDate = peripheralState.connectStartDate {
                                let now = Date()
                                let connectDuration = now.timeIntervalSince1970 - startDate.timeIntervalSince1970
                                if connectDuration > 30 {
                                    let maxRetries = peripheralState.uniqueId == nil ? 1 : 10
                                    if peripheralState.connectionRetries == maxRetries {
                                        NSLog("Giving up after too many connection attempts.  Peripheral \(peripheralId) may be out of range.")
                                        if let peripheral = peripheralState.peripheral {
                                            self.centralManager?.cancelPeripheralConnection(peripheral)
                                        }
                                        if peripheralState.uniqueId == nil {
                                            peripheralState.state = "unconnectable"
                                        }
                                        else {
                                            peripheralState.state = nil // gone
                                        }
                                    }
                                    else {
                                        peripheralState.connectionRetries += 1
                                        NSLog("Timeout trying to connect to peripheral. Retrying.  Attempt \(peripheralState.connectionRetries)")
                                        peripheralState.state = "connecting"
                                        peripheralState.connectStartDate = Date()
                                        self.connectionQueue.sync {
                                            if let peripheral = peripheralState.peripheral {
                                                self.centralManager?.connect(peripheral, options: nil)
                                            }
                                        }

                                    }
                                }
                                else {
                                    NSLog("Still connecting after \(connectDuration) secs")
                                }
                            }
                        }
                    }
                }
            }
            sleep(1)
        }
        self.threadStarted = false
        NSLog("*** EXITING BACKGROUND THREAD")
      }

    }
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        var pName = peripheral.identifier.uuidString
        if let peripheralState = self.peripherals[pName] {
            if let uniqueId = peripheralState.uniqueId {
                pName = "with id: \(uniqueId)"
            }
        }
        NSLog("didModifyServices for peripheral \(pName)")
        if (invalidatedServices.count == 0 ) {
            NSLog("No services invalidated.")
        }
        for service in invalidatedServices {
            NSLog("Service \(service.uuid.uuidString) invalidated for peripheral \(pName)")
        }
        peripheral.discoverServices(nil)
    }

}

