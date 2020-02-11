//
//  OnboardingOne.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 11.02.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import UIKit

class OnboardingOne: UIViewController {

    let defaults = UserDefaults.standard
    var window: UIWindow?
    let settings = SettingsBundleHelper()
    
    @IBOutlet weak var skipButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        skipButton.layer.cornerRadius = 10
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func skipTapped(_ sender: Any) {
        defaults.set(true, forKey: "onBoarding")
        settings.setSettingsValue(value: true, key: "oab_setting")
        settings.setSettingsValue(value: true, key: "recommendation_setting")
        settings.setSettingsValue(value: true, key: "statistic_setting")
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = mainStoryboard.instantiateInitialViewController()!
        UIApplication.shared.keyWindow!.rootViewController = controller
    }
    

}
