//
//  Components.swift
//  Component builder
//
//  Created by Felix Wong on 2025-08-14.
//

import SwiftUI

// MARK: - Button Components

struct PrimaryButton: View {
    let text: String
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(TCGTypography.headline)
                .foregroundColor(.white)
                .padding(.horizontal, TCGSpacing.xxl)
                .padding(.vertical, TCGSpacing.md)
        }
        .tcgButtonStyle()
    }
}

struct SecondaryButton: View {
    let text: String
    var action: () -> Void = {}
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(TCGTypography.headline)
                .padding(.horizontal, TCGSpacing.xxl)
                .padding(.vertical, TCGSpacing.md)
        }
        .tcgSecondaryButtonStyle()
    }
}

// MARK: - TCG Card Components

struct TCGInventoryCard: View {
    let cardName: String
    let set: String
    let condition: String
    let price: String
    let quantity: Int
    let isHolo: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: TCGSpacing.md) {
            // Card header with foil effect for holo cards
            HStack {
                VStack(alignment: .leading, spacing: TCGSpacing.xs) {
                    Text(cardName)
                        .font(TCGTypography.cardTitle)
                        .foregroundColor(TCGTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text(set)
                        .font(TCGTypography.cardSubtitle)
                        .foregroundColor(TCGTheme.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: TCGSpacing.xs) {
                    Text(price)
                        .font(TCGTypography.cardPrice)
                        .foregroundColor(TCGTheme.success)
                        .fontWeight(.bold)
                    
                    Text("Qty: \(quantity)")
                        .font(TCGTypography.cardQuantity)
                        .foregroundColor(TCGTheme.textSecondary)
                        .padding(.horizontal, TCGSpacing.sm)
                        .padding(.vertical, TCGSpacing.xs)
                        .background(TCGTheme.secondaryBackground)
                        .cornerRadius(6)
                }
            }
            
            // Condition and rarity badges
            HStack {
                ConditionBadge(condition: condition)
                
                if isHolo {
                    HoloBadge()
                }
                
                Spacer()
            }
        }
        .padding(TCGSpacing.lg)
        .background(TCGGradients.cardBackground)
        .tcgInventoryCardStyle()
        .overlay(
            Group {
                if isHolo {
                    TCGEffects.foilEffect()
                        .cornerRadius(12)
                }
            }
        )
    }
}

struct ConditionBadge: View {
    let condition: String
    
    var body: some View {
        HStack(spacing: TCGSpacing.xs) {
            Circle()
                .fill(condition.tcgConditionColor)
                .frame(width: 8, height: 8)
            Text(condition)
                .font(TCGTypography.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, TCGSpacing.sm)
        .padding(.vertical, TCGSpacing.xs)
        .background(condition.tcgConditionColor.opacity(0.15))
        .foregroundColor(condition.tcgConditionColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(condition.tcgConditionColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HoloBadge: View {
    var body: some View {
        HStack(spacing: TCGSpacing.xs) {
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(TCGGradients.holo)
            Text("HOLO")
                .font(TCGTypography.caption)
                .fontWeight(.bold)
        }
        .padding(.horizontal, TCGSpacing.sm)
        .padding(.vertical, TCGSpacing.xs)
        .background(TCGGradients.holo.opacity(0.15))
        .foregroundColor(TCGTheme.rarityHolo)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TCGTheme.rarityHolo.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Transaction Components

struct TransactionRow: View {
    let type: TransactionType
    let cardName: String
    let amount: String
    let date: String
    let customer: String
    
    var body: some View {
        HStack(spacing: TCGSpacing.md) {
            // Transaction type icon with card-like styling
            ZStack {
                Circle()
                    .fill(TCGGradients.primary)
                    .frame(width: 44, height: 44)
                    .shadow(color: TCGTheme.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Image(systemName: type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: TCGSpacing.xs) {
                HStack {
                    Text(cardName)
                        .font(TCGTypography.cardTitle)
                        .foregroundColor(TCGTheme.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(amount)
                        .font(TCGTypography.cardPrice)
                        .foregroundColor(type.color)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text(customer)
                        .font(TCGTypography.cardSubtitle)
                        .foregroundColor(TCGTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(date)
                        .font(TCGTypography.cardQuantity)
                        .foregroundColor(TCGTheme.textSecondary)
                        .padding(.horizontal, TCGSpacing.sm)
                        .padding(.vertical, TCGSpacing.xs)
                        .background(TCGTheme.secondaryBackground)
                        .cornerRadius(6)
                }
            }
        }
        .padding(TCGSpacing.lg)
        .background(TCGGradients.cardBackground)
        .tcgInventoryCardStyle()
    }
}

enum TransactionType {
    case sale, trade, purchase
    
    var color: Color {
        switch self {
        case .sale: return TCGTheme.transactionSale
        case .trade: return TCGTheme.transactionTrade
        case .purchase: return TCGTheme.transactionPurchase
        }
    }
    
    var icon: String {
        switch self {
        case .sale: return "dollarsign.circle"
        case .trade: return "arrow.triangle.2.circlepath"
        case .purchase: return "cart"
        }
    }
}

// MARK: - Search and Filter Components

struct TCGSearchBar: View {
    let placeholder: String
    @Binding var text: String
    @State private var isSearching = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(TCGTheme.textSecondary)
                    .font(.system(size: 16, weight: .medium))
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(TCGTypography.body)
                
                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(TCGTheme.textSecondary)
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .padding(TCGSpacing.lg)
            .background(TCGTheme.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TCGTheme.cardBorderLight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
    }
}

struct FilterChips: View {
    @Binding var selectedFilters: Set<String>
    let filters: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TCGSpacing.sm) {
                ForEach(filters, id: \.self) { filter in
                    FilterChip(
                        title: filter,
                        isSelected: selectedFilters.contains(filter)
                    ) {
                        if selectedFilters.contains(filter) {
                            selectedFilters.remove(filter)
                        } else {
                            selectedFilters.insert(filter)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: TCGSpacing.xs) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(TCGTypography.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, TCGSpacing.md)
            .padding(.vertical, TCGSpacing.sm)
            .background(isSelected ? TCGTheme.primary : TCGTheme.secondaryBackground)
            .foregroundColor(isSelected ? .white : TCGTheme.textPrimary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? TCGTheme.primaryDark : TCGTheme.cardBorderLight, lineWidth: 1)
            )
            .shadow(color: isSelected ? TCGTheme.primary.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
        }
        .animation(TCGAnimation.easeOut, value: isSelected)
    }
}

// MARK: - Stats Components

struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: TCGSpacing.md) {
            // Card header with icon
            HStack {
                Text(title)
                    .font(TCGTypography.cardSubtitle)
                    .foregroundColor(TCGTheme.textSecondary)
                    .textCase(.uppercase)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Decorative card corner
                Rectangle()
                    .fill(color.opacity(0.2))
                    .frame(width: 20, height: 20)
                    .cornerRadius(4)
            }
            
            // Main value with card-like styling
            Text(value)
                .font(TCGTypography.cardPrice)
                .fontWeight(.bold)
                .foregroundColor(color)
                .padding(.vertical, TCGSpacing.sm)
                .padding(.horizontal, TCGSpacing.md)
                .background(color.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            
            Text(subtitle)
                .font(TCGTypography.cardQuantity)
                .foregroundColor(TCGTheme.textSecondary)
        }
        .padding(TCGSpacing.lg)
        .background(TCGGradients.cardBackground)
        .tcgInventoryCardStyle()
    }
}

// MARK: - Card Components

struct InfoCard: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: TCGSpacing.md) {
            Text(title)
                .font(TCGTypography.headline)
                .foregroundColor(TCGTheme.textPrimary)
            
            Text(description)
                .font(TCGTypography.body)
                .foregroundColor(TCGTheme.textSecondary)
                .lineLimit(3)
        }
        .padding(TCGSpacing.lg)
        .tcgCardStyle()
    }
}

struct ProfileCard: View {
    let name: String
    let role: String
    let avatar: String
    
    var body: some View {
        HStack(spacing: TCGSpacing.md) {
            Image(systemName: avatar)
                .font(.system(size: 40))
                .foregroundColor(TCGTheme.primary)
            
            VStack(alignment: .leading, spacing: TCGSpacing.xs) {
                Text(name)
                    .font(TCGTypography.headline)
                    .foregroundColor(TCGTheme.textPrimary)
                
                Text(role)
                    .font(TCGTypography.bodySmall)
                    .foregroundColor(TCGTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(TCGSpacing.lg)
        .tcgCardStyle()
    }
}

// MARK: - Input Components

struct SearchInput: View {
    let placeholder: String
    @State private var text = ""
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(TCGTheme.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(TCGTypography.body)
        }
        .padding(TCGSpacing.md)
        .background(TCGTheme.secondaryBackground)
        .cornerRadius(8)
    }
}

// MARK: - Navigation Components

struct CustomTabBar: View {
    @State private var selectedTab = 0
    
    var body: some View {
        HStack {
            ForEach(0..<3) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: TCGSpacing.xs) {
                        Image(systemName: tabIcon(for: index))
                            .font(.system(size: 20))
                        Text(tabTitle(for: index))
                            .font(TCGTypography.caption)
                    }
                    .foregroundColor(selectedTab == index ? TCGTheme.primary : TCGTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, TCGSpacing.sm)
        .background(TCGTheme.background)
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house"
        case 1: return "heart"
        case 2: return "person"
        default: return "circle"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Favorites"
        case 2: return "Profile"
        default: return "Tab"
        }
    }
}

// MARK: - Feedback Components

enum AlertType {
    case success, warning, error
    
    var color: Color {
        switch self {
        case .success: return TCGTheme.success
        case .warning: return TCGTheme.warning
        case .error: return TCGTheme.error
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct AlertBanner: View {
    let title: String
    let message: String
    let type: AlertType
    
    var body: some View {
        HStack(spacing: TCGSpacing.md) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            VStack(alignment: .leading, spacing: TCGSpacing.xs) {
                Text(title)
                    .font(TCGTypography.headline)
                    .foregroundColor(TCGTheme.textPrimary)
                
                Text(message)
                    .font(TCGTypography.bodySmall)
                    .foregroundColor(TCGTheme.textSecondary)
            }
            
            Spacer()
        }
        .padding(TCGSpacing.lg)
        .background(type.color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Layout Components

struct GridLayout: View {
    let columns = Array(repeating: GridItem(.flexible(), spacing: TCGSpacing.lg), count: 2)
    let items = Array(1...6)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: TCGSpacing.lg) {
            ForEach(items, id: \.self) { item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(TCGTheme.primary.opacity(0.2))
                    .frame(height: 80)
                    .overlay(
                        Text("\(item)")
                            .font(TCGTypography.headline)
                            .foregroundColor(TCGTheme.primary)
                    )
            }
        }
        .padding()
    }
}

// MARK: - Previews

#Preview("Primary Button") {
    PrimaryButton(text: "Primary Action")
        .padding()
}

#Preview("Secondary Button") {
    SecondaryButton(text: "Secondary Action")
        .padding()
}

#Preview("TCG Inventory Card") {
    TCGInventoryCard(
        cardName: "Charizard VMAX",
        set: "Champion's Path",
        condition: "Near Mint",
        price: "$45.00",
        quantity: 3,
        isHolo: true
    )
    .padding()
}

#Preview("Transaction Row") {
    VStack(spacing: 12) {
        TransactionRow(
            type: .sale,
            cardName: "Pikachu V",
            amount: "+$12.50",
            date: "Today",
            customer: "John D."
        )
        TransactionRow(
            type: .trade,
            cardName: "Blastoise GX",
            amount: "Trade",
            date: "Yesterday",
            customer: "Sarah M."
        )
    }
    .padding()
}

#Preview("TCG Search Bar") {
    TCGSearchBar(placeholder: "Search cards...", text: .constant(""))
        .padding()
}

#Preview("Filter Chips") {
    FilterChips(
        selectedFilters: .constant(["Holo", "Near Mint"]),
        filters: ["Mint", "Near Mint", "Holo", "First Edition", "Promo"]
    )
    .padding()
}

#Preview("Stats Card") {
    HStack(spacing: 16) {
        StatsCard(
            title: "Today's Sales",
            value: "$247.50",
            subtitle: "+12% from yesterday",
            color: TCGTheme.success
        )
        
        StatsCard(
            title: "Cards Sold",
            value: "23",
            subtitle: "This week",
            color: TCGTheme.primary
        )
    }
    .padding()
}

#Preview("Info Card") {
    InfoCard(
        title: "Sample Card",
        description: "This is a sample info card component with title and description text."
    )
    .padding()
}

#Preview("Profile Card") {
    ProfileCard(
        name: "John Doe",
        role: "Software Engineer",
        avatar: "person.circle.fill"
    )
    .padding()
}

#Preview("Search Input") {
    SearchInput(placeholder: "Search...")
        .padding()
}

#Preview("Custom Tab Bar") {
    CustomTabBar()
        .padding()
}

#Preview("Alert Banner") {
    VStack(spacing: 16) {
        AlertBanner(
            title: "Success!",
            message: "Your action was completed successfully.",
            type: .success
        )
        
        AlertBanner(
            title: "Warning!",
            message: "Please check your input before proceeding.",
            type: .warning
        )
        
        AlertBanner(
            title: "Error!",
            message: "Something went wrong. Please try again.",
            type: .error
        )
    }
    .padding()
}

#Preview("Grid Layout") {
    GridLayout()
}
