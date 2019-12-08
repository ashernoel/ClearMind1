//
//  ProfileViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 12/8/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//

import SafariServices
import AWSMobileClient
import AWSAuthCore
import AWSAuthUI

class ProfileCell: UITableViewCell
{

    @IBOutlet var photoContainer: UIView!
    @IBOutlet var itemButton: UIButton!
    @IBOutlet var itemTitle: UILabel!
    @IBOutlet var itemDescription: UILabel!
    @IBOutlet var backgroundImage: UIImageView!
    
    func populateItem (entry: [String]) {
        itemTitle.text = entry[0]
        itemDescription.text = entry[1]
        
        photoContainer.layer.cornerRadius = 10
        photoContainer.layer.cornerRadius = 10
        photoContainer.layer.shadowOpacity = 0.35
        photoContainer.layer.shadowRadius = 7
        photoContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        photoContainer.layer.shadowColor = UIColor(red: 30/255.0, green: 30/255.0, blue: 30/255.0, alpha: 1).cgColor
        
        itemTitle.layer.shadowOffset = CGSize(width: 0, height: 0)
        itemTitle.layer.shadowOpacity = 1
        itemTitle.layer.shadowRadius = 6
        itemTitle.shadowColor = UIColor.black
        
   
        
        if entry[0] == "Logout" {
            
            photoContainer.backgroundColor = UIColor.red
            
            backgroundImage.image = UIImage(named:"logoutPhoto")
            
            
            
        } else if entry[0] == "Settings" {
            
            photoContainer.backgroundColor = UIColor.green
    
             backgroundImage.image = UIImage(named:"settingsPhoto")
            
        } else if entry[0] == "Learn More" {
            
            photoContainer.backgroundColor = UIColor.yellow
            backgroundImage.image = UIImage(named:"learnMorePhoto")
        }
    }
}

class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var profileInformation = [["Logout", "Re-initiate login sequence"], ["Settings", "Change app settings"], ["Learn More", "View the project source code on Github"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
    }
    
    // Remove the navigation bar
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return profileInformation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileCell", for: indexPath) as! ProfileCell
   
        let entry = profileInformation[indexPath.row]
        cell.populateItem(entry: entry)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        if entry[0] == "Logout" {
            cell.itemButton.addTarget(self, action: #selector(self.logout), for: .touchUpInside)
            
        } else if entry[0] == "Learn More" {
            cell.itemButton.addTarget(self, action: #selector(self.learnMore), for: .touchUpInside)
        } else if entry[0] == "Settings" {
            cell.itemButton.addTarget(self, action: #selector(self.settingsSegue), for: .touchUpInside)
        }
        
        return cell
    }
    
    @objc func logout () {
        AWSMobileClient.default().signOut()
        
    
        
        performSegue(withIdentifier: "logoutSegue", sender: self)
    }
    
    @objc func learnMore() {
          guard let url = URL(string: "https://www.github.com/ashernoel/ClearMind") else {
              return
          }
          
          let safariVC = SFSafariViewController(url: url)
          safariVC.delegate = self
          
          
          present(safariVC, animated: true, completion: nil)
          
      }
    
    @objc func settingsSegue() {
        performSegue(withIdentifier: "settingsSegue", sender: self)
    }
}
