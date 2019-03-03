//
//  OnboardingFive.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 03.03.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit

class OnboardingFive: UIViewController {
    
    let defaults = UserDefaults.standard
    var window: UIWindow?
    let settings = SettingsBundleHelper()

    @IBOutlet weak var bookMarkSwitch: UISwitch!
    @IBOutlet weak var iCloudSwitch: UISwitch!
    @IBOutlet weak var openSettingsButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        openSettingsButton.layer.cornerRadius = 10
        if(self.settings.getSettingsValue(key: "bookmarks")){
            bookMarkSwitch.isOn = true
        }
        else{
            bookMarkSwitch.isOn = false
        }
        if(self.settings.getSettingsValue(key: "bookmarks_icloud")){
            iCloudSwitch.isOn = true
        }
        else{
            iCloudSwitch.isOn = false
        }
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingFive.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver( self, name: UserDefaults.didChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(self.settings.getSettingsValue(key: "bookmarks")){
            bookMarkSwitch.isOn = true
        }
        else{
            bookMarkSwitch.isOn = false
        }
        if(self.settings.getSettingsValue(key: "bookmarks_icloud")){
            iCloudSwitch.isOn = true
        }
        else{
            iCloudSwitch.isOn = false
        }
    }
    
    @objc func defaultsChanged(){
        if settings.getSettingsValue(key: "bookmarks") {
            DispatchQueue.main.async {
                self.bookMarkSwitch.isOn = true
            }
        }
        else {
            DispatchQueue.main.async {
                self.bookMarkSwitch.isOn = false
            }
        }
        if settings.getSettingsValue(key: "bookmarks_icloud") {
            DispatchQueue.main.async {
                self.iCloudSwitch.isOn = true
            }
        }
        else {
            DispatchQueue.main.async {
                self.iCloudSwitch.isOn = false
            }
        }
    }
    
    
    
    
    @IBAction func bookMarksSwitched(_ sender: Any) {
        if(self.bookMarkSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "bookmarks")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "bookmarks")
            self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
        }
    }
    
    @IBAction func iCloudSwitched(_ sender: Any) {
        if(self.iCloudSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "bookmarks_icloud")
            self.settings.setSettingsValue(value: true, key: "bookmarks")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
        }
    }
    
    
    @IBAction func openSettingsTapped(_ sender: Any) {
        if let url = URL(string:UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    


}
