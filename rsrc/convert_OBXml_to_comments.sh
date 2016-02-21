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
  | perl -ne 's/<obxml([^>]*)>/<!--obxml${1}-->/gi ; print $_' \
  | perl -ne 's{</obxml([^>]*)>}{<!--/obxml${1}-->}gi ; print $_' \
  | perl -ne 's/<branches([^>]*)>/<!--branches${1}-->/g ; print $_' \
  | perl -ne 's{</branches([^>]*)>}{<!--/branches${1}-->}g ; print $_' \
  | perl -ne 's{</branch([^>]*)>}{<!--/branch${1}-->}g ; print $_' \
  | perl -ne 's/<branch([^>]*)>/<!--branch${1}-->/g ; print $_' \
  > $1 ;
  #
#

#
