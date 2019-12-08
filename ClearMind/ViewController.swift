//
//  ViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 12/2/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//

import UIKit
import AWSAuthCore
import AWSAuthUI
import AWSMobileClient

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        AWSMobileClient.default().initialize { (userState, error) in
            if let userState = userState {
                print("UserState: \(userState.rawValue)")
            } else if let error = error {
                print("error: \(error.localizedDescription)")
            }
        }
        
        
        AWSMobileClient.default()
                   .showSignIn(navigationController: self.navigationController!,
                                    signInUIOptions: SignInUIOptions(
                                          canCancel: false,
                                          logoImage: UIImage(named: "Logo"),
                                           backgroundColor: UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0))) { (result, err) in
                                           //handle results and errors
               }
        
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

