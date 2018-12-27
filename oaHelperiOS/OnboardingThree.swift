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
    
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
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
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = mainStoryboard.instantiateInitialViewController()!
        self.present(controller, animated: true, completion: nil)
    }
    
}
