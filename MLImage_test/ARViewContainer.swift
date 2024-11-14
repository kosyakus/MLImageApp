//
//  ARViewContainer.swift
//  MLImage_test
//
//  Created by Natalia Sinitsyna on 14.11.2024.
//

import SwiftUI
import ARKit
import Vision

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ViewModel  // Подключаем ViewModel для передачи результатов

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        arView.delegate = context.coordinator
        arView.session.run(ARWorldTrackingConfiguration())
        
        // Настройка камеры для анализа изображения
        arView.scene = SCNScene()
        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        private var request: VNCoreMLRequest?
        private var lastProcessedTime: TimeInterval = 0  // Время последней обработки
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()
            setupModel()
        }
        
        private func setupModel() {
            guard let model = try? image_model(configuration: MLModelConfiguration()).model else { return }
            let vnModel = try? VNCoreMLModel(for: model)
            request = VNCoreMLRequest(model: vnModel!, completionHandler: handleResults)
        }

        // Выполнение запроса на каждом кадре AR-сцены
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            guard let currentFrame = (renderer as? ARSCNView)?.session.currentFrame else { return }
            
            // Проверка интервала времени: если прошло меньше 2 секунд, обработка не выполняется
            if time - lastProcessedTime < 1.0 {
                return
            }
            lastProcessedTime = time  // Обновляем время последней обработки
            
            let ciImage = CIImage(cvPixelBuffer: currentFrame.capturedImage)
            
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try? handler.perform([request!])
        }
        
        // Обработка результатов запроса
        private func handleResults(request: VNRequest, error: Error?) {
            guard error == nil,
                  let observations = request.results as? [VNClassificationObservation] else { return }

            // Форматируем результаты в строку и обновляем ViewModel
            DispatchQueue.main.async {
                self.parent.viewModel.recognitionResults = observations.map {
                    "id: \($0.identifier) : \($0.confidence)"
                }.joined(separator: "\n")
            }
        }
    }
}
