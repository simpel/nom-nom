import SwiftUI

struct PartyHealthStrengthsCard: View {
    let topStrengths: [String]
    let topConsiderations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("Nutritional Patterns")
                .font(.headline)
                .foregroundStyle(DS.Color.textPrimary)
            
            if !topStrengths.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Top Strengths")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Color.textSecondary)
                    
                    ForEach(topStrengths, id: \.self) { strength in
                        HStack(alignment: .top, spacing: DS.Spacing.xs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DS.Color.Pine.pine600)
                                .font(.footnote)
                                .padding(.top, 2)
                            Text(strength)
                                .font(.subheadline)
                                .foregroundStyle(DS.Color.textPrimary)
                        }
                    }
                }
            }
            
            if !topConsiderations.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Watch-outs")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.Color.textSecondary)
                    
                    ForEach(topConsiderations, id: \.self) { consideration in
                        HStack(alignment: .top, spacing: DS.Spacing.xs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color("ds/reaction/bad/text"))
                                .font(.footnote)
                                .padding(.top, 2)
                            Text(consideration)
                                .font(.subheadline)
                                .foregroundStyle(DS.Color.textPrimary)
                        }
                    }
                }
                .padding(.top, topStrengths.isEmpty ? 0 : DS.Spacing.xs)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.sunken)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}
