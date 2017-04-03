//
//  ImageView+DSImageCache.swift
//  DSImageCache
//
//  Created by Dipak Sonara on 29/03/17.
//  Copyright © 2017 Dipak Sonara. All rights reserved.
//

import UIKit

// MARK: - Extension methods.
/**
 *	Set image to use from web.
 */
extension DSImageCache where Base: ImageView {
    /**
     Set an image with a resource, a placeholder image, options, progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter placeholder:       A placeholder image when retrieving the image at URL.
     - parameter options:           A dictionary could control some behaviors. See `DSImageCacheOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.
     
     - returns: A task represents the retrieving process.
     
     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */
    @discardableResult
    public func setImage(with resource: Resource?,
                         placeholder: Image? = nil,
                         options: DSImageCacheOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        guard let resource = resource else {
            base.image = placeholder
            setWebURL(nil)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        var options = options ?? DSImageCacheEmptyOptionsInfo
        
        if !options.keepCurrentImageWhileLoading {
            base.image = placeholder
        }

        let maybeIndicator = indicator
        maybeIndicator?.startAnimatingView()
        
        setWebURL(resource.downloadURL)

        if base.shouldPreloadAllGIF() {
            options.append(.preloadAllGIFData)
        }
        
        let task = DSImageCacheManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.webURL else {
                    return
                }
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: {[weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let strongBase = base, imageURL == self.webURL else {
                        return
                    }
                    self.setImageTask(nil)
                    guard let image = image else {
                        maybeIndicator?.stopAnimatingView()
                        completionHandler?(nil, error, cacheType, imageURL)
                        return
                    }
                    
                    guard let transitionItem = options.firstMatchIgnoringAssociatedValue(.transition(.none)),
                        case .transition(let transition) = transitionItem, ( options.forceTransition || cacheType == .none) else
                    {
                        maybeIndicator?.stopAnimatingView()
                        strongBase.image = image
                        completionHandler?(image, error, cacheType, imageURL)
                        return
                    }
                    
                        UIView.transition(with: strongBase, duration: 0.0, options: [],
                                          animations: { maybeIndicator?.stopAnimatingView() },
                                          completion: { _ in
                                            UIView.transition(with: strongBase, duration: transition.duration,
                                                              options: [transition.animationOptions, .allowUserInteraction],
                                                              animations: {
                                                                // Set image property in the animation.
                                                                transition.animations?(strongBase, image)
                                                              },
                                                              completion: { finished in
                                                                transition.completion?(finished)
                                                                completionHandler?(image, error, cacheType, imageURL)
                                                              })
                                          })
                }
            })
        
        setImageTask(task)
        
        return task
    }
    
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func cancelDownloadTask() {
        imageTask?.cancel()
    }
}

// MARK: - Associated Object
private var lastURLKey: Void?
private var indicatorKey: Void?
private var indicatorTypeKey: Void?
private var imageTaskKey: Void?

extension DSImageCache where Base: ImageView {
    /// Get the image URL binded to this image view.
    public var webURL: URL? {
        return objc_getAssociatedObject(base, &lastURLKey) as? URL
    }
    
    fileprivate func setWebURL(_ url: URL?) {
        objc_setAssociatedObject(base, &lastURLKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /// Holds which indicator type is going to be used.
    /// Default is .none, means no indicator will be shown.
    public var indicatorType: IndicatorType {
        get {
            let indicator = (objc_getAssociatedObject(base, &indicatorTypeKey) as? Box<IndicatorType?>)?.value
            return indicator ?? .none
        }
        
        set {
            switch newValue {
            case .none:
                indicator = nil
            case .activity:
                indicator = ActivityIndicator()
            case .image(let data):
                indicator = ImageIndicator(imageData: data)
            case .custom(let anIndicator):
                indicator = anIndicator
            }
            
            objc_setAssociatedObject(base, &indicatorTypeKey, Box(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Holds any type that conforms to the protocol `Indicator`.
    /// The protocol `Indicator` has a `view` property that will be shown when loading an image.
    /// It will be `nil` if `indicatorType` is `.none`.
    public fileprivate(set) var indicator: Indicator? {
        get {
            return (objc_getAssociatedObject(base, &indicatorKey) as? Box<Indicator?>)?.value
        }
        
        set {
            // Remove previous
            if let previousIndicator = indicator {
                previousIndicator.view.removeFromSuperview()
            }
            
            // Add new
            if var newIndicator = newValue {
                newIndicator.view.frame = base.frame
                newIndicator.viewCenter = CGPoint(x: base.bounds.midX, y: base.bounds.midY)
                newIndicator.view.isHidden = true
                base.addSubview(newIndicator.view)
            }
            
            // Save in associated object
            objc_setAssociatedObject(base, &indicatorKey, Box(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &imageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}


// MARK: - Deprecated. Only for back compatibility.
/**
*	Set image to use from web. Deprecated. Use `ds` namespacing instead.
*/
extension ImageView {
    /**
    Set an image with a resource, a placeholder image, options, progress handler and completion handler.
    
    - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter placeholder:       A placeholder image when retrieving the image at URL.
    - parameter options:           A dictionary could control some behaviors. See `DSImageCacheOptionsInfo` for more.
    - parameter progressBlock:     Called when the image downloading progress gets updated.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread. 
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    @available(*, deprecated, message: "Extensions directly on image views are deprecated. Use `imageView.ds.setImage` instead.", renamed: "ds.setImage")
    @discardableResult
    public func ds_setImage(with resource: Resource?,
                              placeholder: Image? = nil,
                                  options: DSImageCacheOptionsInfo? = nil,
                            progressBlock: DownloadProgressBlock? = nil,
                        completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        return ds.setImage(with: resource, placeholder: placeholder, options: options, progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    @available(*, deprecated, message: "Extensions directly on image views are deprecated. Use `imageView.ds.cancelDownloadTask` instead.", renamed: "ds.cancelDownloadTask")
    public func ds_cancelDownloadTask() { ds.cancelDownloadTask() }
    
    /// Get the image URL binded to this image view.
    @available(*, deprecated, message: "Extensions directly on image views are deprecated. Use `imageView.ds.webURL` instead.", renamed: "ds.webURL")
    public var ds_webURL: URL? { return ds.webURL }
    
    /// Holds which indicator type is going to be used.
    /// Default is .none, means no indicator will be shown.
    @available(*, deprecated, message: "Extensions directly on image views are deprecated. Use `imageView.ds.indicatorType` instead.", renamed: "ds.indicatorType")
    public var ds_indicatorType: IndicatorType {
        get { return ds.indicatorType }
        set { ds.indicatorType = newValue }
    }
    
    @available(*, deprecated, message: "Extensions directly on image views are deprecated. Use `imageView.ds.indicator` instead.", renamed: "ds.indicator")
    /// Holds any type that conforms to the protocol `Indicator`.
    /// The protocol `Indicator` has a `view` property that will be shown when loading an image.
    /// It will be `nil` if `ds_indicatorType` is `.none`.
    public private(set) var ds_indicator: Indicator? {
        get { return ds.indicator }
        set { ds.indicator = newValue }
    }
    
    @available(*, deprecated, message: "Extensions directly on image views are deprecated.", renamed: "ds.imageTask")
    fileprivate var ds_imageTask: RetrieveImageTask? { return ds.imageTask }
    @available(*, deprecated, message: "Extensions directly on image views are deprecated.", renamed: "ds.setImageTask")
    fileprivate func ds_setImageTask(_ task: RetrieveImageTask?) { ds.setImageTask(task) }
    @available(*, deprecated, message: "Extensions directly on image views are deprecated.", renamed: "ds.setWebURL")
    fileprivate func ds_setWebURL(_ url: URL) { ds.setWebURL(url) }
}

extension ImageView {
    func shouldPreloadAllGIF() -> Bool { return true }
}
