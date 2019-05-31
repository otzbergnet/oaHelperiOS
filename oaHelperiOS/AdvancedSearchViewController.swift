//
//  AdvancedSearchViewController.swift
//  oaHelperiOS
//
//  Created by Claus Wolf on 29.05.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import UIKit

class AdvancedSearchViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var articleTitle: UITextField!
    @IBOutlet weak var authorLastName: UITextField!
    @IBOutlet weak var publicationYear: UITextField!
    @IBOutlet weak var language: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var searchButton: UIButton!
    
    let helper = HelperClass()
    
    var searchStatement : [String] = []
    var apiData = Data()
    var stopSearch = false
 
    // variables used for the HUD control
    let messageFrame = UIView()
    var activityIndicator = UIActivityIndicatorView()
    var strLabel = UILabel()
    let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    
    // allow some haptic feedback
    let selection = UISelectionFeedbackGenerator()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchButton.layer.cornerRadius = 10
        self.clearError()
        
        // dismiss keyboard
        self.articleTitle.delegate = self
        self.authorLastName.delegate = self
        self.publicationYear.delegate = self
        self.language.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    

    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        doResignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        doSearch()
        return true
    }
    
    func doResignFirstResponder(){
        self.articleTitle.resignFirstResponder()
        self.authorLastName.resignFirstResponder()
        self.publicationYear.resignFirstResponder()
        self.language.resignFirstResponder()
    }
    
    func clearError(){
        self.errorLabel.text = ""
        self.errorLabel.textColor = .black
    }
    
    func makeSearch() -> String{
        self.searchStatement = []
        makeYear()
        makeTextSearch(prefix: "title", searchString: self.articleTitle.text ?? "")
        makeTextSearch(prefix: "authors", searchString: self.authorLastName.text ?? "")
        makeTextSearch(prefix: "language.name", searchString: self.language.text ?? "")
        
        let actualSearch = self.searchStatement.joined(separator: " AND ")
        
        return actualSearch
    }
    
    func makeTextSearch(prefix: String, searchString: String){
        if(prefix != "language.name" && searchString != ""){
            self.searchStatement.append("\(prefix):\(searchString)")
        }
        else if(prefix == "language.name" && searchString != ""){
            self.searchStatement.append("\(prefix):\(searchString)")
        }
    }
    
    func makeYear(){
        let date = Date()
        let calendar = Calendar.current
        let thisYear = Int(calendar.component(.year, from: date))
        let yearPlusSome = thisYear + 3
        if let intYear = Int(self.publicationYear.text ?? ""){
            if(intYear > 1500 && intYear < yearPlusSome){
                self.searchStatement.append("year:\(intYear)")
            }
            else{
                print("year does not meet requirements")
                self.stopSearch = true
                self.errorLabel.text = "The year seems invalid, it needs to be between 1500 and \(yearPlusSome)"
                self.errorLabel.textColor = UIColor.red
            }
        }
        else{
            if(self.publicationYear.text?.count ?? 0 > 0){
                print("year does not meet requirements")
                self.stopSearch = true
                self.errorLabel.text = "Are you sure you entered a year"
                self.errorLabel.textColor = UIColor.red
            }
            
        }
    }
    
    func doSearch(){
        self.clearError()
        self.doResignFirstResponder()
        let message = NSLocalizedString("Searching core.ac.uk for you", comment: "shows as soon as search is submitted")
        self.activityIndicator(message)
        let search = self.makeSearch()
        if(search != "" && !self.stopSearch){
            print(search)
            // let's get the API key from the git-ignored plist (apikey)
            let apiKey = self.helper.getAPIKeyFromPlist()
            // if the apiKey is empty show an error, but we can't recover from it
            if(apiKey == ""){
                self.effectView.removeFromSuperview()
                print("couldn't get API key")
                return
            }
            // lets get the data via the search
            self.helper.checkCore(search: search, apiKey: apiKey) { ( res) in
                switch res {
                case .success(let data):
                    DispatchQueue.main.async {
                        self.apiData = data
                        self.effectView.removeFromSuperview()
                        self.performSegue(withIdentifier: "advancedSearchResults", sender: nil)
                    }
                case .failure(let error):
                    self.effectView.removeFromSuperview()
                    print(error)
                }
            }
        }
        else{
            self.effectView.removeFromSuperview()
            print("invalid search")
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
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "advancedSearchResults" {
            if let nextViewController = segue.destination as? TableViewController {
                nextViewController.apiData = self.apiData
            }
        }
    }
 
    // MARK: buttons
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        self.selection.selectionChanged()
        self.stopSearch = false
        self.doSearch()
    }
    
    @IBAction func clearFieldsTapped(_ sender: Any) {
        self.selection.selectionChanged()
        self.articleTitle.text = nil
        self.authorLastName.text = nil
        self.publicationYear.text = nil
        self.language.text = nil
    }
    
    
}

