//
//  DeviceCardView.swift
//  FinancialFlowApp
//
//  Created by Ibrahim Koteish on 16/2/25.
//

import SwiftUI
import Models
import Utils
import GRDB


public struct DeviceCardView: View {
    
    public let data: HomeReducer.Items.State
    
    init(data: HomeReducer.Items.State) {
        self.data = data
    }

    // Convert elapsed days into the number of usage periods.
    // For example, if usageRatePeriod.daysMultiplier is 7 (for a week),
    // then 14 days equals 2 periods.
    var elapsedPeriodCount: Double {
        let days = Double(data.device.elapsedDays)
        return days / Double(data.usageRatePeriod.daysMultiplier)
    }
    
    // Calculate the accumulated cost using the usage rate per period.
    var accumulatedCost: Double {
        return data.device.usageRate * elapsedPeriodCount
    }
    
    // Calculate remaining cost.
    var remainingCost: Double {
        return max(data.device.purchasePrice - accumulatedCost, 0)
    }
    
    // Calculate progress as a value between 0 and 1.
    var progress: Double {
        min(accumulatedCost / data.device.purchasePrice, 1.0)
    }
    
    @ViewBuilder
    private var remainingDays: some View {
        let perDay = Double(data.device.usageRate / Double(data.usageRatePeriod.daysMultiplier))
        let days = (data.device.purchasePrice / perDay) - Double(data.device.elapsedDays)
        if days > 0 {
            Text("Remaining days: \(days.formatted(.number))")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.device.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Purchased for \(data.device.purchasePrice.formatted(.currency(code: data.currency.code)))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Used for \(data.device.elapsedDays) days (\(elapsedPeriodCount, specifier: "%.1f") \(data.usageRatePeriod.name)s)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // show rate
                    Text("Rate: \(data.device.usageRate.formatted(.currency(code: data.currency.code)))/\(data.usageRatePeriod.name)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    remainingDays
                    
                    Text("Remaining Cost: \(remainingCost.formatted(.currency(code: data.currency.code)))")
                        .font(.headline)
                        .foregroundColor(remainingCost == 0 ? .green : .blue)
                }
                Spacer()
                
                // Circular Progress Bar
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    
                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(width: 50, height: 50)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}


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
                name: "iPhone 13 Pro",
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
}
