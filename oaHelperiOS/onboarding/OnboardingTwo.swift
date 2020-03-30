//
//  OnboardingTwo.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 19.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit
import SafariServices

class OnboardingTwo: UIViewController {

    @IBOutlet weak var openSafariButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        openSafariButton.layer.cornerRadius = 10
        // Do any additional setup after loading the view.
        if #available(iOS 13.4, *) {
            openSafariButton.isPointerInteractionEnabled = true
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

    @IBAction func safariButtonTapped(_ sender: Any) {
        
        guard let url = URL(string: "https://www.oahelper.org/as.php") else { return }
        let vc = SFSafariViewController(url: url)
        self.present(vc, animated: true, completion: nil)
    }
}
