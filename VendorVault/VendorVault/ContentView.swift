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
    @State private var selectedCondition: Condition = .gemMint
    @State private var selectedLanguage: String = Locale.current.localizedString(forIdentifier: "en") ?? "English"
    @State private var setName: String = ""
    @State private var setNumber: String = ""
    @State private var showPokemonDropdown: Bool = false
    @State private var showSetDropdown: Bool = false
    @State private var cardImageURL: String? = nil
    @ObservedObject var pokemonFetcher = PokemonNameFetcher()
    @ObservedObject var setFetcher = PokemonSetFetcher()
    @ObservedObject var cardNumberFetcher = CardNumberFetcher()
    @ObservedObject var cardImageFetcher = CardImageFetcher()
    
    enum Condition: String, CaseIterable, Identifiable {
        case gemMint = "Gem Mint"
        case nearMint = "Near Mint"
        case lightlyPlayed = "Lightly Played"
        case moderatelyPlayed = "Moderately Played"
        case heavilyPlayed = "Heavily Played"
        case damaged = "Damaged"
        
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
    
    private func updateSetNumber() {
        guard !pokemonName.isEmpty && !setName.isEmpty else {
            setNumber = ""
            return
        }
        
        cardNumberFetcher.fetchCardNumber(pokemonName: pokemonName, setName: setName) { number in
            if let number = number {
                setNumber = number
                updateCardImage()
            }
        }
    }
    
    private func updateCardImage() {
        guard !setName.isEmpty && !setNumber.isEmpty else {
            cardImageURL = nil
            return
        }
        
        cardImageFetcher.fetchCardImage(setName: setName, setNumber: setNumber) { imageURL in
            cardImageURL = imageURL
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Card Name")) {
                TextField("Search or enter card name", text: $cardName)
                    .autocapitalization(.words)
                // Placeholder for card name search results
            }
            
            Section(header: Text("Pokemon Name")) {
                TextField("Search Pokemon name", text: $pokemonName)
                    .autocapitalization(.words)
                    .onChange(of: pokemonName) { _ in
                        showPokemonDropdown = !pokemonName.isEmpty && !filteredPokemonNames.isEmpty
                        updateSetNumber()
                    }
                    .onAppear {
                        pokemonFetcher.fetchPokemonNames()
                    }
                
                if showPokemonDropdown && !filteredPokemonNames.isEmpty {
                    ForEach(filteredPokemonNames, id: \.self) { name in
                        Button(action: {
                            pokemonName = name
                            showPokemonDropdown = false
                            updateSetNumber()
                        }) {
                            Text(name)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            Section(header: Text("Set Name")) {
                TextField("Search set name", text: $setName)
                    .autocapitalization(.words)
                    .onChange(of: setName) { _ in
                        showSetDropdown = !setName.isEmpty && !filteredSetNames.isEmpty
                        updateSetNumber()
                        updateCardImage()
                    }
                    .onAppear {
                        setFetcher.fetchSetNames()
                    }
                
                if showSetDropdown && !filteredSetNames.isEmpty {
                    ForEach(filteredSetNames, id: \.self) { name in
                        Button(action: {
                            setName = name
                            showSetDropdown = false
                            updateSetNumber()
                            updateCardImage()
                        }) {
                            Text(name)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            Section(header: Text("Set Number")) {
                HStack {
                    TextField("Set number", text: $setNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: setNumber) { _ in
                            updateCardImage()
                        }
                    
                    if cardNumberFetcher.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            
            Section(header: Text("Card Image")) {
                if let imageURL = cardImageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                    } placeholder: {
                        ProgressView()
                            .frame(height: 200)
                    }
                } else if cardImageFetcher.isLoading {
                    ProgressView("Loading card image...")
                        .frame(height: 200)
                } else {
                    Text("No card image available")
                        .foregroundColor(.secondary)
                        .frame(height: 100)
                }
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
        }
        .navigationTitle("Edit Card")
    }
}

struct InventoryView: View {
    var body: some View {
        VStack {
            Text("Inventory Tab")
        }
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
