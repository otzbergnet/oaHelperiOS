//
//  OnboardingThree.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 19.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit

class OnboardingThree: UIViewController {
    
    let defaults = UserDefaults.standard
    var window: UIWindow?
    let settings = SettingsBundleHelper()
    let helper = HelperClass()
    
    @IBOutlet weak var dataShare: UISwitch!
    @IBOutlet weak var openSettingsButton: UIButton!
    @IBOutlet weak var shareSwitch: UISwitch!
    @IBOutlet weak var shareSwitchLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        openSettingsButton.layer.cornerRadius = 10
        if(self.settings.getSettingsValue(key: "share_stats")){
            dataShare.isOn = true
        }
        else{
            dataShare.isOn = false
        }
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingThree.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        if(self.helper.isSE()){
            shareSwitch.isHidden = true
            shareSwitchLabel.isHidden = true
        }
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver( self, name: UserDefaults.didChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(self.settings.getSettingsValue(key: "share_stats")){
            dataShare.isOn = true
        }
        else{
            dataShare.isOn = false
        }
    }
    
    @objc func defaultsChanged(){
        if settings.getSettingsValue(key: "share_stats") {
            DispatchQueue.main.async {
                self.dataShare.isOn = true
            }
        }
        else {
            DispatchQueue.main.async {
                self.dataShare.isOn = false
            }
        }
    }
    

    @IBAction func dataShareSwitched(_ sender: Any) {
        if(self.dataShare.isOn){
            self.settings.setSettingsValue(value: true, key: "share_stats")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "share_stats")
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
