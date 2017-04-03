//
//  Indicator.swift
//  DSImageCache
//
//  Created by Dipak Sonara on 29/03/17.
//  Copyright © 2017 Dipak Sonara. All rights reserved.

import UIKit

public typealias IndicatorView = UIView

public enum IndicatorType {
    /// No indicator.
    case none
    /// Use system activity indicator.
    case activity
    /// Use an image as indicator. GIF is supported.
    case image(imageData: Data)
    /// Use a custom indicator, which conforms to the `Indicator` protocol.
    case custom(indicator: Indicator)
}

// MARK: - Indicator Protocol
public protocol Indicator {
    func startAnimatingView()
    func stopAnimatingView()

    var viewCenter: CGPoint { get set }
    var view: IndicatorView { get }
}

extension Indicator {
    
    public var viewCenter: CGPoint {
        get {
            return view.center
        }
        set {
            view.center = newValue
        }
    }
 
}

// MARK: - ActivityIndicator
// Displays a NSProgressIndicator / UIActivityIndicatorView
struct ActivityIndicator: Indicator {

    private let activityIndicatorView: UIActivityIndicatorView
    
    var view: IndicatorView {
        return activityIndicatorView
    }

    func startAnimatingView() {
        activityIndicatorView.startAnimating()
        activityIndicatorView.isHidden = false
    }

    func stopAnimatingView() {
        activityIndicatorView.stopAnimating()
        activityIndicatorView.isHidden = true
    }

    init() {

            let indicatorStyle = UIActivityIndicatorViewStyle.gray
            activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle:indicatorStyle)
            activityIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
    }
}

// MARK: - ImageIndicator
// Displays an ImageView. Supports gif
struct ImageIndicator: Indicator {
    private let animatedImageIndicatorView: ImageView

    var view: IndicatorView {
        return animatedImageIndicatorView
    }

    init?(imageData data: Data, processor: ImageProcessor = DefaultImageProcessor.default, options: DSImageCacheOptionsInfo = DSImageCacheEmptyOptionsInfo) {

        var options = options
        // Use normal image view to show gif, so we need to preload all gif data.
        if !options.preloadAllGIFData {
            options.append(.preloadAllGIFData)
        }
        
        guard let image = processor.process(item: .data(data), options: options) else {
            return nil
        }

        animatedImageIndicatorView = ImageView()
        animatedImageIndicatorView.image = image
        
        animatedImageIndicatorView.contentMode = .center
            
        animatedImageIndicatorView.autoresizingMask = [.flexibleLeftMargin,
                                                           .flexibleRightMargin,
                                                           .flexibleBottomMargin,
                                                           .flexibleTopMargin]
    }

    func startAnimatingView() {
        animatedImageIndicatorView.startAnimating()
        animatedImageIndicatorView.isHidden = false
    }

    func stopAnimatingView() {
        animatedImageIndicatorView.stopAnimating()
        animatedImageIndicatorView.isHidden = true
    }
}
