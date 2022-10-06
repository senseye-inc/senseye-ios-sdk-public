//
//  BerryMedPulseOx.swift
//  
//
//  Created by Bobby Srisan on 9/30/22.
//

import Foundation

protocol HeartParamsParsingProtocol {
    func parse(dataStream: Data) -> [HeartParams]
}

struct HeartParams: Codable {
    let plethysmograph: UInt8 // value for plethysmograph https://www.amperordirect.com/pc/help-pulse-oximeter/z-what-is-pi.html
    let pulseRate: UInt8   // beats per minute
    let spo2: UInt8       // blood oxygen level

    enum CodingKeys: String, CodingKey {
        case plethysmograph, spo2
        case pulseRate = "pulse_rate"
    }
}

struct BerryMedPulseOx: HeartParamsParsingProtocol {
    // TODO: barGraph, signalStrength, noSignal, probeUnplugged, pulseBeep, noFinger, pulseResearch

    private struct Constants {
        static let berrymedDataPackSize: Int = 5
        static let bitIndexOfHeader: UInt8 = 7

        static let byteIndexOfPlethysmographBits = 1
        static let byteIndexOfPulseRateBits7 = 2
        static let byteIndexOfPulseRateBits0_6 = 3
        static let byteIndexOfSpo2Bits = 4

        static let invalidPulseRate: UInt8 = 0xFF
        static let invalidSpo2: UInt8 = 0x7F
        static let invalidPlethysmograph: UInt8 = 0x00
    }

    private enum ParamType {
        case plethysmograph
        case pulseRate
        case spo2
    }

    func parse(dataStream: Data) -> [HeartParams] {
        var dataPoints: [HeartParams] = []
        let headerIndices = getHeaderIndicesOfCompletePackets(dataStream: dataStream)
        for headerIndex in headerIndices {
            if let dataPoint = parse(dataPacket: Data(dataStream[headerIndex...(headerIndex+4)])) {
                dataPoints.append(dataPoint)
            } else {
                Log.info("unable to parse a datapoint")
            }
        }
        return dataPoints
    }

    // bit indexing is MSb to LSb, left to right
    // The BCI protocol consists of 5 Bytes https://github.com/zh2x/BCI_Protocol/blob/master/BCI%20Protocol%20V1.2.pdf
    // the most sig bit of the zeroth byte is the package head and should be 1, the most significant bit of the next four bytes should be 0.
    // assumes bytes have already been checked for alignment (bit 7
    private func parse(dataPacket: Data) -> HeartParams? {
        if dataPacket.count == Constants.berrymedDataPackSize, dataPacket[0].isBitSet(atIndex: Constants.bitIndexOfHeader) {
            var plethysmograph: UInt8 = dataPacket[Constants.byteIndexOfPlethysmographBits]
            var pulseRate: UInt8 = dataPacket[Constants.byteIndexOfPulseRateBits0_6] | (dataPacket[Constants.byteIndexOfPulseRateBits7].isolateBit(atIndex: 6)).shift(.right, by: 1)
            var spo2: UInt8 = dataPacket[Constants.byteIndexOfSpo2Bits]
            plethysmograph = sanitize(value: plethysmograph, for: .plethysmograph)
            pulseRate = sanitize(value: pulseRate, for: .pulseRate)
            spo2 = sanitize(value: spo2, for: .spo2)
            return HeartParams(plethysmograph: plethysmograph, pulseRate: pulseRate, spo2: spo2)
        } else {
            Log.info("Package data length is not \(Constants.berrymedDataPackSize) Bytes")
            return nil
        }
    }

    private func getHeaderIndicesOfCompletePackets(dataStream: Data) -> [Int] {
        var headerByteIndices: [Int] = []
        // find header bytes ie bytes where the MSb is set
        for (i, byte) in dataStream.enumerated() {
            if byte.isBitSet(atIndex: Constants.bitIndexOfHeader) {
                headerByteIndices.append(i)
            }
        }

        var indicesOfIncompletePackets: Set<Int> = []

        if headerByteIndices.isEmpty {
            return headerByteIndices
        } else {
            // verify header bytes are 5 bytes apart. remove any that isn't 5 bytes away from the next
            for i in 1...(headerByteIndices.count-1) {
                if (headerByteIndices[i] - headerByteIndices[i-1]) != Constants.berrymedDataPackSize {
                    indicesOfIncompletePackets.insert(headerByteIndices[i-1])
                }
            }

            if let last = headerByteIndices.last, (dataStream.count - last) != Constants.berrymedDataPackSize {
                indicesOfIncompletePackets.insert(last)
            }
        }

        return Set(headerByteIndices).subtracting(indicesOfIncompletePackets).sorted()
    }

    private func sanitize(value: UInt8, for type: ParamType) -> UInt8 {
        switch type {
        case .plethysmograph: return value == Constants.invalidPlethysmograph ? 0 : value
        case .spo2: return value == Constants.invalidSpo2 ? 0 : value
        case .pulseRate: return value == Constants.invalidPulseRate ? 0 : value
        }
    }
}

fileprivate extension UInt8 {
    enum Direction {
        case left
        case right
    }

    func shift(_ direction: Direction, by places: UInt8) -> UInt8 {
        switch direction {
        case .left: return self >> places
        case .right: return self << places
        }
    }

    func isolateBit(atIndex index: UInt8) -> UInt8 {
        let mask = UInt8(0x01).shift(.right, by: index)
        return self & mask
    }

    func isBitSet(atIndex index: UInt8) -> Bool {
        let mask = UInt8(0x01).shift(.right, by: index)
        return self.isolateBit(atIndex: index) == mask
    }
}
