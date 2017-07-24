//
//  AppDelegate.swift
//  WarrantyTrackerv0.2
//
//  Created by Jeff Chimney on 2016-11-01.
//  Copyright © 2016 Jeff Chimney. All rights reserved.
//

import UIKit
import CoreData
import CloudKit
import UserNotifications
import Ensembles

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CDEPersistentStoreEnsembleDelegate {
    
    enum ShortcutType: String {
        case Add = "Add"
    }

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Use verbose logging for sync
        CDESetCurrentLoggingLevel(CDELoggingLevel.verbose.rawValue)
        // Setup Core Data Stack
        self.setupCoreData()
        
        // Setup Ensemble
        let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")
        cloudFileSystem = CDEICloudFileSystem(ubiquityContainerIdentifier: nil)
        ensemble = CDEPersistentStoreEnsemble(ensembleIdentifier: "NumberStore", persistentStore: storeURL, managedObjectModelURL: modelURL!, cloudFileSystem: cloudFileSystem)
        ensemble.delegate = self
        
        // Listen for local saves, and trigger merges
        NotificationCenter.default.addObserver(self, selector:#selector(AppDelegate.localSaveOccurred(_:)), name:NSNotification.Name.CDEMonitoredManagedObjectContextDidSave, object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(AppDelegate.cloudDataDidDownload(_:)), name:NSNotification.Name.CDEICloudFileSystemDidDownloadFiles, object:nil)
        
        // register for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [[.alert, .sound, .badge]], completionHandler: { (granted, error) in
            // Handle Error
        })
        
        let settings = UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil)
        
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        if let options: NSDictionary = launchOptions as NSDictionary? {
            let remoteNotification =
                options[UIApplicationLaunchOptionsKey.remoteNotification]
            
            
            if let notification = remoteNotification {
                
                self.application(application, didReceiveRemoteNotification:
                    notification as! [AnyHashable : Any],
                                 fetchCompletionHandler:  { (result) in
                })
                UIApplication.shared.applicationIconBadgeNumber = 1 // clear current notifications
            }
        }
        
        // check for network availability
        do {
            Network.reachability = try Reachability(hostname: "www.google.com")
            do {
                try Network.reachability?.start()
            } catch let error as Network.Error {
                print(error)
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        let taskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        try! managedObjectContext.save()
        self.sync {
            UIApplication.shared.endBackgroundTask(taskIdentifier)
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.sync(nil)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        saveContext()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
            case "Add" :
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let newItemViewController : UIViewController = storyboard.instantiateViewController(withIdentifier: "newItemViewController") as! NewItemViewController
                window?.rootViewController?.show(newItemViewController, sender: nil)
            default:
            break
        }
        completionHandler(true)
    }

    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "WarrantyTracker")
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
    
    // MARK: Notification Handlers
    
    func localSaveOccurred(_ notif: Notification) {
        self.sync(nil)
    }
    
    func cloudDataDidDownload(_ notif: Notification) {
        self.sync(nil)
    }
    
    // MARK: - Core Data Saving support
    var managedObjectContext: NSManagedObjectContext!
    
    var storeDirectoryURL: URL {
        return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    
    var storeURL: URL {
        return self.storeDirectoryURL.appendingPathComponent("store.sqlite")
    }
    
    func setupCoreData() {
        let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOf: modelURL!)
        
        try! FileManager.default.createDirectory(at: self.storeDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.storeURL, options: options)
        
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
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
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController : PrimaryViewController = storyboard.instantiateViewController(withIdentifier: "primaryController") as! PrimaryViewController
        window?.rootViewController?.show(viewController, sender: nil)
        
        let notification: CKNotification =
            CKNotification(fromRemoteNotificationDictionary:
                userInfo as! [String : NSObject])
        
        if (notification.notificationType ==
            CKNotificationType.query) {
            
            let queryNotification =
                notification as! CKQueryNotification
            
            let recordID = queryNotification.recordID
            
            CloudKitHelper.fetchRecord(recordID: recordID!)
        }
    }
    
    // MARK: Ensembles
    
    var cloudFileSystem: CDECloudFileSystem!
    var ensemble: CDEPersistentStoreEnsemble!
    
    func sync(_ completion: (() -> Void)?) {
        let viewController = self.window?.rootViewController as! PrimaryViewController
        //viewController.activityIndicator?.startAnimating()
        if !ensemble.isLeeched {
            ensemble.leechPersistentStore {
                error in
                //viewController.activityIndicator?.stopAnimating()
                viewController.refresh()
                completion?()
            }
        }
        else {
            ensemble.merge {
                error in
                //viewController.activityIndicator?.stopAnimating()
                viewController.refresh()
                completion?()
            }
        }
    }
    
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, didSaveMergeChangesWith notification: Notification) {
        managedObjectContext.performAndWait {
            self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
//    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble!, globalIdentifiersForManagedObjects objects: [Any]!) -> [Any]! {
//        //let numberHolders = objects as! [NumberHolder]
//        //return numberHolders.map { $0.uniqueIdentifier }
//    }
}

