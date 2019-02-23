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
    
    @IBOutlet weak var dataShare: UISwitch!
    @IBOutlet weak var openSettingsButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        openSettingsButton.layer.cornerRadius = 10
        if(self.settings.getSubmitStatsValue()){
            dataShare.isOn = true
        }
        else{
            dataShare.isOn = false
        }
        NotificationCenter.default.addObserver(self, selector: #selector(OnboardingThree.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if(self.settings.getSubmitStatsValue()){
            dataShare.isOn = true
        }
        else{
            dataShare.isOn = false
        }
    }
    
    @objc func defaultsChanged(){
        if settings.getSubmitStatsValue() {
            dataShare.isOn = true
            
        }
        else {
            dataShare.isOn = false
        }
    }
    

    @IBAction func dataShareSwitched(_ sender: Any) {
        if(self.dataShare.isOn){
            self.settings.setSubmitStatsValue(value: true)
        }
        else{
            self.settings.setSubmitStatsValue(value: false)
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
