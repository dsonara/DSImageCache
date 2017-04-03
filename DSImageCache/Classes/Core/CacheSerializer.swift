//
//  CacheSerializer.swift
//  DSImageCache
//
//  Created by Dipak Sonara on 29/03/17.
//  Copyright © 2017 Dipak Sonara. All rights reserved.

import Foundation

/// An `CacheSerializer` would be used to convert some data to an image object for 
/// retrieving from disk cache and vice versa for storing to disk cache.
public protocol CacheSerializer {
    
    /// Get the serialized data from a provided image
    /// and optional original data for caching to disk.
    ///
    ///
    /// - parameter image:    The image needed to be serialized.
    /// - parameter original: The original data which is just downloaded. 
    ///                       If the image is retrieved from cache instead of
    ///                       downloaded, it will be `nil`.
    ///
    /// - returns: A data which will be stored to cache, or `nil` when no valid
    ///            data could be serialized.
    func data(with image: Image, original: Data?) -> Data?
    
    /// Get an image deserialized from provided data.
    ///
    /// - parameter data:    The data from which an image should be deserialized.
    /// - parameter options: Options for deserialization.
    ///
    /// - returns: An image deserialized or `nil` when no valid image 
    ///            could be deserialized.
    func image(with data: Data, options: DSImageCacheOptionsInfo?) -> Image?
}


/// `DefaultCacheSerializer` is a basic `CacheSerializer` used in default cache of
/// DSImageCache. It could serialize and deserialize PNG, JEPG and GIF images. For 
/// image other than these formats, a normalized `pngRepresentation` will be used.
public struct DefaultCacheSerializer: CacheSerializer {
    
    public static let `default` = DefaultCacheSerializer()
    private init() {}
    
    public func data(with image: Image, original: Data?) -> Data? {
        let imageFormat = original?.ds.imageFormat ?? .unknown
        
        let data: Data?
        switch imageFormat {
        case .PNG: data = image.ds.pngRepresentation()
        case .JPEG: data = image.ds.jpegRepresentation(compressionQuality: 1.0)
        case .GIF: data = image.ds.gifRepresentation()
        case .unknown: data = original ?? image.ds.normalized.ds.pngRepresentation()
        }
        
        return data
    }
    
    public func image(with data: Data, options: DSImageCacheOptionsInfo?) -> Image? {
        let options = options ?? DSImageCacheEmptyOptionsInfo
        return DSImageCache<Image>.image(
            data: data,
            scale: options.scaleFactor,
            preloadAllGIFData: options.preloadAllGIFData,
            onlyFirstFrame: options.onlyLoadFirstFrame)
    }
}
