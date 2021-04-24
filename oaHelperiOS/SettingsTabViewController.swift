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
    
    @IBOutlet weak var bookMarkSwitch: UISwitch!
    @IBOutlet weak var iCloudSwitch: UISwitch!
    @IBOutlet weak var iCloudStatusLabel: UILabel!
    @IBOutlet weak var iCloudSwitchLabel: UILabel!
    @IBOutlet weak var resetBookMarksLabel: UILabel!
    @IBOutlet weak var resetBookMarksSwitch: UISwitch!
    @IBOutlet weak var onlyUnpaywallSwitch: UISwitch!
    @IBOutlet weak var openAccessButtonSwitch: UISwitch!
    @IBOutlet weak var recommendationSwitch: UISwitch!
    @IBOutlet weak var useProxySwitch: UISwitch!
    @IBOutlet weak var useProxyLabel: UILabel!
    @IBOutlet weak var useOpenCitationsSwitch: UISwitch!
    @IBOutlet weak var useIllSwitch: UISwitch!
    @IBOutlet weak var useIllLabel: UILabel!
    @IBOutlet weak var useEPMCLabel: UILabel!
    @IBOutlet weak var useEPMCSwitch: UISwitch!
    @IBOutlet weak var zoteroSwitch: UISwitch!
    
    
    // Mark: Buttons
    
    @IBOutlet weak var openSettingsButton: UIButton!
    @IBOutlet weak var setupProxyButton: UIButton!
    @IBOutlet weak var leaveReviewButton: UIButton!
    @IBOutlet weak var tellYourFriendsButton: UIButton!
    
    // Mark: Header Labels
    
    @IBOutlet weak var openAccessOptionsHeaderLabel: UILabel!
    @IBOutlet weak var bookmarksHeaderLabel: UILabel!
    @IBOutlet weak var additionalFeaturesHeaderLabel: UILabel!
    
    
    let settings = SettingsBundleHelper()
    let dataSync = DataSync()
    let helper = HelperClass()
    let selection = UISelectionFeedbackGenerator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        openSettingsButton.layer.cornerRadius = 10
        setupProxyButton.layer.cornerRadius = 10
        openAccessOptionsHeaderLabel.layer.masksToBounds = true
        bookmarksHeaderLabel.layer.masksToBounds = true
        additionalFeaturesHeaderLabel.layer.masksToBounds = true
        openAccessOptionsHeaderLabel.layer.cornerRadius = 5
        bookmarksHeaderLabel.layer.cornerRadius = 5
        additionalFeaturesHeaderLabel.layer.cornerRadius = 5
        
        readSettingsForSwitches()
        
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsTabViewController.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        
        iCloudStatus()
        AppStoreReviewManager.requestReviewIfAppropriate()
        
        if #available(iOS 13.4, *) {
            openSettingsButton.isPointerInteractionEnabled = true
            setupProxyButton.isPointerInteractionEnabled = true
            leaveReviewButton.isPointerInteractionEnabled = true
            tellYourFriendsButton.isPointerInteractionEnabled = true
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        readSettingsForSwitches()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver( self, name: UserDefaults.didChangeNotification, object: nil)
    }
    
    @objc func defaultsChanged(){
        
        // bookmark enabled
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
        
        // sync bookmakrs with iCloud
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
        
        // use only Unaywall
        if(self.settings.getSettingsValue(key: "only_unpaywall")){
            DispatchQueue.main.async {
                self.onlyUnpaywallSwitch.isOn = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.onlyUnpaywallSwitch.isOn = false
            }
        }
        
        //open access button
        if(self.settings.getSettingsValue(key: "open_access_button")){
            DispatchQueue.main.async {
                self.openAccessButtonSwitch.isOn = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.openAccessButtonSwitch.isOn = false
            }
        }
        
        // core.ac.uk recommendations
        if(self.settings.getSettingsValue(key: "recommendation")){
            DispatchQueue.main.async {
                self.recommendationSwitch.isOn = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.recommendationSwitch.isOn = false
            }
        }
        
        // useProxy
        if(self.settings.getSettingsValue(key: "useProxy")){
            DispatchQueue.main.async {
                self.useProxySwitch.isOn = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.useProxySwitch.isOn = false
            }
        }
        // useIll
        if(self.settings.getSettingsValue(key: "useIll")){
            DispatchQueue.main.async {
                self.useIllSwitch.isOn = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.useIllSwitch.isOn = false
            }
        }
        
        // enable / disable proxy / ill based on values
        
        if(self.settings.getSettingsStringValue(key: "proxyPrefix") == ""){
            DispatchQueue.main.async {
                self.useProxySwitch.isOn = false
                self.useProxySwitch.isEnabled = false
                self.useProxyLabel.isEnabled = false
                
            }
        }
        else{
            DispatchQueue.main.async {
                self.useProxySwitch.isEnabled = true;
                self.useProxyLabel.isEnabled = true
            }
        }
        
        if(self.settings.getSettingsStringValue(key: "illUrl") == ""){
            DispatchQueue.main.async {
                self.useIllSwitch.isOn = false
                self.useIllSwitch.isEnabled = false;
                self.useIllLabel.isEnabled = false
                
            }
        }
        else{
            DispatchQueue.main.async {
                self.useIllSwitch.isEnabled = true
                self.useIllLabel.isEnabled = true
            }
        }
        
        // useOpenCitations
        if(self.settings.getSettingsValue(key: "openCitations")){
            DispatchQueue.main.async {
                self.useOpenCitationsSwitch.isOn = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.useOpenCitationsSwitch.isOn = false
            }
        }
        
        // use Europe PMC
        if(self.settings.getSettingsValue(key: "epmc")){
            DispatchQueue.main.async {
                self.useEPMCSwitch.isOn = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.useEPMCSwitch.isOn = false
            }
        }
        
        // use zotero
        if(self.settings.getSettingsValue(key: "zotero")){
            DispatchQueue.main.async {
                self.zoteroSwitch.isOn = true
            }
        }
        else{
            DispatchQueue.main.async {
                self.zoteroSwitch.isOn = false
            }
        }

    }
    
    func readSettingsForSwitches(){
               
        // use bookmarks
        if(self.settings.getSettingsValue(key: "bookmarks")){
            bookMarkSwitch.isOn = true
        }
        else{
            bookMarkSwitch.isOn = false
        }
        
        // sync bookmarks with iCloud
        if(self.settings.getSettingsValue(key: "bookmarks_icloud")){
            iCloudSwitch.isOn = true
        }
        else{
            iCloudSwitch.isOn = false
        }
        
        //reset bookmarks from iCloud (delete and reload)
        if(self.settings.getSettingsValue(key: "reset_bookmarks_icloud")){
            resetBookMarksSwitch.isOn = true
        }
        else{
            resetBookMarksSwitch.isOn = false
        }
        
        //only use unpaywall.org
        if(self.settings.getSettingsValue(key: "only_unpaywall")){
            onlyUnpaywallSwitch.isOn = true
        }
        else{
            onlyUnpaywallSwitch.isOn = false
        }
        
        //use OpenAccessButton
        if(self.settings.getSettingsValue(key: "open_access_button")){
            openAccessButtonSwitch.isOn = true
        }
        else{
            openAccessButtonSwitch.isOn = false
        }
        
        // show recommendations
        if(self.settings.getSettingsValue(key: "recommendation")){
            recommendationSwitch.isOn = true
        }
        else{
            recommendationSwitch.isOn = false
        }
        
        // useProxy
        if(self.settings.getSettingsValue(key: "useProxy")){
            useProxySwitch.isOn = true
        }
        else{
            useProxySwitch.isOn = false
        }
        
        // useIll
        if(self.settings.getSettingsValue(key: "useIll")){
            useIllSwitch.isOn = true
        }
        else{
            useIllSwitch.isOn = false
        }
        
        // useOpenCitations
        if(self.settings.getSettingsValue(key: "openCitations")){
            useOpenCitationsSwitch.isOn = true
        }
        else{
            useOpenCitationsSwitch.isOn = false
        }
        
        // useEPMC
        if(self.settings.getSettingsValue(key: "epmc")){
            useEPMCSwitch.isOn = true
        }
        else{
            useEPMCSwitch.isOn = false
        }
        
        // use zotero
        if(self.settings.getSettingsValue(key: "zotero")){
            zoteroSwitch.isOn = true
        }
        else{
            zoteroSwitch.isOn = false
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
        self.iCloudSwitch.isEnabled = false
        self.iCloudSwitchLabel.isEnabled = false
        self.resetBookMarksSwitch.isEnabled = false
        self.resetBookMarksLabel.isEnabled = false
        self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
    }
    
    @IBAction func bookMarksSwitched(_ sender: UISwitch!) {
        if(self.bookMarkSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "bookmarks")
            self.settings.setSettingsValue(value: false, key: "zotero")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "bookmarks")
            self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
        }
    }
    
    @IBAction func iCloudSwitched(_ sender: UISwitch!) {
        if(self.iCloudSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "bookmarks_icloud")
            self.settings.setSettingsValue(value: true, key: "bookmarks")
            self.settings.setSettingsValue(value: false, key: "zotero")
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
    
    @IBAction func resetSwitched(_ sender: UISwitch!) {
        if(self.resetBookMarksSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "reset_bookmarks_icloud")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "reset_bookmarks_icloud")
        }
    }
    
    @IBAction func onlyUnpawayllSwitched(_ sender: UISwitch!) {
        if(self.onlyUnpaywallSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "only_unpaywall")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "only_unpaywall")
        }
    }
    
    @IBAction func openAccessButtonSwitched(_ sender: UISwitch!) {
        if(self.openAccessButtonSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "open_access_button")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "open_access_button")
        }
    }
    
    @IBAction func recommendationButtonSwitched(_ sender: UISwitch!) {
        if(self.recommendationSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "recommendation")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "recommendation")
        }
    }
    
    @IBAction func useProxyButtonSwitched(_ sender: Any) {
        if(self.useProxySwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "useProxy")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "useProxy")
        }
    }
    
    @IBAction func useIllButtonSwitched(_ sender: Any) {
        if(self.useIllSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "useIll")
        }
        else{
            self.settings.setSettingsValue(value: false, key: "useIll")
        }
    }
    
    @IBAction func useOpenCitationsSwitched(_ sender: Any) {
        if(self.useOpenCitationsSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "openCitations")
            
        }
        else{
            self.settings.setSettingsValue(value: false, key: "openCitations")
        }
    }
    
    @IBAction func useEPMCSwitched(_ sender: Any) {
        if(self.useEPMCSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "epmc")
            
        }
        else{
            self.settings.setSettingsValue(value: false, key: "epmc")
        }
    }
    
    @IBAction func zoteroSwitched(_ sender: Any) {
        if(self.zoteroSwitch.isOn){
            self.settings.setSettingsValue(value: true, key: "zotero")
            self.settings.setSettingsValue(value: false, key: "bookmarks")
            self.settings.setSettingsValue(value: false, key: "bookmarks_icloud")
            performSegue(withIdentifier: "settings2zoteroSegue", sender: nil)
        }
        else{
            self.settings.setSettingsValue(value: false, key: "zotero")
        }
    }
    
    
    @IBAction func openSettingsTapped(_ sender: Any) {
        DispatchQueue.main.async {
            self.selection.selectionChanged()
            if let url = URL(string:UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    @IBAction func leaveReviewTapped(_ sender: Any) {
        guard let productURL = URL(string: "https://apps.apple.com/us/app/open-access-helper/id1447927317?l=de&ls=1") else {
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
    
    @IBAction func shareAppTapped(_ sender: UIButton) {
        
        guard let productURL = URL(string: "https://apps.apple.com/us/app/open-access-helper/id1447927317?l=de&ls=1") else {
            return
        }
        let promoText = NSLocalizedString("Check for Open Access copies of scientific articles with Open Access Helper!", comment: "Promotional String")
        let items: [Any] = [promoText, productURL]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
        if let popOver = activityViewController.popoverPresentationController {
            popOver.sourceView = sender
            popOver.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
        }
    }
    
    @IBAction func setupProxyPrefixTapped(_ sender: Any) {
        performSegue(withIdentifier: "ezProxySegue", sender: nil)
    }
    
    
}
