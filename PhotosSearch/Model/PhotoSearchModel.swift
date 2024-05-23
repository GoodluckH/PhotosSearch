//
//  PhotoSearchModel.swift
//  PhotosSearch
//
//  Created by Xipu Li on 5/22/24.
//

import Foundation
import CoreML
import Foundation
import Accelerate

struct PhotoSearcherModel {
    private var texEncoder: TextEncoder?
    
    mutating func load_text_encoder() {
        
        guard let myResourceURL = Bundle.main.resourceURL else {
            fatalError("Fatal error: failed to find the resource URL.")
        }
       
        // TODO: move the pipeline creation to background task because it's heavy
        
        let encoder = try! TextEncoder(resourcesAt: myResourceURL)
        texEncoder = encoder
    }
    
    func text_embedding(prompt: String) -> MLShapedArray<Float32> {
        let emb = try! texEncoder?.computeTextEmbedding(prompt: prompt)
        return emb!
    }
    
    func cosine_similarity(A: MLShapedArray<Float32>, B: MLShapedArray<Float32>) async -> Float {
        let magnitude = vDSP.sumOfSquares(A.scalars).squareRoot() * vDSP.sumOfSquares(B.scalars).squareRoot()
        let dotarray = vDSP.dot(A.scalars, B.scalars)
        return  dotarray / magnitude
    }
    
    func spherical_dist_loss(A: MLShapedArray<Float32>, B: MLShapedArray<Float32>) async -> Float {
        let a = vDSP.divide(A.scalars, sqrt(vDSP.sumOfSquares(A.scalars)))
        let b = vDSP.divide(B.scalars, sqrt(vDSP.sumOfSquares(B.scalars)))
        
        let magnitude = sqrt(vDSP.sumOfSquares(vDSP.subtract(a, b)))
        return pow(asin(magnitude / 2.0), 2) * 2.0
    }

}
