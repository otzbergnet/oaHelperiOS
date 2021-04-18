//
//  ZoteroConnectViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 18.04.21.
//  Copyright © 2021 Claus Wolf. All rights reserved.
//

import UIKit

class ZoteroConnectViewController: UIViewController {

    @IBOutlet weak var connectZoteroButton: UIButton!
    @IBOutlet weak var instructionTextView: UITextView!
    
    
    let settings = SettingsBundleHelper()
    let zoteroAPI = ZoteroAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        connectZoteroButton.layer.cornerRadius = 10
        
    }
    
    func openOAuthUrl(url: String) {
        DispatchQueue.main.async {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        }
    }

    func startZoteroOAuth(){
        self.settings.setSettingsValue(value: true, key: "activeOAuth")
        zoteroAPI.oAuthRequestToken(start: true) { (res) in
            switch(res) {
            case .success(let token):
                self.settings.setSettingsStringValue(value: token.requestToken, key: "requestToken")
                self.settings.setSettingsStringValue(value: token.requestTokenSecret, key: "requestTokenSecret")
                let url = "https://www.zotero.org/oauth/authorize?oauth_token=\(token.requestToken)&library_access=1&notes_access=1&write_access=1&all_groups=write"
                self.openOAuthUrl(url: url)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    @IBAction func connectZoteroTapped(_ sender: Any) {
        self.settings.setSettingsValue(value: false, key: "bookmarks")
        self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
        self.settings.setSettingsValue(value: true, key: "zotero")
        self.startZoteroOAuth()
    }
    
}
