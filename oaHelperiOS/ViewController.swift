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
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var enterSearchLabel: UILabel!
    //@IBOutlet weak var bookmarkButton: UIButton!
    //@IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var offlineLabel: UILabel!
    
    var searchTerm = ""
    var apiData = Data()
    var urlScheme = false
    
    // variables used for the HUD control
    let messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    let settings = SettingsBundleHelper()
    let stats = StatisticSubmit()
    var bookMarkData = BookMarkData()
    let helper = HelperClass()
    let newsItemData = NewsItemData()
    //var bookMarkList : [BookMark] = []

    let selection = UISelectionFeedbackGenerator()
    
    var showBookMarkButton = true
    var activeBookMarkCheck = false
    var isOnline = true
    
    
    // MARK: View Did Load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //search button should have rounded corners
        searchButton.layer.cornerRadius = 10
        //bookmarkButton.layer.cornerRadius = 10
        //bookmarkButton.isHidden = true
        //syncButton.isHidden = true
        
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
        
        //only do when the view truly did load, we don't want to do this too often
        //the function also checks to ensure it only happens once a month
        self.stats.submitStats()
        
        self.checkNews()
        self.updateUnreadCount()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.networkAvailable()
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
            if appDelegate.search != "" {
                //print(appDelegate.search)
                self.textField.text = appDelegate.search
                let message = NSLocalizedString("Searching core.ac.uk for you", comment: "shows as soon as search is submitted")
                self.activityIndicator(message)
                let query = createSearch(search: appDelegate.search)
                
                checkCore(search: query)
                // setting this to true, there was a case, where the search would execute again, if you left the app and opened it again
                // the search fromt he previuos url scheme would be re-executed
                urlScheme = true
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
    
    func doSearch(){
        selection.selectionChanged()
        self.textField.resignFirstResponder()
        if let search = textField.text {
            let message = NSLocalizedString("Searching core.ac.uk for you", comment: "shows as soon as search is submitted")
            self.activityIndicator(message)
            let query = createSearch(search: search)
            checkCore(search: query)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchSegue" {
            if let nextViewController = segue.destination as? TableViewController {
                nextViewController.apiData = self.apiData
            }
        }
    }
    
    func checkCore(search: String){
        // let's get the API key from the git-ignored plist (apikey)
        let apiKey = self.helper.getAPIKeyFromPlist()
        // if the apiKey is empty show an error, but we can't recover from it
        if(apiKey == ""){
            self.effectView.removeFromSuperview()
            let text = NSLocalizedString("core.ac.uk API key missing - please quit app", comment: "missing API key, breaking error")
            self.activityIndicator(text)
            return
        }
        // lets get the data via the search
        self.helper.checkCore(search: search, apiKey: apiKey) { ( res) in
            switch res {
            case .success(let data):
                DispatchQueue.main.async {
                    self.settings.incrementOACount(key : "oa_search")
                    self.apiData = data
                    self.effectView.removeFromSuperview()
                    self.enterSearchLabel.text = NSLocalizedString("Enter your search:", comment: "above the search field")
                    self.enterSearchLabel.textColor = UIColor.black
                    self.performSegue(withIdentifier: "searchSegue", sender: nil)
                }
            case .failure(let error):
                self.effectView.removeFromSuperview()
                self.enterSearchLabel.text = NSLocalizedString("Sorry, we encountered a problem", comment: "problem with search")
                self.enterSearchLabel.textColor = UIColor.red
                print(error)
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
    
    func createSearch(search: String) -> String{
        //TO DO: need to support AND, OR, NOT
        let andSearch = search.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: " AND ")
        let query = "title:((\(andSearch)) ) OR description:((\(andSearch)) )"
        
        return query
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
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.textField.resignFirstResponder()
    }
    
    @IBAction func showHelpTapped(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Onboarding", bundle: nil)
        let controller = mainStoryboard.instantiateInitialViewController()!
        self.present(controller, animated: true, completion: nil)
    }
    
}

