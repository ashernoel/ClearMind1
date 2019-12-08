//
//  AppDelegate.swift
//  ClearMind
//
//  Created by Asher Noel on 12/2/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//

// Import all of the AWS necessities and goodness
import UIKit
import AWSMobileClient
import AWSPinpoint
import UserNotifications
import Amplify
import AmplifyPlugins
import AWSPluginsCore
import AWSAuthUI
import AWSUserPoolsSignIn
import AWSAppSync



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // Initialize variables for AWS
    var pinpoint: AWSPinpoint?
    var appSyncClient: AWSAppSyncClient?
    
    // Add a AWSMobileClient call in application:open url
    func application(_ application: UIApplication, open url: URL,
        sourceApplication: String?, annotation: Any) -> Bool {

        AWSDDLog.add(AWSDDTTYLogger.sharedInstance)
        AWSDDLog.sharedInstance.logLevel = .info
        
        return AWSMobileClient.default().interceptApplication(
            application, open: url,
            sourceApplication: sourceApplication,
            annotation: annotation)

    }


    // Add a AWSMobileClient call in application:didFinishLaunching
     func application(
        _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Create AWSMobileClient to connect with AWS
        AWSMobileClient.default().initialize { (userState, error) in
          if let error = error {
        print("Error initializing AWSMobileClient: \(error.localizedDescription)")
          } else if let userState = userState {
        print("AWSMobileClient initialized. Current UserState: \(userState.rawValue)")
          }
        }

        // Initialize Pinpoint for Analytics tracking and notifications
        let pinpointConfiguration = AWSPinpointConfiguration.defaultPinpointConfiguration(launchOptions: launchOptions)
        pinpoint = AWSPinpoint(configuration: pinpointConfiguration)
    
        // Attempt to register for push notificatios when running on a simulator
        registerForPushNotifications()
                
        runMutation()
        
        do {
            // You can choose the directory in which AppSync stores its persistent cache databases
            let cacheConfiguration = try AWSAppSyncCacheConfiguration()

            // AppSync configuration & client initialization
            let appSyncServiceConfig = try AWSAppSyncServiceConfig()
            let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: appSyncServiceConfig,
                                                                  cacheConfiguration: cacheConfiguration)
            appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            print("Initialized appsync client.")
        } catch {
            print("Error initializing appsync client. \(error)")
        }
        
        return AWSMobileClient.default().interceptApplication(
             application, didFinishLaunchingWithOptions:
             launchOptions)
        
    }
    
    func runMutation(){
        print("starting mutation")
        let mutationInput = CreateRecordingInput(content: "hello")
        appSyncClient?.perform(mutation: CreateRecordingMutation(input: mutationInput)) { (result, error) in
            if let error = error as? AWSAppSyncClientError {
                print("Error occurred: \(error.localizedDescription )")
            }
            if let resultError = result?.errors {
                print("Error saving the item on server: \(resultError)")
                return
            }
            print("Mutation complete.")
        }
        
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
    
    
    // MARK:  -- Push Notifications
    // The following three functions register for push notifications
    //
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        pinpoint!.notificationManager.interceptDidRegisterForRemoteNotifications(
            withDeviceToken: deviceToken)
     
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                                    fetchCompletionHandler completionHandler:
        @escaping (UIBackgroundFetchResult) -> Void) {

        pinpoint!.notificationManager.interceptDidReceiveRemoteNotification(
            userInfo, fetchCompletionHandler: completionHandler)

        if (application.applicationState == .active) {
            let alert = UIAlertController(title: "Notification Received",
                                        message: userInfo.description,
                                        preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))

            UIApplication.shared.keyWindow?.rootViewController?.present(
                alert, animated: true, completion:nil)
        }
    }

    // Request user to grant permissions for the app to use notifications
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            // 1. Check if permission granted
            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    
    
}



