//
//  OnboardingSix.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 13.12.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit

class OnboardingSix: UIViewController {

    @IBOutlet weak var oabSwitch: UISwitch!
    @IBOutlet weak var recomSwitch: UISwitch!
    @IBOutlet weak var moreInfoButton: UIButton!
    
    let settings = SettingsBundleHelper()
    let helper = HelperClass()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        moreInfoButton.layer.cornerRadius = 10
        
        if(self.settings.getSettingsValue(key: "open_acess_button")){
            self.oabSwitch.isOn = true
        }
        if(self.settings.getSettingsValue(key: "reommendation")){
            self.recomSwitch.isOn = true
        }
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingSix.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver( self, name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @objc func defaultsChanged(){
        if settings.getSettingsValue(key: "open_access_button") {
            DispatchQueue.main.async {
                self.oabSwitch.isOn = true
            }
        }
        else {
            DispatchQueue.main.async {
                self.oabSwitch.isOn = false
            }
        }
        if settings.getSettingsValue(key: "recommendation") {
            DispatchQueue.main.async {
                self.recomSwitch.isOn = true
            }
        }
        else {
            DispatchQueue.main.async {
                self.recomSwitch.isOn = false
            }
        }
    }
    
    @IBAction func oabSwitched(_ sender: Any) {
        if(self.oabSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "open_access_button")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "open_access_button")
        }
    }
    
    @IBAction func recomSwitched(_ sender: Any) {
        if(self.recomSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "recommendation")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "recommendation")
        }
    }
    
    @IBAction func moreInfoTapped(_ sender: Any) {
        guard let url = URL(string: "https://www.otzberg.net/oahelper/moreoaoptions.html") else { return }
        UIApplication.shared.open(url)
    }
    
}