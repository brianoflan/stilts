
use strict ; use warnings ;
use File::Path qw(make_path);
use File::Copy;
use File::Spec::Functions;

my $DEBUG1 = '1' ;
my $DEBUG2 = 2 ;

print "Perl running do_OBXml.pl\n" if ( $DEBUG1 ) ;

print "Args: " . join(',', @ARGV) . "\n" if ( $DEBUG1 ) ;

use File::Basename ;
my $thisDir = dirname( $0 ) ;
print "thisDir = '$thisDir'\n" if ($DEBUG2 > 1 ) ;
my $destFolder = $ENV{'obxml_to'} ;
$destFolder ||= 'buildX' ;
my $sourceFolder = $ENV{'obxml_from'} ;
$sourceFolder ||= 'obxmlX' ;
$ENV{'OBXML_CONFIG'} = $sourceFolder ;
my $xmlToObxScript = "$thisDir/xml_to_OBXml.sh" ;
my $obxToXmlScript = "$thisDir/OBXml_to_xml.sh" ;
# my $cmdScript = 'bin/OBXml.sh' ;
my $cmdScript = "$thisDir/do_OBXml.sh" ;
if ( $^O eq 'MSWin32' ) {
  $cmdScript = "$thisDir\\do_OBXml.bat" ;
}

sub doDir {

  # TODO:  Make this smoother with the '.' case.
  my $dir = shift( @_ ) ;
  my $dirX = catfile( $sourceFolder, $dir ) ;
  
  my @content ;
  my $dh ;
  opendir( $dh, $dirX ) or die( "Failed to opendir $dirX ." ) ;
  @content = readdir( $dh ) ;
  closedir( $dh ) ;
  my $x ;
  foreach $x ( @content ) {
    next() if ( $x =~ /^[.]+$/ ) ;
    my $dX = "$dir/$x" ;
    my $d = "$dirX/$x" ;
    if ( -d $d ) {
      doDir( $dX ) ;
    } elsif ( $x =~ /\.xml$/ ) {
      if ( $x =~ /\.(x?ht|x)ml\.xml$/ ) {
        my $cmd = "$xmlToObxScript $d 2>&1" ;
        my $result = `/bin/bash $cmd` ;
      }
      print "\n\n" if ( $DEBUG1 ) ;
      print "$d $x\n" if ( $DEBUG1 ) ;
      my $cmd = "$cmdScript $d $sourceFolder $destFolder 2>&1" ;
      if ( $^O eq 'MSWin32' ) {
        $cmd = "CALL $cmd" ;
      } else {
        $cmd = "/bin/bash $cmd" ;
      }
      my $result = `$cmd` ;
      print "cmd q{$cmd}\n" if ( $DEBUG1 ) ;
      print "result q{$result}\n" if ( $DEBUG1 ) ;
      if ( $x =~ /\.(x?ht|x)ml\.xml$/ ) {
        {
        my $cmd = "$obxToXmlScript $d 2>&1" ;
        my $result = `/bin/bash $cmd` ;
        }
        {
        my $outputFile = $d ;
        $outputFile =~ s/\.xml$// ;
        $outputFile =~ s/^\Q${sourceFolder}\E/$destFolder/ ;
        my $cmd = "$obxToXmlScript $outputFile 2>&1" ;
        my $result = `/bin/bash $cmd` ;
        print "cmd q{$cmd}\n" if ( $DEBUG1 ) ;
        print "result q{$result}\n" if ( $DEBUG1 ) ;
        }
      }
      print "\n\n" if ( $DEBUG1 ) ;
    } else {
      make_path("$destFolder/$dir" ) ;
      copy($d,"$destFolder/$dir/$x") or die "Copy failed: $!";
    }
  }
  return() ;
}

sub main {
  doDir( '.' ) ;
} # end sub main

main() ;
exit(0) ;

#
