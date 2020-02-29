//
//  AppDelegate.swift
//  Authenticator
//
//  Created by skytoup on 2019/9/28.
//  Copyright © 2019 test. All rights reserved.
//

import UIKit
import CoreData
import WatchConnectivity
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    
    fileprivate var frc: NSFetchedResultsController<CodeModel>?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.enableAutoToolbar = false
        
        // Watch
        if WCSession.isSupported() {
            let wcs = WCSession.default
            wcs.delegate = self
            wcs.activate()
        }
        
        // Core Data
        let ctx = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fReq = NSFetchRequest<CodeModel>(entityName: CodeModel.name)
        fReq.sortDescriptors = [NSSortDescriptor(key: "score", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: fReq, managedObjectContext: ctx, sectionNameKeyPath: nil, cacheName: nil)
        frc?.delegate = self
        
        if let _ = try? frc?.performFetch(), let codes = frc?.fetchedObjects {
            TOTPManager.shared.secretKeys = codes.compactMap(\.secretKey)
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "CodeModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// MARK: - WCSessionDelegate
extension AppDelegate: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard let _ = error else {
            return
        }
        guard case .activated = activationState else {
            return
        }
        guard let _ = try? frc?.performFetch(), let codes = frc?.fetchedObjects else {
            return
        }
        pushToWatch(codes: codes)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension AppDelegate: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let codes = controller.fetchedObjects as? [CodeModel] else {
            return
        }
        
        TOTPManager.shared.secretKeys = codes.compactMap(\.secretKey)
        pushToWatch(codes: codes)
    }
    
    /// watch数据推送
    /// - Parameter codes:
    fileprivate func pushToWatch(codes: [CodeModel]) {
        let wcs = WCSession.default
        guard WCSession.isSupported(), wcs.isPaired, wcs.isWatchAppInstalled else {
                return
        }
        
        let ds = codes.map { $0.dictionaryWithValues(forKeys: ["account", "secretKey", "remark"]) }
        try? wcs.updateApplicationContext(["datas": ds, "ver": "v1"])
    }
}
