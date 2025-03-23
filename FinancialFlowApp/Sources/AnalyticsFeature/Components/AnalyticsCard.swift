import SwiftUI

struct AnalyticsCard: View {
    let title: String
    let value: String
    
    init(
        title: String,
        value: String
    ) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            titleText
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(12)
    }
    
    var titleText: some View {
        Text(title)
            .font(.subheadline) 
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
} 
