//
//  InfoChildViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 24.05.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import UIKit
import SafariServices

class InfoChildViewController: UIViewController {

    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var showMeButton: UIButton!
    
    @IBOutlet weak var topImage: UIImageView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    
    var type = "hint"
    var days = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dismissButton.layer.cornerRadius = 10
        showMeButton.layer.cornerRadius = 10
        if #available(iOS 13.4, *) {
            dismissButton.isPointerInteractionEnabled = true
            showMeButton.isPointerInteractionEnabled = true
        }
    }
    
    func setStuff(){
        if(type == "hint"){
            headingLabel.text = NSLocalizedString("Here's a tip for you!", comment: "")
            bodyLabel.text = NSLocalizedString("Did you know that OA Helper has a Safari Share Sheet Extension to help you find Open Access while you browse publisher websites?", comment: "")
            topImage.image = UIImage(named: "info_icon")
            showMeButton.setTitle(NSLocalizedString("Show me how", comment: ""), for: .normal)
            
        }
        else if(type == "anniversary"){
            headingLabel.text = NSLocalizedString("Thank you!", comment: "")
            let bodyLabelText1 = NSLocalizedString("You've installed Open Access Helper", comment: "first half of text")
            let bodyLabelText2 = NSLocalizedString("days ago. Thank you for your support! Want to let others know about it?", comment: "second half of text")
            bodyLabel.text = "\(bodyLabelText1) \(days) \(bodyLabelText2)"
            topImage.image = UIImage(named: "star_icon")
            showMeButton.setTitle(NSLocalizedString("Share", comment: ""), for: .normal)
        }
    }
    
    func recommendApp(){
        let vc = self.parent as! ViewController
        vc.removeInfoChildViewController()
        guard let productURL = URL(string: "https://apps.apple.com/us/app/open-access-helper/id1447927317?l=de&ls=1") else {
            return
        }
        let promoText = NSLocalizedString("Check for Open Access copies of scientific articles with Open Access Helper!", comment: "Promotional String")
        let items: [Any] = [promoText, productURL]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
        if let popOver = activityViewController.popoverPresentationController {
            if let parentView = vc.oahelperLogo{
                popOver.sourceView = parentView
                popOver.sourceRect = CGRect(x: 0, y: 0, width: parentView.frame.size.width, height: parentView.frame.size.height)
            }
        }
        
    }
    
    func showVideo(){
        let mainVC = self.parent as! ViewController
        mainVC.removeInfoChildViewController()
        guard let url = URL(string: "http://www.youtube.com/embed/bNJx5_xujE8") else { return }
        let vc = SFSafariViewController(url: url)
        self.present(vc, animated: true, completion: nil)
    }
    

    @IBAction func dismissButtonTapped(_ sender: Any) {
        let vc = self.parent as! ViewController
        vc.removeInfoChildViewController()
    }
    
    @IBAction func showMeTapped(_ sender: Any) {
        if(type == "hint"){
            showVideo()
        }
        else if(type == "anniversary"){
            recommendApp()
        }
    }
    
}
