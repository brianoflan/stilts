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
