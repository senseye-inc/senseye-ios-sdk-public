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
    var bluetoothService: BluetoothService?
    var fileUploadService: FileUploadAndPredictionService?

    // TODO: move to different module?
    var receivedBytesTimestamps: [Int64] = []
    var receivedBytes: [Data] = []
    var startTimestamp: Int64 = 0
    var stopTimestamp: Int64 = 0

    var cancellables = Set<AnyCancellable>()
    
    init(bluetoothService: BluetoothService, fileUploadService: FileUploadAndPredictionService) {
        bluetoothService.onConnected = { [weak self] in
            self?.startTimestamp = Date().currentTimeMillis()
        }

        bluetoothService.onDataUpdated = { data in
            self.receivedBytes.append(data)
            self.receivedBytesTimestamps.append(Date().self.currentTimeMillis())
        }
        self.bluetoothService = bluetoothService

        fileUploadService.stopBluetooth = {
            self.stopTimestamp = Date().currentTimeMillis()
            self.bluetoothService?.disconnectFromPeripheral()
            self.addTaskInfoToJson()
        }
        self.fileUploadService = fileUploadService
        addBLESubscriber()
    }
    
    func addBLESubscriber() {
        guard let bluetoothService = bluetoothService else {
            return
        }
        
        bluetoothService.$discoveredPeripherals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peripherals in
                guard let self = self else { return }
                self.discoveredPeripheral = peripherals.first
            }
            .store(in: &cancellables)
    }
    
    func connect() {
        if let discoveredPeripheral = self.discoveredPeripheral {
            bluetoothService?.connect(to: discoveredPeripheral.peripheral)
        }
    }

    func addTaskInfoToJson() {
        let taskInfo = SenseyeTask(taskID: "heartrate", frameTimestamps: [startTimestamp, stopTimestamp], timestamps: receivedBytesTimestamps, rawData: receivedBytes)
        fileUploadService?.addTaskRelatedInfo(for: taskInfo)
    }
}
