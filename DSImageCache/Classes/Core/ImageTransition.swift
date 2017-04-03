//
//  ImageTransition.swift
//  DSImageCache
//
//  Created by Dipak Sonara on 29/03/17.
//  Copyright © 2017 Dipak Sonara. All rights reserved.


import UIKit

public enum ImageTransition {
    ///  No animation transistion.
    case none
    
    /// Fade in the loaded image.
    case fade(TimeInterval)

    /// Flip from left transition.
    case flipFromLeft(TimeInterval)

    /// Flip from right transition.
    case flipFromRight(TimeInterval)
    
    /// Flip from top transition.
    case flipFromTop(TimeInterval)
    
    /// Flip from bottom transition.
    case flipFromBottom(TimeInterval)
    
    /// Custom transition.
    case custom(duration: TimeInterval,
                 options: UIViewAnimationOptions,
              animations: ((UIImageView, UIImage) -> Void)?,
              completion: ((Bool) -> Void)?)
    
    var duration: TimeInterval {
        switch self {
        case .none:                          return 0
        case .fade(let duration):            return duration
            
        case .flipFromLeft(let duration):    return duration
        case .flipFromRight(let duration):   return duration
        case .flipFromTop(let duration):     return duration
        case .flipFromBottom(let duration):  return duration
            
        case .custom(let duration, _, _, _): return duration
        }
    }
    
    var animationOptions: UIViewAnimationOptions {
        switch self {
        case .none:                         return []
        case .fade(_):                      return .transitionCrossDissolve
            
        case .flipFromLeft(_):              return .transitionFlipFromLeft
        case .flipFromRight(_):             return .transitionFlipFromRight
        case .flipFromTop(_):               return .transitionFlipFromTop
        case .flipFromBottom(_):            return .transitionFlipFromBottom
            
        case .custom(_, let options, _, _): return options
        }
    }
    
    var animations: ((UIImageView, UIImage) -> Void)? {
        switch self {
        case .custom(_, _, let animations, _): return animations
        default: return { $0.image = $1 }
        }
    }
    
    var completion: ((Bool) -> Void)? {
        switch self {
        case .custom(_, _, _, let completion): return completion
        default: return nil
        }
    }
}
