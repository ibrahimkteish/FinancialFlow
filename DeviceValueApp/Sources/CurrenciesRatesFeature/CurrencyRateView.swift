import ComposableArchitecture
import Generated
import SwiftUI

public struct CurrencyRateView: View {
  @Bindable var store: StoreOf<CurrencyRateFeature>

  public init(store: StoreOf<CurrencyRateFeature>) {
    self.store = store
  }

  public var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(store.currency.symbol)
            .font(.headline)
            .foregroundColor(.primary)
          Text(store.currency.name)
            .font(.headline)
        }
        Text(store.currency.code)
          .font(.subheadline)
          .foregroundColor(.secondary)
      }

      Spacer()

      if store.currency.code == "USD" {
        Text(Strings.base)
          .foregroundColor(.secondary)
          .fontWeight(.medium)
      } else {
        VStack(alignment: .trailing) {
          TextField("", text: $store.usdRate)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .padding(4)
            .frame(width: 100)
            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))

          Text(self.store.currency.usdRate.formatted(.currency(code: store.currency.code)))
            .foregroundColor(.secondary)
            .fontWeight(.medium)

        }
      }
    }
    .padding(.vertical, 4)
    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
      if store.currency.code != "USD" {
        Button(role: .destructive) {
          store.send(.delete)
        } label: {
          Label(Strings.delete, systemImage: "trash")
        }
      }
    }
  }
}
