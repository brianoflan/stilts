//markupLinkRegexp=new RegExp( "\\[\\[([^\\]]+)\\]\\]", "g" ) ;
markupLinkRegexp= /(\[+)([^\[\]]+)\]+/g;
//refList=new Object() ;
//hardToFind=new Object() ;
////divList=new Array() ;
//divList=new Object() ;
//divOrder=new Array() ;
divList={} ;
divOrder=[] ;
jsWConfig={
  // // Config:
  DEBUG: true,
  reload: true,
  babyBadBrowsers: true,
  
  // // Variables:
  section: '',
  // 
  
  // // Methods:
  // addSiblingDivClass(tgtDiv,addedClass)
  // divExist(idArg)
  // refreshAnchorDo(event)
} ;

function addSiblingDivClass(tgtDiv,addedClass){
  var tagName = tgtDiv.tagName ? tgtDiv.tagName : '' ;
  if ( tagName == 'DIV') {
    if ( !tgtDiv.className.match( addedClass ) ) {
      tgtDiv.className += tgtDiv.className ? " " + addedClass : addedClass ;
    }
  } else {
    if ( tagName == 'BODY') {
      return true ;
    } else {
      if ( tagName !== '') {
        jsWConfig.DEBUG && console.log("addSiblingDivClass tagName " + tagName ) ;
      }
    }
  }
  tgtDiv.nextSibling && addSiblingDivClass(tgtDiv.nextSibling,addedClass)  ;
  return true ;
}

function displayOnlyAnchor(div) {
  if ( !("displayDivStyle" in jsWConfig) ) {
    jsWConfig["displayDivStyle"] = '' ;
  }
  if ( jsWConfig["section"] ) {
    if ( div ) {
      displayOnlyAnchor_div(div) ;
    } else {
      jsWConfig["displayDiv"] = 0 ;
      displayOnlyAnchor(document.getElementById('bodyDiv').firstChild) ;
      var tgtDiv=document.getElementById(jsWConfig["section"]) ;
      if ( tgtDiv ) {
        addSiblingDivClass(tgtDiv.parentNode.firstChild, 'OtherDivs') ;
        removeParentDivClass(tgtDiv, 'OtherDivs') ;
      }
      if (jsWConfig["displayDiv"] === 0) {
        if ( tgtDiv ) {
          jsWConfig["newDisplayDiv"] = 'none' ;
        } else {
          jsWConfig["newDisplayDiv"] = 'block' ;
        }
      } else {
          jsWConfig["newDisplayDiv"] = 'none' ;
      }
      displayOnlyAnchor_style() ;
    }
  } else {
    displayOnlyAnchor_removeStyle() ;
  }
}

function displayOnlyAnchor_div(div) {
  var nodeValue = div.nodeValue ? div.nodeValue : '' ;
  var tagName = div.tagName ? div.tagName : '' ;
  var id = (div.getAttribute && div.getAttribute('id') ) ? div.getAttribute('id') : '' ;
  if ( tagName == 'DIV') {
    if (id == jsWConfig["section"]) {
      jsWConfig["displayDiv"] += 1 ;
    } else {
    }
    if ( !div.className.match( 'OtherDivs' ) ) {
      div.className += div.className ? ' OtherDivs' : 'OtherDivs' ;
    }
  }
  div.nextSibling && displayOnlyAnchor( div.nextSibling ) ;
}

function displayOnlyAnchor_removeStyle() {
    var sheetToBeRemoved = document.getElementById('styleSheetId');
    if (sheetToBeRemoved) {
      var sheetParent = sheetToBeRemoved.parentNode;
      sheetParent.removeChild(sheetToBeRemoved);
    }
}

function displayOnlyAnchor_style() {
  if ( jsWConfig["displayDivStyle"] !== jsWConfig["newDisplayDiv"]) {
    displayOnlyAnchor_removeStyle() ;
    var styleText = ".OtherDivs {display: "+jsWConfig["newDisplayDiv"]+";}";
    var sheet = document.createElement('style') ;
    document.body.appendChild(sheet);
    sheet.setAttribute('id','styleSheetId') ;
    sheet.setAttribute('type','text/css') ;
    if ( jsWConfig["not_msie"] || !( jsWConfig["msie_ver_lte_8"] ) ) {
      if ( sheet.styleSheet) { // IE
        sheet.styleSheet.cssText = styleText ;
      } else {
        sheet.innerHTML = styleText ;
      }
    } else { // Extremely poor, old, bad browsers
      console.log("MSIE vesion is less than 9.  Are you a time traveler from the distant past?" ) ;
      sheet.styleSheet.addRule(".OtherDivs", "display: "+jsWConfig["newDisplayDiv"] ) ;
      //console.log("cssText " + sheet.cssText ) ;
      sheet.styleSheet.cssText = styleText ;
      //console.log("cssText " + sheet.cssText ) ;
    }
    jsWConfig["displayDivStyle"] = jsWConfig["newDisplayDiv"] ;
  }
}

function divExist(idArg) {
  var result='' ;
  var ids = [idArg, idArg.replace(/ /g, '_'), idArg.replace(/_/g, ' ')] ;
  for ( var i=0 ; i < ids.length; i++ ) {
    var id = ids[i] ;
    var divById=document.getElementById(id) ;
    if (divById) {
      result='#' + id ;
    }
    if ( result !== '' ) {
      break ;
    }
  }
  return result ;
}

function getAnchorHash () {  
  return unescape(window.location.hash.replace(new RegExp("^[#]"), ""));  
}

function linkIt(divId, linkTerm, link) {
  var div=document.getElementById(divId) ;
  var txt=div.innerHTML ;
  //var replacement = '<a href="' + link + '" class="refreshAnchor" ">' + linkTerm + '</a>' ;
  //var replacement = '<a href="' + link + '" class="refreshAnchor" onclick="jsWConfig.refreshAnchorDo(event)">' + linkTerm + '</a>' ;
  var replacement = '<a href="' + link + '" onclick="jsWConfig.refreshAnchorDo(event)">' + linkTerm + '</a>' ;
  var tmpRegExp = new RegExp( '\\[+' + linkTerm + '\\]+', 'g' );
  txt = txt.replace( tmpRegExp, replacement ) ;
  div.innerHTML = txt ;
}

function linkItIfItExists(divId, linkTerm) {
  var result=linkItIfItExists_Div(divId, linkTerm) ;
  // if ( result === '' ) {
    // result = linkItIfItExists_Ajax(divId, linkTerm) ;
  // }
  return result ;
}
function linkItIfItExists_Div(divId, linkTerm) {
  var result='' ;
  var ids = [linkTerm, linkTerm.replace(/ /g, '_'), linkTerm.replace(/_/g, ' ')] ;
  for (var i=0 ; i < ids.length; i++) {
    var id = ids[i] ;
    var divById=document.getElementById(id) ;
    if (divById){
      result='#' + id ;
    }
    if ( result !== '' ) {
      break ;
    }
  }
  if ( result !== '' ) {
    linkIt(divId, linkTerm, result) ;
  }
  return result ;
}

jsWConfig["refreshAnchorDo"] = function(e){
  //var linkHref = e.target.getAttribute('href') ;
  // IE 8
  e = e || window.event ;
  var target = e.target || e.srcElement ;
  var linkHref = target.getAttribute('href') ;
  //if ( getAnchorHash() != linkHref ) {
  if ( jsWConfig["section"] !== linkHref ) {
    //var baseLocation = new String(window.location).replace(new RegExp("[#].+$"), "" ) ;
    var baseLocation = window.location.replace(new RegExp("[#].+$"), "" ) ;
    window.location.assign(baseLocation + linkHref) ;
    jsWConfig["section"] ;
    if ( jsWConfig["reload"] ) {
      location.reload() ;
    }
  }
} ;

function removeParentDivClass(tgtDiv,removedClass){
  tgtDiv.className = tgtDiv.className.replace(
  	new RegExp("(?:^|\\s)" +
  	removedClass +
  	"(?!\\S)" , "g"), '') ;
  tgtDiv.parentNode && tgtDiv.parentNode.className && removeParentDivClass(tgtDiv.parentNode,removedClass)  ;
}

jsWConfig["tryMakeLinks"] = function() {
  var divs = document.body.childNodes ;
  for(var i=0; i<divs.length; i++) {
    if (divs[i].getAttribute){
      var id=divs[i].getAttribute("id") ;
      var type=divs[i].getAttribute("data-type") ;
      var t=divs[i].tagName ;
      if ( t.match(/div/i) ) {
        if (type !== 'pretty') {
          divOrder.push(id) ;
          divList[id] = 1 ;
          var txt=divs[i].innerHTML ;
          var result ;
          while ((result = markupLinkRegexp.exec(txt)) !== null){
            var ref=result[2] ;
            var sqBrackets=result[1] ;
            if (sqBrackets == '[[') { // Non-URI
              linkItIfItExists( id, ref );
            } else { // URI
              linkIt(id, ref, ref) ;
            }
          }
        //} else { // Already pretty
          //;
        } // if pretty else
      } // if div
    } // if getAttribute
  } // for each child
} ; // tryMakeLinks()

jsWConfig.watchForBrowserBackButton = function() {
  if (("onhashchange" in window) && jsWConfig["not_msie"]) {
    window.onhashchange = function () {
      jsWConfig["main"]() ;
    } ;
  } else {
    if (jsWConfig["babyBadBrowsers"]) {
      var prevHash = window.location.hash;
      window.setInterval(function () {
        if (window.location.hash !== prevHash) {
          prevHash = window.location.hash; // Why? QQQ
          jsWConfig["main"]() ;
        }
      }, 500);
    }
  }
} ;


// MAIN

jsWConfig["main"] = function() {
  if ( !jsWConfig["init"] ) {
    jsWConfig.tryMakeLinks() ;
    jsWConfig["init"] = true ;
  }
  if ( !jsWConfig["mainLock"] ) {
    jsWConfig["mainLock"] = true ;
    jsWConfig["section"] = getAnchorHash() ;
    console.log("anchor hash " + jsWConfig["section"]) ;
    if ( jsWConfig["section"] !== jsWConfig["mainLockLast"] ) {
      //jsWConfig.tryMakeLinks() ;
      displayOnlyAnchor() ;
      jsWConfig["watchForBrowserBackButton"]() ;
      jsWConfig["mainLockLast"] = jsWConfig["section"] ;
    }
    jsWConfig["mainLock"] = false ;
  } else {
    jsWConfig.DEBUG && console.log( "mainLock" ) ;
  }
} ;

window.onload = function() {
  jsWConfig.DEBUG && console.log('Start with onload (testJsAjax)!') ;
  jsWConfig["main"]() ;
  jsWConfig.DEBUG && console.log('Done with onload (testJsAjax)!') ;
} ;


