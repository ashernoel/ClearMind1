//
//  ViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 12/2/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//

// This view controller is the default initial view controller that calls the LOGIN screen
//
import UIKit
import AWSAuthCore
import AWSAuthUI
import AWSMobileClient

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Initialize the AWS Mobile Client
        //
        AWSMobileClient.default().initialize { (userState, error) in
            if let userState = userState {
                print("UserState: \(userState.rawValue)")
            } else if let error = error {
                print("error: \(error.localizedDescription)")
            }
        }
        
        // Change the settings on the login screen to match my particular app
        //
        AWSMobileClient.default()
                   .showSignIn(navigationController: self.navigationController!,
                                    signInUIOptions: SignInUIOptions(
                                          canCancel: false,
                                          logoImage: UIImage(named: "Logo"),
                                           backgroundColor: UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0))) { (result, err) in
                                           //handle results and errors
               }
        
        // If the user is NOT logged in, then show the LOGIN SCREEN
        //
        if !AWSSignInManager.sharedInstance().isLoggedIn {
           AWSAuthUIViewController
             .presentViewController(with: self.navigationController!,
                  configuration: nil,
                  completionHandler: { (provider: AWSSignInProvider, error: Error?) in
                     if error != nil {
                         print("Error occurred: \(String(describing: error))")
                     } else {
                         // Sign in successful.
                     }
                  })
        }
        
       
        
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        performSegue(withIdentifier: "enterApp", sender: self)
    }
    
    // Remove the navigation bar
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }


}

