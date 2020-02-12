//
//  OnboardingFive.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 03.03.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit
import CloudKit

class OnboardingFive: UIViewController {
    
    let defaults = UserDefaults.standard
    var window: UIWindow?
    let settings = SettingsBundleHelper()
    let helper = HelperClass()
    let dataSync = DataSync()

    @IBOutlet weak var bookMarkSwitch: UISwitch!
    @IBOutlet weak var iCloudSwitch: UISwitch!
    @IBOutlet weak var iCloudSwitchLabel: UILabel!
    @IBOutlet weak var openSettingsButton: UIButton!
    @IBOutlet weak var iCloudStatusLabel: UILabel!
    @IBOutlet weak var bookMarkSwitchLabel1: UILabel!
    
    
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
        
        iCloudStatus()
        
        if(self.helper.isSE()){
            iCloudSwitch.isHidden = true
            iCloudSwitchLabel.isHidden = true
            bookMarkSwitch.isHidden = true
            bookMarkSwitchLabel1.isHidden = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
    
    func iCloudStatus(){
        CKContainer.default().accountStatus { (accountStatus, error) in
            switch accountStatus {
                case .available:
                    DispatchQueue.main.async {
                        self.iCloudStatusLabel.text = ""
                    }
                
                case .noAccount:
                    DispatchQueue.main.async {
                        self.iCloudStatusLabel.text = NSLocalizedString("Sadly, your iCloud account seems unavailable. We've disabled the iCloud option for you.", comment: "No iCloud account")
                        self.hideiCloudRelatedContent()
                    }
                case .restricted:
                    DispatchQueue.main.async {
                        self.iCloudStatusLabel.text = NSLocalizedString("iOS reports iCloud status as restricted. We've disabled the iCloud option for you.", comment: "iCloud restricted")
                        self.hideiCloudRelatedContent()
                    }
                case .couldNotDetermine:
                    DispatchQueue.main.async {
                        self.iCloudStatusLabel.text = NSLocalizedString("Unable to determine iCloud status. We've disabled the iCloud option for you.", comment: "Unable to determine iCloud status")
                        self.hideiCloudRelatedContent()
                    }
                @unknown default:
                    print("unknown default")
            }
        }
    }
    
    func hideiCloudRelatedContent(){
        self.iCloudSwitch.isOn = false
        self.iCloudSwitch.isHidden = true
        self.iCloudSwitchLabel.isHidden = true
        self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
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
            self.dataSync.hasCustomZone(){ (test) in
                if(!test){
                    //NSLOG("I don't have custom zone and could not create")
                    print("I don't have custom zone and could not create")
                }
            }
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
