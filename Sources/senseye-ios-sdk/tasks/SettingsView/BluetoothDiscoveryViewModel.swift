//
//  DiscoveryViewModel.swift
//  
//
//  Created by Frank Oftring on 9/26/22.
//

import SwiftUI
import Combine

class BluetoothDiscoveryViewModel: ObservableObject {
    
    @Published var discoveredPeripheral: DiscoveredPeripheral?
    var bluetoothService: BluetoothService?
    var onConnected: (()->())? // TODO: do something
    
    var cancellables = Set<AnyCancellable>()
    
    init(bluetoothService: BluetoothService) {
        self.bluetoothService = bluetoothService
        addBLESubscriber()
        self.bluetoothService?.onConnected = { [weak self] in
            self?.onConnected?()
        }
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
}
