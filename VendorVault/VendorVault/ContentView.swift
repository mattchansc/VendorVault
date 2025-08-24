//
//  ContentView.swift
//  VendorVault
//
//  Created by Matthew Chan on 7/20/25.
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - TCG Theme Integration
// Using TCGTheme.swift and Components.swift for consistent design

struct ContentView: View {
    var body: some View {
        ZStack {
            TabView {
                EditView(showingEditSheet: .constant(false))
                    .tabItem {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Card")
                            .font(TCGTypography.caption)
                    }
                    .tag(0)
                
                InventoryView()
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Inventory")
                            .font(TCGTypography.caption)
                    }
                    .tag(1)
                
                CameraView()
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("Camera")
                            .font(TCGTypography.caption)
                    }
                    .tag(2)
                
                SummaryView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Summary")
                            .font(TCGTypography.caption)
                    }
                    .tag(3)
            }
            .preferredColorScheme(.light) // Changed to light theme for TCG design
            .accentColor(TCGTheme.primary)
            .background(TCGTheme.background.ignoresSafeArea())
            
            // Version indicator with TCG styling
            VStack {
                HStack {
                    Spacer()
                    
                    Text("v3.2.3")
                        .font(TCGTypography.captionSmall)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, TCGSpacing.sm)
                        .padding(.vertical, TCGSpacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(TCGTheme.primary)
                                .stroke(TCGTheme.primaryDark, lineWidth: 1)
                        )
                        .shadow(color: TCGTheme.primary.opacity(0.4), radius: 3, x: 0, y: 2)
                }
                .padding(.top, 50)
                .padding(.trailing, 20)
                
                Spacer()
            }
            .zIndex(1000)
        }
    }
}

class PokemonNameFetcher: ObservableObject {
    @Published var allPokemonNames: [String] = []
    @Published var isLoading = false

    func fetchPokemonNames() {
        guard allPokemonNames.isEmpty else { return }
        isLoading = true
        let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=10000")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { DispatchQueue.main.async { self.isLoading = false } }
            guard let data = data,
                  let result = try? JSONDecoder().decode(PokemonListResponse.self, from: data) else { return }
            DispatchQueue.main.async {
                self.allPokemonNames = result.results.map { $0.name.capitalized }
            }
        }.resume()
    }

    struct PokemonListResponse: Decodable {
        struct PokemonEntry: Decodable { let name: String }
        let results: [PokemonEntry]
    }
}

class PokemonSetFetcher: ObservableObject {
    @Published var allSetNames: [String] = []
    @Published var isLoading = false
    
    func fetchSetNames() {
        guard allSetNames.isEmpty else { return }
        isLoading = true
        let url = URL(string: "https://api.pokemontcg.io/v2/sets")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { DispatchQueue.main.async { self.isLoading = false } }
            guard let data = data,
                  let result = try? JSONDecoder().decode(PokemonSetListResponse.self, from: data) else { return }
            DispatchQueue.main.async {
                self.allSetNames = result.data.map { $0.name }
            }
        }.resume()
    }
}

class CardNumberFetcher: ObservableObject {
    @Published var isLoading = false
    
    func fetchCardNumber(pokemonName: String, setName: String, completion: @escaping (String?) -> Void) {
        guard !pokemonName.isEmpty && !setName.isEmpty else {
            completion(nil)
            return
        }
        
        isLoading = true
        
        // Build search query using only pokemon name and set name
        var searchTerms: [String] = []
        searchTerms.append("name:\"\(pokemonName)\"")
        searchTerms.append("set.name:\"\(setName)\"")
        
        let query = searchTerms.joined(separator: " ")
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://api.pokemontcg.io/v2/cards?q=\(encodedQuery)")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { DispatchQueue.main.async { self.isLoading = false } }
            guard let data = data,
                  let result = try? JSONDecoder().decode(CardSearchResponse.self, from: data),
                  let firstCard = result.data.first else {
                completion(nil)
                return
            }
            
            DispatchQueue.main.async { completion(firstCard.number) }
        }.resume()
    }
}

class CardImageFetcher: ObservableObject {
    @Published var cardImageURL: String? = nil
    @Published var isLoading = false
    
    func fetchCardImage(setName: String, setNumber: String, completion: @escaping (String?) -> Void) {
        guard !setName.isEmpty && !setNumber.isEmpty else {
            completion(nil)
            return
        }
        
        isLoading = true
        
        // Build search query using set name and set number
        let query = "set.name:\"\(setName)\" number:\"\(setNumber)\""
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "https://api.pokemontcg.io/v2/cards?q=\(encodedQuery)")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { DispatchQueue.main.async { self.isLoading = false } }
            guard let data = data,
                  let result = try? JSONDecoder().decode(CardSearchResponse.self, from: data),
                  let firstCard = result.data.first else {
                completion(nil)
                return
            }
            
            DispatchQueue.main.async {
                completion(firstCard.images.large)
            }
        }.resume()
    }
}

struct PokemonSetListResponse: Decodable {
    let data: [PokemonSet]
}

struct PokemonSet: Decodable {
    let name: String
}

struct CardSearchResponse: Decodable {
    let data: [CardData]
}

struct CardData: Codable {
    let number: String
    let images: CardImages
}

struct CardImages: Codable {
    let small: String
    let large: String
}

struct Card: Decodable {
    let number: String
}

struct EditView: View {
    @State private var cardName: String = ""
    // TODO: Provide card name list for search/filter functionality
    // let allCardNames: [String] = ...
    // var filteredCardNames: [String] { ... }

    @State private var pokemonName: String = ""
    @State private var selectedCondition: Condition = .nearMint
    @State private var selectedLanguage: String = Locale.current.localizedString(forIdentifier: "en") ?? "English"
    @State private var selectedItemType: ItemType = .raw
    @State private var qrCodeID: String = ""
    @State private var acquisitionPrice: String = ""
    @State private var setName: String = ""
    @State private var setNumber: String = ""
    @State private var showPokemonDropdown: Bool = false
    @State private var showSetDropdown: Bool = false
    @State private var isSaving: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showingDeleteAlert: Bool = false
    
    // Add support for editing existing cards
    let cardToEdit: PokemonCard?
    @Binding var showingEditSheet: Bool
    
    @ObservedObject var pokemonFetcher = PokemonNameFetcher()
    @ObservedObject var setFetcher = PokemonSetFetcher()
    @ObservedObject var cardNumberFetcher = CardNumberFetcher()
    @ObservedObject var cardImageFetcher = CardImageFetcher()
    @StateObject private var firebaseService = FirebaseService()
    @EnvironmentObject var authService: AuthService
    
    // Initialize for creating new cards
    init(showingEditSheet: Binding<Bool>) {
        self.cardToEdit = nil
        self._showingEditSheet = showingEditSheet
    }
    
    // Initialize for editing existing cards
    init(card: PokemonCard, showingEditSheet: Binding<Bool>) {
        self.cardToEdit = card
        self._showingEditSheet = showingEditSheet
    }
    
    enum Condition: String, CaseIterable, Identifiable {
        case gemMint = "Gem Mint"
        case nearMint = "Near Mint"
        case lightlyPlayed = "Lightly Played"
        case moderatelyPlayed = "Moderately Played"
        case heavilyPlayed = "Heavily Played"
        case damaged = "Damaged"
        
        var id: String { rawValue }
    }
    
    enum ItemType: String, CaseIterable, Identifiable {
        case sealed = "Sealed"
        case slabs = "Slabs"
        case raw = "Raw"
        case other = "Other"
        
        var id: String { rawValue }
    }
    
    var filteredPokemonNames: [String] {
        if pokemonName.isEmpty {
            return []
        }
        return pokemonFetcher.allPokemonNames.filter { $0.localizedCaseInsensitiveContains(pokemonName) }.prefix(10).map { $0 }
    }
    
    var filteredSetNames: [String] {
        if setName.isEmpty {
            return []
        }
        return setFetcher.allSetNames.filter { $0.localizedCaseInsensitiveContains(setName) }.prefix(10).map { $0 }
    }
    
    let isoLanguageCodes: [String] = Locale.isoLanguageCodes
    
    func generateUniqueQRCode() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomComponent = Int.random(in: 1000...9999)
        return "VV-\(timestamp)-\(randomComponent)"
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    func updateSetNumber() {
        guard !pokemonName.isEmpty && !setName.isEmpty else {
            setNumber = ""
            return
        }
        
        // Debounce API calls
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            cardNumberFetcher.fetchCardNumber(pokemonName: pokemonName, setName: setName) { number in
                if let number = number {
                    setNumber = number
                } else {
                    setNumber = ""
                }
            }
        }
    }
    
    func saveCard() {
        guard let userId = authService.user?.uid else {
            errorMessage = "User not authenticated"
            showErrorAlert = true
            return
        }
        
        guard !pokemonName.isEmpty && !setName.isEmpty && !acquisitionPrice.isEmpty else {
            errorMessage = "Please fill in all required fields (Pokemon name, Set name, and Acquisition price)"
            showErrorAlert = true
            return
        }
        
        guard let card = PokemonCard.createFromForm(
            cardName: cardName,
            pokemonName: pokemonName,
            setName: setName,
            setNumber: setNumber,
            condition: selectedCondition.rawValue,
            language: selectedLanguage,
            itemType: selectedItemType.rawValue,
            acquisitionPrice: acquisitionPrice,
            cardImageURL: cardImageFetcher.cardImageURL
        ) else {
            errorMessage = "Invalid acquisition price format"
            showErrorAlert = true
            return
        }
        
        isSaving = true
        
                        Task {
                    do {
                        if let existingCard = cardToEdit {
                            // Update existing card
                            var updatedCard = card
                            updatedCard.id = existingCard.id
                            updatedCard.dateAdded = existingCard.dateAdded
                            try await firebaseService.updateCard(updatedCard)
                        } else {
                            // Create new card
                            try await firebaseService.saveCard(card)
                        }
                        
                        await MainActor.run {
                            isSaving = false
                            if cardToEdit != nil {
                                // For editing, dismiss the sheet and refresh inventory
                                showSuccessAlert = false // Don't show alert for edit
                                clearForm()
                                showingEditSheet = false // Dismiss the sheet
                            } else {
                                // For new cards, show success alert
                                showSuccessAlert = true
                                clearForm()
                            }
                        }
                    } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    func clearForm() {
        cardName = ""
        pokemonName = ""
        selectedCondition = .nearMint
        selectedLanguage = Locale.current.localizedString(forIdentifier: "en") ?? "English"
        selectedItemType = .raw
        acquisitionPrice = ""
        setName = ""
        setNumber = ""
        cardImageFetcher.cardImageURL = nil
    }
    
    func populateFormForEditing() {
        guard let card = cardToEdit else { return }
        cardName = card.cardName
        pokemonName = card.pokemonName
        selectedCondition = Condition(rawValue: card.condition) ?? .nearMint
        selectedLanguage = card.language
        selectedItemType = ItemType(rawValue: card.itemType) ?? .raw
        acquisitionPrice = String(card.acquisitionPrice)
        setName = card.setName
        setNumber = card.setNumber
        cardImageFetcher.cardImageURL = card.cardImageURL
        qrCodeID = generateUniqueQRCode()
    }
    
    func deleteCard() {
        guard let card = cardToEdit else { return }
        
        Task {
            do {
                try await firebaseService.deleteCard(card)
                await MainActor.run {
                    showingEditSheet = false // Dismiss the sheet
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: TCGSpacing.xl) {
                    // Card Information & Details Section (Combined)
                    VStack(alignment: .leading, spacing: TCGSpacing.lg) {
                        Text("Card Information & Details")
                            .font(TCGTypography.titleSmall)
                            .foregroundColor(TCGTheme.textPrimary)
                            .padding(.horizontal, TCGSpacing.lg)
                        
                        VStack(spacing: TCGSpacing.md) {
                            // Set Name
                            VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                                Text("Set Name")
                                    .font(TCGTypography.headline)
                                    .foregroundColor(TCGTheme.textPrimary)
                                
                                TextField("Search or enter set name", text: $setName)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(TCGTypography.body)
                                    .padding(TCGSpacing.md)
                                    .background(TCGTheme.secondaryBackground)
                                    .cornerRadius(8)
                                    .onChange(of: setName) { _ in
                                        showSetDropdown = !setName.isEmpty && !filteredSetNames.isEmpty
                                        updateSetNumber()
                                    }
                                    .onAppear {
                                        setFetcher.fetchSetNames()
                                    }
                                
                                if showSetDropdown && !filteredSetNames.isEmpty {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(filteredSetNames, id: \.self) { name in
                                            Button(action: {
                                                setName = name
                                                showSetDropdown = false
                                            }) {
                                                Text(name)
                                                    .font(TCGTypography.body)
                                                    .foregroundColor(TCGTheme.textPrimary)
                                                    .padding(TCGSpacing.md)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .background(TCGTheme.background)
                                            Divider()
                                                .background(TCGTheme.cardBorderLight)
                                        }
                                    }
                                    .background(TCGTheme.secondaryBackground)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(TCGTheme.cardBorderLight, lineWidth: 1)
                                    )
                                }
                            }
                            
                            // Set Number
                            VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                                Text("Set Number")
                                    .font(TCGTypography.headline)
                                    .foregroundColor(TCGTheme.textPrimary)
                                
                                HStack {
                                    TextField("Card set number", text: $setNumber)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(TCGTypography.body)
                                        .keyboardType(.numberPad)
                                        .padding(TCGSpacing.md)
                                        .background(TCGTheme.secondaryBackground)
                                        .cornerRadius(8)
                                    
                                    if cardNumberFetcher.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: TCGTheme.primary))
                                    }
                                }
                            }
                            
                            // Pokemon Name
                            VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                                Text("Pokemon Name")
                                    .font(TCGTypography.headline)
                                    .foregroundColor(TCGTheme.textPrimary)
                                
                                TextField("Search or enter Pokemon name", text: $pokemonName)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(TCGTypography.body)
                                    .padding(TCGSpacing.md)
                                    .background(TCGTheme.secondaryBackground)
                                    .cornerRadius(8)
                                    .onChange(of: pokemonName) { _ in
                                        showPokemonDropdown = !pokemonName.isEmpty && !filteredPokemonNames.isEmpty
                                        updateSetNumber()
                                    }
                                    .onAppear {
                                        pokemonFetcher.fetchPokemonNames()
                                    }
                                
                                if showPokemonDropdown && !filteredPokemonNames.isEmpty {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(filteredPokemonNames, id: \.self) { name in
                                            Button(action: {
                                                pokemonName = name
                                                showPokemonDropdown = false
                                            }) {
                                                Text(name)
                                                    .font(TCGTypography.body)
                                                    .foregroundColor(TCGTheme.textPrimary)
                                                    .padding(TCGSpacing.md)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .background(TCGTheme.background)
                                            Divider()
                                                .background(TCGTheme.cardBorderLight)
                                        }
                                    }
                                    .background(TCGTheme.secondaryBackground)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(TCGTheme.cardBorderLight, lineWidth: 1)
                                    )
                                }
                            }
                            
                            // Card Name
                            VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                                Text("Card Name")
                                    .font(TCGTypography.headline)
                                    .foregroundColor(TCGTheme.textPrimary)
                                
                                TextField("Search or enter card name", text: $cardName)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(TCGTypography.body)
                                    .padding(TCGSpacing.md)
                                    .background(TCGTheme.secondaryBackground)
                                    .cornerRadius(8)
                            }
                            
                            // Acquisition Price
                            VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                                Text("Acquisition Price")
                                    .font(TCGTypography.headline)
                                    .foregroundColor(TCGTheme.textPrimary)
                                
                                HStack {
                                    Text("$")
                                        .foregroundColor(TCGTheme.success)
                                        .font(TCGTypography.titleSmall)
                                        .fontWeight(.bold)
                                    
                                    TextField("0.00", text: $acquisitionPrice)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .font(TCGTypography.body)
                                        .keyboardType(.decimalPad)
                                        .padding(TCGSpacing.md)
                                        .background(TCGTheme.secondaryBackground)
                                        .cornerRadius(8)
                                        .onChange(of: acquisitionPrice) { newValue in
                                            let filtered = newValue.filter { "0123456789.".contains($0) }
                                            if filtered != newValue {
                                                acquisitionPrice = filtered
                                            }
                                        }
                                }
                            }
                            
                            // Condition
                            VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                                Text("Condition")
                                    .font(TCGTypography.headline)
                                    .foregroundColor(TCGTheme.textPrimary)
                                
                                Picker("Condition", selection: $selectedCondition) {
                                    ForEach(Condition.allCases) { condition in
                                        Text(condition.rawValue).tag(condition)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(TCGSpacing.md)
                                .background(TCGTheme.secondaryBackground)
                                .cornerRadius(8)
                            }
                            
                            // Language
                            VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                                Text("Language")
                                    .font(TCGTypography.headline)
                                    .foregroundColor(TCGTheme.textPrimary)
                                
                                Picker("Language", selection: $selectedLanguage) {
                                    ForEach(isoLanguageCodes.compactMap { code in
                                        Locale.current.localizedString(forIdentifier: code)
                                    }.sorted(), id: \.self) { language in
                                        Text(language).tag(language)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(TCGSpacing.md)
                                .background(TCGTheme.secondaryBackground)
                                .cornerRadius(8)
                            }
                            
                            // Item Type
                            VStack(alignment: .leading, spacing: TCGSpacing.sm) {
                                Text("Item Type")
                                    .font(TCGTypography.headline)
                                    .foregroundColor(TCGTheme.textPrimary)
                                
                                Picker("Item Type", selection: $selectedItemType) {
                                    ForEach(ItemType.allCases) { itemType in
                                        Text(itemType.rawValue).tag(itemType)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(TCGSpacing.md)
                                .background(TCGTheme.secondaryBackground)
                                .cornerRadius(8)
                            }
                        }
                        .padding(TCGSpacing.lg)
                        .tcgCardStyle()
                    }
                    
                    // QR Code Section
                    VStack(alignment: .leading, spacing: TCGSpacing.lg) {
                        Text("QR Code ID")
                            .font(TCGTypography.titleSmall)
                            .foregroundColor(TCGTheme.textPrimary)
                            .padding(.horizontal, TCGSpacing.lg)
                        
                        VStack(spacing: TCGSpacing.md) {
                            TextField("QR Code ID", text: $qrCodeID)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(TCGTypography.body)
                                .padding(TCGSpacing.md)
                                .background(TCGTheme.secondaryBackground)
                                .cornerRadius(8)
                                .onChange(of: qrCodeID) { _ in }
                                .onAppear {
                                    qrCodeID = generateUniqueQRCode()
                                }
                            
                            Text("Generated: \(qrCodeID)")
                                .font(TCGTypography.caption)
                                .foregroundColor(TCGTheme.textSecondary)
                            
                            if !qrCodeID.isEmpty {
                                VStack(spacing: TCGSpacing.lg) {
                                    Text("Scannable QR Code")
                                        .font(TCGTypography.headline)
                                        .foregroundColor(TCGTheme.primary)
                                    
                                    Image(uiImage: generateQRCode(from: qrCodeID))
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                        .padding(TCGSpacing.lg)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(TCGTheme.cardBorder, lineWidth: 2)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    
                                    Text("Scan this code to identify this card entry")
                                        .font(TCGTypography.caption)
                                        .foregroundColor(TCGTheme.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding(TCGSpacing.lg)
                        .tcgCardStyle()
                    }
                    
                    // Action Buttons
                    VStack(spacing: TCGSpacing.md) {
                        if cardToEdit != nil {
                            // Edit mode - show both Update and Delete buttons
                            HStack(spacing: TCGSpacing.md) {
                                Button(action: {
                                    saveCard()
                                }) {
                                    HStack {
                                        if isSaving {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                            Text("Saving...")
                                                .font(TCGTypography.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        } else {
                                            Text("Update Card")
                                                .font(TCGTypography.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(TCGSpacing.lg)
                                }
                                .tcgButtonStyle()
                                .disabled(isSaving)
                                
                                Button(action: {
                                    showingDeleteAlert = true
                                }) {
                                    Text("Delete Card")
                                        .font(TCGTypography.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(TCGSpacing.lg)
                                }
                                .background(TCGTheme.error)
                                .cornerRadius(12)
                                .shadow(color: TCGTheme.error.opacity(0.4), radius: 3, x: 0, y: 2)
                                .disabled(isSaving)
                            }
                        } else {
                            // Add mode - show only Submit button
                            Button(action: {
                                saveCard()
                            }) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                        Text("Saving...")
                                            .font(TCGTypography.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    } else {
                                        Text("Submit Card")
                                            .font(TCGTypography.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(TCGSpacing.lg)
                            }
                            .tcgButtonStyle()
                            .disabled(isSaving)
                        }
                    }
                    .padding(.horizontal, TCGSpacing.lg)
                }
                .padding(.vertical, TCGSpacing.lg)
            }
            .background(TCGTheme.background)
            .navigationTitle(cardToEdit != nil ? "Edit Card" : "Add Card")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(TCGTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(cardToEdit != nil ? "Card updated successfully!" : "Card saved successfully!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Card", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteCard()
                }
            } message: {
                if let card = cardToEdit {
                    Text("Are you sure you want to delete '\(card.pokemonName)'? This action cannot be undone.")
                }
            }
            .onAppear {
                pokemonFetcher.fetchPokemonNames()
                setFetcher.fetchSetNames()
                
                // Populate form if editing an existing card
                if cardToEdit != nil {
                    populateFormForEditing()
                } else {
                    // Generate QR code for new cards
                    qrCodeID = generateUniqueQRCode()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct InventoryView: View {
    @StateObject private var firebaseService = FirebaseService()
    @State private var searchText = ""
    @EnvironmentObject var authService: AuthService
    @State private var inboxCount: Int = 0
    @State private var showOnlyIncomplete: Bool = false
    @State private var selectedCardForEdit: PokemonCard?
    @State private var showingEditSheet = false
    
    var filteredCards: [PokemonCard] {
        var cards = firebaseService.cards
        
        // Filter by completion status
        if showOnlyIncomplete {
            cards = cards.filter { !$0.isComplete }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            cards = cards.filter { card in
                card.pokemonName.localizedCaseInsensitiveContains(searchText) ||
                card.setName.localizedCaseInsensitiveContains(searchText) ||
                card.cardName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return cards
    }
    
    // Calculate inbox count based on incomplete items
    var incompleteItemsCount: Int {
        firebaseService.cards.filter { !$0.isComplete }.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // TCG Search Bar
                TCGSearchBar(placeholder: "Search cards...", text: $searchText)
                    .padding(.horizontal, TCGSpacing.lg)
                    .padding(.top, TCGSpacing.md)
                
                if firebaseService.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: TCGTheme.primary))
                        Text("Loading cards...")
                            .font(TCGTypography.body)
                            .foregroundColor(TCGTheme.textSecondary)
                            .padding(.top, TCGSpacing.lg)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TCGTheme.background)
                } else if filteredCards.isEmpty {
                    VStack(spacing: TCGSpacing.xl) {
                        Image(systemName: showOnlyIncomplete ? "checkmark.circle" : "tray")
                            .font(.system(size: 60))
                            .foregroundColor(TCGTheme.textSecondary)
                        
                        Text(showOnlyIncomplete ? "No Incomplete Items" : "No Cards in Inventory")
                            .font(TCGTypography.titleMedium)
                            .foregroundColor(TCGTheme.textPrimary)
                        
                        Text(showOnlyIncomplete ? "All your cards are complete!" : "Add your first card using the 'Add Card' tab")
                            .font(TCGTypography.body)
                            .foregroundColor(TCGTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, TCGSpacing.xxxl)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(TCGTheme.background)
                } else {
                    ScrollView {
                        LazyVStack(spacing: TCGSpacing.md) {
                            ForEach(filteredCards) { card in
                                TCGInventoryCard(
                                    cardName: card.pokemonName,
                                    set: card.setName,
                                    condition: card.condition,
                                    price: "$\(String(format: "%.2f", card.acquisitionPrice))",
                                    quantity: 1,
                                    isHolo: card.condition.lowercased().contains("mint")
                                )
                                .onTapGesture {
                                    selectedCardForEdit = card
                                    showingEditSheet = true
                                }
                                .padding(.horizontal, TCGSpacing.lg)
                            }
                        }
                        .padding(.vertical, TCGSpacing.lg)
                    }
                    .refreshable {
                        await firebaseService.loadCards()
                    }
                }
            }
            .background(TCGTheme.background)
            .navigationTitle(showOnlyIncomplete ? "Incomplete Items" : "Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TCGTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showOnlyIncomplete.toggle()
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: showOnlyIncomplete ? "tray.fill" : "tray.full.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(showOnlyIncomplete ? TCGTheme.warning : TCGTheme.primary)
                            if incompleteItemsCount > 0 {
                                ZStack {
                                    Circle()
                                        .fill(TCGTheme.error)
                                    Text("\(min(incompleteItemsCount, 99))")
                                        .font(TCGTypography.captionSmall)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .frame(width: 18, height: 18)
                                .offset(x: 8, y: -8)
                                .transition(.scale)
                            }
                        }
                        .accessibilityLabel(showOnlyIncomplete ? "Show All Items" : "Show Incomplete Items")
                        .accessibilityHint(showOnlyIncomplete ? "Shows all items in inventory" : "Shows only incomplete items")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            .onAppear {
                Task {
                    await firebaseService.loadCards()
                }
            }
            .sheet(isPresented: $showingEditSheet, onDismiss: {
                Task {
                    await firebaseService.loadCards()
                }
            }) {
                if let card = selectedCardForEdit {
                    EditView(card: card, showingEditSheet: $showingEditSheet)
                        .environmentObject(authService)
                }
            }
        }
        .preferredColorScheme(.light)
    }
    

}



struct CameraView: View {
    @State private var showCamera: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: TCGSpacing.xxxl) {
                Spacer()
                
                VStack(spacing: TCGSpacing.xl) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(TCGTheme.primary)
                        .shadow(color: TCGTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Card Scanner")
                        .font(TCGTypography.titleLarge)
                        .foregroundColor(TCGTheme.textPrimary)
                    
                    Text("Capture photos of your trading cards for easy cataloging and identification")
                        .font(TCGTypography.body)
                        .foregroundColor(TCGTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, TCGSpacing.xxxl)
                }
                
                Button(action: {
                    showCamera = true
                }) {
                    HStack(spacing: TCGSpacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Open Camera")
                            .font(TCGTypography.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, TCGSpacing.xxxl)
                    .padding(.vertical, TCGSpacing.lg)
                }
                .tcgButtonStyle()
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(TCGTheme.background)
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(TCGTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showCamera) {
                CameraPicker(isPresented: $showCamera)
            }
        }
        .preferredColorScheme(.light)
    }
}

struct SummaryView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: TCGSpacing.xl) {
                    // Financial Overview Section
                    VStack(alignment: .leading, spacing: TCGSpacing.lg) {
                        Text("Financial Overview")
                            .font(TCGTypography.titleSmall)
                            .foregroundColor(TCGTheme.textPrimary)
                            .padding(.horizontal, TCGSpacing.lg)
                        
                        HStack(spacing: TCGSpacing.md) {
                            StatsCard(
                                title: "Total Expenses",
                                value: "$1,247.50",
                                subtitle: "This month",
                                color: TCGTheme.error
                            )
                            
                            StatsCard(
                                title: "Net Profit",
                                value: "$3,892.25",
                                subtitle: "This month",
                                color: TCGTheme.success
                            )
                        }
                    }
                    
                    // Show Performance Section
                    VStack(alignment: .leading, spacing: TCGSpacing.lg) {
                        Text("Show Performance")
                            .font(TCGTypography.titleSmall)
                            .foregroundColor(TCGTheme.textPrimary)
                            .padding(.horizontal, TCGSpacing.lg)
                        
                        VStack(spacing: TCGSpacing.md) {
                            TransactionRow(
                                type: .sale,
                                cardName: "Pokemon World Championships 2024",
                                amount: "+$1,250.00",
                                date: "This month",
                                customer: "Event Sales"
                            )
                            
                            TransactionRow(
                                type: .sale,
                                cardName: "Local Card Show - Spring",
                                amount: "+$875.50",
                                date: "This month",
                                customer: "Event Sales"
                            )
                            
                            TransactionRow(
                                type: .sale,
                                cardName: "Comic Con Trading",
                                amount: "+$1,150.75",
                                date: "This month",
                                customer: "Event Sales"
                            )
                            
                            TransactionRow(
                                type: .sale,
                                cardName: "Regional Tournament",
                                amount: "+$616.00",
                                date: "This month",
                                customer: "Event Sales"
                            )
                        }
                        .padding(.horizontal, TCGSpacing.lg)
                    }
                    
                    // Account Section
                    VStack(alignment: .leading, spacing: TCGSpacing.lg) {
                        Text("Account")
                            .font(TCGTypography.titleSmall)
                            .foregroundColor(TCGTheme.textPrimary)
                            .padding(.horizontal, TCGSpacing.lg)
                        
                        VStack(spacing: TCGSpacing.md) {
                            ProfileCard(
                                name: authService.user?.email ?? "Unknown",
                                role: "Vendor Account",
                                avatar: "envelope.fill"
                            )
                            
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                HStack(spacing: TCGSpacing.md) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(TCGTheme.error)
                                    
                                    Text("Sign Out")
                                        .font(TCGTypography.headline)
                                        .foregroundColor(TCGTheme.error)
                                    
                                    Spacer()
                                }
                                .padding(TCGSpacing.lg)
                                .background(TCGTheme.error.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(TCGTheme.error.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, TCGSpacing.lg)
                    }
                }
                .padding(.vertical, TCGSpacing.lg)
            }
            .background(TCGTheme.background)
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(TCGTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .preferredColorScheme(.light)
    }
}



// MARK: - Camera Picker
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Handle the captured image if needed
            parent.isPresented = false
        }
    }
}




