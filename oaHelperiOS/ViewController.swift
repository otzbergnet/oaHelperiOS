//
//  ViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 08.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit
import SafariServices
import Network

class ViewController: UIViewController, UITextFieldDelegate {

    // MARK: Properties
    
    @IBOutlet weak var textField: UITextField!

    @IBOutlet weak var enterSearchLabel: UILabel!
    //@IBOutlet weak var bookmarkButton: UIButton!
    //@IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var offlineLabel: UILabel!
    
    // MARK: Buttons
    
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var advancedSearchButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    
    @IBOutlet weak var oahelperLogo: UIImageView!
    
    @IBOutlet weak var searchProviderLogo: UIImageView!
    @IBOutlet weak var searchProviderMention: UILabel!
    
    
    var searchTerm = ""
    var search = ""
    var proxy = ""
    var apiData = Data()
    var searchResults = SearchResult()
    var urlScheme = false
    
    // variables used for the HUD control
    let messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    let settings = SettingsBundleHelper()
    var bookMarkData = BookMarkData()
    let helper = HelperClass()
    let newsItemData = NewsItemData()
    //var bookMarkList : [BookMark] = []

    let selection = UISelectionFeedbackGenerator()
    
    var showBookMarkButton = true
    var activeBookMarkCheck = false
    var isOnline = true
    
    var infoChildViewController = InfoChildViewController()
    
    // MARK: View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.settings.ensureSettingsAreRegistered()
        
        if(self.settings.getSettingsValue(key: "oauthreturn") && self.settings.getSettingsValue(key: "activeOAuth")){
            self.tabBarController?.selectedIndex = 1
        }

        //search button should have corner radius and offlineLabel should be empty
        searchButton.layer.cornerRadius = 10
        offlineLabel.text = ""
        
        //we want to set the title
        self.title = NSLocalizedString("Search", comment: "Search shown in navbar on first view controller")
        
        //dismiss keyboard, when we tap outside of search field
        self.textField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        //get search terms from the AppExtension via the URL Scheme oahelper://
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        //do the bookMarkCheck
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        self.checkNews()
        self.updateUnreadCount()
        
        // do promo containerView (Child VC)
        self.addInfoChildViewController()
        
        //check if data data update is required
        
        
        //support mouse pointer
        if #available(iOS 13.4, *) {
            helpButton.isPointerInteractionEnabled = true
            advancedSearchButton.isPointerInteractionEnabled = true
            searchButton.isPointerInteractionEnabled = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.networkAvailable()
        self.setSearchProviderLogo()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    

    // MARK:  NotificationCenter Observer Functions
    
    @objc func didBecomeActive() {
        /*self.showBookMarkButton = self.settings.getSettingsValue(key: "bookmarks")
        if(self.showBookMarkButton){
            self.bookMarkCheck(){ (type: String) in
                if(type == "done"){
                    //print("didBecomeActive bookmarkcheck finished and done")
                    self.activeBookMarkCheck = false;
                }
                else if(type == "active"){
                    print("active check, didn't bother");
                }
            }
        }*/
        
    }

    //handles the data from the URLscheme
    @objc func applicationDidBecomeActive() {
        if(!urlScheme){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if(appDelegate.search != ""){
                //print(appDelegate.search)
                self.textField.text = appDelegate.search
                let message = NSLocalizedString("Searching core.ac.uk for you", comment: "shows as soon as search is submitted")
                self.activityIndicator(message)
                let query = self.helper.createSearch(search: appDelegate.search)
                self.search = query
                checkCore(search: query)
                // setting this to true, there was a case, where the search would execute again, if you left the app and opened it again
                // the search fromt he previuos url scheme would be re-executed
                urlScheme = true
            }
            else if (appDelegate.proxy != ""){
                let alertTitle = NSLocalizedString("New Proxy Added", comment: "alert title: new proxy added")
                let alertMessage = NSLocalizedString("We have added your new proxy prefix. It is ready to use!", comment: "alert body: new proxy added")
                let okButton = NSLocalizedString("OK", comment: "alert ok button")
                self.showErrorAlert(alertTitle : alertTitle, alertMessage : alertMessage, okButton : okButton)
            }
        }
        
        
    }
    

    deinit {
        NotificationCenter.default.removeObserver( self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        doSearch()
        return true
    }
    

    
    func doSearch(){
        selection.selectionChanged()
        self.textField.resignFirstResponder()
        if let search = textField.text {
            if (self.settings.getSettingsValue(key: "epmc")){
                let query = search
                self.search = query
                let message = NSLocalizedString("Searching Europe PMC for you", comment: "shows as soon as search is submitted")
                self.activityIndicator(message)
                checkEPMC(search: query)
            }
            else {
                let query = self.helper.createSearch(search: search)
                self.search = query
                let message = NSLocalizedString("Searching core.ac.uk for you", comment: "shows as soon as search is submitted")
                self.activityIndicator(message)
                checkCore(search: query)
            }
            
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchSegue" {
            if let nextViewController = segue.destination as? TableViewController {
                nextViewController.apiData = self.apiData
                nextViewController.searchResults = self.searchResults
                nextViewController.page = 1
                nextViewController.search = self.search
                //print("searchTerm:", self.search)
            }
        }
    }
    
    func checkCore(search: String){
        // let's get the API key from the git-ignored plist (apikey)
        let apiKey = self.helper.getAPIKeyFromPlist(key: "core")
        // if the apiKey is empty show an error, but we can't recover from it
        if(apiKey == ""){
            self.effectView.removeFromSuperview()
            let text = NSLocalizedString("core.ac.uk API key missing - please quit app", comment: "missing API key, breaking error")
            self.activityIndicator(text)
            return
        }
        // lets get the data via the search
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.helper.checkCore(search: search, apiKey: apiKey, page: 1) { (res) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            switch res {
            case .success(let data):
                DispatchQueue.main.async {
                    self.settings.incrementOACount(key : "oa_search")
                    self.searchResults = data
                    self.effectView.removeFromSuperview()
                    self.enterSearchLabel.text = NSLocalizedString("Enter your search:", comment: "above the search field")
                    self.enterSearchLabel.textColor = UIColor.black
                    self.performSegue(withIdentifier: "searchSegue", sender: nil)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.effectView.removeFromSuperview()
                    self.enterSearchLabel.text = NSLocalizedString("Sorry, we encountered a problem", comment: "problem with search")
                    self.enterSearchLabel.textColor = UIColor.red
                    print(error)
                }
            }
        }
    }
   
    func checkEPMC(search: String){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.helper.checkEPMC(search: search, nextCursorMark: "*", page: 1) { (res) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            switch res {
            case .success(let data):
                DispatchQueue.main.async {
                    self.settings.incrementOACount(key : "oa_search")
                    self.searchResults = data
                    self.effectView.removeFromSuperview()
                    self.enterSearchLabel.text = NSLocalizedString("Enter your search:", comment: "above the search field")
                    self.enterSearchLabel.textColor = UIColor.black
                    self.performSegue(withIdentifier: "searchSegue", sender: nil)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.effectView.removeFromSuperview()
                    self.enterSearchLabel.text = NSLocalizedString("Sorry, we encountered a problem", comment: "problem with search")
                    self.enterSearchLabel.textColor = UIColor.red
                    print(error)
                }
            }
        }
    }
    
    func activityIndicator(_ title: String) {
        
        strLabel.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        effectView.removeFromSuperview()
        let width = 275
        let height = 75
        let height2 = height + (height/3*2)
        
        strLabel = UILabel(frame: CGRect(x: 0, y: 35, width: width, height: height))
        strLabel.text = title
        strLabel.font = .systemFont(ofSize: 14, weight: .medium)
        strLabel.textColor = UIColor(white: 0.9, alpha: 0.7)
        strLabel.textAlignment = .center;
            
        effectView.frame = CGRect(x: view.frame.midX - CGFloat(width/2), y: view.frame.midY - CGFloat(height/2) , width: CGFloat(width), height: CGFloat(height2))
        effectView.layer.cornerRadius = 15
        effectView.layer.masksToBounds = true
            
        activityIndicator = UIActivityIndicatorView(style: .white)
        activityIndicator.frame = CGRect(x: width/2-23, y: 15, width: 46, height: 46)
        activityIndicator.startAnimating()
            
        effectView.contentView.addSubview(activityIndicator)
        effectView.contentView.addSubview(strLabel)
        view.addSubview(effectView)
        self.view.layoutIfNeeded()
      
        
    }
    
    func showErrorAlert(alertTitle : String, alertMessage : String, okButton : String){
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButton, style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            //self.syncButton.isHidden = true
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func networkAvailable(){
        let monitor = NWPathMonitor()
        
        monitor.pathUpdateHandler = { path in
            if path.availableInterfaces.count == 0 {
                DispatchQueue.main.async {
                    self.isOnline = false
                    self.offlineLabel.text = "offline"
                }
            }
            else{
                DispatchQueue.main.async {
                    self.isOnline = true
                    self.offlineLabel.text = ""
                    if(self.settings.getSettingsValue(key: "bookmarks_icloud")){
                        //self.syncButton.isHidden = false
                    }
                }
                
            }
        }
        
        let queue = DispatchQueue.global(qos: .background)
        monitor.start(queue: queue)
    }
    
    func checkNews(){
        self.newsItemData.getNews(forced: false) { ( res) in
            switch res {
            case .success(_):
                DispatchQueue.main.async {
                    self.updateUnreadCount();
                }
            case .failure(let error):
                print("failed to fetch newsItems:", error)
            }
        }
    }
    
    func updateUnreadCount(){
        let unreadCount = self.newsItemData.getUnreadCount();
        if let tabBar = self.tabBarController{
            self.helper.updateTabBar(tabBarController: tabBar, value: "\(unreadCount)")
        }
    }
    
    func addInfoChildViewController(){
        //if hint or anniversary was shown, we are done
        let hintShown = self.settings.getSettingsValue(key: "hintShown")
        let anniversaryShown = self.settings.getSettingsValue(key: "anniversaryShown")
        var type = ""

        if(hintShown && anniversaryShown){
            return
        }

        if(!hintShown){
            //find oa_found & oa_search counts, we don't want to show to users
            //who have done the extension several times, or who are very low on oa_search counts
            let oa_found = self.settings.getOACount(key: "oa_found");
            let oa_search = self.settings.getOACount(key: "oa_search");
            if(oa_found > 2){
                self.settings.setSettingsValue(value: true, key: "hintShown")
                return
            }
            if(oa_search < 5){
                return
            }
            type = "hint"
        }
        else if(!anniversaryShown){
            // installedHowLongAgo returns number of days
            // we want to show to folks, who have used the app at least for 45 days
            if(installedHowLongAgo() < 45){
                return
            }
            type = "anniversary"
        }
        
        
        blurBackground()
        infoChildViewController = storyboard!.instantiateViewController(withIdentifier: "InfoChildViewController") as! InfoChildViewController
        addChild(infoChildViewController)
        view.addSubview(infoChildViewController.view)
        infoChildViewController.didMove(toParent: self)
        setAddInfoChildViewControllerConstraints()
        
        if(type == "hint"){
            infoChildViewController.type = "hint"
            //set hintShown to true - for dev set it to false
            self.settings.setSettingsValue(value: true, key: "hintShown")
        }
        else if(type == "anniversary"){
            infoChildViewController.type = "anniversary"
            infoChildViewController.days = installedHowLongAgo()
            //set hintShown to true - for dev set it to false
            self.settings.setSettingsValue(value: true, key: "anniversaryShown")
        }
        
        infoChildViewController.setStuff()
        
        infoChildViewController.view.transform = CGAffineTransform(scaleX: 0.3, y: 2)
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            self.infoChildViewController.view.transform = .identity
        }) { (finished) in
            //print("I am finished")
        }
        
        
    }
    
    func removeInfoChildViewController(){
        let blurEffect = self.view.subviews.compactMap{ $0 as? UIVisualEffectView }
               
        
        UIView.animate(withDuration: 0.4, delay: 0.1, options: .allowUserInteraction, animations: {
            self.infoChildViewController.view.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
   
        }) { (finished) in
            self.infoChildViewController.view.alpha = 0
            self.infoChildViewController.willMove(toParent: nil)
            self.infoChildViewController.view.removeFromSuperview()
            self.infoChildViewController.removeFromParent()
            for effect in blurEffect{
                effect.removeFromSuperview()
            }
        }
    }
    
    func setAddInfoChildViewControllerConstraints(){
        infoChildViewController.view.translatesAutoresizingMaskIntoConstraints = false
        infoChildViewController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50).isActive = true
        infoChildViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        infoChildViewController.view.heightAnchor.constraint(equalToConstant: 280).isActive = true
        infoChildViewController.view.widthAnchor.constraint(equalToConstant: 280).isActive = true
        infoChildViewController.view.layer.cornerRadius = 10
    }
    
    func blurBackground(){
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
    }
    
    func installedHowLongAgo() -> Int{
        
        let calendar = Calendar.current
        
        var appInstallDate: Date {
          if let documentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
            if let installDate = try! FileManager.default.attributesOfItem(atPath: documentsFolder.path)[.creationDate] as? Date {
              return installDate
            }
          }
          return Date() // Should never execute
        }
        
        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: appInstallDate)
        let date2 = calendar.startOfDay(for: Date())

        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day ?? 0
    }
    
    func openExternalUrlWithProxy(url: String){
        if(url != ""){
            // need to get ProxyPrefix
            let newProxyPrefix = settings.getSettingsStringValue(key: "proxyPrefix")
            let newUrl = "\(newProxyPrefix)\(url)"
            let url = URL(string: newUrl.trimmingCharacters(in: .whitespacesAndNewlines))
            let vc = SFSafariViewController(url: url!)
            self.present(vc, animated: true, completion: nil)
        }
        else{
            //print("access Tapped failed somehow - empty?")
        }
    }
    
    func setSearchProviderLogo(){
        let isEPMC = self.settings.getSettingsValue(key: "epmc")
        if (isEPMC) {
            self.searchProviderLogo.image = UIImage(named: "epmc_logo")
            self.searchProviderMention.text = "Search API kindly provided by Europe PMC"
        }
        else{
            self.searchProviderLogo.image = UIImage(named: "core_ac_uk")
            self.searchProviderMention.text = "Search API kindly provided by core.ac.uk"
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.textField.resignFirstResponder()
    }
    
    @IBAction func showHelpTapped(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
        let controller = mainStoryboard.instantiateInitialViewController()!
        UIApplication.shared.keyWindow!.rootViewController = controller
    }
    
    @IBAction func checkTapped(_ sender: Any) {
        if(!self.isOnline){
            let alertTitle = NSLocalizedString("Network Unavailable", comment: "iCloud Sync Error - most likely caused by a network being unavailable")
            let alertMessage = NSLocalizedString("The app is unable to connect to the internet and thus won't be able to function correctly. Please ensure appropriate connectivity", comment: "iCloud Sync Error - most likely caused by wifi or mobile data being unavailable")
            let okButton = "OK"
            self.showErrorAlert(alertTitle : alertTitle, alertMessage : alertMessage, okButton : okButton)
        }
        else{
           doSearch()
        }
        
    }
    
}

