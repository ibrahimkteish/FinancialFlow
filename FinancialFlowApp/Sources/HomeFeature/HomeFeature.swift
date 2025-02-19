//
//  HomeFeature.swift
//  FinancialFlowApp
//
//  Created by Ibrahim Koteish on 15/2/25.
//

import ComposableArchitecture
import Models
import SharingGRDB
import AddDeviceFeature

@Reducer
public struct HomeReducer: Sendable {

    @Reducer(state: .equatable, .sendable, action: .equatable, .sendable)
    public enum Destination {
        case addDevice(AddDeviceReducer)
    }
    
    @ObservableState
    public struct State: Equatable, Sendable {
        
        @Presents
        public var destination: Destination.State?

        @SharedReader
        public var devices: [Items.State]

        @Shared(.inMemory("order"))
        var ordering: Ordering = .created
        
        public init() {
            _devices = SharedReader.init(.fetch(Items(ordering: .created)))
        }
    }
    
    public enum Ordering: String, Equatable, Sendable, CaseIterable {
        case updatedAt = "updatedAt"
        case created = "createdAt"
        case name = "name"
        case currency = "currencyId"
        case price = "purchasePrice"
        

        var orderingTerm: any SQLOrderingTerm & Sendable {
            switch self {
            case .updatedAt: return Column("updatedAt")
            case .created: return Column("createdAt")
            case .name: return Column("name")
            case .currency: return Column("currencyId")
            case .price: return Column("purchasePrice")
            }
        }
    }
    
    public struct Items: FetchKeyRequest {
        public let ordering: Ordering
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
        
        public init(ordering: Ordering) {
            self.ordering = ordering
        }
        
        public func fetch(_ db: Database) throws -> [State] {
            // Use raw SQL to join the tables
            let sql = Device.all()
                .including(required: Device.currency)
                .including(required: Device.usageRatePeriod)
                .order(ordering.orderingTerm)
            
            // Execute the query and map results
            return try Row.fetchAll(db, sql).map { row in
                State(device: try Device(row: row), currency: row["currency"], usageRatePeriod: row["usage_rate_period"])
            }
        }
    }
    
    public enum Action: Equatable {
        case addDeviceButtonTapped
        case cancelAddDeviceButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case removeDevice(Int64)
        case onAppear
        case onSortChanged(Ordering)
        case submitButtonTapped
    }
    
    @Dependency(\.defaultDatabase) var database
    
    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addDeviceButtonTapped:
                state.destination = .addDevice(AddDeviceReducer.State())
                return .none
            case .cancelAddDeviceButtonTapped:
                state.destination = nil
                return .none
            case let .removeDevice(id):
                return .run { _ in
                    _ = try await database.write { db in
                        try Device.deleteOne(db, id: id)
                    }
                }
            case .onAppear:
                return .none
            case let .onSortChanged(newSort):
                state.$ordering.withLock { $0 = newSort }
                return .run { [state] _ in
                    try await state.$devices.load(.fetch(HomeReducer.Items(ordering: state.ordering)))
                }
                    
            case .submitButtonTapped:
                state.destination = nil
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
