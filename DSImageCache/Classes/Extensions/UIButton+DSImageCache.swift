//
//  UIButton+DSImageCache.swift
//  DSImageCache
//
//  Created by Dipak Sonara on 29/03/17.
//  Copyright © 2017 Dipak Sonara. All rights reserved.

import UIKit

// MARK: - Set Images
/**
 *	Set image to use in button from web for a specified state.
 */
extension DSImageCache where Base: UIButton {
    /**
     Set an image to use for a specified state with a resource, a placeholder image, options, progress handler and
     completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter state:             The state that uses the specified image.
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
                         for state: UIControlState,
                         placeholder: UIImage? = nil,
                         options: DSImageCacheOptionsInfo? = nil,
                         progressBlock: DownloadProgressBlock? = nil,
                         completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        guard let resource = resource else {
            base.setImage(placeholder, for: state)
            setWebURL(nil, for: state)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        let options = options ?? DSImageCacheEmptyOptionsInfo
        if !options.keepCurrentImageWhileLoading {
            base.setImage(placeholder, for: state)
        }
        
        setWebURL(resource.downloadURL, for: state)
        let task = DSImageCacheManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.webURL(for: state) else {
                    return
                }
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: {[weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let strongBase = base, imageURL == self.webURL(for: state) else {
                        return
                    }
                    self.setImageTask(nil)
                    
                    if image != nil {
                        strongBase.setImage(image, for: state)
                    }

                    completionHandler?(image, error, cacheType, imageURL)
                }
            })
        
        setImageTask(task)
        return task
    }
    
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func cancelImageDownloadTask() {
        imageTask?.cancel()
    }
    
    /**
     Set the background image to use for a specified state with a resource,
     a placeholder image, options progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter state:             The state that uses the specified image.
     - parameter placeholder:       A placeholder image when retrieving the image at URL.
     - parameter options:           A dictionary could control some behaviors. See `DSImageCacheOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.
     
     - returns: A task represents the retrieving process.
     
     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */
    @discardableResult
    public func setBackgroundImage(with resource: Resource?,
                                   for state: UIControlState,
                                   placeholder: UIImage? = nil,
                                   options: DSImageCacheOptionsInfo? = nil,
                                   progressBlock: DownloadProgressBlock? = nil,
                                   completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        guard let resource = resource else {
            base.setBackgroundImage(placeholder, for: state)
            setBackgroundWebURL(nil, for: state)
            completionHandler?(nil, nil, .none, nil)
            return .empty
        }
        
        let options = options ?? DSImageCacheEmptyOptionsInfo
        if !options.keepCurrentImageWhileLoading {
            base.setBackgroundImage(placeholder, for: state)
        }
        
        setBackgroundWebURL(resource.downloadURL, for: state)
        let task = DSImageCacheManager.shared.retrieveImage(
            with: resource,
            options: options,
            progressBlock: { receivedSize, totalSize in
                guard resource.downloadURL == self.backgroundWebURL(for: state) else {
                    return
                }
                if let progressBlock = progressBlock {
                    progressBlock(receivedSize, totalSize)
                }
            },
            completionHandler: { [weak base] image, error, cacheType, imageURL in
                DispatchQueue.main.safeAsync {
                    guard let strongBase = base, imageURL == self.backgroundWebURL(for: state) else {
                        return
                    }
                    self.setBackgroundImageTask(nil)
                    if image != nil {
                        strongBase.setBackgroundImage(image, for: state)
                    }
                    completionHandler?(image, error, cacheType, imageURL)
                }
            })
        
        setBackgroundImageTask(task)
        return task
    }
    
    /**
     Cancel the background image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    public func cancelBackgroundImageDownloadTask() {
        backgroundImageTask?.cancel()
    }

}

// MARK: - Associated Object
private var lastURLKey: Void?
private var imageTaskKey: Void?

extension DSImageCache where Base: UIButton {
    /**
     Get the image URL binded to this button for a specified state.
     
     - parameter state: The state that uses the specified image.
     
     - returns: Current URL for image.
     */
    public func webURL(for state: UIControlState) -> URL? {
        return webURLs[NSNumber(value:state.rawValue)] as? URL
    }
    
    fileprivate func setWebURL(_ url: URL?, for state: UIControlState) {
        webURLs[NSNumber(value:state.rawValue)] = url
    }
    
    fileprivate var webURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(base, &lastURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            setWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    fileprivate func setWebURLs(_ URLs: NSMutableDictionary) {
        objc_setAssociatedObject(base, &lastURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var imageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &imageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &imageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}


private var lastBackgroundURLKey: Void?
private var backgroundImageTaskKey: Void?


extension DSImageCache where Base: UIButton {
    /**
     Get the background image URL binded to this button for a specified state.
     
     - parameter state: The state that uses the specified background image.
     
     - returns: Current URL for background image.
     */
    public func backgroundWebURL(for state: UIControlState) -> URL? {
        return backgroundWebURLs[NSNumber(value:state.rawValue)] as? URL
    }
    
    fileprivate func setBackgroundWebURL(_ url: URL?, for state: UIControlState) {
        backgroundWebURLs[NSNumber(value:state.rawValue)] = url
    }
    
    fileprivate var backgroundWebURLs: NSMutableDictionary {
        var dictionary = objc_getAssociatedObject(base, &lastBackgroundURLKey) as? NSMutableDictionary
        if dictionary == nil {
            dictionary = NSMutableDictionary()
            setBackgroundWebURLs(dictionary!)
        }
        return dictionary!
    }
    
    fileprivate func setBackgroundWebURLs(_ URLs: NSMutableDictionary) {
        objc_setAssociatedObject(base, &lastBackgroundURLKey, URLs, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    fileprivate var backgroundImageTask: RetrieveImageTask? {
        return objc_getAssociatedObject(base, &backgroundImageTaskKey) as? RetrieveImageTask
    }
    
    fileprivate func setBackgroundImageTask(_ task: RetrieveImageTask?) {
        objc_setAssociatedObject(base, &backgroundImageTaskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Deprecated. Only for back compatibility.
/**
*	Set image to use from web for a specified state. Deprecated. Use `ds` namespacing instead.
*/
extension UIButton {
    /**
    Set an image to use for a specified state with a resource, a placeholder image, options, progress handler and 
     completion handler.
    
    - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
    - parameter state:             The state that uses the specified image.
    - parameter placeholder:       A placeholder image when retrieving the image at URL.
    - parameter options:           A dictionary could control some behaviors. See `DSImageCacheOptionsInfo` for more.
    - parameter progressBlock:     Called when the image downloading progress gets updated.
    - parameter completionHandler: Called when the image retrieved and set.
    
    - returns: A task represents the retrieving process.
     
    - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
    */
    @discardableResult
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.ds.setImage` instead.",
    renamed: "ds.setImage")
    public func ds_setImage(with resource: Resource?,
                                for state: UIControlState,
                              placeholder: UIImage? = nil,
                                  options: DSImageCacheOptionsInfo? = nil,
                            progressBlock: DownloadProgressBlock? = nil,
                        completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        return ds.setImage(with: resource, for: state, placeholder: placeholder, options: options,
                              progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
     Cancel the image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.ds.cancelImageDownloadTask` instead.",
    renamed: "ds.cancelImageDownloadTask")
    public func ds_cancelImageDownloadTask() { ds.cancelImageDownloadTask() }
    
    /**
     Set the background image to use for a specified state with a resource,
     a placeholder image, options progress handler and completion handler.
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter state:             The state that uses the specified image.
     - parameter placeholder:       A placeholder image when retrieving the image at URL.
     - parameter options:           A dictionary could control some behaviors. See `DSImageCacheOptionsInfo` for more.
     - parameter progressBlock:     Called when the image downloading progress gets updated.
     - parameter completionHandler: Called when the image retrieved and set.
     
     - returns: A task represents the retrieving process.
     
     - note: Both the `progressBlock` and `completionHandler` will be invoked in main thread.
     The `CallbackDispatchQueue` specified in `optionsInfo` will not be used in callbacks of this method.
     */
    @discardableResult
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.ds.setBackgroundImage` instead.",
    renamed: "ds.setBackgroundImage")
    public func ds_setBackgroundImage(with resource: Resource?,
                                      for state: UIControlState,
                                      placeholder: UIImage? = nil,
                                      options: DSImageCacheOptionsInfo? = nil,
                                      progressBlock: DownloadProgressBlock? = nil,
                                      completionHandler: CompletionHandler? = nil) -> RetrieveImageTask
    {
        return ds.setBackgroundImage(with: resource, for: state, placeholder: placeholder, options: options,
                                     progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /**
     Cancel the background image download task bounded to the image view if it is running.
     Nothing will happen if the downloading has already finished.
     */
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.ds.cancelBackgroundImageDownloadTask` instead.",
    renamed: "ds.cancelBackgroundImageDownloadTask")
    public func ds_cancelBackgroundImageDownloadTask() { ds.cancelBackgroundImageDownloadTask() }
    
    /**
     Get the image URL binded to this button for a specified state.
     
     - parameter state: The state that uses the specified image.
     
     - returns: Current URL for image.
     */
    @available(*, deprecated,
        message: "Extensions directly on UIButton are deprecated. Use `button.ds.webURL` instead.",
        renamed: "ds.webURL")
    public func ds_webURL(for state: UIControlState) -> URL? { return ds.webURL(for: state) }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "ds.setWebURL")
    fileprivate func ds_setWebURL(_ url: URL, for state: UIControlState) { ds.setWebURL(url, for: state) }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "ds.webURLs")
    fileprivate var ds_webURLs: NSMutableDictionary { return ds.webURLs }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "ds.setWebURLs")
    fileprivate func ds_setWebURLs(_ URLs: NSMutableDictionary) { ds.setWebURLs(URLs) }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "ds.imageTask")
    fileprivate var ds_imageTask: RetrieveImageTask? { return ds.imageTask }
    
    @available(*, deprecated, message: "Extensions directly on UIButton are deprecated.",renamed: "ds.setImageTask")
    fileprivate func ds_setImageTask(_ task: RetrieveImageTask?) { ds.setImageTask(task) }
    
    /**
     Get the background image URL binded to this button for a specified state.
     
     - parameter state: The state that uses the specified background image.
     
     - returns: Current URL for background image.
     */
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated. Use `button.ds.backgroundWebURL` instead.",
    renamed: "ds.backgroundWebURL")
    public func ds_backgroundWebURL(for state: UIControlState) -> URL? { return ds.backgroundWebURL(for: state) }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "ds.setBackgroundWebURL")
    fileprivate func ds_setBackgroundWebURL(_ url: URL, for state: UIControlState) {
        ds.setBackgroundWebURL(url, for: state)
    }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "ds.backgroundWebURLs")
    fileprivate var ds_backgroundWebURLs: NSMutableDictionary { return ds.backgroundWebURLs }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "ds.setBackgroundWebURLs")
    fileprivate func ds_setBackgroundWebURLs(_ URLs: NSMutableDictionary) { ds.setBackgroundWebURLs(URLs) }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "ds.backgroundImageTask")
    fileprivate var ds_backgroundImageTask: RetrieveImageTask? { return ds.backgroundImageTask }
    
    @available(*, deprecated,
    message: "Extensions directly on UIButton are deprecated.",renamed: "ds.setBackgroundImageTask")
    fileprivate func ds_setBackgroundImageTask(_ task: RetrieveImageTask?) { return ds.setBackgroundImageTask(task) }
    
}
