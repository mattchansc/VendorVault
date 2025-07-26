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

// MARK: - Font Extensions for Modern Typography
extension Font {
    static func modernCaption(weight: Font.Weight = .medium) -> Font {
        return .system(.caption, design: .rounded, weight: weight)
    }
    
    static func modernSubheadline(weight: Font.Weight = .semibold) -> Font {
        return .system(.subheadline, design: .rounded, weight: weight)
    }
    
    static func modernHeadline(weight: Font.Weight = .semibold) -> Font {
        return .system(.headline, design: .rounded, weight: weight)
    }
    
    static func modernTitle(weight: Font.Weight = .bold) -> Font {
        return .system(.title, design: .rounded, weight: weight)
    }
    
    static func modernTitle2(weight: Font.Weight = .semibold) -> Font {
        return .system(.title2, design: .rounded, weight: weight)
    }
    
    static func modernLargeTitle(weight: Font.Weight = .bold) -> Font {
        return .system(.largeTitle, design: .rounded, weight: weight)
    }
    
    static func modernBody(weight: Font.Weight = .regular) -> Font {
        return .system(.body, design: .rounded, weight: weight)
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            EditView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Card")
                        .font(.modernCaption())
                }
                .tag(0)
            
            InventoryView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle")
                    Text("Inventory")
                        .font(.modernCaption())
                }
                .tag(1)
            
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                        .font(.modernCaption())
                }
                .tag(2)
            
            SummaryView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Summary")
                        .font(.modernCaption())
                }
                .tag(3)
        }
        .preferredColorScheme(.dark)
        .accentColor(.cyan)
        .background(Color.black.ignoresSafeArea())
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
    
    @ObservedObject var pokemonFetcher = PokemonNameFetcher()
    @ObservedObject var setFetcher = PokemonSetFetcher()
    @ObservedObject var cardNumberFetcher = CardNumberFetcher()
    @ObservedObject var cardImageFetcher = CardImageFetcher()
    @StateObject private var firebaseService = FirebaseService()
    
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
                try await firebaseService.saveCard(card)
                await MainActor.run {
                    isSaving = false
                    showSuccessAlert = true
                    clearForm()
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set Name")
                    .foregroundColor(.cyan)
                    .font(.modernSubheadline())
                    .textCase(nil)) {
                    TextField("Search or enter set name", text: $setName)
                        .autocapitalization(.words)
                        .onChange(of: setName) { _ in
                            showSetDropdown = !setName.isEmpty && !filteredSetNames.isEmpty
                            updateSetNumber()
                        }
                        .onAppear {
                            setFetcher.fetchSetNames()
                        }
                        .padding(.vertical, 8)
                    
                    if showSetDropdown && !filteredSetNames.isEmpty {
                        List(filteredSetNames, id: \.self) { name in
                            Button(action: {
                                setName = name
                                showSetDropdown = false
                            }) {
                                Text(name)
                                    .foregroundColor(.primary)
                            }
                            .listRowBackground(Color.black.opacity(0.3))
                        }
                        .frame(maxHeight: 150)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .cornerRadius(8)
                    }
                }
                
                Section(header: Text("Set Number")
                    .foregroundColor(.cyan)
                    .font(.modernSubheadline())
                    .textCase(nil)) {
                    HStack {
                        TextField("Card set number", text: $setNumber)
                            .keyboardType(.numberPad)
                            .onChange(of: setNumber) { _ in
                                // updateCardImage() // Removed as per edit hint
                            }
                            .padding(.vertical, 8)
                        if cardNumberFetcher.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        }
                    }
                }
                
                Section(header: Text("Pokemon Name")
                    .foregroundColor(.cyan)
                    .font(.modernSubheadline())
                    .textCase(nil)) {
                    TextField("Search or enter Pokemon name", text: $pokemonName)
                        .autocapitalization(.words)
                        .onChange(of: pokemonName) { _ in
                            showPokemonDropdown = !pokemonName.isEmpty && !filteredPokemonNames.isEmpty
                            updateSetNumber()
                        }
                        .onAppear {
                            pokemonFetcher.fetchPokemonNames()
                        }
                        .padding(.vertical, 8)
                    
                    if showPokemonDropdown && !filteredPokemonNames.isEmpty {
                        List(filteredPokemonNames, id: \.self) { name in
                            Button(action: {
                                pokemonName = name
                                showPokemonDropdown = false
                            }) {
                                Text(name)
                                    .foregroundColor(.primary)
                            }
                            .listRowBackground(Color.black.opacity(0.3))
                        }
                        .frame(maxHeight: 150)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .cornerRadius(8)
                    }
                }
                
                Section(header: Text("Acquisition Price")
                    .foregroundColor(.cyan)
                    .font(.modernSubheadline())
                    .textCase(nil)) {
                    HStack {
                        Text("$")
                            .foregroundColor(.green)
                            .font(.modernTitle2())
                        TextField("0.00", text: $acquisitionPrice)
                            .keyboardType(.decimalPad)
                            .onChange(of: acquisitionPrice) { newValue in
                                // Format the input to ensure it's a valid currency format
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != newValue {
                                    acquisitionPrice = filtered
                                }
                            }
                            .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Card Name")
                    .foregroundColor(.cyan)
                    .font(.modernSubheadline())
                    .textCase(nil)) {
                    TextField("Search or enter card name", text: $cardName)
                        .autocapitalization(.words)
                        .padding(.vertical, 8)
                    // Placeholder for card name search results
                }
                
                Section(header: Text("Condition")
                    .foregroundColor(.cyan)
                    .font(.modernSubheadline())
                    .textCase(nil)) {
                    Picker("Condition", selection: $selectedCondition) {
                        ForEach(Condition.allCases) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.vertical, 8)
                    .background(Color.clear)
                }
                
                Section(header: Text("Language")
                    .foregroundColor(.cyan)
                    .font(.modernSubheadline())
                    .textCase(nil)) {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(isoLanguageCodes.compactMap { code in
                            Locale.current.localizedString(forIdentifier: code)
                        }.sorted(), id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.vertical, 8)
                    .background(Color.clear)
                }
                
                Section(header: Text("Item Type")
                    .foregroundColor(.cyan)
                    .font(.modernSubheadline())
                    .textCase(nil)) {
                    Picker("Item Type", selection: $selectedItemType) {
                        ForEach(ItemType.allCases) { itemType in
                            Text(itemType.rawValue).tag(itemType)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.vertical, 8)
                    .background(Color.clear)
                }
                
                Section(header: Text("QR Code ID")
                    .foregroundColor(.cyan)
                    .font(.modernSubheadline())
                    .textCase(nil)) {
                    TextField("QR Code ID", text: $qrCodeID)
                        .onChange(of: qrCodeID) { _ in
                            // No specific action on change, just for display
                        }
                        .onAppear {
                            qrCodeID = generateUniqueQRCode()
                        }
                        .padding(.vertical, 8)
                    
                    Text("Generated: \(qrCodeID)")
                        .font(.modernCaption(weight: .regular))
                        .foregroundColor(.secondary)
                    
                    // Display the QR Code Image
                    if !qrCodeID.isEmpty {
                        VStack(spacing: 16) {
                            Text("Scannable QR Code")
                                .font(.modernHeadline())
                                .foregroundColor(.cyan)
                                .padding(.top)
                            
                            Image(uiImage: generateQRCode(from: qrCodeID))
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 5)
                                )
                            
                            Text("Scan this code to identify this card entry")
                                .font(.modernCaption(weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.bottom)
                        }
                        .padding(.vertical)
                    }
                }
                
                // Submit button section
                Section {
                    Button(action: {
                        // TODO: Implement submit action to save/process the card data
                        print("Submit button tapped - implement save functionality here")
                    }) {
                        HStack {
                            Spacer()
                            Text("Submit Card")
                                .font(.modernHeadline())
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .cyan.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Add or Edit Card")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                pokemonFetcher.fetchPokemonNames()
                setFetcher.fetchSetNames()
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct InventoryView: View {
    @StateObject private var firebaseService = FirebaseService()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Incomplete Inventory")
                        .foregroundColor(.orange)
                        .font(.modernHeadline())
                }) {
                    InventoryCard(
                        title: "Pikachu - Base Set",
                        subtitle: "Missing condition",
                        isIncomplete: true,
                        icon: "questionmark.circle.fill"
                    )
                    
                    InventoryCard(
                        title: "Charizard - Base Set",
                        subtitle: "Missing set number",
                        isIncomplete: true,
                        icon: "number.circle.fill"
                    )
                    
                    InventoryCard(
                        title: "Blastoise - Base Set",
                        subtitle: "Missing acquisition price",
                        isIncomplete: true,
                        icon: "dollarsign.circle.fill"
                    )
                }
                .listRowBackground(Color.clear)
                
                Section(header: HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Complete Inventory")
                        .foregroundColor(.green)
                        .font(.modernHeadline())
                }) {
                    InventoryCard(
                        title: "Mewtwo - Base Set #150",
                        subtitle: "Near Mint • $45.00",
                        isIncomplete: false,
                        icon: "star.fill"
                    )
                    
                    InventoryCard(
                        title: "Alakazam - Base Set #1",
                        subtitle: "Lightly Played • $32.50",
                        isIncomplete: false,
                        icon: "star.fill"
                    )
                    
                    InventoryCard(
                        title: "Venusaur - Base Set #15",
                        subtitle: "Near Mint • $38.75",
                        isIncomplete: false,
                        icon: "star.fill"
                    )
                    
                    InventoryCard(
                        title: "Gyarados - Base Set #6",
                        subtitle: "Gem Mint • $125.00",
                        isIncomplete: false,
                        icon: "gem"
                    )
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

struct InventoryCard: View {
    let title: String
    let subtitle: String
    let isIncomplete: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
                            Image(systemName: icon)
                    .font(.modernTitle2(weight: .medium))
                    .foregroundColor(isIncomplete ? .orange : .cyan)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.modernHeadline())
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.modernSubheadline(weight: .regular))
                    .foregroundColor(isIncomplete ? .orange : .secondary)
            }
            
            Spacer()
            
            if !isIncomplete {
                Image(systemName: "chevron.right")
                    .font(.modernCaption())
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isIncomplete 
                        ? Color.orange.opacity(0.1)
                        : Color.cyan.opacity(0.1)
                )
                .stroke(
                    isIncomplete 
                        ? Color.orange.opacity(0.3)
                        : Color.cyan.opacity(0.3),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isIncomplete 
                ? Color.orange.opacity(0.2)
                : Color.cyan.opacity(0.2),
            radius: 5,
            x: 0,
            y: 2
        )
    }
}

struct CameraView: View {
    @State private var showCamera: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80, design: .rounded))
                        .foregroundColor(.cyan)
                        .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("Card Scanner")
                        .font(.modernLargeTitle())
                        .foregroundColor(.primary)
                    
                    Text("Capture photos of your trading cards for easy cataloging and identification")
                        .font(.modernBody())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Button(action: {
                    showCamera = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.modernTitle2(weight: .medium))
                        Text("Open Camera")
                            .font(.modernHeadline())
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.cyan, .blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("Camera")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showCamera) {
                CameraPicker(isPresented: $showCamera)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SummaryView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.cyan)
                    Text("Financial Overview")
                        .foregroundColor(.cyan)
                        .font(.modernHeadline())
                }) {
                    FinancialCard(
                        title: "Total Expenses",
                        amount: "$1,247.50",
                        color: .red,
                        icon: "minus.circle.fill"
                    )
                    
                    FinancialCard(
                        title: "Net Profit",
                        amount: "$3,892.25",
                        color: .green,
                        icon: "plus.circle.fill"
                    )
                }
                .listRowBackground(Color.clear)
                
                Section(header: HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    Text("Show Performance")
                        .foregroundColor(.yellow)
                        .font(.modernHeadline())
                }) {
                    ShowPerformanceCard(
                        showName: "Pokemon World Championships 2024",
                        profit: "$1,250.00",
                        icon: "crown.fill"
                    )
                    
                    ShowPerformanceCard(
                        showName: "Local Card Show - Spring",
                        profit: "$875.50",
                        icon: "storefront.fill"
                    )
                    
                    ShowPerformanceCard(
                        showName: "Comic Con Trading",
                        profit: "$1,150.75",
                        icon: "person.3.fill"
                    )
                    
                    ShowPerformanceCard(
                        showName: "Regional Tournament",
                        profit: "$616.00",
                        icon: "gamecontroller.fill"
                    )
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.black.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

struct FinancialCard: View {
    let title: String
    let amount: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.modernTitle(weight: .medium))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.modernHeadline())
                    .foregroundColor(.primary)
                
                Text(amount)
                    .font(.modernTitle2(weight: .bold))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

struct ShowPerformanceCard: View {
    let showName: String
    let profit: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.modernTitle2(weight: .medium))
                .foregroundColor(.cyan)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(showName)
                    .font(.modernHeadline())
                    .foregroundColor(.primary)
                
                Text("Profit: \(profit)")
                    .font(.modernSubheadline(weight: .medium))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.modernCaption())
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cyan.opacity(0.1))
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .cyan.opacity(0.2), radius: 5, x: 0, y: 2)
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
