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
    
    var searchStatement : [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        searchButton.layer.cornerRadius = 10
        errorLabel.text = ""
        
        // dismiss keyboard
        self.articleTitle.delegate = self
        self.authorLastName.delegate = self
        self.publicationYear.delegate = self
        self.language.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    

    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        
        self.articleTitle.resignFirstResponder()
        self.authorLastName.resignFirstResponder()
        self.publicationYear.resignFirstResponder()
        self.language.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        doSearch()
        return true
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
        let yearPlusTwo = thisYear + 2
        if let intYear = Int(self.publicationYear.text ?? ""){
            if(intYear > 1500 && intYear < yearPlusTwo){
                self.searchStatement.append("year:\(intYear)")
            }
            else{
                print("year does not meet requirements")
                self.errorLabel.text = "The year seems invalid, it needs to be between 1500 and \(yearPlusTwo)"
            }
        }
        else{
            if(self.publicationYear.text?.count ?? 0 > 0){
                print("year does not meet requirements")
                self.errorLabel.text = "Are you sure you entered a year"
            }
            
        }
    }
    
    func doSearch(){
        let search = self.makeSearch()
        if(search != ""){
            print(search)
            print("valid search")
        }
        else{
            
            print("invalid search")
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
    @IBAction func searchButtonTapped(_ sender: Any) {
        doSearch()
    }
    
}
