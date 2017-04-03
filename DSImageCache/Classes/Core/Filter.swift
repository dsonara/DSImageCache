//
//  Filter.swift
//  DSImageCache
//
//  Created by Dipak Sonara on 29/03/17.
//  Copyright © 2017 Dipak Sonara. All rights reserved.



import CoreImage
import Accelerate

// Reuse the same CI Context for all CI drawing.
private let ciContext = CIContext(options: nil)

/// Transformer method which will be used in to provide a `Filter`.
public typealias Transformer = (CIImage) -> CIImage?

/// Supply a filter to create an `ImageProcessor`.
public protocol CIImageProcessor: ImageProcessor {
    var filter: Filter { get }
}

extension CIImageProcessor {
    public func process(item: ImageProcessItem, options: DSImageCacheOptionsInfo) -> Image? {
        switch item {
        case .image(let image):
            return image.ds.apply(filter)
        case .data(_):
            return (DefaultImageProcessor.default >> self).process(item: item, options: options)
        }
    }
}

/// Wrapper for a `Transformer` of CIImage filters.
public struct Filter {
    
    let transform: Transformer

    public init(tranform: @escaping Transformer) {
        self.transform = tranform
    }
    
    /// Tint filter which will apply a tint color to images.
    public static var tint: (Color) -> Filter = {
        color in
        Filter { input in
            let colorFilter = CIFilter(name: "CIConstantColorGenerator")!
            colorFilter.setValue(CIColor(color: color), forKey: kCIInputColorKey)
            
            let colorImage = colorFilter.outputImage
            let filter = CIFilter(name: "CISourceOverCompositing")!
            filter.setValue(colorImage, forKey: kCIInputImageKey)
            filter.setValue(input, forKey: kCIInputBackgroundImageKey)
            return filter.outputImage?.cropping(to: input.extent)
        }
    }
    
    public typealias ColorElement = (CGFloat, CGFloat, CGFloat, CGFloat)
    
    /// Color control filter which will apply color control change to images.
    public static var colorControl: (ColorElement) -> Filter = {
        brightness, contrast, saturation, inputEV in
        Filter { input in
            let paramsColor = [kCIInputBrightnessKey: brightness,
                               kCIInputContrastKey: contrast,
                               kCIInputSaturationKey: saturation]
            
            let blackAndWhite = input.applyingFilter("CIColorControls", withInputParameters: paramsColor)
            let paramsExposure = [kCIInputEVKey: inputEV]
            return blackAndWhite.applyingFilter("CIExposureAdjust", withInputParameters: paramsExposure)
        }
        
    }
}

extension DSImageCache where Base: Image {
    /// Apply a `Filter` containing `CIImage` transformer to `self`.
    ///
    /// - parameter filter: The filter used to transform `self`.
    ///
    /// - returns: A transformed image by input `Filter`.
    ///
    /// - Note: Only CG-based images are supported. If any error happens during transforming, `self` will be returned.
    public func apply(_ filter: Filter) -> Image {
        
        guard let cgImage = cgImage else {
            assertionFailure("[DSImageCache] Tint image only works for CG-based image.")
            return base
        }
        
        let inputImage = CIImage(cgImage: cgImage)
        guard let outputImage = filter.transform(inputImage) else {
            return base
        }
        
        guard let result = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            assertionFailure("[DSImageCache] Can not make an tint image within context.")
            return base
        }
        
        return Image(cgImage: result, scale: base.scale, orientation: base.imageOrientation)
    }

}

public extension Image {
    
    /// Apply a `Filter` containing `CIImage` transformer to `self`.
    ///
    /// - parameter filter: The filter used to transform `self`.
    ///
    /// - returns: A transformed image by input `Filter`.
    ///
    /// - Note: Only CG-based images are supported. If any error happens during transforming, `self` will be returned.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `ds.apply` instead.",
    renamed: "ds.apply")
    public func ds_apply(_ filter: Filter) -> Image {
        return ds.apply(filter)
    }
}
