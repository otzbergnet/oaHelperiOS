//
//  ProxySettingsViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 10.02.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import UIKit

class ProxySettingsViewController: UIViewController {
    
    
    @IBOutlet weak var proxyPrefixTextfield: UITextField!
    @IBOutlet weak var searchDomainTextfield: UITextField!
    
    @IBOutlet weak var saveProxyButton: UIButton!
    @IBOutlet weak var searchDomainButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    
    let helper = HelperClass()
    let settings = SettingsBundleHelper()
    let proxyFind = ProxyFind()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        saveProxyButton.layer.cornerRadius = 10
        searchDomainButton.layer.cornerRadius = 10
        cancelButton.layer.cornerRadius = 10
        
        statusLabel.text = ""
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getProxyForTextfield()
    }
    
    func getProxyForTextfield(){
        let newProxyPrefix = settings.getSettingsStringValue(key: "proxyPrefix")
        if(newProxyPrefix != ""){
            DispatchQueue.main.async {
                self.proxyPrefixTextfield.text = newProxyPrefix
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    @IBAction func saveProxyButtonTapped(_ sender: Any) {
        if let proxyPrefix = proxyPrefixTextfield.text {
            if(helper.validateProxyPrefix(urlString: proxyPrefix)){
                settings.setSettingsStringValue(value: proxyPrefix, key: "proxyPrefix")
                getProxyForTextfield()
                dismiss(animated: true) {
                    //nothing
                }
            }
        }
    }
    
    @IBAction func searchDomainButtonTapped(_ sender: Any) {
        if let domain = searchDomainTextfield.text {
            if(domain.count > 0){
                proxyFind.askForProxy(domain: domain) { (res) in
                    switch res{
                    case .success(let proxyList):
                        if(proxyList.count == 0){
                            DispatchQueue.main.async {
                                self.statusLabel.text = NSLocalizedString("No match was found", comment: "if 0 hits returned")
                            }
                        }
                        else if(proxyList.count == 1){
                            if let proxyPrefix = proxyList.first?.proxyUrl.replacingOccurrences(of: "{targetUrl}", with: ""){
                                DispatchQueue.main.async {
                                    self.settings.setSettingsStringValue(value: proxyPrefix, key: "proxyPrefix")
                                    self.getProxyForTextfield()
                                    self.statusLabel.text = NSLocalizedString("Successfuly, saved!", comment: "if proxy was successfully saved")
                                    self.statusLabel.textColor = .blue
                                }
                            }
                            else{
                                DispatchQueue.main.async {
                                    self.statusLabel.text = NSLocalizedString("We found a match, but could not get the prefix", comment: "if unable to actually get to the proxyPrefix")
                                }
                            }
                            
                        }
                        else{
                            DispatchQueue.main.async {
                                self.statusLabel.text = NSLocalizedString("Please review your domain-name, as we were unable to find just one match", comment: "if there are more than one result")
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.statusLabel.text = NSLocalizedString("We encountered an unexpected error", comment: "if failure received")
                            print(error)
                        }
                    }
                }
            }
            else{
                DispatchQueue.main.async {
                    self.statusLabel.text = NSLocalizedString("Looks like the domain field was empty", comment: "if proxy field was empty")
                }
            }
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true) {
            //nothing
        }
    }
    
}
