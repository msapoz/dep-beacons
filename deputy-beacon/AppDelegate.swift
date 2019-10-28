//
//  AppDelegate.swift
//  deputy-beacon
//
//  Created by Mikhail Sapozhnikov on 10/24/19.
//  Copyright © 2019 Deputy. All rights reserved.
//

import UIKit
import UserNotifications
import EstimoteProximitySDK

enum Identifiers {
  static let viewAction = "CLOCK_IDENTIFIER"
  static let clockingCategory = "CLOCKING_CATEGORY"
}

enum ClockingAction {
    static let clockIn = "Clock In"
    static let clockOut = "Clock Out"
}

let deviceToken = "ee816c39305725d9a9d4a5b724466d32863dbd1839a53c47a63bba1e5f1512a3"
let keyId = "PJ87H27324"
let teamId = "56HQ8UQ2A5"

let estimoteCloudAppId = "deputy-beacon-aon"
let estimoteCloudAppToken = "3d56903985fb1889c44cdd028d9ef5fa"


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
    var window: UIWindow?
    
    var proximityObserver: ProximityObserver!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        registerForPushNotifications()
        
        // Setup Estimote Cloud credentials and establish the connection
        let cloudCredentials = CloudCredentials(appID: estimoteCloudAppId, appToken: estimoteCloudAppToken)
        self.proximityObserver = ProximityObserver(
            credentials: cloudCredentials,
            onError: { error in
                print("proximity observer error: \(error)")
            })
        
        // Configure proximity zone and enter/exit actions
        let zone = ProximityZone(tag: "worklocation", range: .near)
        zone.onEnter = { context in
            
            print("Entered area...")
            
            // Query Deputy for user's clock-in status to determine action
            let notificationMessage = "Welcome to another day at work, please clock in!"
            
            print("Sending welcome...")
            let businessName = context.attachments["business"] ?? "DefaultBusiness"
            self.sendLocationNotification(businessName: businessName, message: notificationMessage, clockingButton: ClockingAction.clockIn)
        }
        zone.onExit = { context in
            print("Leaving area...")
        }
        
        // Begin beacon observing
        self.proximityObserver.startObserving([zone])
        
        // Override point for customization after application launch.
        return true
    }
    
    func sendLocationNotification(businessName: String, message: String, clockingButton: String) {
        
        print("Sending Local Notification...")
        
        // Setup Notification message
        let content = UNMutableNotificationContent()
        content.title = businessName
        content.body = message
        
        // Setup Notification Interval
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "notification.id.01", content: content, trigger: trigger)
        
        // Setup button action
        let viewAction = UNNotificationAction(identifier: Identifiers.viewAction, title: clockingButton, options: [.foreground])
        let clockingCategory = UNNotificationCategory(identifier: Identifiers.clockingCategory, actions: [viewAction], intentIdentifiers: [], options: [])
        
//        if clockingButton == ClockingAction.clockIn {
//
//        } else if clockingButton == ClockingAction.clockOut {
//
//        }

        UNUserNotificationCenter.current().setNotificationCategories([clockingCategory])
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
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
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
//    func registerForPushNotifications() {
//        UNUserNotificationCenter.current()
//          .requestAuthorization(options: [.alert, .sound, .badge]) {
//          [weak self] granted, error in
//          print("Permission granted: \(granted)")
//
//          guard granted else { return }
//
//          // 1
//          let viewAction = UNNotificationAction(
//            identifier: Identifiers.viewAction, title: "Clock-In",
//            options: [.foreground])
//
//          // 2
//          let clockingCategory = UNNotificationCategory(
//            identifier: Identifiers.clockingCategory, actions: [viewAction],
//            intentIdentifiers: [], options: [])
//
//          // 3
//          UNUserNotificationCenter.current().setNotificationCategories([clockingCategory])
//
//          self?.getNotificationSettings()
//      }
//    }
    
    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
      let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
      let token = tokenParts.joined()
      print("Device Token: \(token)")
    }

    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("Failed to register: \(error)")
    }
}

