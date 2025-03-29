//
//  DeviceCardView.swift
//  DeviceValueApp
//
//  Created by Ibrahim Koteish on 16/2/25.
//

import Generated
import GRDB
import Models
import SwiftUI
import Utils

public struct DeviceCardView: View {

  public let data: HomeFeature.Items.State
  @State private var isPressed: Bool = false
  @Environment(\.colorScheme) private var colorScheme

  // Neumorphic colors based on color scheme
  private var surfaceColor: Color {
    self.colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.93)
  }

  private var shadowColor: Color {
    self.colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.85)
  }

  private var highlightColor: Color {
    self.colorScheme == .dark ? Color(white: 0.3) : .white
  }

  private var innerShadowColor: Color {
    self.colorScheme == .dark ? .black.opacity(0.5) : .gray.opacity(0.3)
  }

  init(data: HomeFeature.Items.State) {
    self.data = data
  }

  // Convert elapsed days into the number of usage periods.
  var elapsedPeriodCount: Double {
    let days = Double(data.device.elapsedDays)
    return days / Double(self.data.usageRatePeriod.daysMultiplier)
  }

  // Calculate the accumulated cost using the usage rate per period.
  var accumulatedCost: Double {
    self.data.device.usageRate * self.elapsedPeriodCount
  }

  // Calculate remaining cost.
  var remainingCost: Double {
    max(self.data.device.purchasePrice - self.accumulatedCost, 0)
  }

  // Calculate progress as a value between 0 and 1.
  var progress: Double {
    min(self.accumulatedCost / self.data.device.purchasePrice, 1.0)
  }

  // Dynamic gradient based on progress
  var progressGradient: LinearGradient {
    if self.progress >= 1.0 {
      return LinearGradient(
        colors: [.green, .green.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    } else {
      return LinearGradient(
        colors: [.blue, .blue.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
  }

  var progressColor: Color {
    self.progress >= 1.0 ? .green : .accentColor
  }

  // MARK: - View Components

  @ViewBuilder
  private var deviceNameView: some View {
    Text(data.device.name)
      .font(.title2.bold())
      .foregroundStyle(.primary)
  }

  @ViewBuilder
  private var purchaseInfoView: some View {
    Text(Strings.purchasedFor(data.device.purchasePrice.formatted(.currency(code: data.currency.code))))
      .font(.subheadline)
      .foregroundStyle(.secondary)
  }

  @ViewBuilder
  private var usagePeriodView: some View {
    Text(
      Strings.usedFor(
        data.device.elapsedDays,
        String(format: "%.1f", elapsedPeriodCount),
        data.usageRatePeriod.localizedName
      )
    )
    .font(.subheadline)
    .foregroundStyle(.secondary)
  }

  @ViewBuilder
  private var rateView: some View {
    Text(
      Strings
        .rate(data.device.usageRate.formatted(.currency(code: data.currency.code)), data.usageRatePeriod.name)
    )
    .font(.subheadline)
    .foregroundStyle(.secondary)
  }

  @ViewBuilder
  private var remainingDays: some View {
    let perDay = Double(data.device.usageRate / Double(data.usageRatePeriod.daysMultiplier))
    let days = (data.device.purchasePrice / perDay) - Double(data.device.elapsedDays)
    if days > 0 {
      Text(Strings.remainingDays(days.formatted(.number)))
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  @ViewBuilder
  private var remainingCostView: some View {
    Text(Strings.remainingCost(remainingCost.formatted(.currency(code: data.currency.code))))
      .font(.headline)
      .foregroundStyle(progressColor)
  }

  @ViewBuilder
  private var deviceInfoStack: some View {
    VStack(alignment: .leading, spacing: 8) {
      deviceNameView
        .padding(.trailing, 60)
      purchaseInfoView
      usagePeriodView
      rateView
      remainingDays
      remainingCostView
    }
  }

  @ViewBuilder
  private var cardBackground: some View {
    ZStack {
      // Base layer
      RoundedRectangle(cornerRadius: 16)
        .fill(surfaceColor)
        .overlay {
          if !isPressed {
            // Outset effect
            LinearGradient(
              colors: [
                highlightColor.opacity(0.5),
                shadowColor.opacity(0.5)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
            .opacity(0.2)
          } else {
            // Inset effect
            LinearGradient(
              colors: [
                shadowColor.opacity(0.5),
                highlightColor.opacity(0.5)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
            .opacity(0.2)
          }
        }
    }
  }

  @ViewBuilder
  private var progressCircle: some View {
    ZStack {
      // Base circle with gradient overlay
      Circle()
        .fill(surfaceColor)
        .overlay {
          Circle()
            .fill(
              LinearGradient(
                colors: [
                  highlightColor.opacity(0.5),
                  shadowColor.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .opacity(0.2)
        }

      // Progress track
      Circle()
        .trim(from: 0, to: 1)
        .stroke(
          progressColor,
          style: StrokeStyle(
            lineWidth: 4,
            lineCap: .round
          )
        )
        .opacity(0.2)

      // Progress indicator
      Circle()
        .trim(from: 0, to: progress)
        .stroke(
          progressColor,
          style: StrokeStyle(
            lineWidth: 4,
            lineCap: .round
          )
        )
        .rotationEffect(.degrees(-90))

      VStack(spacing: 2) {
        Text("\(Int(progress * 100))%")
          .font(.system(.subheadline, design: .rounded).bold())
          .foregroundStyle(progressColor)
        Text(Strings.used)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 70, height: 70)
  }

  public var body: some View {
    ZStack(alignment: .topTrailing) {
      progressCircle
      deviceInfoStack
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(20)
    .background(cardBackground)
    .scaleEffect(isPressed ? 0.98 : 1.0)
    .animation(.spring(response: 0.3), value: isPressed)
    .onTapGesture {
      withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            isPressed = false
          }
        }
      }
    }
  }
}

#if DEBUG
#Preview {
  VStack {
    DeviceCardView(
      data: .init(
        device: .init(
          name: "Sennheiser PXC 550",
          currencyId: 1,
          purchasePrice: 500,
          purchaseDate: Date(year: 2017, month: 6, day: 15),
          usageRate: 0.5,
          usageRatePeriodId: 1
        ),
        currency: .usd,
        usageRatePeriod: .day
      )
    )

    DeviceCardView(
      data: .init(
        device: .init(
          name: "iPhone 13 Pro",
          currencyId: 1,
          purchasePrice: 1599.99,
          purchaseDate: Date(year: 2022, month: 9, day: 16),
          usageRate: 7,
          usageRatePeriodId: 2
        ),
        currency: .usd,
        usageRatePeriod: .week
      )
    )

    DeviceCardView(
      data: .init(
        device: .init(
          name: "MacBook Pro",
          currencyId: 1,
          purchasePrice: 1599.99,
          purchaseDate: Date(year: 2022, month: 9, day: 16),
          usageRate: 30,
          usageRatePeriodId: 3
        ),
        currency: .usd,
        usageRatePeriod: .month
      )
    )
  }
  .preferredColorScheme(.dark)
}
#endif

extension UsageRatePeriod {
  var localizedName: String {
    switch self.name {
      case "day":
        return Strings.day
      case "week":
        return Strings.week
      case "month":
        return Strings.month
      case "year":
        return Strings.year
      default:
        return "day"
    }
  }
}
