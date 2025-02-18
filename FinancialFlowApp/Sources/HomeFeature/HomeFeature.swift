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
        var devices: [Items.State]
        
        public init() {}
    }
    
    
    public struct Items: FetchKeyRequest {
        public struct State: Equatable, Sendable  {
            
            public var id: Int64? {
                self.device.id
            }
            public let device: Device
            public let currency: Currency
            public let usageRatePeriod: UsageRatePeriod
            
            public init(
                device: Device,
                currency: Currency,
                usageRatePeriod: UsageRatePeriod
            ) {
                self.device = device
                self.currency = currency
                self.usageRatePeriod = usageRatePeriod
            }
        }
        
        public func fetch(_ db: Database) throws -> [State] {
            // Use raw SQL to join the tables
            let sql = Device.all()
                .including(required: Device.currency)
                .including(required: Device.usageRatePeriod)
            
            // Execute the query and map results
            return try Row.fetchAll(db, sql).map { row in
                State(device: try Device(row: row), currency: row["currency"], usageRatePeriod: row["usage_rate_period"])
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
