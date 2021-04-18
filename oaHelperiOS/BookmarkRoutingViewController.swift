//
//  BookmarkRoutingViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 10.04.21.
//  Copyright © 2021 Claus Wolf. All rights reserved.
//

import UIKit

class BookmarkRoutingViewController: UIViewController {
    
    let settings = SettingsBundleHelper()
    let zoteroAPI = ZoteroAPI()
    
    @IBOutlet weak var zoteroLabel: UILabel!
    
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var zoteroButton: UIButton!
    @IBOutlet weak var setupButton: UIButton!
    @IBOutlet weak var zoteroLogo: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        zoteroLogo.isHidden = true
        
        bookmarkButton.layer.cornerRadius = 10
        bookmarkButton.isHidden = true
        
        setupButton.layer.cornerRadius = 10
        setupButton.isHidden = true
        
        zoteroButton.layer.cornerRadius = 10
        zoteroLabel.isHidden = true
        
        if(self.settings.getSettingsValue(key: "oauthreturn") && self.settings.getSettingsValue(key: "activeOAuth")){
            finishTokenExchange()
        }
        else if(self.settings.getSettingsValue(key: "bookmarks")) {
            performSegue(withIdentifier: "iCloudBookmark", sender: self)
        }
        else if(self.settings.getSettingsValue(key: "zotero")){
            performSegue(withIdentifier: "zoteroBookmark", sender: self)
        }
        else{
            performSegue(withIdentifier: "noBookmark", sender: self)
        }
    }
    
    func doZoteroDisplay(){
        let activeOAuth = self.settings.getSettingsValue(key: "activeOAuth")
        let zoteroSuccess = self.settings.getSettingsValue(key: "zoteroSuccess")
        let zotero_username = self.settings.getSettingsStringValue(key: "username")
        
        if (!activeOAuth && zoteroSuccess){
            DispatchQueue.main.async {
                self.zoteroLogo.isHidden = false
                self.zoteroLabel.isHidden = false
                let text1 = NSLocalizedString("Hello, ", comment: "part of Hello, <zoterouser>...string")
                let text2 = "\(zotero_username)! "
                let text3 = NSLocalizedString("You can now start using this feature.", comment: "part of Hello, <zoterouser>...string")
                self.zoteroLabel.text = "\(text1)\(text2)\(text3)"
                self.zoteroButton.isHidden = false
            }
        }
    }
    
    func doZoteroAuthFailure(){
        DispatchQueue.main.async {
            self.zoteroLogo.isHidden = false
            self.zoteroLabel.text = NSLocalizedString("Something went wrong 😞 \n\n Try again?!", comment: "shown when authentication failed")
            self.setupButton.isHidden = false
        }
    }
    
    func clearAllTemporaryZoteroSettingValues(){
        self.settings.setSettingsValue(value: false, key: "activeOAuth")
        self.settings.setSettingsValue(value: false, key: "oauthreturn")
        self.settings.setSettingsStringValue(value: "", key: "requestToken")
        self.settings.setSettingsStringValue(value: "", key: "requestTokenSecret")
        self.settings.setSettingsStringValue(value: "", key: "oauth_verifier")
        self.settings.setSettingsStringValue(value: "", key: "oauth_token")
    }
    
    func finishTokenExchange(){
        bookmarkButton.isHidden = true
        zoteroButton.isHidden = true
        setupButton.isHidden = true
        zoteroLabel.text = NSLocalizedString("Finishing Zotero Authentication", comment: "shown at start of finish Token Exchange")
        zoteroLogo.isHidden = false
        let isActive = settings.getSettingsValue(key: "activeOAuth")
        let isOAuthReturn = settings.getSettingsValue(key: "oauthreturn")
        let requestToken = settings.getSettingsStringValue(key: "requestToken")
        let requestTokenSecret = settings.getSettingsStringValue(key: "requestTokenSecret")
        let oauth_verifier = settings.getSettingsStringValue(key: "oauth_verifier")
        let oauth_token = settings.getSettingsStringValue(key: "oauth_token")
        if(isActive && isOAuthReturn && requestToken == oauth_token && oauth_verifier != ""){
            let temporaryCredentials = TemporaryCredentials(requestToken: requestToken, requestTokenSecret: requestTokenSecret)
            self.zoteroAPI.oAuthAccessToken(temporaryCredentials: temporaryCredentials, verifier: oauth_verifier) { (res) in
                switch(res){
                case .success(let token):
                    print(token)
                    self.clearAllTemporaryZoteroSettingValues()
                    self.settings.setSettingsValue(value: true, key: "zoteroSuccess")
                    self.settings.setSettingsStringValue(value: token.accessToken, key: "oauth_token")
                    self.settings.setSettingsStringValue(value: token.accessTokenSecret, key: "oauth_token_secret")
                    self.settings.setSettingsStringValue(value: token.userID, key: "userID")
                    self.settings.setSettingsStringValue(value: token.username, key: "username")
                    self.checkZoteroCollectionExists()
                    
                case .failure(let error):
                    print("error in finishTokenExchange : \(error)")
                    self.settings.setSettingsValue(value: false, key: "zoteroSuccess")
                    self.settings.setSettingsValue(value: false, key: "zotero")
                    self.clearAllTemporaryZoteroSettingValues()
                    self.doZoteroAuthFailure()
                }
            }
        }
        else{
            print("failed on isActive isOAuthREturn requestToken & Co")
            self.settings.setSettingsValue(value: false, key: "zoteroSuccess")
            self.settings.setSettingsValue(value: false, key: "zotero")
            self.clearAllTemporaryZoteroSettingValues()
            self.doZoteroAuthFailure()
        }
    }
    
    func createZoteroCollection() {
        DispatchQueue.main.async {
            self.zoteroLogo.isHidden = false
            self.zoteroLabel.text = NSLocalizedString("Creating the Open Access Helper Collection", comment: "shown while creating collection")
        }
        self.zoteroAPI.createCollection(name: "Open Access Helper") { (res) in
            switch(res){
            case .success(let created):
                DispatchQueue.main.async {
                    if(created){
                        self.doZoteroDisplay()
                    }
                    else{
                        self.zoteroLabel.text = NSLocalizedString("Oops - something went wrong while creating the Open Access Helper Collection", comment: "shown when creating a collection fails")
                    }
                }
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    self.zoteroLabel.text = NSLocalizedString("Oops - something went wrong while creating the Open Access Helper Collection", comment: "shown when creating a collection fails")
                }
            }
        }
    }
    
    func checkZoteroCollectionExists() {
        DispatchQueue.main.async {
            self.zoteroLogo.isHidden = false
            self.zoteroLabel.text = NSLocalizedString("Checking if Open Access Helper Collection exists", comment: "shown while checking collection")
        }
        self.zoteroAPI.collectionExists(name: "Open Access Helper") { (res) in
            switch(res){
            case .success(let exists):
                DispatchQueue.main.async {
                    if(exists){
                        self.doZoteroDisplay()
                    }
                    else{
                        self.createZoteroCollection()
                    }
                }
                
            case .failure(let error):
                print(error)
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
    
}
