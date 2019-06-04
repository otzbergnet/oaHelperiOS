//
//  SettingsTabViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 25.04.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit
import CloudKit

class SettingsTabViewController: UIViewController {

    @IBOutlet weak var shareSwitch: UISwitch!
    @IBOutlet weak var bookMarkSwitch: UISwitch!
    @IBOutlet weak var iCloudSwitch: UISwitch!
    @IBOutlet weak var openSettingsButton: UIButton!
    @IBOutlet weak var iCloudStatusLabel: UILabel!
    @IBOutlet weak var iCloudSwitchLabel: UILabel!
    @IBOutlet weak var resetBookMarksSwitch: UISwitch!
    
    let settings = SettingsBundleHelper()
    let dataSync = DataSync()
    let selection = UISelectionFeedbackGenerator()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        openSettingsButton.layer.cornerRadius = 10
        
        readSettingsForSwitches()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsTabViewController.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        
        iCloudStatus()
        AppStoreReviewManager.requestReviewIfAppropriate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        readSettingsForSwitches()
    }
    
    deinit {
        NotificationCenter.default.removeObserver( self, name: UserDefaults.didChangeNotification, object: nil)
    }

    @objc func defaultsChanged(){
        if settings.getSettingsValue(key: "bookmarks") {
            DispatchQueue.main.async {
                self.bookMarkSwitch.isOn = true
            }
        }
        else {
            DispatchQueue.main.async {
                self.bookMarkSwitch.isOn = false
            }
        }
        if settings.getSettingsValue(key: "bookmarks_icloud") {
            DispatchQueue.main.async {
                self.iCloudSwitch.isOn = true
            }
        }
        else {
            DispatchQueue.main.async {
                self.iCloudSwitch.isOn = false
            }
        }
        if(self.settings.getSettingsValue(key: "share_stats")){
            DispatchQueue.main.async {
                self.shareSwitch.isOn = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.shareSwitch.isOn = false
            }
        }
    }
    
    func readSettingsForSwitches(){
        if(self.settings.getSettingsValue(key: "share_stats")){
            shareSwitch.isOn = true
        }
        else{
            shareSwitch.isOn = false
        }
        if(self.settings.getSettingsValue(key: "bookmarks")){
            bookMarkSwitch.isOn = true
        }
        else{
            bookMarkSwitch.isOn = false
        }
        if(self.settings.getSettingsValue(key: "bookmarks_icloud")){
            iCloudSwitch.isOn = true
        }
        else{
            iCloudSwitch.isOn = false
        }
        if(self.settings.getSettingsValue(key: "reset_bookmarks_icloud")){
            resetBookMarksSwitch.isOn = true
        }
        else{
            resetBookMarksSwitch.isOn = false
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
    
    func iCloudStatus(){
        CKContainer.default().accountStatus { (accountStatus, error) in
            switch accountStatus {
            case .available:
                DispatchQueue.main.async {
                    self.iCloudStatusLabel.text = ""
                }
                
            case .noAccount:
                DispatchQueue.main.async {
                    self.iCloudStatusLabel.text = NSLocalizedString("Sadly, your iCloud account seems unavailable. We've disabled the iCloud option for you.", comment: "No iCloud account")
                    self.hideiCloudRelatedContent()
                }
            case .restricted:
                DispatchQueue.main.async {
                    self.iCloudStatusLabel.text = NSLocalizedString("iOS reports iCloud status as restricted. We've disabled the iCloud option for you.", comment: "iCloud restricted")
                    self.hideiCloudRelatedContent()
                }
            case .couldNotDetermine:
                DispatchQueue.main.async {
                    self.iCloudStatusLabel.text = NSLocalizedString("Unable to determine iCloud status. We've disabled the iCloud option for you.", comment: "Unable to determine iCloud status")
                    self.hideiCloudRelatedContent()
                }
            @unknown default:
                print("unknown default")
            }
        }
    }
    
    func hideiCloudRelatedContent(){
        self.iCloudSwitch.isOn = false
        self.iCloudSwitch.isHidden = true
        self.iCloudSwitchLabel.isHidden = true
        self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
    }
    
    @IBAction func dataShareSwitched(_ sender: Any) {
        if(self.shareSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "share_stats")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "share_stats")
        }
    }
    
    @IBAction func bookMarksSwitched(_ sender: Any) {
        if(self.bookMarkSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "bookmarks")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "bookmarks")
            self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
        }
    }
    
    @IBAction func iCloudSwitched(_ sender: Any) {
        if(self.iCloudSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "bookmarks_icloud")
            self.settings.setSettingsValue(value: true, key: "bookmarks")
            self.dataSync.hasCustomZone(){ (test) in
                if(!test){
                    //NSLOG("I don't have custom zone and could not create")
                    print("I don't have custom zone and could not create")
                }
            }
        }
        else{
            self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
        }
    }

    @IBAction func resetSwitched(_ sender: Any) {
        if(self.resetBookMarksSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "reset_bookmarks_icloud")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "reset_bookmarks_icloud")
        }
    }
    
    @IBAction func openSettingsTapped(_ sender: Any) {
        selection.selectionChanged()
        if let url = URL(string:UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    @IBAction func leaveReviewTapped(_ sender: Any) {
        let appId = "1447927317"
        guard let productURL = URL(string: "https://itunes.apple.com/de/app/id\(appId)") else {
            return
        }
        var components = URLComponents(url: productURL, resolvingAgainstBaseURL: false)
        
        components?.queryItems = [
            URLQueryItem(name: "action", value: "write-review")
        ]
        
        guard let writeReviewURL = components?.url else {
            return
        }
        UIApplication.shared.open(writeReviewURL)
    }
  
    @IBAction func shareAppTapped(_ sender: Any) {
        let appId = "1447927317"
        guard let productURL = URL(string: "https://itunes.apple.com/de/app/id\(appId)") else {
            return
        }
        let promoText = NSLocalizedString("Check for Open Access copies of scientific articles with Open Access Helper!", comment: "Promotional String")
        let items: [Any] = [promoText, productURL]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
    
}
