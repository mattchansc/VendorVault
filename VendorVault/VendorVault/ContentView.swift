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

struct EditView: View {
    var body: some View {
        VStack {
            Text("Edit Tab")
        }
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
