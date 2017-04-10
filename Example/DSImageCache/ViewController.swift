//
//  ViewController.swift
//  DSImageCache
//
//  Created by dsonara on 04/01/2017.
//  Copyright (c) 2017 dsonara. All rights reserved.
//

import UIKit
import DSImageCache

class ViewController: UICollectionViewController {
    
    @IBOutlet weak var activityIndicator:UIActivityIndicatorView!
    
    var refreshControl: UIRefreshControl!
    var arrayData = NSArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = "DSImageCache"
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshData(sender:)), for: UIControlEvents.valueChanged)
        if #available(iOS 10.0, *) {
            collectionView?.refreshControl = refreshControl
        } else {
            // Fallback on earlier versions
            collectionView?.addSubview(refreshControl)
        }
        
        self.getWebApiData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func refreshData(sender:AnyObject) {
        // Code to refresh collection view
        refreshControl.endRefreshing()
        self.getWebApiData()
    }
    
    @IBAction func clearCache(sender: AnyObject) {
        DSImageCacheManager.shared.cache.clearMemoryCache()
        DSImageCacheManager.shared.cache.clearDiskCache()
    }
    
    @IBAction func reload(sender: AnyObject) {
        collectionView?.reloadData()
    }
    
    func getWebApiData () {
        
        self.activityIndicator.startAnimating()
        WebServices.getData { (json, connectionError) in
            
            DispatchQueue.global(qos: .default).async(
            execute: {() -> Void in
        
                self.activityIndicator.stopAnimating()
                
                DispatchQueue.main.async {
                    self.arrayData = json as! NSArray
                    //print(self.arrayData)
                    self.collectionView?.reloadData()
                }
            })
        }
    }
}

extension ViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrayData.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // This will cancel all unfinished downloading task when the cell disappearing.
        (cell as! CollectionViewCell).cellImageView.ds.cancelDownloadTask()
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let dict : NSDictionary = self.arrayData.object(at:indexPath.row) as! NSDictionary
        let originalString = dict.value(forKeyPath: "user.profile_image.large") as! String?
        
        if (originalString != nil) {
            
            let urlImage = URL(string: originalString!)
            
            _ = (cell as! CollectionViewCell).cellImageView.ds.setImage(with: urlImage,placeholder: nil, options: [.transition(ImageTransition.fade(3))], progressBlock: { receivedSize, totalSize in
                print("\(indexPath.row + 1): \(receivedSize)/\(totalSize)")
            },                                                        completionHandler: { image, error, cacheType, imageURL in

                print("\(indexPath.row + 1): Finished")
            })
        }
        
        _ = (cell as! CollectionViewCell).userLbl.text = dict.value(forKeyPath: "user.username") as! String?
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! CollectionViewCell
        
        cell.cellImageView.ds.indicatorType = .activity
        
        return cell
    }
}


