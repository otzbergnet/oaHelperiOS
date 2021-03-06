//
//  ProxySettingsViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 10.02.20.
//  Copyright © 2020 Claus Wolf. All rights reserved.
//

import UIKit

class ProxySettingsViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var proxyPrefixTextfield: UITextField!
    @IBOutlet weak var searchDomainTextfield: UITextField!
    @IBOutlet weak var illUrlTextfield: UITextField!
    
    @IBOutlet weak var saveProxyButton: UIButton!
    @IBOutlet weak var saveIllButton: UIButton!
    @IBOutlet weak var searchDomainButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchTypeSegmentControl: UISegmentedControl!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    
    let helper = HelperClass()
    let settings = SettingsBundleHelper()
    let proxyFind = ProxyFind()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        saveProxyButton.layer.cornerRadius = 5
        searchDomainButton.layer.cornerRadius = 5
        saveIllButton.layer.cornerRadius = 5
        cancelButton.layer.cornerRadius = 5
        
        statusLabel.text = ""
        self.proxyPrefixTextfield.delegate = self
        self.searchDomainTextfield.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        if #available(iOS 13.4, *) {
            saveProxyButton.isPointerInteractionEnabled = true
            searchDomainButton.isPointerInteractionEnabled = true
            cancelButton.isPointerInteractionEnabled = true
            saveIllButton.isPointerInteractionEnabled = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getProxyForTextfield()
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.proxyPrefixTextfield.resignFirstResponder()
        self.searchDomainTextfield.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let restorationIdentifier = textField.restorationIdentifier{
            switch(restorationIdentifier){
            case "domainField":
                self.serchByDomainFunction()
            case "proxyPrefix":
                self.saveProxyManually()
            default:
                print("nothing")
            }
        }
        return true
    }
    
    func getProxyForTextfield(){
        let newProxyPrefix = settings.getSettingsStringValue(key: "proxyPrefix")
        if(newProxyPrefix != ""){
            DispatchQueue.main.async {
                self.proxyPrefixTextfield.text = newProxyPrefix
            }
        }
        let newIllUrl = settings.getSettingsStringValue(key: "illUrl")
        if(newIllUrl != ""){
            DispatchQueue.main.async {
                self.illUrlTextfield.text = newIllUrl
            }
        }
    }
    
    func dismissLater(seconds: Double){
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: {
            self.dismiss(animated: true) {
                //nothing
            }
        })
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    func saveProxyManually() {
        self.proxyPrefixTextfield.resignFirstResponder()
        if let proxyPrefix = proxyPrefixTextfield.text {
            if(helper.validateProxyPrefix(urlString: proxyPrefix)){
                settings.setSettingsStringValue(value: proxyPrefix, key: "proxyPrefix")
                self.settings.setSettingsStringValue(value: "-", key: "instituteId")
                getProxyForTextfield()
                self.statusLabel.text = NSLocalizedString("Successfully saved!", comment: "shown upon save")
                self.statusLabel.textColor = .blue
                self.dismissLater(seconds: 0.75)
            }
            else{
                self.statusLabel.text = NSLocalizedString("The proxy prefixed you entered, failed to validate. Please enter the prefix in the format https://proxy.university.edu/login?url=", comment: "failed to validate proxy prefix")
            }
        }
    }
    
    @IBAction func saveProxyButtonTapped(_ sender: Any) {
        saveProxyManually()
    }
    
    @IBAction func saveIllButtonTapped(_ sender: Any) {
        //TO DO
    }
    
    @IBAction func searchTypeSegmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            searchDomainTextfield.placeholder = "Institute Domain, e.g. harvard.edu"
        case 1:
            searchDomainTextfield.placeholder = "Partial Name, e.g. harva"
        default:
            break;
        }
    }
    
    
    func serchByDomainFunction() {
        self.searchDomainTextfield.resignFirstResponder()
        self.statusLabel.text = NSLocalizedString("Searching...", comment: "show searching, when looking up settings")
        let queryTypeRawValue = self.searchTypeSegmentControl.selectedSegmentIndex
        var queryType = "domain"
        if(queryTypeRawValue == 1){
            queryType = "query"
        }
        if let domain = searchDomainTextfield.text {
            if(domain.count > 0){
                proxyFind.askForProxy(domain: domain, queryType: queryType) { (res) in
                    switch res{
                    case .success(let proxyList):
                        if(proxyList.count == 0){
                            self.updateStatusLabel(statusLabel: NSLocalizedString("No match was found", comment: "if 0 hits returned"), textColor: .black)
                        }
                        else if(proxyList.count == 1){
                            self.proxyFind.processProxyList(proxyList: proxyList) { (res1) in
                                switch res1 {
                                case .success(_):
                                    print("success")
                                    self.getProxyForTextfield()
                                    self.updateStatusLabel(statusLabel: NSLocalizedString("Successfuly, saved!", comment: "if proxy was successfully saved"), textColor: .blue)
                                case .failure(_):
                                    self.updateStatusLabel(statusLabel: NSLocalizedString("We found a match, but could not get the prefix", comment: "if unable to actually get to the proxyPrefix"), textColor: .black)
                                    self.dismissLater(seconds: 0.75)
                                }
                            }
                        }
                        else{
                            self.updateStatusLabel(statusLabel: NSLocalizedString("Please review your domain-name, as we were unable to find just one match", comment: "if there are more than one result"), textColor: .black)
                        }
                    case .failure(let error):
                        self.updateStatusLabel(statusLabel: NSLocalizedString("We encountered an unexpected error", comment: "if failure received"), textColor: .black)
                        print(error)
                    }
                }
            }
            else{
                self.updateStatusLabel(statusLabel: NSLocalizedString("Looks like the domain field was empty", comment: "if proxy field was empty"), textColor: .black)
            }
        }
    }
    
    func updateStatusLabel(statusLabel: String, textColor: UIColor){
        DispatchQueue.main.async {
            self.statusLabel.text = statusLabel
        }
    }
    
    
    @IBAction func searchDomainButtonTapped(_ sender: Any) {
        serchByDomainFunction()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true) {
            //nothing
        }
    }
    
}
