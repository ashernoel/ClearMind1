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
        
        AWSMobileClient.default().signOut()
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
            print("not logged in")
        }
        
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        performSegue(withIdentifier: "enterApp", sender: self)
    }


}

