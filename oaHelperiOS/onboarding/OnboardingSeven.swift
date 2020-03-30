//
//  OnboardingSeven.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 11.02.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import UIKit

class OnboardingSeven: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var domainTextField: UITextField!
    @IBOutlet weak var setupProxyButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    let proxyFind = ProxyFind()
    let settings = SettingsBundleHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupProxyButton.layer.cornerRadius = 10
        statusLabel.text = NSLocalizedString("Remote Access", comment: "Status Label")
        
        self.domainTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        if #available(iOS 13.4, *) {
            setupProxyButton.isPointerInteractionEnabled = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        domainTextField.resignFirstResponder()
        findProxy()
        return true
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.domainTextField.resignFirstResponder()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func findProxy(){
        self.statusLabel.text = NSLocalizedString("Checking...", comment: "shown while checking")
        if let domain = domainTextField.text {
            if(domain.count > 0){
                proxyFind.askForProxy(domain: domain) { (res) in
                    switch res{
                    case .success(let proxyList):
                        if(proxyList.count == 0){
                            DispatchQueue.main.async {
                                self.statusLabel.text = NSLocalizedString("No match found", comment: "if 0 hits returned")
                            }
                        }
                        else if(proxyList.count == 1){
                            if let proxyPrefix = proxyList.first?.proxyUrl.replacingOccurrences(of: "{targetUrl}", with: ""){
                                DispatchQueue.main.async {
                                    self.settings.setSettingsStringValue(value: proxyPrefix, key: "proxyPrefix")
                                    self.settings.setSettingsValue(value: true, key: "useProxy")
                                    if let instituteId = proxyList.first?.id{
                                        self.settings.setSettingsStringValue(value: instituteId, key: "instituteId")
                                    }
                                    self.statusLabel.text = NSLocalizedString("Success!", comment: "if proxy was successfully saved")
                                    self.domainTextField.isHidden = true
                                    self.setupProxyButton.isHidden = true
                                }
                            }
                            else{
                                DispatchQueue.main.async {
                                    self.statusLabel.text = NSLocalizedString("General Error", comment: "if unable to actually get to the proxyPrefix")
                                }
                            }
                            
                        }
                        else{
                            DispatchQueue.main.async {
                                self.statusLabel.text = NSLocalizedString("Try again!", comment: "if there are more than one result")
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.statusLabel.text = NSLocalizedString("Unexpected Error", comment: "if failure received")
                            print(error)
                        }
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    self.statusLabel.text = NSLocalizedString("Field Empty?", comment: "if proxy field was empty")
                }
            }
        }
    }
    
    @IBAction func setupProxyTapped(_ sender: Any) {
        findProxy()
        self.domainTextField.resignFirstResponder()
    }

}
