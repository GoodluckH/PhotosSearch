//
//  NSImage+Extension.swift
//  PhotosSearch
//
//  Created by Xipu Li on 5/22/24.
//

import Foundation
import AppKit

extension NSImage {
    
    /// Returns the height of the current image.
    var height: CGFloat {
        return self.size.height
    }
    
    /// Returns the width of the current image.
    var width: CGFloat {
        return self.size.width
    }
    
    /// Returns a png representation of the current image.
    var PNGRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }
        
        return nil
    }
    
    func convertToBuffer() -> CVPixelBuffer? {
         let width = Int(self.size.width)
         let height = Int(self.size.height)
         
         let attributes = [
             kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
         ] as CFDictionary
         
         var pixelBuffer: CVPixelBuffer?
         
         let status = CVPixelBufferCreate(
             kCFAllocatorDefault, width, height,
             kCVPixelFormatType_32ARGB,
             attributes,
             &pixelBuffer)
         
         guard status == kCVReturnSuccess else {
             return nil
         }
         
         CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
         
         guard let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!) else {
             CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
             return nil
         }
         
         let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
         
         guard let context = CGContext(
             data: pixelData,
             width: width,
             height: height,
             bitsPerComponent: 8,
             bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
             space: rgbColorSpace,
             bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                 CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
                 return nil
         }
         
         context.translateBy(x: 0, y: CGFloat(height))
         context.scaleBy(x: 1.0, y: -1.0)
         
         let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
         if let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) {
             context.draw(cgImage, in: rect)
         }
         
         CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
         
         return pixelBuffer
     }
    
    ///  Copies the current image and resizes it to the given size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func copy(size: NSSize) -> NSImage? {
        // Create a new rect with given width and height
        let frame = NSMakeRect(0, 0, size.width, size.height)
        
        // Get the best representation for the given size.
        guard let rep = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create an empty image with the given size.
        let img = NSImage(size: size)
        
        // Set the drawing context and make sure to remove the focus before returning.
        img.lockFocus()
        defer { img.unlockFocus() }
        
        // Draw the new image
        if rep.draw(in: frame) {
            return img
        }
        
        // Return nil in case something went wrong.
        return nil
    }
    
    /// Copies the current image and resizes it to the size of the given NSSize, without
    /// maintaining the aspect ratio of the original image.
    ///
    /// - parameter size: The size of the new image.
    ///
    /// - returns: The resized copy of the given image.
    func resize(to size: NSSize) -> NSImage? {
        let newImage = NSImage(size: size)
        
        newImage.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        self.draw(in: rect, from: NSRect(origin: .zero, size: self.size), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
    }
    
    ///  Copies the current image and resizes it to the size of the given NSSize, while
    ///  maintaining the aspect ratio of the original image.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func resizeWhileMaintainingAspectRatio(to size: NSSize) -> NSImage? {
        let newSize: NSSize
        
        let widthRatio  = size.width / self.width
        let heightRatio = size.height / self.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio), height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio), height: floor(self.height * heightRatio))
        }
        
        return self.copy(size: newSize)
    }
    
    ///  Copies and crops an image to the supplied size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The cropped copy of the given image.
    func crop(size: NSSize) -> NSImage? {
        // Resize the current image, while preserving the aspect ratio.
        guard let resized = self.resizeWhileMaintainingAspectRatio(to: size) else {
            return nil
        }
        // Get some points to center the cropping area.
        let x = floor((resized.width - size.width) / 2)
        let y = floor((resized.height - size.height) / 2)
        
        // Create the cropping frame.
        let frame = NSMakeRect(x, y, size.width, size.height)
        
        // Get the best representation of the image for the given cropping frame.
        guard let rep = resized.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create a new image with the new size
        let img = NSImage(size: size)
        
        img.lockFocus()
        defer { img.unlockFocus() }
        
        if rep.draw(in: NSMakeRect(0, 0, size.width, size.height),
                    from: frame,
                    operation: NSCompositingOperation.copy,
                    fraction: 1.0,
                    respectFlipped: false,
                    hints: [:]) {
            // Return the cropped image.
            return img
        }
        
        // Return nil in case anything fails.
        return nil
    }
    
    ///  Saves the PNG representation of the current image to the HD.
    ///
    /// - parameter url: The location url to which to write the png file.
    func savePNGRepresentationToURL(url: URL) throws {
        if let png = self.PNGRepresentation {
            try png.write(to: url, options: .atomicWrite)
        }
    }
}
