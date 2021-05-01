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

    @IBOutlet weak var openSettingsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        openSettingsButton.layer.cornerRadius = 10
        if #available(iOS 13.4, *) {
            openSettingsButton.isPointerInteractionEnabled = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    
    @IBAction func openSettingsTapped(_ sender: Any) {
        if let url = URL(string:UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    


}
