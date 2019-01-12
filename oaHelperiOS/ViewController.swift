//
//  ViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 08.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit
import SafariServices

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var enterSearchLabel: UILabel!
    
    
    var searchTerm = ""
    var apiData = Data()
    var urlScheme = false
    
    let messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //search button should have rounded corners
        searchButton.layer.cornerRadius = 10
        
        //we want to set the title
        self.title = NSLocalizedString("Search", comment: "Search shown in navbar on first view controller")
        
        //ensure we can dismiss keyboard, when we tap outside of search field
        self.textField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        //ensure we can get search terms from the AppExtension via the URL Scheme oahelper://
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    //handles the data from the URLscheme
    @objc func applicationDidBecomeActive() {
        if(!urlScheme){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if appDelegate.search != "" {
                //print(appDelegate.search)
                self.textField.text = appDelegate.search
                let message = NSLocalizedString("Searchig core.ac.uk for you", comment: "shows as soon as search is submitted")
                activityIndicator(message)
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
        doSearch()
    }
    
    func doSearch(){
        self.textField.resignFirstResponder()
        if let search = textField.text {
            let message = NSLocalizedString("Searchig core.ac.uk for you", comment: "shows as soon as search is submitted")
            activityIndicator(message)
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
    

    func checkDissem(search: String) {
        
        if let encodedString = search.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed){
            let jsonUrlString = "https://dissem.in/api/search/?q=\(encodedString)"
            let url = URL(string: jsonUrlString)
            
            let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
                if let error = error{
                    //we got an error, let's tell the user
                    DispatchQueue.main.async {
                        self.effectView.removeFromSuperview()
                        self.enterSearchLabel.text = NSLocalizedString("Sorry, we encountered a problem", comment: "problem with search")
                        self.enterSearchLabel.textColor = UIColor.red
                        print(error)
                    }
                }
                if let data = data {
                    DispatchQueue.main.async {
                        self.apiData = data
                        self.effectView.removeFromSuperview()
                        self.enterSearchLabel.text = NSLocalizedString("Enter your search:", comment: "above the search field")
                        self.enterSearchLabel.textColor = UIColor.black
                        self.performSegue(withIdentifier: "searchSegue", sender: nil)
                    }
                }
                else{
                    DispatchQueue.main.async {
                        self.effectView.removeFromSuperview()
                        self.enterSearchLabel.text = NSLocalizedString("Sorry, we encountered a problem", comment: "problem with search")
                        self.enterSearchLabel.textColor = UIColor.red
                    }
                    return
                }
                
            }
            task.resume()
        }
        
    }
    
    
    func checkCore(search: String) {
        //print("check core")
        // let's get the API key from the git-ignored plist (apikey)
        let apiKey = getAPIKeyFromPlist()
        // if the apiKey is empty show an error, but we can't recover from it
        if(apiKey == ""){
            self.effectView.removeFromSuperview()
            let text = NSLocalizedString("core.ac.uk API key missing - please quit app", comment: "missing API key, breaking error")
            activityIndicator(text)
            return
        }
        
        if let encodedString = search.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed){
            
            let jsonUrlString = "https://core.ac.uk/api-v2/articles/search/\(encodedString)?page=1&pageSize=50&metadata=true&fulltext=false&citations=false&similar=false&duplicate=false&urls=true&faithfulMetadata=false&apiKey=\(apiKey)"
            guard let url = URL(string: jsonUrlString) else {
                return
            }
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
                if let error = error{
                    //we got an error, let's tell the user
                    DispatchQueue.main.async {
                        self.effectView.removeFromSuperview()
                        self.enterSearchLabel.text = NSLocalizedString("Sorry, we encountered a problem", comment: "problem with search")
                        self.enterSearchLabel.textColor = UIColor.red
                        print(error)
                    }
                }
                if let data = data {
                    DispatchQueue.main.async {
                        self.apiData = data
                        self.effectView.removeFromSuperview()
                        self.enterSearchLabel.text = NSLocalizedString("Enter your search:", comment: "above the search field")
                        self.enterSearchLabel.textColor = UIColor.black
                        self.performSegue(withIdentifier: "searchSegue", sender: nil)
                        
                    }
                }
                else{
                    DispatchQueue.main.async {
                        self.effectView.removeFromSuperview()
                        self.enterSearchLabel.text = NSLocalizedString("Sorry, we encountered a data problem", comment: "unable to parse data object")
                        self.enterSearchLabel.textColor = UIColor.red
                    }
                    return
                }
                
            }
            task.resume()
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
    
    
    func getAPIKeyFromPlist() -> String{
        //we are going to read the api key for coar.ac.uk from apikey.plist
        //this file isn't the github bundle and as such you'll need to create it yourself, it is a simple Object
        // core : String = API Key from core.ac.uk
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "apikey", ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
        }
        if let core = nsDictionary?["core"]{
            return "\(core)"
        }
        return ""
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

