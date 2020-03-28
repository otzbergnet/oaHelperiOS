//
//  OnboardingThree.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 19.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit

class OnboardingFour: UIViewController {
    
    let defaults = UserDefaults.standard
    var window: UIWindow?
    let settings = SettingsBundleHelper()
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
        if #available(iOS 13.4, *) {
            doneButton.isPointerInteractionEnabled = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func doneButtonTapped(_ sender: Any) {
        defaults.set(true, forKey: "onBoarding")
        settings.setSettingsValue(value: true, key: "oab_setting")
        settings.setSettingsValue(value: true, key: "recommendation_setting")
        settings.setSettingsValue(value: true, key: "statistic_setting")
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = mainStoryboard.instantiateInitialViewController()!
        UIApplication.shared.keyWindow!.rootViewController = controller
    }
    
}
