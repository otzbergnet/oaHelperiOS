var GetURL = function() {};

GetURL.prototype = {
    
run: function(arguments) {
    arguments.completionFunction({ "currentUrl" : document.URL, "docTitle" : document.title, "doi" : findDoi(), "abstract" : findAbstract() });
},
    
finalize: function(arguments) {
    var message = arguments;
    if (message["returnUrl"]) {
        if(message["returnUrl"].substring(0,4) == "http"){
            window.location.href = message["returnUrl"]
        }
        else if(message["returnUrl"] != ""){
            //            alert(message);
        }
    }
    else if(message["action"] && message["action"] == "bookmarked"){
        if(window.navigator.language.indexOf("de") == 0){
            insertConfirmation("Bookmark hinzugefügt!");
        }
        else{
            insertConfirmation("Bookmark added!");
        }
        
    }
}
    
};

var ExtensionPreprocessingJS = new GetURL;



function findDoi(){
    //console.log("Open Acces Helper: DOI0");
    // we are going to look in meta-tags for the DOI
    var option = ['citation_doi', 'doi', 'dc.doi', 'dc.identifier', 'dc.identifier.doi', 'bepress_citation_doi', 'rft_id', 'dcsext.wt_doi', 'DC.identifier'];
    var doi = "0";
    var doi1 = "0";
    var doi2 = "0";
    for(i = 0; i < option.length; i++){
        doi = getMeta(option[i]);
        if(doi != "0"){
            break;
        }
    }
    
    // here we are a bit more specifc about what we are looking for
    if(doi == "0"){
        var doi1 = getMetaScheme('dc.Identifier', 'doi');
    }
    
    //on this one I am rather desperate and start scraping specific elements
    if(doi == "0" && doi1 == "0"){
        doi2 = scrapePage();
    }
    
    if(doi != "0" && doi1 == "0" && doi2 == "0"){
        var cleanedDOI = cleanDOI(doi);
        if(isDOI(cleanedDOI)){
            return cleanedDOI;
        }
        else{
            return "0";
        }
    }
    else if(doi1 != "0" && doi == "0" && doi2 == "0"){
        var cleanedDOI = cleanDOI(doi1);
        if(isDOI(cleanedDOI)){
            return cleanedDOI;
        }
        else{
            return "0";
        }
    }
    else if(doi2 != "0" && doi == "0" && doi1 == "0"){
        if(isDOI(doi2)){
            return doi2;
        }
        else{
            return "0";
        }
    }
    else{
        return "0";
    }
    
}

function cleanDOI(doi){
    
    // clean for a few common known prefixes (well exactly one right now, but easy to expand
    var clean = ['info:doi/'];
    
    for(let i = 0; i < clean.length; i++){
        doi = doi.replace(clean[i], '');
    }
    
    return doi;
}

function findAbstract(){
    var locations = ['DC.description', 'DCTERMS.abstract', 'eprints.abstract', 'description'];
    var abstract = "0";
    
    for(i = 0; i < locations.length; i++){
        if(abstract == "0"){
            abstract = getMeta(locations[i]);
        }
    }
    var ogLocation = ['og:description'];
    for(j = 0; j < ogLocation.length; j++){
        if(abstract == "0"){
            abstract = getMetaProperty(ogLocation[j]);
        }
    }
    return abstract;
}

function getMeta(metaName) {
    // get meta tags and loop through them. Looking for the name attribute and see if it is the metaName
    // we were looking for
    const metas = document.getElementsByTagName('meta');
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName) {
            return metas[i].getAttribute('content');
        }
    }
    
    return "0";
}

function getMetaScheme(metaName, scheme){
    // pretty much the same as the other function, but it also double-checks the scheme
    const metas = document.getElementsByTagName('meta');
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('name') === metaName && metas[i].getAttribute('scheme') === scheme) {
            return metas[i].getAttribute('content');
        }
    }
    
    return "0";
}

function getMetaProperty(metaName){
    const metas = document.getElementsByTagName('meta');
    
    for (let i = 0; i < metas.length; i++) {
        if (metas[i].getAttribute('property') === metaName) {
            return metas[i].getAttribute('content');
        }
    }
    
    return "0";
}

function isDOI(doi){
    
    // these regular expressions were recommended by CrossRef in a blog post
    // https://www.crossref.org/blog/dois-and-matching-regular-expressions/
    var regex1 = /^10.\d{4,9}\/[-._;()\/:A-Z0-9]+$/i;
    var regex2 = /^10.1002\/[^\s]+$/i;
    var regex3 = /^10.\d{4}\/\d+-\d+X?(\d+)\d+<[\d\w]+:[\d\w]*>\d+.\d+.\w+;\d$/i;
    var regex4 = /^10.1021\/\w\w\d+$/i;
    var regex5 = /^10.1207\/[\w\d]+\&\d+_\d+$/i;
    
    if(regex1.test(doi)) {
        return true;
    }
    else if (regex2.test(doi)){
        return true;
    }
    else if (regex3.test(doi)){
        return true;
    }
    else if (regex4.test(doi)){
        return true;
    }
    else if (regex5.test(doi)){
        return true;
    }
    else {
        return false;
    }
}

function scrapePage(){
    //selectors[0] = PubMed
    //selectors[1] = IEEE
    var selectors = ['p[class=\"j\"]', 'a[class=\"ng-isolate-scope\"]', 'a[ref=\"aid_type=doi\"]', 'div.stats-document-abstract-doi>a', 'dd', '.abstract_Text'];
    
    var doi = ""
    for(i = 0; i < selectors.length; i++){
        doi = getFromSelector(selectors[i]);
        if(doi != ""){
            break;
        }
    }
    if(doi != ""){
        return doi;
    }
    else{
        var host = document.URL;
        if(host.indexOf("ieeexplore.ieee.org") > -1){
            // IEEE
            var regex = new RegExp('"doi":"([^"]+)"');
            var doi = runRegexOnDoc(regex);
            if(doi != false){
                return doi;
            }
            
        }
        else if(host.indexOf("nber.org") > -1){
            //National Bureau of Economic Research
            var regex = new RegExp('Document Object Identifier \\(DOI\\): (10.*?)<\\/p>');
            var doi = runRegexOnDoc(regex);
            return doi;
            
        }
        else if(host.indexOf("base-search.net") > -1){
            // BASE SEARCH - for detail view, really quite superflous, but I like base
            if (document.querySelectorAll("a.link-orange[href^=\"https://doi.org/\"]").length > 0){
                var doi = document.querySelectorAll("a.link-orange[href^=\"https://doi.org/\"]")[0].href.replace('https://doi.org/','').replace('http://doi.org/','');
                return doi;
            }
        }
        else if(host.indexOf("gettheresearch.org") > -1){
            doConsoleLog("Open Access Helper (Safari Extension) - support for gettheresearch.org is experimental");
            // GetTheResearch.org- for detail view, really quite superflous, but I like base
            if(window.location.search.indexOf("zoom=") > -1){
                var potentialDoi = getQueryVariable("zoom");
                return doi;
            }
        }
        else if(host.indexOf("psycnet.apa.org") > -1){
            doConsoleLog("Open Access Helper (Safari Extension) - support for psycnet.apa.org is experimental");
            
            if(document.querySelectorAll(".citation-text>a").length > 0){
                var doiElements = document.querySelectorAll(".citation-text>a");
                var potentialDoi = doiElements[0];
                potentialDoi = potentialDoi.replace('https://doi.org/', '');
                return doi;
            }
        }
        else if(host.indexOf("proquest.com") > -1){
            doConsoleLog("Open Access Helper (Safari Extension) - support for proquest.com is experimental");
            if(document.querySelectorAll(".abstract_Text").length > 0){
                var doiElements = document.querySelectorAll(".abstract_Text");
                var potentialDoi = doiElements[0];
                var regex = new RegExp('DOI:(10\..*)');
                var doi = runRegexOnText(potentialDoi.textContent, regex);
                return doi;
            }
        }
        else if(host.indexOf("ebscohost.com") > -1 && document.location.href.indexOf("/detail") > -1){
            doConsoleLog("Open Access Helper (Safari Extension) - support for ebscohost.com is experimental");
            const fullTextIndicators = ['pdf-ft', 'html-ft', 'html-ftwg'];
            let isFullText = false;
            fullTextIndicators.forEach(function(item){
                let element = document.getElementsByClassName(item);
                if(element.length > 0){
                    isFullText = true;
                }
            });
            
            
            if(document.getElementsByTagName("dd").length > 0){
                var doiElements = document.getElementsByTagName("dd");
                [...doiElements].forEach(function(element){
                    if(element.textContent.indexOf("10.") == 0 && isDOI(element.textContent)){
                        if(!isFullText){
                            return element.textContent;
                        }
                        
                    }
                });
            }
        }
        else if(host.indexOf("dl.acm.org") > -1 && document.location.href.indexOf("/doi/") > -1){
            doConsoleLog("Open Access Helper (Safari Extension) - support for dl.acm.org is experimental");
            var urlParts = document.location.href.split("/doi/");
            if(isDOI(urlParts[1])){
                return urlParts[1];
            }
        }
        else{
            return 0;
        }
    }
}

function getFromSelector(selector){
    // allow for more complex CSS selectors, these are likely more unreliable
    const elements = document.querySelectorAll(selector);
    
    for (let i = 0; i < elements.length; i++) {
        // make sure we test what we find to be a proper DOI
        var match = matchAgainstRegex(elements[i].innerHTML)
        if(isDOI(match)){
            return match;
        }
    }
    
    return '';
}

function matchAgainstRegex(data){
    var doiRegex = ["10.\\d{4,9}/[-._;()/:A-Z0-9]+", "10.1002/[^\\s]+", "10.\\d{4}/\\d+-\\d+X?(\\d+)\\d+<[\\d\\w]+:[\\d\\w]*>\\d+.\\d+.\\w+;\\d", "10.1021/\\w\\w\\d+", "10.1207/[\\w\\d]+&\\d+_\\d+"];
    for(i = 0; i < doiRegex.length; i++){
        var regex = new RegExp(doiRegex[i], "i");
        var match = data.match(regex);
        if(match != null && match.length > 0){
            for(i = 0; i < match.length; i++){
                if(isDOI(match[i].replace(/\.$/, ""))){
                    return match[i].replace(/\.$/, "");
                }
            }
        }
    }
    
    return '';
}

function runRegexOnDoc(regEx){
    var m = regEx.exec(document.documentElement.innerHTML);
    if (m && m.length > 1){
        return m[1];
    }
    return false
}

function runRegexOnText(text, regEx){
    doConsoleLog(text)
    var m = regEx.exec(text);
    if (m && m.length > 1){
        doConsoleLog(m)
        return m[1];
    }
    return false
}

function insertConfirmation(message){
    var el = document.querySelector('body');
    var newEl = document.createElement('div');
    newEl.appendChild(document.createTextNode(message));
    newEl.setAttribute("style", "background-color:#FF9300 !important;width: 100%;color:#FFFFFF;height:3em;text-align:center;text-align: center;display: flex;justify-content:center;align-content:center;flex-direction:column;z-index: 99999 !important;position:fixed;");
    newEl.setAttribute("id", "oahelper_bookmark_confirmation");
    el.appendChild(newEl);
    el.insertBefore(newEl, null);
    el.insertBefore(newEl, el.childNodes[0] || null);
    setTimeout(function(){ document.getElementById("oahelper_bookmark_confirmation").outerHTML = ""; }, 2000);
}
