//
//  PhotosViewController.swift
//  NSOperatiosTutorial
//
//  Created by Vanessa Cantero Gómez on 02/10/15.
//  Copyright © 2015 Vanessa Cantero Gómez. All rights reserved.
//

import UIKit

let dataSourceURL = NSURL(string: "http://www.raywenderlich.com/downloads/ClassicPhotosDictionary.plist")
let cellIdentifier = "cell"

class PhotosViewController: UITableViewController {
    
    // MARK: - Properties
    
    private var photos = [PhotoRecord]()
    private let pendingOperations = PendingOperations()
    
    
    // MARK: - UITableViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Classic Photos"
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        fetchPhotoDetails()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        
        if cell.accessoryView == nil {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            cell.accessoryView = indicator
        }
        
        let indicator = cell.accessoryView as! UIActivityIndicatorView
        
        let photoDetails = photos[indexPath.row]
        
        cell.textLabel?.text = photoDetails.name
        cell.imageView?.image = photoDetails.image
        
        switch (photoDetails.state) {
        case .Filtered:
            indicator.stopAnimating()
        case .Failed:
            indicator.stopAnimating()
            cell.textLabel?.text = "Failed to load"
        case .New, .Downloaded:
            indicator.startAnimating()
            if !tableView.dragging && !tableView.decelerating {
                startOperationsForPhotoRecord(photoDetails, indexPath: indexPath)
            }
        }
        
        return cell
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        suspendAllOperations()
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadImagesForOnScreenCells()
            resumeAllOperations()
        }
    }
    
    private func loadImagesForOnScreenCells() {
        if let pathsArray = tableView.indexPathsForVisibleRows {
            var allPendingOperations = Set(pendingOperations.downloadsInProgress.keys)
            allPendingOperations.unionInPlace(pendingOperations.filtrationsInProgress.keys)
            
            var toBeCancelled = allPendingOperations
            let visiblePaths = Set(pathsArray)
            toBeCancelled.subtractInPlace(visiblePaths)
            
            var toBeStarted = visiblePaths
            toBeStarted.subtractInPlace(allPendingOperations)
            
            for indexPath in toBeCancelled {
                if let pendingDownload = pendingOperations.downloadsInProgress[indexPath] {
                    pendingDownload.cancel()
                }
                pendingOperations.downloadsInProgress.removeValueForKey(indexPath)
                if let pendingFiltration = pendingOperations.filtrationsInProgress[indexPath] {
                    pendingFiltration.cancel()
                }
                pendingOperations.filtrationsInProgress.removeValueForKey(indexPath)
            }
            
            for indexPath in toBeStarted {
                let indexPath = indexPath as NSIndexPath
                let recordToProcess = self.photos[indexPath.row]
                startOperationsForPhotoRecord(recordToProcess, indexPath: indexPath)
            }
        }
    }
    
    private func resumeAllOperations() {
        pendingOperations.downloadQueue.suspended = false
        pendingOperations.filtrationQueue.suspended = false
    }
    
    private func suspendAllOperations() {
        pendingOperations.downloadQueue.suspended = true
        pendingOperations.filtrationQueue.suspended = true
    }
    
    private func startOperationsForPhotoRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath){
        switch (photoDetails.state) {
        case .New:
            startDownloadForRecord(photoDetails, indexPath: indexPath)
        case .Downloaded:
            startFiltrationForRecord(photoDetails, indexPath: indexPath)
        default:
            NSLog("do nothing")
        }
    }
    
    private func startDownloadForRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath) {
        if let _ = pendingOperations.downloadsInProgress[indexPath] { // If there is already an operation id downloadInProgress, ignore it
            return
        }
        
        let downloader = ImageDownloader(photoRecord: photoDetails) // If not, create an instance of ImageDownloader
        
        downloader.completionBlock = { // Will be executed when the operation is completed
            if downloader.cancelled {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.pendingOperations.downloadsInProgress.removeValueForKey(indexPath)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
        }
        
        pendingOperations.downloadsInProgress[indexPath] = downloader
        // This is how we actualy get the oeration to start running. The queue takes care
        // of scheduling once we've added the operation
        pendingOperations.downloadQueue.addOperation(downloader)
    }
    
    private func startFiltrationForRecord(photoDetails: PhotoRecord, indexPath: NSIndexPath) {
        if let _ = pendingOperations.filtrationsInProgress[indexPath] {
            return
        }
        
        let filtered = ImageFiltration(photoRecord: photoDetails)
        filtered.completionBlock = {
            if filtered.cancelled {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.pendingOperations.filtrationsInProgress.removeValueForKey(indexPath)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            })
        }
        
        pendingOperations.filtrationsInProgress[indexPath] = filtered
        pendingOperations.filtrationQueue.addOperation(filtered)
        
    }
    
    private func fetchPhotoDetails() {
        let request = NSURLRequest(URL: dataSourceURL!)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error == nil {
                do {
                    let dataSourceDictionary =  try NSPropertyListSerialization.propertyListWithData(data!, options: .Immutable , format: nil) as! NSDictionary
                    
                    for (key, value) in dataSourceDictionary {
                        let name = key as? String
                        let url = NSURL(string: value as? String ?? "")
                        if name != nil && url != nil {
                            let photoRecord = PhotoRecord(name: name!, url: url!)
                            self.photos.append(photoRecord)
                        }
                    }
                } catch {
                    print("Error")
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.tableView.reloadData()
                })
            }
        }
        
        task.resume()
    }
}
