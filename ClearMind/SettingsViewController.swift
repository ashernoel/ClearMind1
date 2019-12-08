//
//  SettingsViewController.swift
//  ClearMind
//
//  Created by Asher Noel on 12/8/19.
//  Copyright © 2019 Asher Noel. All rights reserved.
//
import UIKit
import UserNotifications

class SettingsViewController: UIViewController
{
    
    @IBOutlet var tableView: UITableView!
    
    let settingsInformation = [
            ["Notifications", "Recieve updates."]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        

    }
    
    //Show the navigation bar.
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {

        return settingsInformation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        
        cell.imageView1.image = nil
        
        let entry = settingsInformation[indexPath.row]
        cell.itemTitle.text = entry[0]
        cell.populateItem(event: entry)
        
        cell.selectionStyle = UITableViewCell.SelectionStyle.none

        
        return cell
    }
    
}

import UserNotifications

class SettingCell: UITableViewCell
{
    @IBOutlet var itemTitle: UILabel!
    @IBOutlet var itemDescription: UILabel!
    @IBOutlet var itemButton: UIButton!
    
    var switchView = UISwitch()
    var imageView1 = UIImageView()
    
    func populateItem(event: [String])
    {
        itemTitle.text = event[0]
        if event[0] == "Notifications" {
            
            createButton()
            
            //add switch to button
            switchView = UISwitch(frame: .zero)
            switchView.setOn(self.pushEnabledAtOSLevel(), animated: true)
            
            switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
            itemButton.addSubview(switchView)
            switchView.center = CGPoint(x: itemButton.frame.size.width  / 2,
                                       y: itemButton.frame.size.height / 2)
            switchView.onTintColor = UIColor.lightGray
            
            itemButton.addTarget(self, action: #selector(self.toggleSwitch), for: .touchUpInside)
        }
        
        itemDescription.text = event[1]
    }

    @objc func switchChanged(_ sender: UISwitch) {
        if (sender.isOn) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                    if !granted {
                        self.openSettings()
                    }
                }
            print("Turn on notificaitons")
            //add user to list
            
        } else {
            //Turn off post notifications
            // remove user from list
            if pushEnabledAtOSLevel() {
                self.openSettings()
            }
            print("Turn off notificaitons")
            
        }
    }
    
    @objc func toggleSwitch(_ sender: UIButton) {
        if (switchView.isOn) {
            switchView.setOn(false, animated: true)
            switchChanged(switchView)
        } else {
            switchView.setOn(true, animated: true)
            switchChanged(switchView)
        }
    }
    
    func createButton() {
        itemButton.layer.cornerRadius = 40
        self.accessoryView = itemButton
        
        itemButton.backgroundColor = UIColor(red:0.00, green:0.69, blue:1.00, alpha:1.0)
        itemButton.layer.shadowOpacity = 1
        itemButton.layer.shadowRadius = 3
        itemButton.layer.shadowOffset = CGSize(width: 0, height: 0.3)
        itemButton.layer.shadowColor = UIColor.black.cgColor
        itemButton.isEnabled = true
    }
    
    func pushEnabledAtOSLevel() -> Bool {
        guard let currentSettings = UIApplication.shared.currentUserNotificationSettings?.types else { return false }
        return currentSettings.rawValue != 0
    }
    
    func openSettings() {
        if let appSettings = NSURL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(appSettings as URL)
        }
    }
    
}


