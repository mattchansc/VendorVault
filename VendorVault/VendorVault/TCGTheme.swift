//
//  TCGTheme.swift
//  Component builder
//
//  Created by Felix Wong on 2025-08-14.
//

import SwiftUI

// MARK: - TCG Color Theme

struct TCGTheme {
    // MARK: - Primary Colors (Card-inspired)
    static let primary = Color(red: 0.15, green: 0.25, blue: 0.45) // Deep card blue
    static let primaryLight = Color(red: 0.25, green: 0.35, blue: 0.55)
    static let primaryDark = Color(red: 0.1, green: 0.2, blue: 0.35)
    
    // MARK: - Secondary Colors (Gold accents)
    static let secondary = Color(red: 0.85, green: 0.7, blue: 0.3) // Trading card gold
    static let secondaryLight = Color(red: 0.95, green: 0.8, blue: 0.4)
    static let secondaryDark = Color(red: 0.75, green: 0.6, blue: 0.2)
    
    // MARK: - Accent Colors (Energy-inspired)
    static let accent = Color(red: 0.8, green: 0.3, blue: 0.4) // Fire energy red
    static let accentLight = Color(red: 0.9, green: 0.4, blue: 0.5)
    static let accentDark = Color(red: 0.7, green: 0.2, blue: 0.3)
    
    // MARK: - Success/Error Colors
    static let success = Color(red: 0.2, green: 0.6, blue: 0.3) // Grass energy green
    static let warning = Color(red: 0.9, green: 0.6, blue: 0.2) // Fighting energy orange
    static let error = Color(red: 0.8, green: 0.2, blue: 0.2) // Psychic energy red
    
    // MARK: - Card Background Colors
    static let background = Color(red: 0.98, green: 0.98, blue: 0.96) // Off-white card background
    static let secondaryBackground = Color(red: 0.95, green: 0.95, blue: 0.93)
    static let tertiaryBackground = Color(red: 0.92, green: 0.92, blue: 0.90)
    
    // MARK: - Text Colors
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1) // Dark card text
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.4) // Secondary card text
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6) // Muted text
    
    // MARK: - Card Condition Colors (PSA-style)
    static let conditionMint = Color(red: 0.1, green: 0.6, blue: 0.3) // PSA 10 green
    static let conditionNearMint = Color(red: 0.2, green: 0.5, blue: 0.7) // PSA 9 blue
    static let conditionExcellent = Color(red: 0.8, green: 0.6, blue: 0.2) // PSA 8 gold
    static let conditionGood = Color(red: 0.9, green: 0.7, blue: 0.2) // PSA 7 yellow
    static let conditionLightPlayed = Color(red: 0.8, green: 0.4, blue: 0.3) // PSA 6 orange
    
    // MARK: - Rarity Colors (Pokémon TCG inspired)
    static let rarityCommon = Color(red: 0.5, green: 0.5, blue: 0.5) // Gray
    static let rarityUncommon = Color(red: 0.2, green: 0.6, blue: 0.3) // Green
    static let rarityRare = Color(red: 0.2, green: 0.4, blue: 0.8) // Blue
    static let rarityHolo = Color(red: 0.8, green: 0.2, blue: 0.8) // Purple
    static let raritySecret = Color(red: 0.9, green: 0.6, blue: 0.2) // Gold
    
    // MARK: - Transaction Colors
    static let transactionSale = success
    static let transactionTrade = primary
    static let transactionPurchase = warning
    
    // MARK: - Card Border Colors
    static let cardBorder = Color(red: 0.2, green: 0.2, blue: 0.2) // Dark card border
    static let cardBorderLight = Color(red: 0.3, green: 0.3, blue: 0.3) // Light card border
    static let foilBorder = Color(red: 0.8, green: 0.7, blue: 0.4) // Foil card border
}

// MARK: - TCG Style Extensions

extension View {
    func tcgCardStyle() -> some View {
        self
            .background(TCGTheme.background)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(TCGTheme.cardBorder, lineWidth: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(TCGTheme.cardBorderLight, lineWidth: 1)
                    .padding(1)
            )
    }
    
    func tcgFoilCardStyle() -> some View {
        self
            .background(TCGTheme.background)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(TCGTheme.foilBorder, lineWidth: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(TCGTheme.secondary, lineWidth: 1)
                    .padding(2)
            )
    }
    
    func tcgButtonStyle() -> some View {
        self
            .background(TCGGradients.primary)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: TCGTheme.primary.opacity(0.4), radius: 3, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TCGTheme.primaryDark, lineWidth: 1)
            )
    }
    
    func tcgSecondaryButtonStyle() -> some View {
        self
            .background(Color.clear)
            .foregroundColor(TCGTheme.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TCGTheme.primary, lineWidth: 2)
            )
            .shadow(color: TCGTheme.primary.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    func tcgGoldButtonStyle() -> some View {
        self
            .background(TCGGradients.secondary)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: TCGTheme.secondary.opacity(0.4), radius: 3, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TCGTheme.secondaryDark, lineWidth: 1)
            )
    }
    
    func tcgInventoryCardStyle() -> some View {
        self
            .background(TCGTheme.background)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TCGTheme.cardBorderLight, lineWidth: 1)
            )
    }
}

// MARK: - TCG Typography

struct TCGTypography {
    // Modern, professional typography without rounded design
    static let titleLarge = Font.system(size: 32, weight: .bold, design: .default)
    static let titleMedium = Font.system(size: 24, weight: .semibold, design: .default)
    static let titleSmall = Font.system(size: 20, weight: .semibold, design: .default)
    
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let captionSmall = Font.system(size: 11, weight: .medium, design: .default)
    
    // Card-specific typography with refined sizing
    static let cardTitle = Font.system(size: 19, weight: .bold, design: .default)
    static let cardSubtitle = Font.system(size: 15, weight: .medium, design: .default)
    static let cardPrice = Font.system(size: 22, weight: .bold, design: .default)
    static let cardQuantity = Font.system(size: 13, weight: .semibold, design: .default)
}

// MARK: - TCG Spacing

struct TCGSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - TCG Gradients

struct TCGGradients {
    static let primary = LinearGradient(
        colors: [TCGTheme.primary, TCGTheme.primaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondary = LinearGradient(
        colors: [TCGTheme.secondary, TCGTheme.secondaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accent = LinearGradient(
        colors: [TCGTheme.accent, TCGTheme.accentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let holo = LinearGradient(
        colors: [
            Color(red: 0.8, green: 0.2, blue: 0.8),
            Color(red: 0.6, green: 0.2, blue: 0.9),
            Color(red: 0.4, green: 0.2, blue: 0.8),
            Color(red: 0.8, green: 0.2, blue: 0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let foil = LinearGradient(
        colors: [
            Color(red: 0.9, green: 0.8, blue: 0.5),
            Color(red: 0.8, green: 0.7, blue: 0.4),
            Color(red: 0.9, green: 0.8, blue: 0.5),
            Color(red: 0.7, green: 0.6, blue: 0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardBackground = LinearGradient(
        colors: [TCGTheme.background, TCGTheme.secondaryBackground],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - TCG Animation

struct TCGAnimation {
    static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    static let easeInOut = Animation.easeInOut(duration: 0.3)
    static let easeOut = Animation.easeOut(duration: 0.2)
    static let easeIn = Animation.easeIn(duration: 0.2)
    static let cardFlip = Animation.easeInOut(duration: 0.4)
}

// MARK: - TCG Condition Helper

extension String {
    var tcgConditionColor: Color {
        switch self.lowercased() {
        case "mint": return TCGTheme.conditionMint
        case "near mint": return TCGTheme.conditionNearMint
        case "excellent": return TCGTheme.conditionExcellent
        case "good": return TCGTheme.conditionGood
        case "light played": return TCGTheme.conditionLightPlayed
        default: return TCGTheme.textSecondary
        }
    }
}

// MARK: - TCG Rarity Helper

enum TCGRarity: String, CaseIterable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case holo = "Holo"
    case secret = "Secret"
    
    var color: Color {
        switch self {
        case .common: return TCGTheme.rarityCommon
        case .uncommon: return TCGTheme.rarityUncommon
        case .rare: return TCGTheme.rarityRare
        case .holo: return TCGTheme.rarityHolo
        case .secret: return TCGTheme.raritySecret
        }
    }
    
    var icon: String {
        switch self {
        case .common: return "circle.fill"
        case .uncommon: return "diamond.fill"
        case .rare: return "star.fill"
        case .holo: return "sparkles"
        case .secret: return "crown.fill"
        }
    }
}

// MARK: - TCG Card Effects

struct TCGEffects {
    static func foilEffect() -> some View {
        Rectangle()
            .fill(TCGGradients.foil)
            .opacity(0.3)
            .blendMode(.overlay)
    }
    
    static func cardShadow() -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.1))
            .blur(radius: 4)
            .offset(x: 2, y: 2)
    }
}

