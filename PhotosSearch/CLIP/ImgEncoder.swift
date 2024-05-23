//
//  ImgEncoder.swift
//  PhotosSearch
//
//  Created by Xipu Li on 5/22/24.
//

import Foundation
import CoreML
import AppKit

public struct ImgEncoder {
    var model: MLModel
    
    init(resourcesAt baseURL: URL,
         configuration config: MLModelConfiguration = .init()
    ) throws {
        let imgEncoderURL = baseURL.appending(path:"ImageEncoder_float32.mlmodelc")
        let imgEncoderModel = try MLModel(contentsOf: imgEncoderURL, configuration: config)
        self.model = imgEncoderModel
    }
    
    public func computeImgEmbedding(img: NSImage) async throws -> MLShapedArray<Float32> {
        let imgEmbedding = try await self.encode(image: img)
        return imgEmbedding
    }
    
//    public init(model: MLModel) {
//        self.model = model
//    }
    
    /// Prediction queue
    let queue = DispatchQueue(label: "imgencoder.predict")
    
    private func encode(image: NSImage) async throws -> MLShapedArray<Float32> {
        do {
            guard let resizedImage = image.resize(to: NSSize(width: 224, height: 224)) else {
                throw ImageEncodingError.resizeError
            }
            
            guard let buffer = resizedImage.convertToBuffer() else {
                throw ImageEncodingError.bufferConversionError
            }
            
            guard let inputFeatures = try? MLDictionaryFeatureProvider(dictionary: ["colorImage": buffer]) else {
                throw ImageEncodingError.featureProviderError
            }
            
            let result = try queue.sync { try model.prediction(from: inputFeatures) }
            guard let embeddingFeature = result.featureValue(for: "embOutput"),
                  let multiArray = embeddingFeature.multiArrayValue else {
                throw ImageEncodingError.predictionError
            }
            
            return MLShapedArray<Float32>(converting: multiArray)
        } catch {
            print("Error in encoding: \(error)")
            throw error
        }
    }
}

// Define the custom errors
enum ImageEncodingError: Error {
    case resizeError
    case bufferConversionError
    case featureProviderError
    case predictionError
}
