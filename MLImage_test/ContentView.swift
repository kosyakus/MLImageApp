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
    @State private var showCamera = false  // Переменная для отображения камеры
    
    var body: some View {
        VStack {
            if viewModel.selectedImage != nil {
                Image(uiImage: viewModel.selectedImage!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .padding(.top, 20)
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
            } label: {
                Text("Распознать через камеру")
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
            .frame(maxWidth: .infinity, maxHeight: 200)
            
            
        }
        .padding()
    }
}
