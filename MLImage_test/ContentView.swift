//
//  ContentView.swift
//  MLImage_test
//
//  Created by Natalia Sinitsyna on 10.11.2024.
//

import SwiftUI
import PhotosUI
import UIKit

struct ContentView: View {
    @StateObject var viewModel = ViewModel()
    
    @State var showSelection = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showARView = false
    
    var body: some View {
        VStack {
            
            if showARView {
                ARViewContainer(viewModel: viewModel)
                    .frame(height: 300)
                    .padding()
            }
            
            if viewModel.selectedImage != nil && showARView == false {
                Image(uiImage: viewModel.selectedImage!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .padding()
            }
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()) {
                    Text("Загрузить фото из галлереи")
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            DispatchQueue.main.async {
                                viewModel.selectedImage = UIImage(data: data)
                            }
                        }
                    }
                }
            
            Button {
                viewModel.tryImage()
            } label: {
                Text("Распознать фото")
            }
            
            Button {
                showCamera = true
                showARView = false
            } label: {
                Text("Распознать через камеру")
            }
            
            Button {
                showARView = true
            } label: {
                Text("Распознать через ARView")
            }
            
            .sheet(isPresented: $showCamera) {
                CameraView(image: $viewModel.selectedImage, onImageCaptured: {
                    viewModel.tryImage()
                })
            }
            
            // Добавляем TextView для отображения результатов
            ScrollView {
                Text(viewModel.recognitionResults)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: 300)
            
            
        }
        .padding()
    }
}
