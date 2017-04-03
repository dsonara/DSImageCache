//
//  DSImageCache.swift
//  DSImageCache
//
//  Created by Dipak Sonara on 29/03/17.
//  Copyright © 2017 Dipak Sonara. All rights reserved.

import Foundation
import ImageIO

import UIKit
public typealias Image = UIImage
public typealias Color = UIColor
public typealias ImageView = UIImageView
typealias Button = UIButton

public final class DSImageCache<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

/**
 A type that has DSImageCache extensions.
 */
public protocol DSImageCacheCompatible {
    associatedtype CompatibleType
    var ds: CompatibleType { get }
}

public extension DSImageCacheCompatible {
    public var ds: DSImageCache<Self> {
        get { return DSImageCache(self) }
    }
}

extension Image: DSImageCacheCompatible { }
extension ImageView: DSImageCacheCompatible { }
extension Button: DSImageCacheCompatible { }

