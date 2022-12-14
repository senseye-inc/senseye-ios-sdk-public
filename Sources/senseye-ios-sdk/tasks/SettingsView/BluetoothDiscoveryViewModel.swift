//
//  DiscoveryViewModel.swift
//  
//
//  Created by Frank Oftring on 9/26/22.
//

import SwiftUI
import Combine

@available(iOS 14.0, *)
class BluetoothDiscoveryViewModel: ObservableObject {
    
    @Published var discoveredPeripheral: DiscoveredPeripheral?
    var bluetoothService: BluetoothService
    var fileUploadService: FileUploadAndPredictionService
    
    // TODO: move to different module?
    var receivedBytes: [Data] = []
    var startConnectionTimestamp: Int64 = 0
    var endConnectionTimestamp: Int64 = 0
    var parser: HeartParamsParsingProtocol = BerryMedPulseOx()
    var cancellables = Set<AnyCancellable>()
    
    init(bluetoothService: BluetoothService, fileUploadService: FileUploadAndPredictionService) {
        self.bluetoothService = bluetoothService
        self.fileUploadService = fileUploadService

        addSubscribers()
    }
    
    func addSubscribers() {
        bluetoothService.$discoveredPeripherals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peripherals in
                guard let self = self, !peripherals.isEmpty else { return }
                self.discoveredPeripheral = peripherals.sorted(by: {$0.rssi > $1.rssi }).first
            }
            .store(in: &cancellables)
        
        bluetoothService.$receivedBytes
            .receive(on: DispatchQueue.main)
            .compactMap({ $0 })
            .sink { [weak self] receivedByte in
                self?.receivedBytes.append(receivedByte)
            }
            .store(in: &cancellables)
        
        bluetoothService.$isDeviceConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDeviceConnected in
                if isDeviceConnected {
                    self?.startConnectionTimestamp = Date().currentTimeMillis()
                    Log.info("BLE startConnectionTimestamp \(String(describing: self?.startConnectionTimestamp))")
                }
            }
            .store(in: &cancellables)
        
        fileUploadService.$shouldStopBluetooth
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldStopBluetooth in
                guard let self = self else { return }
                if shouldStopBluetooth {
                    self.endConnectionTimestamp = Date().currentTimeMillis()
                    self.bluetoothService.disconnectFromPeripheral()
                    self.addTaskInfoToJson()
                    self.reset()
                }
            }
            .store(in: &cancellables)
    }
    
    func connect() {
        if let discoveredPeripheral = self.discoveredPeripheral {
            bluetoothService.connect(to: discoveredPeripheral.peripheral)
        }
    }

    func addTaskInfoToJson() {
        let heartParams: [HeartParams] = parser.parse(dataStream: Data(receivedBytes.joined()), startEndTimestamps: [startConnectionTimestamp, endConnectionTimestamp])
        let taskInfo = SenseyeTask(
            taskID: "heartrate",
            frameTimestamps: [startConnectionTimestamp, endConnectionTimestamp],
            timestamps: heartParams.map { $0.timestamp },
            plethysmograph: heartParams.map { $0.plethysmograph },
            pulseRate: heartParams.map { $0.pulseRate },
            spo2: heartParams.map { $0.spo2 }
        )
        Log.info("Adding Heart Rate data points of \(String(describing: taskInfo.timestamps?.count)) elements")
        fileUploadService.addTaskRelatedInfo(for: taskInfo)
    }

    func reconnectToLastPeripheral() {
        bluetoothService.reconnectToLastPeripheral()
    }

    func reset() {
        receivedBytes = []
        startConnectionTimestamp = 0
        endConnectionTimestamp = 0
    }
}
