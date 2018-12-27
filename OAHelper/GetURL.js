var GetURL = function() {};

GetURL.prototype = {

run: function(arguments) {
    arguments.completionFunction({ "currentUrl" : document.URL, "doi" : findDoi() });
},
    
finalize: function(arguments) {
    var message = arguments["returnUrl"];
    if (message) {
        if(message.substring(0,4) == "http"){
            //alert(message)
            window.location.href = message
        }
        else if(message != ""){
            alert(message)
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
    for(i = 0; i < option.length; i++){
        doi = getMeta(option[i]);
        if(doi != "0"){
            break;
        }
    }
    if(doi == "0"){
        var doi1 = getMetaScheme('dc.Identifier', 'doi');
    }
    
    if(doi != "0" && doi1 == "0"){
        var cleanedDOI = cleanDOI(doi);
        if(isDOI(cleanedDOI)){
            return cleanedDOI;
        }
        else{
            return "0";
        }
    }
    else if(doi1 != "0" && doi == "0"){
        var cleanedDOI = cleanDOI(doi1);
        if(isDOI(cleanedDOI)){
            return cleanedDOI;
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
