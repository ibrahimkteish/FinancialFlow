//
//  RateFeature.swift
//  DeviceValueApp
//
//  Created by Ibrahim Kteish on 28/3/25.
//

import ComposableArchitecture
import Models

@Reducer
public struct CurrencyRateFeature: Sendable {

  @ObservableState
  public struct State: Equatable, Sendable, Identifiable {
    public var id: Int64 { self.currency.id! }
    public var currency: Currency
    public var usdRate: String
    public var updated: Bool {
      self.initialRate != self.currency.usdRate
    }

    private var initialRate: Double

    public init(currency: Currency) {
      self.currency = currency
      self.usdRate = "\(currency.usdRate)"
      self.initialRate = currency.usdRate
    }
  }

  public enum Action: Equatable, BindableAction, Sendable {
    case binding(BindingAction<State>)
    case delete
    case delegate(Delegate)
    case changeRate(Double)

    public enum Delegate: Equatable, Sendable {
      case didChangeRate
      case delete
    }
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
        case .binding:
          guard let usdRate = Double(state.usdRate.replacingOccurrences(of: ",", with: ".")) else { return .none }
          state.currency.usdRate = usdRate
          return .none
        case .delete:
          return .send(.delegate(.delete))
        case let .changeRate(rate):
          state.currency.usdRate = rate
          return .none
        case .delegate:
          return .none
      }
    }
    ._printChanges()
  }
}
