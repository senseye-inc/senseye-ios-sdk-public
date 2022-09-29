//
//  BluetoothService.swift
//  
//
//  Created by Frank Oftring on 9/21/22.
//

import Foundation

import CoreBluetooth

class BluetoothService: NSObject, ObservableObject {
    // Service Module


    // provide capability to discover and connect to peripherals
    private var manager: CBCentralManager!

    // It's required that we keep local copy of peripherals we want to perform commands on

    @Published private(set) var discoveredPeripherals: [DiscoveredPeripheral] = []
    @Published var isDeviceConnected: Bool = false

    private var connectedPeripheral: CBPeripheral?
    private let decoder = JSONDecoder()

    // let clients know that perip lists have been updated by providing an optional closure they can use
    var onDiscovered: (()->())?
    var onDataUpdated: ((StreamingDataModel)->())?
    var onConnected: (()->())?

    private let centralManagerOptions: [String: Any] = [
        CBCentralManagerOptionRestoreIdentifierKey: "myCentralIdentifier"     // TODO: use for state preservation and restoration
    ]

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
        Log.info("BluetoothService Initialized")
    }

    func scanForPeripherals() {

        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: false]

        // withServices is an array of CBUUID debices we want to filter for. withServices: nil means find anything and everything
        manager.scanForPeripherals(withServices: nil, options: options)
    }

    func connect(to peripheral: CBPeripheral) {

        // before trying to connect, we should stop scanning periphs to preserve batt and free up radio to manage connectiosn
        manager.stopScan()

        // options dict provides insturctions to handling notificaitons to user during connection and disconnection events while the app is backgrounded
        // The outcome of connect is success, fail, or no feedback
        // connection attempts don't timeout and it's possible the periph is no longer available. The next ttime the periph becomes avail, it may succesfuuly conect
        manager.connect(peripheral, options: nil)

    }

}

extension BluetoothService: CBCentralManagerDelegate {
    // MARK: - CBCentralManagerDelegate
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            scanForPeripherals()

            // TODO: reinstate state after disconnect
            /*
            if let lastConnectedPeripheral = connectedPeripheral {
                central.connect(lastConnectedPeripheral, options: nil)
            } else {
                scanForPeripherals()
            }
             */
        case .poweredOff, .unknown, .unsupported, .unauthorized, .resetting:
            Log.error("central is unavail: \(central.state.rawValue)")

        @unknown default:
            Log.error("central is unavail. Unhandled state: \(central.state.rawValue)")
        }
    }

    // anytime a peripheral is discovered, this delegate is notified. If it's a periph with updated RSSI or advertisementData, it'll technically get rediscovered
    func centralManager(
        _ central: CBCentralManager, // the central mgr that invoked this method
        didDiscover peripheral: CBPeripheral, // the periph discoverd
        advertisementData: [String: Any], // dict that contains several optional pcs of info about the periph
        rssi RSSI: NSNumber // current received signal strength. a diff rssi makes a new notification
    ) {
        guard peripheral.name == "BerryMed" else { return }
        
        let discoveredPeripheral = DiscoveredPeripheral(
            peripheral: peripheral,
            rssi: RSSI as! Int,
            advertisementData: advertisementData
        )

        // if the peripheral that was discovered is just an update to its RSSI or advert data, then update that periph in our list, else add new periphs to our list
        // TODO: I think this logic needs fixing
        if let existingPeripheralIndex = discoveredPeripherals.firstIndex(where: {$0.peripheral.identifier.uuidString == peripheral.identifier.uuidString}) {
            Log.info("duplicate found \(String(describing: discoveredPeripheral.peripheral.name)) \(discoveredPeripheral.peripheral.identifier.uuidString)")
            discoveredPeripherals[existingPeripheralIndex] = discoveredPeripheral

        } else {
            discoveredPeripherals.append(discoveredPeripheral)
        }
        // let clients know that perip lists have been updated by providing an optional closure they can use
        onDiscovered?()

    }

    // on connection to a periph, this is called
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Log.info("Central did connect to \(peripheral.identifier.uuidString)")
        connectedPeripheral = peripheral
        // assign BLECentral as delegate to connected peripheral
        connectedPeripheral?.delegate = self
        // send the services we're interested in the connected peripheral. If service is discovered, it'll hit the peripheralDidDiscoverServices method
        // passing in nil means search all possible services
        let targetServices: [CBUUID]? = [
            CBUUID(string: BLEIdentifiers.berryMedService),
        ]
        connectedPeripheral?.discoverServices(targetServices)
        isDeviceConnected = true
        onConnected?()

    }

    // this event is specifically when connection failure occurs, not including timeout. We need to set a connection attempt timeout elsewhere
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Log.error("Central failed to connect")
    }

    // called on any disconnect
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isDeviceConnected = false
        discoveredPeripherals.removeAll()
        Log.info("Disconnecting from peripheral: \(peripheral.name)")
        if let error = error {
            Log.error("didDisconnectPeripheral error: \(error.localizedDescription)")
            // TODO: to attempt to reconnect, you have to repeart process of service and characteristic discovery
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
//                    CBUUID(string: BLEIdentifiers.myCharacteristicIdentifier)
                ]

                // passing in nil means find all characteristics
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
            Log.info("Characteristic value updated \(characteristic)")

            // when new value is udpated to the characteristic, do something with it for the app
            if let value = characteristic.value, let deviceData = try? decoder.decode(StreamingDataModel.self, from: value) {
                Log.info("\(deviceData)")
                onDataUpdated?(deviceData)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            Log.error("peripheral failed to discover descriptor: \(error.localizedDescription)")
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

protocol SomeStreamingDataProtocol {
    var onUpdate: ((StreamingDataModel)->())? { get set }
    func start()
    func stop()
}

struct StreamingDataModel: Codable {
    let timestamp: TimeInterval
    let dataPoint1: Double
    let dataPoint2: Double
    let dataPoint3: Double
}

enum BLEIdentifiers {
    static let berryMedService = "49535343-FE7D-4AE5-8FA9-9FAFD205E455" // heartbeat GATT service
    static let berryMedCharacteristic = "49535343-1E4D-4BD9-BA61-23C647249616" // "receive" characteristic of heartbeat service
}
