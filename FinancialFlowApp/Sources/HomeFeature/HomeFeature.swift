//
//  HomeFeature.swift
//  FinancialFlowApp
//
//  Created by Ibrahim Koteish on 15/2/25.
//

import ComposableArchitecture
import Models
import SharingGRDB

@Reducer
public struct AddDeviceReducer {}

@Reducer
public struct HomeReducer: Sendable {
    
    @Reducer(state: .equatable, .sendable, action: .equatable, .sendable)
    public enum Path {
        case addDevice(AddDeviceReducer)
    }
    
    @ObservableState
    public struct State: Equatable {
        var path = StackState<Path.State>()
        
        @SharedReader(.fetch(Items(), animation: .default))
        public var devices: [DeviceCard]
        
        public init() {}
        
        
        private struct Items: FetchKeyRequest {
            func fetch(_ db: Database) throws -> [DeviceCard] {
                var retDevices = [DeviceCard]()
                
                let devices =  try Device
                    .fetchAll(db)
                for device in devices {
                    guard let currency = try Currency.fetchOne(db, key: device.currencyId),
                          let usageRatePeriod = try UsageRatePeriod.fetchOne(db, key: device.usageRatePeriodId) else {
                        continue
                    }
                    
                    let deviceCard = DeviceCard(device: device, currency: currency, usageRatePeriod: usageRatePeriod)
                    retDevices.append(deviceCard)
                }
                return retDevices
            }
        }
    }
    
    public enum Action: Equatable {
        case addDevice(Device)
        case removeDevice(Int64)
        case onAppear
        case path(StackAction<Path.State, Path.Action>)

    }
    
    @Dependency(\.defaultDatabase) var database
    
    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addDevice(let device):
                return .run { _ in
                    try await database.write { db in
                        var device_ = device
                        _ = try device_.insert(db)
                    }
                }
            case let .removeDevice(id):
                return .run { _ in
                    _ = try await database.write { db in
                        try Device.deleteOne(db, id: id)
                    }
                }
            case .onAppear:
                return .none
            
            case .path:
                return .none
        }
        }
        .forEach(\.path, action: \.path)
    }
}
