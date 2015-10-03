//
//  PhotoOperations.swift
//  NSOperatiosTutorial
//
//  Created by Vanessa Cantero Gómez on 02/10/15.
//  Copyright © 2015 Vanessa Cantero Gómez. All rights reserved.
//

import Foundation
import UIKit

enum PhotoRecordState {
    case New, Downloaded, Filtered, Failed
}

class PhotoRecord {
    let name:String
    let url:NSURL
    var state:PhotoRecordState = .New
    var image = UIImage(named:"placeholder")
    
    init(name:String, url:NSURL) {
        self.name = name
        self.url = url
    }
}

class PendingOperations {
    lazy var downloadsInProgress = [NSIndexPath:NSOperation]()
    
    lazy var downloadQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Download queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
        }()
    
    lazy var filtrationsInProgress = [NSIndexPath:NSOperation]()
    
    lazy var filtrationQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Image Filtration queue"
        queue.maxConcurrentOperationCount = 1
        
        return queue
        }()
}

class ImageDownloader: NSOperation {
    
    let photoRecord:PhotoRecord
    
    init(photoRecord:PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if self.cancelled {
            return
        }
        
        let imageData = NSData(contentsOfURL: photoRecord.url)
        
        if self.cancelled {
            return
        }
        
        if imageData?.length > 0 {
            photoRecord.image = UIImage(data: imageData!)
            photoRecord.state = .Downloaded
        } else {
            photoRecord.state = .Failed
            photoRecord.image = UIImage(named: "placeholder")
        }
    }
}

class ImageFiltration: NSOperation {
    
    let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if self.cancelled {
            return
        }
        
        if photoRecord.state != .Downloaded {
            return
        }
        
        if let filteredImage = applySepiaFilter(photoRecord.image!) {
            photoRecord.image = filteredImage
            photoRecord.state = .Filtered
        }
    }
    
    private func applySepiaFilter(image:UIImage) -> UIImage? {
        let inputImage = CIImage(data: UIImagePNGRepresentation(image)!)
        
        if self.cancelled {
            return nil
        }
        
        let context = CIContext(options: nil)
        let filter = CIFilter(name: "CISepiaTone")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(0.8, forKey: "inputIntensity")
        let outputImage = filter?.outputImage
        
        if self.cancelled {
            return nil
        }
        
        let outImage = context.createCGImage(outputImage!, fromRect: outputImage!.extent)
        let returnImage =  UIImage(CGImage: outImage)
        
        return returnImage
    }
}
