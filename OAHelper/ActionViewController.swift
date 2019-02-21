//
//  ActionViewController.swift
//  OAHelper
//
//  Created by Claus Wolf on 08.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var oaLogo: UIImageView!
    @IBOutlet weak var oaTypeLabel: UILabel!
    
    var returnURLString = ""
    var urlAction = false
    var selectAction = false
    
    let settings = SettingsBundleHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
       
        actionButton.isHidden = true
        actionButton.layer.cornerRadius = 10
        
        dismissButton.isHidden = true
        dismissButton.layer.cornerRadius = 10
        
        activityIndicator.startAnimating()
        
        headerLabel.text = ""
        sourceLabel.text = ""
        oaTypeLabel.text = ""
        
        //this ensurs there is no padding on the UITextView, which otherwise would be painful for alignment
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
        oaLogo.isHidden = true

        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return
        }
        
        for extensionItem in extensionItems {
            if let itemProviders = extensionItem.attachments {
                for itemProvider in itemProviders {
                    if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                        
                        itemProvider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil, completionHandler: { text, error in
                            if let myText = text as? String {
                                
                                let doi = self.doiFinder(str: myText)
                                if(doi.count > 0){
                                    DispatchQueue.main.async {
                                        self.selectAction = true
                                        if(doi.count == 1){
                                            self.headerLabel.text = NSLocalizedString("DOI detected", comment: "DOI detected")
                                            self.sourceLabel.text = ""
                                            self.textView.text = NSLocalizedString("We found a DOI and are checking the web for an Open Access version", comment: "checking text")
                                            self.checkUnpaywall(doi: "\(doi[0])")
                                        }
                                        else{
                                            self.activityIndicator.stopAnimating()
                                            self.activityIndicator.isHidden = true
                                            self.headerLabel.text = NSLocalizedString("Multiple DOIs detected", comment: "Multiple DOIs detected")
                                            self.sourceLabel.text = NSLocalizedString("Select one of the DOIs below and try again:", comment: "Select one of the DOIs below and try again:")
                                            self.textView.text = ""
                                            var count = 4
                                            if(doi.count < 4){
                                                count = doi.count
                                            }
                                            for d in (0 ..< count){
                                                self.textView.text += "\(d+1)) \(doi[d]) \n"
                                            }
                                            if(doi.count > 4){
                                                self.textView.text += "..."
                                            }
                                            
                                        }
                                        
                                    }
                                }
                                else{
                                    DispatchQueue.main.async {
                                        if let encodedString = myText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed){
                                            self.activityIndicator.stopAnimating()
                                            self.activityIndicator.isHidden = true
                                            self.headerLabel.text = NSLocalizedString("Search", comment: "Search")
                                            self.sourceLabel.text = ""
                                            let formattedText = String(format: NSLocalizedString("%@ \n\nIf you wish to search the above at core.ac.uk, click the button below", comment: "selected text to be seached"), myText)
                                            self.textView.text = formattedText
                                            //self.returnURLString = "https://core.ac.uk/search?q=%22\(encodedString)%22"
                                            self.returnURLString = "oahelper://\(encodedString)"
                                            let titleTranslation = NSLocalizedString("Search core.ac.uk", comment: "Search core.ac.uk")
                                            self.actionButton.setTitle(titleTranslation, for: .normal)
                                            self.actionButton.isHidden = false
                                            self.dismissButton.isHidden = false
                                            self.urlAction = false
                                            //self.searchAction()
                                        }
                                        
                                    }
                                }
                            }
                        })
                    }
                    else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                        itemProvider.loadItem(forTypeIdentifier: String(kUTTypePropertyList), options: nil, completionHandler: { (item, error) -> Void in
                            let dictionary = item as! NSDictionary
                            OperationQueue.main.addOperation {
                                let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! NSDictionary
                                
                                if let urlString = results["currentUrl"] as? String {
                                    DispatchQueue.main.async {
                                        self.headerLabel.text = "Digital Object Identifier"
                                        self.textView.text = urlString
                                        
                                    }
                                }
                                if let doiString = results["doi"] as? String {
                                    if doiString != "0" {
                                        DispatchQueue.main.async {
                                            self.textView.text += "\n\(doiString)"
                                            
                                        }
                                        self.checkUnpaywall(doi: doiString)
                                    }
                                    else{
                                        //print("DOI was 0 so we are here")
                                        DispatchQueue.main.async {
                                            self.activityIndicator.stopAnimating()
                                            self.activityIndicator.isHidden = true
                                            self.headerLabel.text = NSLocalizedString("No DOI found", comment: "No DOI found")
                                            self.sourceLabel.text = ""
                                            self.textView.text += NSLocalizedString("\n\nWe were unable to identify a DOI and thus unable to identify an Open Access version of the document", comment: "no doi, no search")
                                            self.returnURLString = ""
                                            self.dismissButton.isHidden = false
                                        }
                                        
                                    }
                                }
                                else{
                                    //print("problem with doi string")
                                    DispatchQueue.main.async {
                                        self.activityIndicator.stopAnimating()
                                        self.activityIndicator.isHidden = true
                                        self.headerLabel.text = NSLocalizedString("No Open Access Found", comment: "No Open Access Found")
                                        self.sourceLabel.text = ""
                                        self.textView.text += NSLocalizedString("\n\nWe were unable to identify an Open Access Version of this document!", comment: "longer text about no open access found")
                                        self.returnURLString = ""
                                        self.dismissButton.isHidden = false
                                    }
                                }
                                
                                
                                
                            }
                        })
                    }
                }
            }
        }
        
    }

    
    func checkUnpaywall(doi: String) {
        let jsonUrlString = "https://api.unpaywall.org/v2/\(doi)?email=oahelper@otzberg.net"
        let url = URL(string: jsonUrlString)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                print(error)
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.headerLabel.text = NSLocalizedString("We've encountered an error", comment: "We've encountered an error")
                self.sourceLabel.text = ""
                self.textView.text = ""
                self.returnURLString = ""
                self.dismissButton.isHidden = false
            }
            if let data = data {
                self.handleData(data: data)
            }
            else{
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.headerLabel.text = NSLocalizedString("No Open Access found", comment: "No Open Access found")
                self.sourceLabel.text = ""
                self.textView.text = NSLocalizedString("We were unable to identify an Open Access Version of this document!", comment: "longer no oa text")
                self.returnURLString = ""
                self.dismissButton.isHidden = false
            }
            
        }
        
        task.resume()
    }
    
    func handleData(data: Data){
        //sole purpose is to dispatch the url
        do{
            let oaData = try JSONDecoder().decode(Unpaywall.self, from: data)
            if let boa = oaData.best_oa_location {
                if (boa.url != "") {
                    // open acces
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                        if let title = oaData.title {
                            
                            self.headerLabel.text = title
                        }
                        else{
                            self.headerLabel.text = "Open Access"
                        }
                        self.sourceLabel.text = self.constructSource(data: oaData)
                        let oaFoundText = String(format: NSLocalizedString("Open Access version is available at:\n\n%@", comment: "shows when OA was found"), boa.url)
                        self.textView.text = oaFoundText
                        self.returnURLString = boa.url
                        self.settings.incrementOAFoundCount()
                        let oaFoundButtonText = NSLocalizedString("Go to document now", comment: "Go to document now")
                        self.actionButton.setTitle(oaFoundButtonText, for: .normal)
                        self.actionButton.isHidden = false
                        self.dismissButton.isHidden = false
                        self.urlAction = true
                        
                        let myOaType = self.oaColor(data: oaData)
                        let oaTypeImg = "\(myOaType)_oa"
                        self.oaLogo.image = UIImage(named: oaTypeImg)
                        self.oaLogo.isHidden = false
                        self.oaTypeLabel.text = "\(myOaType.capitalizingFirstLetter()) Open Access"
                    }
                }
                else{
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                        self.headerLabel.text = NSLocalizedString("We've encountered a problem", comment: "We've encountered a problem")
                        self.sourceLabel.text = ""
                        self.textView.text = NSLocalizedString("Open Access of this article should be available, but the URL was empty", comment: "Open Access of this article should be available, but the URL was empty")
                        self.returnURLString = ""
                        self.dismissButton.isHidden = false
                    }
                    
                }
            }
            else {
                // not oa
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    if let title = oaData.title{
                        self.headerLabel.text = title
                        if let encodedString = title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed){
                            self.sourceLabel.text = self.constructSource(data: oaData)
                            self.textView.text = NSLocalizedString("We were unable to find an Open Access version of this article. Please click the button below to search for the title of the article in core.ac.uk", comment: "unable to find OA")
                            self.returnURLString = "https://core.ac.uk/search?q=%22\(encodedString)%22"
                            let titleTranslation = NSLocalizedString("Search core.ac.uk", comment: "Search core.ac.uk")
                            self.actionButton.setTitle(titleTranslation, for: .normal)
                            self.actionButton.isHidden = false
                            self.dismissButton.isHidden = false
                            self.urlAction = true
                            self.selectAction = false
                        }
                    }
                    else{
                        self.headerLabel.text = NSLocalizedString("No Open Access available", comment: "No Open Access available")
                        self.sourceLabel.text = ""
                        self.textView.text = NSLocalizedString("We were unable to identify an Open Access Version of this document!", comment: "longer no oa available")
                        self.returnURLString = ""
                        self.dismissButton.isHidden = false
                    }
                }
            }
            
            
        }
        catch let jsonError{
            //the most likely error here is that the DOI is actually invalid or oadoi API returns another errror
            DispatchQueue.main.async {
                print(jsonError)
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.headerLabel.text = NSLocalizedString("No Open Access available", comment: "No Open Access available")
                self.sourceLabel.text = ""
                self.textView.text = NSLocalizedString("We were unable to identify an Open Access Version of this document!", comment: "longer no oa available")
                self.returnURLString = ""
                self.dismissButton.isHidden = false
            }
            return
        }
    }
    

    @IBAction func done() {

        let extensionItem = NSExtensionItem()
        let jsDict = [ NSExtensionJavaScriptFinalizeArgumentKey : [ "action" : "dismiss"]]
        extensionItem.attachments = [ NSItemProvider(item: jsDict as NSSecureCoding?, typeIdentifier: kUTTypePropertyList as String)]
        
        self.extensionContext!.completeRequest(returningItems: [extensionItem], completionHandler: nil)
        
    }

    @IBAction func actionButtonTapped(_ sender: Any) {
        if(self.urlAction && self.selectAction == false){
            let extensionItem = NSExtensionItem()
            let jsDict = [ NSExtensionJavaScriptFinalizeArgumentKey : [ "returnUrl" : self.returnURLString]]
            extensionItem.attachments = [ NSItemProvider(item: jsDict as NSSecureCoding?, typeIdentifier: kUTTypePropertyList as String)]
            
            self.extensionContext!.completeRequest(returningItems: [extensionItem], completionHandler: nil)
        }
        else{
            searchAction()
        }
        
    }
    
    @objc func openURL(_ url: URL) {
        return
    }
    
    func searchAction(){
        var responder: UIResponder? = self as UIResponder
        let selector = #selector(openURL(_:))
        while responder != nil {
            if responder!.responds(to: selector) && responder != self {
                responder!.perform(selector, with: URL(string: self.returnURLString)!)
                let extensionItem = NSExtensionItem()
                let jsDict = [ NSExtensionJavaScriptFinalizeArgumentKey : [ "returnUrl" : self.returnURLString]]
                extensionItem.attachments = [ NSItemProvider(item: jsDict as NSSecureCoding?, typeIdentifier: kUTTypePropertyList as String)]
                self.extensionContext!.completeRequest(returningItems: [extensionItem], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
    }
    
    func regexMatches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex, options: .caseInsensitive)
            let results = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func doiFinder(str: String) -> [String]{
        var result = [String]()
        let pattern = ["10.\\d{4,9}/[-._;()/:A-Z0-9]+", "10.1002/[^\\s]+", "10.\\d{4}/\\d+-\\d+X?(\\d+)\\d+<[\\d\\w]+:[\\d\\w]*>\\d+.\\d+.\\w+;\\d", "10.1021/\\w\\w\\d+", "10.1207/[\\w\\d]+&\\d+_\\d+"]
        
        for pat in pattern{
            for doi in regexMatches(for: pat, in: str) {
                result.append(doi)
            }
        }
        
        return result
    }
    
    func constructSource(data: Unpaywall) -> String{
        
        var sourceString = ""
        
        if let authors = data.z_authors{
            if(authors.count == 1){
                if let family = authors[0].family{
                        sourceString = family
                }
            }
            else{
                if let family = authors[0].family{
                    sourceString = "\(family) et al."
                }
            }
        }
        
        if let year = data.year {
            sourceString += " (\(year))"
        }
        
        if let jname = data.journal_name {
            sourceString += " \(jname)"
        }
        
        sourceString += "; \(data.doi)"
        
        
        return sourceString
        
    }
    
    func oaColor(data: Unpaywall) -> String{
        //logic "borrowed" from https://github.com/Impactstory/unpaywall/blob/master/extension/unpaywall.js
        
        //everything is bronze
        var color =  "bronze"
        
        //if repository is green
        if let hostType = data.best_oa_location?.host_type {
            if(hostType == "repository"){
                color = "green"
            }
        }
        
        //if doaj then gold
        if(data.journal_is_in_doaj) {
            color = "gold"
        }
        
        return color
    }
    
}


extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
