//
//  DetailViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 16.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit
import SafariServices

class DetailData{
    var title : String = ""
    var author = [String]()
    var abstract : String = ""
    var url : String = ""
    var buttonLabel = ""
}

class DetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var abstractLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accessButton: UIButton!
    @IBOutlet var mainView: UIView!
    
    var coreRecord = DetailData()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        accessButton.layer.cornerRadius = 10
        
        // Do any additional setup after loading the view.
        titleLabel.text = coreRecord.title
        let byText = NSLocalizedString("By: ", comment: "By is shown just before authors")
        if(coreRecord.author.count > 0){
            if(coreRecord.author.count > 3){
                authorLabel.text = "\(byText) \(coreRecord.author[0]), \(coreRecord.author[1]), et al."
            }
            else if(coreRecord.author.count > 1){
                authorLabel.text = "\(byText) \(coreRecord.author[0]), \(coreRecord.author[1])"
            }
            else{
                authorLabel.text = "\(byText) \(coreRecord.author[0])"
            }
            
        }
        else{
            authorLabel.text = ""
        }
        
        abstractLabel.text = coreRecord.abstract
        abstractLabel.sizeToFit()
        accessButton.setTitle(coreRecord.buttonLabel, for: .normal)
        let label = NSLocalizedString("View Record at core.ac.uk", comment: "in this case used for string comparison")
        if(coreRecord.buttonLabel == label){
            accessButton.backgroundColor = UIColor(displayP3Red: 0.102, green: 0.596, blue: 0.988, alpha: 1.00)
        }
        if(coreRecord.url == "" ){
            accessButton.isHidden = true
        }
    }
    

    override func viewDidLayoutSubviews() {
        //resizeView()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func accessTapped(_ sender: Any) {
        
        if(coreRecord.url != ""){
            //print(coreRecord.url)
            let url = URL(string: self.coreRecord.url.trimmingCharacters(in: .whitespacesAndNewlines))
            let vc = SFSafariViewController(url: url!)
            self.present(vc, animated: true, completion: nil)
        }
        else{
            print("accss Tapped failed somehow - empty?")
        }
    }

}
