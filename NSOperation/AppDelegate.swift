//
//  AppDelegate.swift
//  NSOperatiosTutorial
//
//  Created by Vanessa Cantero Gómez on 02/10/15.
//  Copyright © 2015 Vanessa Cantero Gómez. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    
    // MARK: - Properties
    
    var window: UIWindow? = {
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window.rootViewController = UINavigationController(rootViewController: PhotosViewController())
        return window
        }()
}

extension AppDelegate: UIApplicationDelegate {
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        let navigationBar = UINavigationBar.appearance()
        navigationBar.barStyle = .Black
        navigationBar.tintColor = UIColor(white: 1, alpha: 0.6)
        
        window?.makeKeyAndVisible()
        return true
    }
}