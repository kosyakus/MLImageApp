//
//  ViewModel.swift
//  MLImage_test
//
//  Created by Natalia Sinitsyna on 11.11.2024.
//

import Foundation
import Vision
import CoreML
import SwiftUI

class ViewModel: ObservableObject {
    @Published var selectedImage: UIImage? = nil
    @Published var recognitionResults: String = ""
    
    // импортировали модель
    private let initialModel: image_model? = {
        do {
            return try image_model(configuration: MLModelConfiguration())
        } catch {
            print("Error initializing model: \(error)")
            return nil
        }
    }()
    private var vnCoreMLModel: VNCoreMLModel? // оборачиваем модель
    private var request: VNCoreMLRequest? // делаем реквест (запрос)
    
    init() {
        guard let initialModel = initialModel else { return }
        vnCoreMLModel = try? VNCoreMLModel(for: initialModel.model)
        request = VNCoreMLRequest(model: vnCoreMLModel!, completionHandler: response)
    }
    
    func tryImage() {
        guard let image = selectedImage, let cgImage = image.cgImage else {
            print("Invalid image or cgImage is nil")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        do {
            try handler.perform([request!])
        } catch {
            print("Error performing request: \(error)")
        }
    }
    
    func response(request: VNRequest, error: Error?) {
        if let error = error {
            print("Error in response: \(error)")
            return
        }
        guard let observations = request.results as? [VNClassificationObservation] else {
            print("Unexpected result type")
            return
        }
        observations.forEach { ob in
            print("id: \(ob.identifier) : \(ob.confidence)")
        }
        
        // Форматируем результаты в строку и обновляем `recognitionResults`
        recognitionResults = observations.map { observation in
            "id: \(observation.identifier) : \(observation.confidence)"
        }.joined(separator: "\n")
    }
}
