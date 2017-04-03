//
//  Image.swift
//  DSImageCache
//
//  Created by Dipak Sonara on 29/03/17.
//  Copyright © 2017 Dipak Sonara. All rights reserved.


import UIKit
import Accelerate   
import MobileCoreServices
private var imageSourceKey: Void?

private var animatedImageDataKey: Void?

import ImageIO
import CoreGraphics

// MARK: - Image Properties
extension DSImageCache where Base: Image {
    fileprivate(set) var animatedImageData: Data? {
        get {
            return objc_getAssociatedObject(base, &animatedImageDataKey) as? Data
        }
        set {
            objc_setAssociatedObject(base, &animatedImageDataKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var cgImage: CGImage? {
        return base.cgImage
    }
    
    var scale: CGFloat {
        return base.scale
    }
    
    var images: [Image]? {
        return base.images
    }
    
    var duration: TimeInterval {
        return base.duration
    }
    
    fileprivate(set) var imageSource: ImageSource? {
        get {
            return objc_getAssociatedObject(base, &imageSourceKey) as? ImageSource
        }
        set {
            objc_setAssociatedObject(base, &imageSourceKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var size: CGSize {
        return base.size
    }
}

// MARK: - Image Conversion
extension DSImageCache where Base: Image {
    
    static func image(cgImage: CGImage, scale: CGFloat, refImage: Image?) -> Image {
        if let refImage = refImage {
            return Image(cgImage: cgImage, scale: scale, orientation: refImage.imageOrientation)
        } else {
            return Image(cgImage: cgImage, scale: scale, orientation: .up)
        }
    }
    
    /**
     Normalize the image. This method will try to redraw an image with orientation and scale considered.
     
     - returns: The normalized image with orientation set to up and correct scale.
     */
    public var normalized: Image {
        // prevent animated image (GIF) lose it's images
        guard images == nil else { return base }
        // No need to do anything if already up
        guard base.imageOrientation != .up else { return base }
    
        return draw(cgImage: nil, to: size) {
            base.draw(in: CGRect(origin: CGPoint.zero, size: size))
        }
    }
    
    static func animated(with images: [Image], forDuration duration: TimeInterval) -> Image? {
        return .animatedImage(with: images, duration: duration)
    }
}

// MARK: - Image Representation
extension DSImageCache where Base: Image {
    // MARK: - PNG
    public func pngRepresentation() -> Data? {
        
            return UIImagePNGRepresentation(base)

    }
    
    // MARK: - JPEG
    public func jpegRepresentation(compressionQuality: CGFloat) -> Data? {
        
            return UIImageJPEGRepresentation(base, compressionQuality)
        
    }
    
    // MARK: - GIF
    public func gifRepresentation() -> Data? {
        return animatedImageData
    }
}

// MARK: - Create images from data
extension DSImageCache where Base: Image {
    static func animated(with data: Data, scale: CGFloat = 1.0, duration: TimeInterval = 0.0, preloadAll: Bool, onlyFirstFrame: Bool = false) -> Image? {
        
        func decode(from imageSource: CGImageSource, for options: NSDictionary) -> ([Image], TimeInterval)? {
            
            //Calculates frame duration for a gif frame out of the kCGImagePropertyGIFDictionary dictionary
            func frameDuration(from gifInfo: NSDictionary?) -> Double {
                let gifDefaultFrameDuration = 0.100
                
                guard let gifInfo = gifInfo else {
                    return gifDefaultFrameDuration
                }
                
                let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber
                let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber
                let duration = unclampedDelayTime ?? delayTime
                
                guard let frameDuration = duration else { return gifDefaultFrameDuration }
                
                return frameDuration.doubleValue > 0.011 ? frameDuration.doubleValue : gifDefaultFrameDuration
            }
            
            let frameCount = CGImageSourceGetCount(imageSource)
            var images = [Image]()
            var gifDuration = 0.0
            for i in 0 ..< frameCount {
                
                guard let imageRef = CGImageSourceCreateImageAtIndex(imageSource, i, options) else {
                    return nil
                }

                if frameCount == 1 {
                    // Single frame
                    gifDuration = Double.infinity
                } else {
                    
                    // Animated GIF
                    guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) else {
                        return nil
                    }

                    let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as String] as? NSDictionary
                    gifDuration += frameDuration(from: gifInfo)
                }
                
                images.append(DSImageCache<Image>.image(cgImage: imageRef, scale: scale, refImage: nil))
                
                if onlyFirstFrame { break }
            }
            
            return (images, gifDuration)
        }
        
        // Start of ds.animatedImageWithGIFData
        let options: NSDictionary = [kCGImageSourceShouldCache as String: true, kCGImageSourceTypeIdentifierHint as String: kUTTypeGIF]
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options) else {
            return nil
        }
      
            let image: Image?
            if preloadAll || onlyFirstFrame {
                guard let (images, gifDuration) = decode(from: imageSource, for: options) else { return nil }
                image = onlyFirstFrame ? images.first : DSImageCache<Image>.animated(with: images, forDuration: duration <= 0.0 ? gifDuration : duration)
            } else {
                image = Image(data: data)
                image?.ds.imageSource = ImageSource(ref: imageSource)
            }
            image?.ds.animatedImageData = data
            return image
        
    }
    
    static func image(data: Data, scale: CGFloat, preloadAllGIFData: Bool, onlyFirstFrame: Bool) -> Image? {
        var image: Image?
        
            switch data.ds.imageFormat {
            case .JPEG:
                image = Image(data: data, scale: scale)
            case .PNG:
                image = Image(data: data, scale: scale)
            case .GIF:
                image = DSImageCache<Image>.animated(
                    with: data,
                    scale: scale,
                    duration: 0.0,
                    preloadAll: preloadAllGIFData,
                    onlyFirstFrame: onlyFirstFrame)
            case .unknown:
                image = Image(data: data, scale: scale)
            }
        return image
    }
}

// MARK: - Image Transforming
extension DSImageCache where Base: Image {

    // MARK: - Round Corner
    /// Create a round corner image based on `self`.
    ///
    /// - parameter radius: The round corner radius of creating image.
    /// - parameter size:   The target size of creating image.
    ///
    /// - returns: An image with round corner of `self`.
    ///
    /// - Note: This method only works for CG-based image.
    public func image(withRoundRadius radius: CGFloat, fit size: CGSize) -> Image {
        
        guard let cgImage = cgImage else {
            assertionFailure("[DSImageCache] Round corner image only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(cgImage: cgImage, to: size) {
            
                guard let context = UIGraphicsGetCurrentContext() else {
                    assertionFailure("[DSImageCache] Failed to create CG context for image.")
                    return
                }
                let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: radius, height: radius)).cgPath
                context.addPath(path)
                context.clip()
                base.draw(in: rect)
            
        }
    }
    
    func resize(to size: CGSize, for contentMode: UIViewContentMode) -> Image {
        switch contentMode {
        case .scaleAspectFit:
            return resize(to: size, for: .aspectFit)
        case .scaleAspectFill:
            return resize(to: size, for: .aspectFill)
        default:
            return resize(to: size)
        }
    }
    
    // MARK: - Resize
    /// Resize `self` to an image of new size.
    ///
    /// - parameter size: The target size.
    ///
    /// - returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image.
    public func resize(to size: CGSize) -> Image {
        
        guard let cgImage = cgImage else {
            assertionFailure("[DSImageCache] Resize only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        return draw(cgImage: cgImage, to: size) {
                base.draw(in: rect)
        }
    }
    
    /// Resize `self` to an image of new size, respecting the content mode.
    ///
    /// - Parameters:
    ///   - size: The target size.
    ///   - contentMode: Content mode of output image should be.
    /// - Returns: An image with new size.
    public func resize(to size: CGSize, for contentMode: ContentMode) -> Image {
        switch contentMode {
        case .aspectFit:
            let newSize = self.size.ds.constrained(size)
            return resize(to: newSize)
        case .aspectFill:
            let newSize = self.size.ds.filling(size)
            return resize(to: newSize)
        default:
            return resize(to: size)
        }
    }
    
    public func crop(to size: CGSize, anchorOn anchor: CGPoint) -> Image {
        guard let cgImage = cgImage else {
            assertionFailure("[DSImageCache] Crop only works for CG-based image.")
            return base
        }
        
        let rect = self.size.ds.constrainedRect(for: size, anchor: anchor)
        guard let image = cgImage.cropping(to: rect) else {
            assertionFailure("[DSImageCache] Cropping image failed.")
            return base
        }
        
        return DSImageCache.image(cgImage: image, scale: scale, refImage: base)
    }
    
    // MARK: - Blur
    
    /// Create an image with blur effect based on `self`.
    ///
    /// - parameter radius: The blur radius should be used when creating blue.
    ///
    /// - returns: An image with blur effect applied.
    ///
    /// - Note: This method only works for CG-based image.
    public func blurred(withRadius radius: CGFloat) -> Image {
        
            guard let cgImage = cgImage else {
                assertionFailure("[Kingfisher] Blur only works for CG-based image.")
                return base
            }
            
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            // if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            let s = Float(max(radius, 2.0))
            // We will do blur on a resized image (*0.5), so the blur radius could be half as well.
            
            // Fix the slow compiling time for Swift 3.
            // See https://github.com/onevcat/Kingfisher/issues/611
            let pi2 = 2 * Float.pi
            let sqrtPi2 = sqrt(pi2)
            var targetRadius = floor(s * 3.0 * sqrtPi2 / 4.0 + 0.5)
            
            if targetRadius.isEven {
                targetRadius += 1
            }
            
            let iterations: Int
            if radius < 0.5 {
                iterations = 1
            } else if radius < 1.5 {
                iterations = 2
            } else {
                iterations = 3
            }
            
            let w = Int(size.width)
            let h = Int(size.height)
            let rowBytes = Int(CGFloat(cgImage.bytesPerRow))
            
            func createEffectBuffer(_ context: CGContext) -> vImage_Buffer {
                let data = context.data
                let width = vImagePixelCount(context.width)
                let height = vImagePixelCount(context.height)
                let rowBytes = context.bytesPerRow
                
                return vImage_Buffer(data: data, height: height, width: width, rowBytes: rowBytes)
            }
            
            guard let context = beginContext(size: size) else {
                assertionFailure("[Kingfisher] Failed to create CG context for blurring image.")
                return base
            }
            defer { endContext() }
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
            
            var inBuffer = createEffectBuffer(context)
            
            guard let outContext = beginContext(size: size) else {
                assertionFailure("[Kingfisher] Failed to create CG context for blurring image.")
                return base
            }
            defer { endContext() }
            var outBuffer = createEffectBuffer(outContext)
            
            for _ in 0 ..< iterations {
                vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, UInt32(targetRadius), UInt32(targetRadius), nil, vImage_Flags(kvImageEdgeExtend))
                (inBuffer, outBuffer) = (outBuffer, inBuffer)
            }
            
            let result = outContext.makeImage().flatMap { Image(cgImage: $0, scale: base.scale, orientation: base.imageOrientation) }
            
            guard let blurredImage = result else {
                assertionFailure("[Kingfisher] Can not make an blurred image within this context.")
                return base
            }
            
            return blurredImage
        
    }
    
    // MARK: - Overlay
    
    /// Create an image from `self` with a color overlay layer.
    ///
    /// - parameter color:    The color should be use to overlay.
    /// - parameter fraction: Fraction of input color. From 0.0 to 1.0. 0.0 means solid color, 1.0 means transparent overlay.
    ///
    /// - returns: An image with a color overlay applied.
    ///
    /// - Note: This method only works for CG-based image.
    public func overlaying(with color: Color, fraction: CGFloat) -> Image {
        
        guard let cgImage = cgImage else {
            assertionFailure("[DSImageCache] Overlaying only works for CG-based image.")
            return base
        }
        
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        return draw(cgImage: cgImage, to: rect.size) {
                color.set()
                UIRectFill(rect)
                base.draw(in: rect, blendMode: .destinationIn, alpha: 1.0)
                
                if fraction > 0 {
                    base.draw(in: rect, blendMode: .sourceAtop, alpha: fraction)
                }
        }
    }
    
    // MARK: - Tint
    
    /// Create an image from `self` with a color tint.
    ///
    /// - parameter color: The color should be used to tint `self`
    ///
    /// - returns: An image with a color tint applied.
    public func tinted(with color: Color) -> Image {
            return apply(.tint(color))
    }
    
    // MARK: - Color Control
    
    /// Create an image from `self` with color control.
    ///
    /// - parameter brightness: Brightness changing to image.
    /// - parameter contrast:   Contrast changing to image.
    /// - parameter saturation: Saturation changing to image.
    /// - parameter inputEV:    InputEV changing to image.
    ///
    /// - returns: An image with color control applied.
    public func adjusted(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) -> Image {
            return apply(.colorControl(brightness, contrast, saturation, inputEV))
    }
}

// MARK: - Decode
extension DSImageCache where Base: Image {
    var decoded: Image? {
        return decoded(scale: scale)
    }
    
    func decoded(scale: CGFloat) -> Image {
        // prevent animated image (GIF) lose it's images
            if imageSource != nil { return base }
        
        guard let imageRef = self.cgImage else {
            assertionFailure("[DSImageCache] Decoding only works for CG-based image.")
            return base
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = beginContext(size: CGSize(width: imageRef.width, height: imageRef.height)) else {
            assertionFailure("[DSImageCache] Decoding fails to create a valid context.")
            return base
        }
        
        defer { endContext() }
        
        let rect = CGRect(x: 0, y: 0, width: imageRef.width, height: imageRef.height)
        context.draw(imageRef, in: rect)
        let decompressedImageRef = context.makeImage()
        return DSImageCache<Image>.image(cgImage: decompressedImageRef!, scale: scale, refImage: base)
    }
}

/// Reference the source image reference
class ImageSource {
    var imageRef: CGImageSource?
    init(ref: CGImageSource) {
        self.imageRef = ref
    }
}

// MARK: - Image format
private struct ImageHeaderData {
    static var PNG: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    static var JPEG_SOI: [UInt8] = [0xFF, 0xD8]
    static var JPEG_IF: [UInt8] = [0xFF]
    static var GIF: [UInt8] = [0x47, 0x49, 0x46]
}

enum ImageFormat {
    case unknown, PNG, JPEG, GIF
}


// MARK: - Misc Helpers
public struct DataProxy {
    fileprivate let base: Data
    init(proxy: Data) {
        base = proxy
    }
}

extension Data: DSImageCacheCompatible {
    public typealias CompatibleType = DataProxy
    public var ds: DataProxy {
        return DataProxy(proxy: self)
    }
}

extension DataProxy {
    var imageFormat: ImageFormat {
        var buffer = [UInt8](repeating: 0, count: 8)
        (base as NSData).getBytes(&buffer, length: 8)
        if buffer == ImageHeaderData.PNG {
            return .PNG
        } else if buffer[0] == ImageHeaderData.JPEG_SOI[0] &&
            buffer[1] == ImageHeaderData.JPEG_SOI[1] &&
            buffer[2] == ImageHeaderData.JPEG_IF[0]
        {
            return .JPEG
        } else if buffer[0] == ImageHeaderData.GIF[0] &&
            buffer[1] == ImageHeaderData.GIF[1] &&
            buffer[2] == ImageHeaderData.GIF[2]
        {
            return .GIF
        }

        return .unknown
    }
}

public struct CGSizeProxy {
    fileprivate let base: CGSize
    init(proxy: CGSize) {
        base = proxy
    }
}

extension CGSize: DSImageCacheCompatible {
    public typealias CompatibleType = CGSizeProxy
    public var ds: CGSizeProxy {
        return CGSizeProxy(proxy: self)
    }
}

extension CGSizeProxy {
    func constrained(_ size: CGSize) -> CGSize {
        let aspectWidth = round(aspectRatio * size.height)
        let aspectHeight = round(size.width / aspectRatio)

        return aspectWidth > size.width ? CGSize(width: size.width, height: aspectHeight) : CGSize(width: aspectWidth, height: size.height)
    }

    func filling(_ size: CGSize) -> CGSize {
        let aspectWidth = round(aspectRatio * size.height)
        let aspectHeight = round(size.width / aspectRatio)

        return aspectWidth < size.width ? CGSize(width: size.width, height: aspectHeight) : CGSize(width: aspectWidth, height: size.height)
    }

    private var aspectRatio: CGFloat {
        return base.height == 0.0 ? 1.0 : base.width / base.height
    }
    
    
    func constrainedRect(for size: CGSize, anchor: CGPoint) -> CGRect {
        
        let unifiedAnchor = CGPoint(x: anchor.x.clamped(to: 0.0...1.0),
                                    y: anchor.y.clamped(to: 0.0...1.0))
        
        let x = unifiedAnchor.x * base.width - unifiedAnchor.x * size.width
        let y = unifiedAnchor.y * base.height - unifiedAnchor.y * size.height
        let r = CGRect(x: x, y: y, width: size.width, height: size.height)
        
        let ori = CGRect(origin: CGPoint.zero, size: base)
        return ori.intersection(r)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension DSImageCache where Base: Image {
    
    func beginContext(size: CGSize) -> CGContext? {
        
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            let context = UIGraphicsGetCurrentContext()
            context?.scaleBy(x: 1.0, y: -1.0)
            context?.translateBy(x: 0, y: -size.height)
            return context
        
    }
    
    func endContext() {
            UIGraphicsEndImageContext()
    }
    
    func draw(cgImage: CGImage?, to size: CGSize, draw: ()->()) -> Image {
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw()
        return UIGraphicsGetImageFromCurrentImageContext() ?? base
        
    }
}

extension Float {
    var isEven: Bool {
        return truncatingRemainder(dividingBy: 2.0) == 0
    }
}

// MARK: - Deprecated. Only for back compatibility.
extension Image {
    /**
     Normalize the image. This method does nothing in OS X.
     
     - returns: The image itself.
     */
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `ds.normalized` instead.",
    renamed: "ds.normalized")
    public func ds_normalized() -> Image {
        return ds.normalized
    }
    
    // MARK: - Round Corner
    
    /// Create a round corner image based on `self`.
    ///
    /// - parameter radius: The round corner radius of creating image.
    /// - parameter size:   The target size of creating image.
    /// - parameter scale:  The image scale of creating image.
    ///
    /// - returns: An image with round corner of `self`.
    ///
    /// - Note: This method only works for CG-based image.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `ds.image(withRoundRadius:fit:scale:)` instead.",
    renamed: "ds.image")
    public func ds_image(withRoundRadius radius: CGFloat, fit size: CGSize, scale: CGFloat) -> Image {
        return ds.image(withRoundRadius: radius, fit: size)
    }
    
    // MARK: - Resize
    /// Resize `self` to an image of new size.
    ///
    /// - parameter size: The target size.
    ///
    /// - returns: An image with new size.
    ///
    /// - Note: This method only works for CG-based image.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `ds.resize(to:)` instead.",
    renamed: "ds.resize")
    public func ds_resize(to size: CGSize) -> Image {
        return ds.resize(to: size)
    }
    
    // MARK: - Blur
    /// Create an image with blur effect based on `self`.
    ///
    /// - parameter radius: The blur radius should be used when creating blue.
    ///
    /// - returns: An image with blur effect applied.
    ///
    /// - Note: This method only works for CG-based image.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `ds.blurred(withRadius:)` instead.",
    renamed: "ds.blurred")
    public func ds_blurred(withRadius radius: CGFloat) -> Image {
        return ds.blurred(withRadius: radius)
    }
    
    // MARK: - Overlay
    /// Create an image from `self` with a color overlay layer.
    ///
    /// - parameter color:    The color should be use to overlay.
    /// - parameter fraction: Fraction of input color. From 0.0 to 1.0. 0.0 means solid color, 1.0 means transparent overlay.
    ///
    /// - returns: An image with a color overlay applied.
    ///
    /// - Note: This method only works for CG-based image.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `ds.overlaying(with:fraction:)` instead.",
    renamed: "ds.overlaying")
    public func ds_overlaying(with color: Color, fraction: CGFloat) -> Image {
        return ds.overlaying(with: color, fraction: fraction)
    }
    
    // MARK: - Tint
    
    /// Create an image from `self` with a color tint.
    ///
    /// - parameter color: The color should be used to tint `self`
    ///
    /// - returns: An image with a color tint applied.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `ds.tinted(with:)` instead.",
    renamed: "ds.tinted")
    public func ds_tinted(with color: Color) -> Image {
        return ds.tinted(with: color)
    }
    
    // MARK: - Color Control
    
    /// Create an image from `self` with color control.
    ///
    /// - parameter brightness: Brightness changing to image.
    /// - parameter contrast:   Contrast changing to image.
    /// - parameter saturation: Saturation changing to image.
    /// - parameter inputEV:    InputEV changing to image.
    ///
    /// - returns: An image with color control applied.
    @available(*, deprecated,
    message: "Extensions directly on Image are deprecated. Use `ds.adjusted` instead.",
    renamed: "ds.adjusted")
    public func ds_adjusted(brightness: CGFloat, contrast: CGFloat, saturation: CGFloat, inputEV: CGFloat) -> Image {
        return ds.adjusted(brightness: brightness, contrast: contrast, saturation: saturation, inputEV: inputEV)
    }
}

extension DSImageCache where Base: Image {
    @available(*, deprecated,
    message: "`scale` is not used. Use the version without scale instead. (Remove the `scale` argument)")
    public func image(withRoundRadius radius: CGFloat, fit size: CGSize, scale: CGFloat) -> Image {
        return image(withRoundRadius: radius, fit: size)
    }
}
