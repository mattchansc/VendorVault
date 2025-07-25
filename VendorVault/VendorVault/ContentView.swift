//
//  ContentView.swift
//  VendorVault
//
//  Created by Matthew Chan on 7/20/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .edit
    @State private var showCamera: Bool = false
    
    enum Tab: String, CaseIterable, Identifiable {
        case edit = "Edit"
        case inventory = "Inventory"
        case camera = "Camera"
        case summary = "Summary"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .edit: return "pencil"
            case .inventory: return "archivebox"
            case .camera: return "camera"
            case .summary: return "doc.text.magnifyingglass"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sheet(isPresented: $showCamera) {
                    CameraPicker(isPresented: $showCamera)
                }
            Divider()
            customTabBar
                .padding(.bottom, 12)
                .padding(.top, 4)
                .background(Color(.systemGroupedBackground))
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch selectedTab {
        case .edit:
            EditView()
        case .inventory:
            InventoryView()
        case .camera:
            CameraView()
        case .summary:
            SummaryView()
        }
    }
    
    private var customTabBar: some View {
        HStack {
            ForEach(Tab.allCases) { tab in
                Button(action: {
                    if tab == .camera {
                        showCamera = true
                    } else {
                        selectedTab = tab
                    }
                }) {
                    VStack {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(selectedTab == tab ? .accentColor : .gray)
                        Text(tab.rawValue)
                            .font(.caption)
                            .foregroundColor(selectedTab == tab ? .accentColor : .gray)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == tab ? Color(.systemGray5) : Color.clear)
                    .cornerRadius(8)
                }
            }
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
        Form {
            Section(header: Text("Set Name")) {
                TextField("Search or enter set name", text: $setName)
                    .autocapitalization(.words)
                    .onChange(of: setName) { _ in
                        showSetDropdown = !setName.isEmpty && !filteredSetNames.isEmpty
                        updateSetNumber()
                    }
                    .onAppear {
                        setFetcher.fetchSetNames()
                    }
                
                if showSetDropdown && !filteredSetNames.isEmpty {
                    List(filteredSetNames, id: \.self) { name in
                        Button(action: {
                            setName = name
                            showSetDropdown = false
                        }) {
                            Text(name)
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
            
            Section(header: Text("Set Number")) {
                HStack {
                    TextField("Card set number", text: $setNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: setNumber) { _ in
                            // updateCardImage() // Removed as per edit hint
                        }
                    if cardNumberFetcher.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            
            Section(header: Text("Pokemon Name")) {
                TextField("Search or enter Pokemon name", text: $pokemonName)
                    .autocapitalization(.words)
                    .onChange(of: pokemonName) { _ in
                        showPokemonDropdown = !pokemonName.isEmpty && !filteredPokemonNames.isEmpty
                        updateSetNumber()
                    }
                    .onAppear {
                        pokemonFetcher.fetchPokemonNames()
                    }
                
                if showPokemonDropdown && !filteredPokemonNames.isEmpty {
                    List(filteredPokemonNames, id: \.self) { name in
                        Button(action: {
                            pokemonName = name
                            showPokemonDropdown = false
                        }) {
                            Text(name)
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }
            
            Section(header: Text("Acquisition Price")) {
                HStack {
                    Text("$")
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $acquisitionPrice)
                        .keyboardType(.decimalPad)
                        .onChange(of: acquisitionPrice) { newValue in
                            // Format the input to ensure it's a valid currency format
                            let filtered = newValue.filter { "0123456789.".contains($0) }
                            if filtered != newValue {
                                acquisitionPrice = filtered
                            }
                        }
                }
            }
            
            Section(header: Text("Card Name")) {
                TextField("Search or enter card name", text: $cardName)
                    .autocapitalization(.words)
                // Placeholder for card name search results
            }
            
            Section(header: Text("Condition")) {
                Picker("Condition", selection: $selectedCondition) {
                    ForEach(Condition.allCases) { condition in
                        Text(condition.rawValue).tag(condition)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Section(header: Text("Language")) {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(isoLanguageCodes.compactMap { code in
                        Locale.current.localizedString(forIdentifier: code)
                    }.sorted(), id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Section(header: Text("Item Type")) {
                Picker("Item Type", selection: $selectedItemType) {
                    ForEach(ItemType.allCases) { itemType in
                        Text(itemType.rawValue).tag(itemType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Submit button section
            Section {
                Button(action: {
                    saveCard()
                }) {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Submit")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(isSaving ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isSaving)
            }
        }
        .navigationTitle("Add or edit card")
        .onAppear {
            pokemonFetcher.fetchPokemonNames()
            setFetcher.fetchSetNames()
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Card saved successfully!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct InventoryView: View {
    @StateObject private var firebaseService = FirebaseService()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if firebaseService.isLoading {
                    ProgressView("Loading cards...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if firebaseService.cards.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No cards in inventory")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Add your first card using the Edit tab")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(firebaseService.cards) { card in
                            CardRowView(card: card, firebaseService: firebaseService)
                        }
                    }
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search by Pokemon name")
            .onChange(of: searchText) { newValue in
                if newValue.isEmpty {
                    Task {
                        await firebaseService.loadCards()
                    }
                } else {
                    Task {
                        await firebaseService.searchCards(query: newValue)
                    }
                }
            }
            .refreshable {
                await firebaseService.loadCards()
            }
        }
        .onAppear {
            Task {
                await firebaseService.loadCards()
            }
        }
    }
}

struct CardRowView: View {
    let card: PokemonCard
    let firebaseService: FirebaseService
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text(card.pokemonName)
                    .font(.headline)
                Text(card.setName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("$\(String(format: "%.2f", card.acquisitionPrice))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                Text(card.condition)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
                    .padding(6)
            }
            .buttonStyle(PlainButtonStyle())
            .alert("Delete Card", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        isDeleting = true
                        do {
                            try await firebaseService.deleteCard(card)
                        } catch {
                            errorMessage = error.localizedDescription
                            showingErrorAlert = true
                        }
                        isDeleting = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this card?")
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

struct CameraView: View {
    var body: some View {
        VStack {
            Text("Camera Tab")
            Text("Tap the Camera tab below to launch camera.")
        }
    }
}

struct SummaryView: View {
    var body: some View {
        VStack {
            Text("Summary Tab")
        }
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
