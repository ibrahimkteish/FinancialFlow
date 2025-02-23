// AddDeviceFeature.swift
// created by: @ibrahim koteish
// created at: 2025-02-18

import ComposableArchitecture
import Models
import Foundation
import GRDB
import SharingGRDB

@Reducer
public struct AddDeviceReducer: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        var deviceName: String
        var selectedCurrencyId: Int64
        var purchasePrice: String
        var purchaseDate: Date
        var usageRate: String
        var selectedUsageRatePeriodId: Int64
        var currencies: [Currency]
        var usageRatePeriods: [UsageRatePeriod]
        var isValid: Bool {
            !deviceName.isEmpty && 
            Double(purchasePrice) != nil && 
            Double(usageRate) != nil
        }
        
        public init(
            deviceName: String = "",
            selectedCurrencyId: Int64 = Currency.usd.id!,
            purchasePrice: String = "",
            purchaseDate: Date = .now,
            usageRate: String = "",
            selectedUsageRatePeriodId: Int64 = UsageRatePeriod.day.id!,
            currencies: [Currency] = [.usd, .eur, .gbp],
            usageRatePeriods: [UsageRatePeriod] = [.day, .week, .month, .year]
        ) {
            self.deviceName = deviceName
            self.selectedCurrencyId = selectedCurrencyId
            self.purchasePrice = purchasePrice
            self.purchaseDate = purchaseDate
            self.usageRate = usageRate
            self.selectedUsageRatePeriodId = selectedUsageRatePeriodId
            self.currencies = currencies
            self.usageRatePeriods = usageRatePeriods
        }
    }

    public enum Action: BindableAction, Equatable, Sendable {
        case binding(BindingAction<State>)
        case submitButtonTapped
        case cancelButtonTapped
        case delegate(Delegate)
        
        @CasePathable
        public enum Delegate: Equatable, Sendable {
            case didAddDevice(Device)
            case dismiss
        }
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.defaultDatabase) var database

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .cancelButtonTapped:
                return .run { _ in
                    await dismiss()
                }
                
            case .submitButtonTapped:
                guard 
                    let price = Double(state.purchasePrice),
                    let rate = Double(state.usageRate)
                else {
                    return .none
                }
                
                let device = Device(
                    name: state.deviceName,
                    currencyId: state.selectedCurrencyId,
                    purchasePrice: price,
                    purchaseDate: state.purchaseDate,
                    usageRate: rate,
                    usageRatePeriodId: state.selectedUsageRatePeriodId
                )
                
                return .run { _ in
                    try await database.write { db in
                        var device_ = device
                        _ = try device_.insert(db)
                    }
                }
                
            case .delegate:
                return .none
            }
        }
    }
}

