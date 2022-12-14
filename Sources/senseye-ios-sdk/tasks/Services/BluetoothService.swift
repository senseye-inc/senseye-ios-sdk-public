//
//  BluetoothService.swift
//  
//
//  Created by Frank Oftring on 9/21/22.
//

import Foundation

import CoreBluetooth

class BluetoothService: NSObject, ObservableObject {
    private var manager: CBCentralManager!

    // Local copy of peripherals we want to perform commands on
    @Published private(set) var discoveredPeripherals: [DiscoveredPeripheral] = []
    @Published var isDeviceConnected: Bool = false
    @Published var bluetoothDiscovered: Bool = false
    @Published var receivedBytes: Data? = nil
    private var subscribedCharacteristics: [String: [CBCharacteristic]] = [:]

    private var lastConnectedPeripheral: CBPeripheral?
    private let decoder = JSONDecoder()

    private let centralManagerOptions: [String: Any] = [
        CBCentralManagerOptionRestoreIdentifierKey: "senseyeBerryMedBLECentralIdentifier"
    ]

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
        Log.info("BluetoothService Initialized")
    }

    func scanForPeripherals() {
        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: false]

        // withServices is an array of CBUUID devices we want to filter for. withServices: nil means find anything and everything
        manager.scanForPeripherals(withServices: nil, options: options)
    }

    func connect(to peripheral: CBPeripheral, isReconnection: Bool = false) {
        // stop scanning to preserve battery and free up radio to manage connection
        if !isReconnection {
            manager.stopScan()
        }

        // options dict provides instructions to handling notificaitons to user during connection and disconnection events while the app is backgrounded
        // The outcome of connect is success, fail, or no feedback
        // connection attempts don't timeout and it's possible the periph is no longer available. The next time the periph becomes avail, it may succesfully connect
        manager.connect(peripheral, options: nil)
        lastConnectedPeripheral = peripheral
    }

    func disconnectFromPeripheral() {
        // unset notifications then discconect from peripherals
        guard let lastConnectedPeripheral = lastConnectedPeripheral else {
            Log.info("No connected peripheral to disconnect from")
            return
        }
        
        subscribedCharacteristics[lastConnectedPeripheral.identifier.uuidString]?.forEach({ characteristic in
            Log.info("Unsetting notification for BLE characteristic: \(characteristic)")
            lastConnectedPeripheral.setNotifyValue(false, for: characteristic)
        })
        manager.cancelPeripheralConnection(lastConnectedPeripheral)
    }

    func reconnectToLastPeripheral() {
        guard let lastConnectedPeripheral = lastConnectedPeripheral else {
            Log.info("No previous peripheral had been connected")
            return
        }
        //directly returns list of found peripherals corresponding to the list of UUID passed in
        if let peripheral = manager.retrievePeripherals(withIdentifiers: [lastConnectedPeripheral.identifier]).first {
            connect(to: peripheral, isReconnection: true)
        }
    }

}

extension BluetoothService: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            scanForPeripherals()
        case .poweredOff, .unknown, .unsupported, .unauthorized, .resetting:
            Log.error("BLE central is unavailable: \(central.state.rawValue)")
        @unknown default:
            Log.error("BLE central is unavailable. Unhandled state: \(central.state.rawValue)")
        }
    }

    // on peripheral discovery. Updated RSSI or advertisementData also get rediscovered
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard peripheral.name == "BerryMed" else { return }
        
        let discoveredPeripheral = DiscoveredPeripheral(
            peripheral: peripheral,
            rssi: RSSI as! Int,
            advertisementData: advertisementData
        )

        if let existingPeripheralIndex = discoveredPeripherals.firstIndex(where: {$0.peripheral.identifier.uuidString == peripheral.identifier.uuidString}) {
            discoveredPeripherals[existingPeripheralIndex] = discoveredPeripheral
        } else {
            discoveredPeripherals.append(discoveredPeripheral)
        }

        self.bluetoothDiscovered = true
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Log.info("Central did connect to \(peripheral.identifier.uuidString)")
        lastConnectedPeripheral = peripheral
        // assign BLECentral as delegate to connected peripheral
        lastConnectedPeripheral?.delegate = self
        // send the services we're interested in the connected peripheral. If service is discovered, it'll hit the peripheralDidDiscoverServices method
        // passing in nil means search all possible services
        let targetServices: [CBUUID]? = [
            CBUUID(string: BLEIdentifiers.berryMedService),
        ]
        lastConnectedPeripheral?.discoverServices(targetServices)
        isDeviceConnected = true
    }

    // on connection failure events, not including timeout
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Log.error("Central failed to connect")
    }

    // invoked on ANY disconnect. However from iOS 6.0 the device remains connected for about 40-50 seconds (or more), so no didDiscoverPeripheral will be invoked in that timeframe.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isDeviceConnected = false
        discoveredPeripherals.removeAll()
        if let error = error {
            Log.error("didDisconnectPeripheral error: \(error.localizedDescription)")
            // TODO: to attempt to reconnect, you have to repeart process of service and characteristic discovery
        } else {
            Log.info("Disconnected from peripheral: \(peripheral.debugDescription)")
        }
    }
}

extension BluetoothService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            Log.error("peripheral failed to discover services: \(error.localizedDescription)")
        } else {
            peripheral.services?.forEach{ service in
                Log.info("Service discovered: \(service)")
                let targetCharacteristics: [CBUUID]? = [
                    CBUUID(string: BLEIdentifiers.berryMedCharacteristic),
                ]
                peripheral.discoverCharacteristics(targetCharacteristics, for: service)
            }
        }
    }

    // called once per service that is discovered
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            Log.error("peripheral failed to discover characters: \(error.localizedDescription)")
        } else {
            service.characteristics?.forEach{ characteristic in
                Log.info("characaterstic discover: \(characteristic)")


                if characteristic.properties.contains(.notify) {
                    // subscribe to target characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    subscribedCharacteristics[peripheral.identifier.uuidString, default: []].append(characteristic)
                // default to plain one-shot reading if characteristic notification is not enabled
                } else if characteristic.properties.contains(.read)  {// .read is 0x2
                    peripheral.readValue(for: characteristic)
                }
                // then query each characteristic for descriptors
                peripheral.discoverDescriptors(for: characteristic)
            }
        }
    }

    // called per characteristic after peripheral.discoverDescriptors
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            Log.error("peripheral failed to discover characters: \(error.localizedDescription)")
        } else {
            characteristic.descriptors?.forEach{ descriptor in
                Log.info("Descriptor discovered: \(descriptor)")
                peripheral.readValue(for: descriptor) // no need to check if desc has read property
            }
        }
    }

    /*
     The following two delegates must be implemented when you try to readValue, respectively, for
     peripheral.readValue(for: characteristic)
     peripheral.readValue(for: descriptor)
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            Log.error("peripheral failed to discover character: \(error.localizedDescription)")
        } else {

            if let updatedValue = characteristic.value, characteristic.uuid.description == BLEIdentifiers.berryMedCharacteristic {
                self.receivedBytes = updatedValue
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            Log.error("Peripheral failed to discover descriptor: \(error.localizedDescription)")
        } else {
            Log.info("Descriptor value descriptor: \(descriptor)")
        }
    }
}

struct DiscoveredPeripheral {
    let peripheral: CBPeripheral
    let rssi: Int
    let advertisementData: [String: Any]
}

enum BLEIdentifiers {
    static let berryMedService = "49535343-FE7D-4AE5-8FA9-9FAFD205E455" // heartbeat GATT service
    static let berryMedCharacteristic = "49535343-1E4D-4BD9-BA61-23C647249616" // "receive" characteristic of heartbeat service
}
