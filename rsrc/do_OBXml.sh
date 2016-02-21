
thisDir=`dirname $0` ;

echo "OBXML_CONFIG = '${OBXML_CONFIG}'" ;
echo "args $@" ;

python2 "$thisDir/OBXml.py" "$@" ;
error=$? ;
echo "error '$error'"
exit $error ;

#
