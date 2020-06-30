//
//  ActionViewController.swift
//  OAHelper
//
//  Created by Claus Wolf on 08.12.18.
//  Copyright © 2018 Claus Wolf. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import LinkPresentation

class ActionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: User Interface Labels & TextViews
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var oaTypeLabel: UILabel!
    @IBOutlet weak var poweredByLabel: UILabel!
    @IBOutlet weak var coreRecommenderLabel: UILabel!
    
    
    @IBOutlet weak var textView: UITextView!
    
    //MARK: User Interface Activity Indicators
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableViewActivityIndicator: UIActivityIndicatorView!
    
    
    //MARK: User Interface Images
    
    @IBOutlet weak var oaLogo: UIImageView!
    @IBOutlet weak var paperIcon: UIImageView!
    @IBOutlet weak var poweredByImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var openCitationsLogo: UIImageView!
    
    //MARK: User Interface Buttons
    
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var addBookMarkButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var proxyButton: UIButton!
    @IBOutlet weak var openCitationsCountButton: UIButton!
    
    //MARK: Setup Basic Display Logic Variables
    
    var returnURLString = ""
    var urlAction = false
    var selectAction = false
    var fromSelectUrl = false
    var showBookMarkButton = true
    var showOpenAccessButton = true
    var showRecommendations = true
    var showProxyButton = false
    
    //MARK: Initialize Helper Classes
    
    let settings = SettingsBundleHelper()
    let helper = HelperClass()
    let bookMark = BookMarkObject()
    let bookMarkData = BookMarkData()
    
    //MARK: Setup Core Recommender Related Variables
    
    var recommendations : [CoreRecommendations] = []
    let recommendationObject = CoreRequestObject()
    let recommenderHelper = RecommenderHelper()
    var recommendationText = ""
    
    //MARK: OpenCitations
    
    var openCitationHelper = OpenCitationHelper()
    
    var year : Int = 0
    
    //MARK: Central Function to this Extension
    
    override func viewDidLoad() {
        
        //        let timer = ParkBenchTimer()
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.setupEmptyView()
        self.getAndSetBasicSettings()
        
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            return
        }
        
        for extensionItem in extensionItems {
            if let itemProviders = extensionItem.attachments {
                for itemProvider in itemProviders {
                    
                    //user actioned the share sheet, let's see what they are sharing
                    
                    if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                        itemProvider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil, completionHandler: { text, error in
                            if let myText = text as? String {
                                // we have some text, let's handle it
                                self.handleSelectedTextData(myText: myText)
                            }
                            else{
                                //print("cancel badText")
                                self.executeCancel(action: "badText")
                            }
                        })
                    }
                    else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypePropertyList as String) {
                        itemProvider.loadItem(forTypeIdentifier: String(kUTTypePropertyList), options: nil, completionHandler: { (item, error) -> Void in
                            
                            // let's get data from the page, based on the JS that was injected
                            
                            let dictionary = item as! NSDictionary
                            let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as! NSDictionary
                            
                            self.handlePageData(results: results)
                            
                        })
                    }
                    else if itemProvider.hasItemConformingToTypeIdentifier("public.url"){
                        // not sure what to do
                        itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (item, error) -> Void in
                            // let's get data from the page, based on the JS that was injected
                            self.fromSelectUrl = true
                            if let url = item as? NSURL {
                                self.bookMark.url = "\(url)"
                                self.handleReceivedUrl(urlString: "\(url)")
                            }
                            else{
                                //print("cancel badURL")
                                self.executeCancel(action: "badURL")
                            }
                            
                            
                        })
                    }
                    else{
                        print(itemProvider)
                        executeCancel(action: "unknown")
                    }
                }
                
            }
        }
        
    }
    
    func handleSelectedTextData(myText: String){
        //let's see, if we can identify DOIs in the selected text
        let doi = self.doiFinder(str: myText)
        
        if(doi.count > 0){
            //we found at least one DOI, let's handle
            handleFoundDoi(doi: doi)
        }
        else{
            // as we found no DOIs, let's offer the user to search in core.ac.uk (within the main app)
            self.displaySearchForText(myText: myText)
        }
    }
    
    func handleFoundDoi(doi: [String]){
        self.selectAction = true
        if(doi.count == 1){
            
            //only one DOI, let's handle as if we found to DOI in the page
            //great when a user selected an entire citation in a bibliography
            self.displayFoundSingleDOI()
            self.checkUnpaywall(doi: "\(doi[0])")
            
        }
        else if (doi.count == 2){
            if(doi[0] == doi[1]){
                self.displayFoundSingleDOI()
                self.checkUnpaywall(doi: "\(doi[0])")
            }
            else{
                self.displayFoundMultipleDOI(doi: doi)
            }
        }
        else{
            self.displayFoundMultipleDOI(doi: doi)
        }
    }
    
    func handleReceivedUrl(urlString: String){
        let doi = self.doiFinder(str: urlString.replacingOccurrences(of: "%2F", with: "/"))
        
        if(doi.count > 0){
            handleFoundDoi(doi: doi)
        }
        else{
            DispatchQueue.main.async {
                self.fromSelectUrl = true
                self.paperIcon.isHidden = true
                self.activityIndicator.isHidden = true
                
                //if there is neither proxy nor bookmark support, dismiss
                if(!self.showProxyButton && !self.showBookMarkButton){
                    self.executeCancel(action: "dimiss")
                    return
                }
                
                
                self.addSomeUrlMetadata(url: urlString)
                
                
                if(self.showProxyButton){
                    self.proxyButton.isHidden = false
                }
                // need to check if bookmarksis supposed to show
                if(self.showBookMarkButton){
                    self.addBookMarkButton.isHidden = false
                }
                self.dismissButton.isHidden = false
                self.paperIcon.image = UIImage(named: "www_icon")
                self.paperIcon.isHidden = false
                self.sourceLabel.text = urlString
                self.textView.text = NSLocalizedString("For this URL we were unable to identify a DOI. Please see these URL actions below:", comment: "shown when there is no DOI, but there are URL actions like proxy or bookmark")
            }
        }
    }
    
    func addSomeUrlMetadata(url: String){
        if #available(iOSApplicationExtension 13.0, *) {
            let metadataProvider = LPMetadataProvider()
            let url = URL(string: url)!

            metadataProvider.startFetchingMetadata(for: url) { [weak self] metadata, error in
                guard let metadata = metadata else { return }
                if let urlTitle = metadata.title{
                    DispatchQueue.main.async {
                        self?.headerLabel.text = urlTitle
                        self?.bookMark.title = urlTitle
                    }
                }
                
            }
        }
    }
    
    func handlePageData(results: NSDictionary) {
        //page metadata will have been passed in results - Dictionary
        
        // current URL (basically document.URL)
        if let urlString = results["currentUrl"] as? String {
            self.bookMark.url = urlString
            self.recommendationObject.referer = urlString
            DispatchQueue.main.async {
                self.headerLabel.text = "Digital Object Identifier"
                self.textView.text = urlString
            }
        }
        
        //document Title (basically document.title)
        if let titleString = results["docTitle"] as? String{
            self.bookMark.title = titleString
            self.recommendationObject.title = titleString
        }
        
        //document Abstract (basically DC.description, DCTERMS.abstract, etc.)
        if let abstractString = results["abstract"] as? String{
            self.recommendationObject.aabstract = abstractString
        }
        
        //DOIs and the action because of it
        // findDOI will return 0, if no DOI can be found
        if let doiString = results["doi"] as? String {
            if doiString != "0" {
                self.bookMark.doi = doiString
                self.recommendationObject.doi = doiString
                DispatchQueue.main.async {
                    self.textView.text += "\n\(doiString)"
                }
                //                print("up to checkunpaywall \(timer.stop()) seconds.")
                self.checkUnpaywall(doi: doiString)
                
            }
            else{
                // no DOI was found in the page
                self.displayFoundNoDOIinPage()
            }
        }
        else{
            // we didn't get a DOI Object back, which honestly should be quite impossible
            self.displayFoundNoDOIinPage()
        }
    }
    
    //MARK: Unpaywall Related Functions
    
    func checkUnpaywall(doi: String) {
        //        let timer = ParkBenchTimer()
        //        print("checkUnpaywall")
        self.getCoreRecommendations()
        self.getOpenCitations(doi: doi)
        self.bookMark.doi = doi
        let jsonUrlString = "https://api.unpaywall.org/v2/\(doi)?email=oahelper@otzberg.net"
        //        print(jsonUrlString)
        let url = URL(string: jsonUrlString)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            //            print("The unpaywall task took \(timer.stop()) seconds.")
            if let error = error{
                //we got an error, let's move on to core Discovery
                print("error on unpaywall data task")
                print(error.localizedDescription)
                self.checkCore(doi: doi, title: self.recommendationObject.title, sourceLabel: "")
            }
            if let data = data {
                self.handleUnpaywallData(data: data, doi: doi)
            }
            else{
                self.checkCore(doi: doi, title: self.recommendationObject.title, sourceLabel: "")
            }
            
        }
        
        task.resume()
    }
    
    func handleUnpaywallData(data: Data, doi: String){
        //sole purpose is to dispatch the url
        //        print("handleData for unpaywall")
        do{
            let oaData = try JSONDecoder().decode(Unpaywall.self, from: data)
            if let unpaywallYear = oaData.year{
                self.year = unpaywallYear
            }
            else{
                self.year = 0
            }
            if let boa = oaData.best_oa_location {
                if (boa.url != "") {
                    var title = "Open Access"
                    
                    self.showRecommendations = false  // there is open access, show no recommendations, it will recommend the OA version
                    self.hideAllRecommenderRelatedStuff()
                    
                    if let tmpTitle = oaData.title {
                        title = tmpTitle
                    }
                    let sourceLabel = self.constructSource(data: oaData)
                    let myOaType = self.oaColor(data: oaData)
                    let oaVersion = self.getOpenAccessVersion(data: oaData)
                    let oaTypeImg = "\(myOaType)_oa"
                    self.displayFoundOpenAccess(title: title, sourceLabel: sourceLabel, oaUrl: boa.url, oaTypeImg: oaTypeImg, myOaType: myOaType, oaVersion: oaVersion)
                }
                else{
                    // we have an empty best open access location - should be pretty much impossible
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                        self.paperIcon.image = UIImage(named: "paper_unknown")
                        self.headerLabel.text = NSLocalizedString("We've encountered a problem", comment: "We've encountered a problem")
                        self.sourceLabel.text = ""
                        self.textView.text = NSLocalizedString("Open Access of this article should be available, but the URL was empty", comment: "Open Access of this article should be available, but the URL was empty")
                        self.returnURLString = ""
                        self.dismissButton.isHidden = false
                        self.showProxyButtonFunction()
                    }
                    
                }
            }
            else {
                // not oa
                let mySourceLabel = self.constructSource(data: oaData)
                if let title = oaData.title{
                    self.checkCore(doi: doi, title: title, sourceLabel: mySourceLabel)
                }
                else{
                    self.checkCore(doi: doi, title: self.recommendationObject.title, sourceLabel: mySourceLabel)
                }
            }
            
            
        }
        catch let jsonError{
            //the most likely error here is that the DOI is actually invalid or oadoi API returns another errror
            print(jsonError)
            self.checkCore(doi: doi, title: self.recommendationObject.title, sourceLabel: "")
            return
        }
    }
    
    //MARK: Core Discovery Related Functions
    
    func checkCore(doi: String, title: String, sourceLabel: String){
        //        let timer = ParkBenchTimer()
        //        print("checkCore")
        let onlyUnpaywall = self.settings.getSettingsValue(key: "only_unpaywall")
        if(onlyUnpaywall){
            self.noOpenAccessFound(title: title, sourceLabel: "")
            return
        }
        let apiKey = self.helper.getAPIKeyFromPlist(key: "coreDiscovery")
        let jsonUrlString = "https://api.core.ac.uk/discovery/discover?doi=\(doi)&apiKey=\(apiKey)"
        guard let url = URL(string: jsonUrlString) else {
            self.noOpenAccessFound(title: title, sourceLabel: "")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            //            print("The core task took \(timer.stop()) seconds.")
            if let error = error{
                //we got an error, let's tell the user
                //                print("error on core data task")
                print(error.localizedDescription)
                self.noOpenAccessFound(title: title, sourceLabel: sourceLabel)
                
            }
            if let data = data {
                self.handleCoreDiscoveryData(data: data, title: title, sourceLabel: sourceLabel)
            }
            else{
                self.noOpenAccessFound(title: title, sourceLabel: sourceLabel)
                return
            }
            
        }
        
        task.resume()
        
    }
    
    func handleCoreDiscoveryData(data: Data, title: String, sourceLabel: String){
        //        print("core handle data title from function call \(title)")
        //        print("handleCore Data")
        //sole purpose is to dispatch the url
        do{
            let coreData = try JSONDecoder().decode(Coredata.self, from: data)
            if let boa = coreData.fullTextLink {
                if (boa != "") {
                    var myTitle = "Open Access"
                    //we have open access
                    self.showRecommendations = false   // there is open access, show no recommendations, it will recommend the OA version
                    self.hideAllRecommenderRelatedStuff()
                    
                    if title == "" {
                        myTitle = title
                    }
                    self.displayFoundOpenAccess(title: myTitle, sourceLabel: sourceLabel, oaUrl: boa, oaTypeImg: "coreDiscovery", myOaType: "Core Discovery Result", oaVersion: "coreDiscovery")
                    self.showProxyButtonFunction()
                    
                }
                else{
                    self.noOpenAccessFound(title: title, sourceLabel: sourceLabel)
                }
            }
            else {
                self.noOpenAccessFound(title: title, sourceLabel: sourceLabel)
            }
            
            
        }
        catch let jsonError{
            print(jsonError)
            self.noOpenAccessFound(title: title, sourceLabel: sourceLabel)
            return
        }
    }
    
    func noOpenAccessFound(title: String, sourceLabel: String){
        //        print("no open access found")
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            
            if title != "" {
                self.headerLabel.text = title
                self.paperIcon.image = UIImage(named: "paper_no")
                if let encodedString = title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed){
                    
                    if(self.showOpenAccessButton){
                        
                        let fiveYearsAgo = self.getFiveYearsAgo();
                        
                        let myOabUrl = self.bookMark.url
                        let mydoi = self.bookMark.doi
                        if (myOabUrl != "" && self.year > fiveYearsAgo){
                            
                            self.textView.text = NSLocalizedString("We were unable to find an Open Access version of this article. You can click the Open Access Button below, to try request it from the author.", comment: "unable to find OA")
                            if(self.recommendationText != ""){
                                self.textView.text += "\n\n\(self.recommendationText)"
                            }
                            self.returnURLString = "https://openaccessbutton.org/request?url=\(myOabUrl)&doi=\(mydoi)"
                            let titleTranslation = NSLocalizedString("Try Open Access Button", comment: "Open Access Button")
                            self.actionButton.setTitle(titleTranslation, for: .normal)
                            self.actionButton.backgroundColor = UIColor(red: 0.102, green: 0.596, blue: 0.988, alpha: 1.00)
                            self.urlAction = true
                            self.selectAction = false
                            
                        }
                        else{
                            self.displayNoOASearchNow(encodedString: encodedString)
                            self.urlAction = false
                            self.selectAction = false
                        }
                    }
                    else{
                        self.displayNoOASearchNow(encodedString: encodedString)
                        self.urlAction = false
                        self.selectAction = false
                    }
                    
                    self.actionButton.isHidden = false
                    self.dismissButton.isHidden = false
                    self.showBookMarkButtonFunction()
                    self.showProxyButtonFunction()
                    
                }
            }
            else{
                self.paperIcon.image = UIImage(named: "paper_no")
                self.headerLabel.text = NSLocalizedString("No Open Access available", comment: "No Open Access available")
                self.sourceLabel.text = ""
                self.textView.text = NSLocalizedString("We were unable to identify an Open Access Version of this document!", comment: "longer no oa available")
                self.returnURLString = ""
                self.dismissButton.isHidden = false
                self.showBookMarkButtonFunction()
                self.showProxyButtonFunction()
            }
        }
    }
    
    //MARK: Identify DOIs
    
    /* This is used when a string of text is selected to identify, if it contains DOIs*/
    
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
    
    //MARK: Function to help Display Data
    
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
    
    func getOpenAccessVersion(data: Unpaywall) -> String{
        if let version = data.best_oa_location?.version{
            switch version{
            case "submittedVersion":
                return NSLocalizedString(": Submitted Version", comment: "submittedVersion")
            case "acceptedVersion":
                return NSLocalizedString(": Accepted Version", comment: "acceptedVersion")
            case "publishedVersion":
                return NSLocalizedString(": Published Version", comment: "publishedVersion")
            default:
                return ""
            }
            
        }
        return ""
    }
    
    //MARK: viewDidLoadHelper
    
    func getAndSetBasicSettings(){
        self.settings.ensureSettingsAreRegistered()
        self.showBookMarkButton = self.settings.getSettingsValue(key: "bookmarks")
        self.showOpenAccessButton = self.settings.getSettingsValue(key: "open_access_button")
        self.showRecommendations = self.settings.getSettingsValue(key: "recommendation")
        if(self.settings.getSettingsValue(key: "useProxy") && self.settings.getSettingsStringValue(key: "proxyPrefix") != ""){
            self.showProxyButton = true
        }
        
    }
    
    //MARK: Display Data in User Interface Related
    
    func setupEmptyView(){
        actionButton.isHidden = true
        actionButton.layer.cornerRadius = 10
        
        addBookMarkButton.isHidden = true
        addBookMarkButton.layer.cornerRadius = 10
        
        dismissButton.isHidden = true
        dismissButton.layer.cornerRadius = 10
        
        proxyButton.isHidden = true
        proxyButton.layer.cornerRadius = 10
        
        if #available(iOS 13.4, *) {
            actionButton.isPointerInteractionEnabled = true
            addBookMarkButton.isPointerInteractionEnabled = true
            dismissButton.isPointerInteractionEnabled = true
            proxyButton.isPointerInteractionEnabled = true
            openCitationsCountButton.isPointerInteractionEnabled = true
        }
        
        activityIndicator.startAnimating()
        
        headerLabel.text = ""
        sourceLabel.text = ""
        oaTypeLabel.text = ""
        
        //this ensurs there is no padding on the UITextView, which otherwise would be painful for alignment
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
        oaLogo.isHidden = true
        
        let addBookmarkButtonText = NSLocalizedString("Add Bookmark", comment: "Add bookmark")
        self.addBookMarkButton.setTitle(addBookmarkButtonText, for: .normal)
        
        let proxyButtonText = NSLocalizedString("Proxy Original Page", comment: "proxy page button")
        self.proxyButton.setTitle(proxyButtonText, for: .normal)
        
        tableView.isHidden = true
        tableViewActivityIndicator.isHidden = true
        coreRecommenderLabel.isHidden = true
        self.poweredByImage.isHidden = true
        self.poweredByLabel.isHidden = true
        self.openCitationsLogo.isHidden = true
        self.openCitationsCountButton.isHidden = true
        
        if #available(iOS 13.0, *) {
            activityIndicator.style = .medium
            tableViewActivityIndicator.style = .medium
        }
        
        
    }
    
    func displayFoundSingleDOI(){
        DispatchQueue.main.async {
            self.paperIcon.image = UIImage(named: "paper_unknown")
            self.headerLabel.text = NSLocalizedString("DOI detected", comment: "DOI detected")
            self.sourceLabel.text = ""
            self.textView.text = NSLocalizedString("We found a DOI and are checking the web for an Open Access version", comment: "checking text")
        }
    }
    
    func displayFoundMultipleDOI(doi: [String]){
        DispatchQueue.main.async {
            self.stopActivity()
            
            self.paperIcon.image = UIImage(named: "paper_unknown")
            
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
    
    func displayFoundNoDOIinPage(){
        DispatchQueue.main.async {
            self.stopActivity()
            
            self.paperIcon.image = UIImage(named: "paper_search")
            
            self.headerLabel.text = NSLocalizedString("No DOI found", comment: "No DOI found")
            self.sourceLabel.text = ""
            self.textView.text += NSLocalizedString("\n\nWe were unable to identify a DOI and thus unable to identify an Open Access version of the document", comment: "no doi, no search")
            
            self.returnURLString = ""
            self.dismissButton.isHidden = false
            self.showBookMarkButtonFunction()
            self.showProxyButtonFunction()
        }
    }
    
    func displayNoOASearchNow(encodedString: String){
        self.textView.text = NSLocalizedString("We were unable to find an Open Access version of this article. Please click the button below to search for the title of the article in core.ac.uk", comment: "unable to find OA")
        if(self.recommendationText != ""){
            self.textView.text += "\n\n\(self.recommendationText)"
        }
        self.returnURLString = "oahelper://search?search=\(encodedString)"
        let titleTranslation = NSLocalizedString("Search core.ac.uk", comment: "Search core.ac.uk")
        self.actionButton.setTitle(titleTranslation, for: .normal)
        self.actionButton.backgroundColor = UIColor(red: 0.102, green: 0.596, blue: 0.988, alpha: 1.00)
        self.showProxyButtonFunction()
    }
    
    func displayFoundOpenAccess(title: String, sourceLabel: String, oaUrl: String, oaTypeImg: String, myOaType: String, oaVersion: String){
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            self.paperIcon.image = UIImage(named: "paper_ok")
            if title != "Open Access" {
                self.headerLabel.text = title
                self.bookMark.title = title
            }
            else{
                self.headerLabel.text = "Open Access"
            }
            self.sourceLabel.text = sourceLabel
            let oaFoundText = String(format: NSLocalizedString("Open Access version is available at:\n\n%@", comment: "shows when OA was found"), oaUrl)
            self.textView.text = oaFoundText
            self.returnURLString = oaUrl
            self.bookMark.pdf = oaUrl
            self.settings.incrementOACount(key: "oa_found")
            let oaFoundButtonText = NSLocalizedString("Go to Document Now", comment: "Go to document now")
            self.actionButton.setTitle(oaFoundButtonText, for: .normal)
            self.actionButton.isHidden = false
            self.showBookMarkButtonFunction()
            self.dismissButton.isHidden = false
            self.urlAction = true
            self.oaLogo.image = UIImage(named: oaTypeImg)
            self.oaLogo.isHidden = false
            if(oaTypeImg != "coreDiscovery"){
                if(UIDevice.current.userInterfaceIdiom == .pad){
                    self.oaTypeLabel.text = "\(myOaType.capitalizingFirstLetter()) OA\(oaVersion)"
                }
                else{
                    self.oaTypeLabel.text = "\(myOaType.capitalizingFirstLetter()) Open Access\(oaVersion)"
                }
            }
            else{
                self.oaTypeLabel.text = myOaType
            }
            self.showProxyButtonFunction()
            
        }
    }
    
    func displaySearchForText(myText: String){
        DispatchQueue.main.async {
            if let encodedString = myText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed){
                
                let formattedText = String(format: NSLocalizedString("%@ \n\nIf you wish to search the above at core.ac.uk, click the button below", comment: "selected text to be seached"), myText)
                let titleTranslation = NSLocalizedString("Search core.ac.uk", comment: "Search core.ac.uk")
                self.returnURLString = "oahelper://search?search=\(encodedString)"
                
                self.stopActivity()
                
                self.paperIcon.image = UIImage(named: "paper_search")
                
                self.headerLabel.text = NSLocalizedString("Search", comment: "Search")
                self.sourceLabel.text = ""
                self.textView.text = formattedText
                
                self.actionButton.setTitle(titleTranslation, for: .normal)
                self.actionButton.backgroundColor = UIColor(red: 0.102, green: 0.596, blue: 0.988, alpha: 1.00)
                self.actionButton.isHidden = false
                self.dismissButton.isHidden = false
                self.urlAction = false
            }
        }
    }
    
    func showBookMarkButtonFunction(){
        if(self.showBookMarkButton){
            self.addBookMarkButton.isHidden = false
        }
        else{
            self.hideBookmarkButtonCompletely()
        }
    }
    
    func hideBookmarkButtonCompletely(){
        self.proxyButton.isHidden = true
    }
    
    func showProxyButtonFunction(){
        if(self.showProxyButton){
            self.proxyButton.isHidden = false
        }
        else{
            self.proxyButton.isHidden = true
        }
    }
    
    
    func stopActivity(){
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = true
    }
    
    func getFiveYearsAgo() -> Int{
        let date = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: date)
        return currentYear - 6
    }
    
    //MARK: CORE Recommender Related Stuff
    
    func getCoreRecommendations(){
        //        print("do core recommendations")
        if(!self.showRecommendations){
            //            print("no recommendations desired")
            self.hideAllRecommenderRelatedStuff()
            return
        }
        
        DispatchQueue.main.async {
            self.coreRecommenderLabel.isHidden = false
            self.tableViewActivityIndicator.isHidden = false
            self.poweredByImage.isHidden = false
            self.poweredByLabel.isHidden = false
            self.tableViewActivityIndicator.startAnimating()
        }
        self.recommenderHelper.askForRecommendation(metaData: self.recommendationObject) { (res) in
            switch res{
            case .success(let coreRecommends):
                // let's check if there are recommendations and then display
                
                if(!self.showRecommendations){
                    //                    print("if we got here and this is false, then there was open access")
                    self.hideAllRecommenderRelatedStuff()
                    return
                }
                //                print("core recommends code \(coreRecommends.code)")
                
                if(coreRecommends.data.count > 0){
                    //                    print("there were results")
                    
                    DispatchQueue.main.async {
                        //                        print("dispatch core recommend queue to display stuff")
                        self.recommendationText = NSLocalizedString("Scroll down, we found some Open Access recommendations!", comment: "we found some OA recommendations")
                        self.textView.text += "\n\n\(self.recommendationText)"
                        self.settings.incrementOACount(key: "recommendation_count")
                        self.tableViewActivityIndicator.isHidden = true
                        self.tableViewActivityIndicator.stopAnimating()
                        self.tableView.isHidden = false
                        self.recommendations = coreRecommends.data
                        self.tableView.reloadData()
                    }
                }
                else{
                    // there was nothing
                    //                    print("there were 0 hits")
                    self.hideAllRecommenderRelatedStuff()
                }
                
            case .failure(let error):
                //I hate my life right now
                print("core recommend: there was an error: \(error)")
                self.hideAllRecommenderRelatedStuff()
            }
        }
    }
    
    func hideAllRecommenderRelatedStuff(){
        DispatchQueue.main.async {
            self.coreRecommenderLabel.isHidden = true
            self.tableViewActivityIndicator.isHidden = true
            self.tableViewActivityIndicator.stopAnimating()
            self.poweredByImage.isHidden = true
            self.poweredByLabel.isHidden = true
            self.tableView.isHidden = true
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recommendations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recommenderCell", for: indexPath)
        let recommendation = self.recommendations[indexPath.row]
        cell.textLabel?.text = recommendation.title
        var sourceLabel = "";
        if(recommendation.year != ""){
            sourceLabel = "(\(recommendation.year)) \(recommendation.author)"
        }
        else{
            sourceLabel = "\(recommendation.author)"
        }
        cell.detailTextLabel?.text = sourceLabel
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let thisRecommendation = self.recommendations[indexPath.row]
        let thisLink = thisRecommendation.link
        
        if(thisLink == ""){
            return
        }
        
        let extensionItem = NSExtensionItem()
        let jsDict = [ NSExtensionJavaScriptFinalizeArgumentKey : [ "returnUrl" : thisLink] ]
        extensionItem.attachments = [ NSItemProvider(item: jsDict as NSSecureCoding?, typeIdentifier: kUTTypePropertyList as String)]
        self.settings.incrementOACount(key: "recommendation_view")
        self.extensionContext!.completeRequest(returningItems: [extensionItem], completionHandler: nil)
        
    }
    
    //MARK: Open Citations Action Handle
    
    func getOpenCitations(doi: String){
        
        if(!settings.getSettingsValue(key: "openCitations")){
            return
        }
        
        self.openCitationHelper.findCitations(doi: doi){ (res) in
            
            switch res{
                
            case .success(let openCitation):
                if let count = Int(openCitation.count) {
                    if(count > 0){
                        DispatchQueue.main.async {
                            self.openCitationsLogo.isHidden = false
                            let citationText = "Times Cited: \(count)"
                            self.openCitationsCountButton.setTitle(citationText, for: .normal)
                            self.openCitationsCountButton.isHidden = false
                        }
                    }
                }
                
            case .failure(let error):
                //I hate my life right now
                print("openCitation: there was an error: \(error)")
            }
            
        }
    }
    
    //MARK: Actions used in Action Buttons Section
    
    func executeCancel(action: String){
        let extensionItem = NSExtensionItem()
        let jsDict = [ NSExtensionJavaScriptFinalizeArgumentKey : [ "action" : action]]
        extensionItem.attachments = [ NSItemProvider(item: jsDict as NSSecureCoding?, typeIdentifier: kUTTypePropertyList as String)]
        
        self.extensionContext!.completeRequest(returningItems: [extensionItem], completionHandler: nil)
    }
       
    func openUrlAction(url: String){
        print("I got to proxy Action")
        if let url = URL(string: url){
            let openUrlResult = self.openURL(url)
            if(openUrlResult){
                executeCancel(action: "dismiss")
            }
        }
    }
    
    //    @objc func openURL(_ url: URL) {
    //        return
    //    }
    
    //  Function must be named exactly like this so a selector can be found by the compiler!
    //  Anyway - it's another selector in another instance that would be "performed" instead.
    @objc func openURL(_ url: URL) -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application.perform(#selector(openURL(_:)), with: url) != nil
            }
            responder = responder?.next
        }
        return false
    }
    
    //MARK: Action Buttons
    
    @IBAction func done() {
        executeCancel(action: "dismiss")
    }
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        if(self.urlAction && self.selectAction == false && !fromSelectUrl){
            let extensionItem = NSExtensionItem()
            let jsDict = [ NSExtensionJavaScriptFinalizeArgumentKey : [ "returnUrl" : self.returnURLString]]
            extensionItem.attachments = [ NSItemProvider(item: jsDict as NSSecureCoding?, typeIdentifier: kUTTypePropertyList as String)]
            self.extensionContext!.completeRequest(returningItems: [extensionItem], completionHandler: nil)
        }
        else{
            openUrlAction(url: self.returnURLString)
        }
        
    }
    
    @IBAction func addBookMarkTapped(_ sender: Any) {
        self.bookMarkData.saveBookMark(bookmark: self.bookMark){ (success: Bool) in
            print("saved")
        }
        executeCancel(action: "bookmarked")
    }
    
    @IBAction func proxyButtonTapped(_ sender: Any) {
        let url = self.bookMark.url
        let proxyPrefix = self.settings.getSettingsStringValue(key: "proxyPrefix")
        if(url == ""){
            return
        }
        if(proxyPrefix == ""){
            return
        }
        let newUrl = proxyPrefix+url
        print(newUrl)
        settings.incrementOACount(key : "proxy_count")
        
        if(fromSelectUrl){
            self.openUrlAction(url: newUrl)
        }
        else{
            let extensionItem = NSExtensionItem()
            let jsDict = [ NSExtensionJavaScriptFinalizeArgumentKey : [ "returnUrl" : newUrl]]
            extensionItem.attachments = [ NSItemProvider(item: jsDict as NSSecureCoding?, typeIdentifier: kUTTypePropertyList as String)]
            self.extensionContext!.completeRequest(returningItems: [extensionItem], completionHandler: nil)
        }
        
    }
    
    
    @IBAction func openCitationsCountTapped(_ sender: Any) {
        let urlString = "https://www.oahelper.org/opencitations/?doi=\(self.bookMark.doi)"
        let extensionItem = NSExtensionItem()
        let jsDict = [ NSExtensionJavaScriptFinalizeArgumentKey : [ "returnUrl" : urlString]]
        extensionItem.attachments = [ NSItemProvider(item: jsDict as NSSecureCoding?, typeIdentifier: kUTTypePropertyList as String)]
        self.extensionContext!.completeRequest(returningItems: [extensionItem], completionHandler: nil)
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
