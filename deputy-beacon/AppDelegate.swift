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
  static let clockAction = "CLOCK_ACTION"
  static let dismissAction = "DISMISS_ACTION"
  static let clockCategory = "CLOCK_CATEGORY"
}

enum ClockAction {
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
        
        // Authorize phone to receive push notifications
        UNUserNotificationCenter.current()
          .requestAuthorization(options: [.alert, .sound, .badge]) {
          [weak self] granted, error in
          print("Permission granted: \(granted)")
        }
        
        UNUserNotificationCenter.current().delegate = self
        
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
            
            /*
                GET Deputy user clock status
                User is clocked in: notificationMessage = "Another day, another dollar, please clock in!", button = ClockAction.clockIn
                User is clicked out: notificationMessage = Excellent work today, don't forget to clock out!", button = clockAction.clockOut
            */
            
            let notificationMessage = "Welcome to another day at work, please clock in!"
            let clockingButton = ClockAction.clockIn
            
            let businessName = context.attachments["business"] ?? "DefaultBusiness"
            self.sendLocationNotification(businessName: businessName, message: notificationMessage, clockingButton: clockingButton)
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
        
        print("Sending Notification...")
        
        // Setup Notification message
        let content = UNMutableNotificationContent()
        content.title = businessName
        content.body = message
        content.categoryIdentifier = Identifiers.clockCategory
        content.userInfo = ["ACTION" : clockingButton]
        
        // Setup Notification Interval
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "notification.id.01", content: content, trigger: trigger)
        
        // Setup button actions
        let clockAction = UNNotificationAction(identifier: Identifiers.clockAction, title: clockingButton, options: [.foreground])
        let dismissAction = UNNotificationAction(identifier: Identifiers.dismissAction, title: "Dismiss", options: [.foreground])
        let clockCategory = UNNotificationCategory(identifier: Identifiers.clockCategory, actions: [clockAction, dismissAction], intentIdentifiers: [], options: [])
                
        UNUserNotificationCenter.current().setNotificationCategories([clockCategory])
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

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle push notification actions
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("Inside notification delgate")
           
        let userInfo = response.notification.request.content.userInfo
        let clockAction = userInfo["ACTION"] as! String
        print("Clock Action:", clockAction)
        
        // Perform the task associated with the action.
        switch response.actionIdentifier {
        case Identifiers.clockAction:
            print ("Performing Clocking Action...")
            /*
                POST to Deputy
                clockAction is Clock In: POST to START
                clockAction is Clock Out: POST TO STOP
            */
            break
            
        case Identifiers.dismissAction:
            print ("Performing Dismiss Action...")
            break
            
        default:
            break
       }
        
       // Always call the completion handler when done.
       completionHandler()
    }
}

