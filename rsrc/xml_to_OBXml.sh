#!/bin/bash

if [[ -z $1 ]] ; then
  echo "USAGE: one argument, the file to convert." ;
  exit 1 ;
fi ;

backupFile=$1.bak ;
if [[ -e $1.bak ]] ; then
  bakNum=2 ;
  backupFile=$1.bak$bakNum ;
  while [[ -e $backupFile ]] ; do
    bakNum=$((bakNum + 1)) ;
    backupFile=$1.bak$bakNum ;
  done ;
fi ;
mv $1 $backupFile ;
cat $backupFile \
  | perl -ne 's{[>]}{.:gt/:.}g ; print $_' \
  | perl -ne 's{[<]}{<lt/>}g ; print $_' \
  | perl -ne 's{\.:gt/:\.}{<gt/>}g ; print $_' \
  | perl -ne 's{<lt/>[!]\-\-(/?)obxml([^-]*)\-\-<gt/>}{<${1}obxml${2}>}gi ; print $_' \
  | perl -ne 's{<lt/>[!]\-\-(/?)branches([^-]*)\-\-<gt/>}{<${1}branches${2}>}g ; print $_' \
  | perl -ne 's{<lt/>[!]\-\-(/?)branch([^-]*)\-\-<gt/>}{<${1}branch${2}>}g ; print $_' \
  > $1 ;
  #
#

#
