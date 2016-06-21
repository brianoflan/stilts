
use strict ; use warnings ;
use File::Path qw(make_path) ;
use File::Copy ;
use File::Spec::Functions ;

BEGIN {
    use File::Basename ;
    my $thisDir = dirname( $0 ) ;
    push( @INC, "$thisDir" ) ;
}
use Strtr ;

my $DEBUG1 = '' ;
my $DEBUG2 = '' ;

if ( $DEBUG1 ) {
  print "Perl running do_strtr.pl ($0).\n" ;
  print "Args: " . join(',', @ARGV) . ".\n" ;
}

my $toFolder = $ENV{'strtr_to'} ;
$toFolder ||= 'src_to_trans';
my $fromFolder = $ENV{'strtr_from'} ;
$fromFolder ||= 'transd';
my $strSpace = $ENV{'strtr_stringspace'} ;
$strSpace ||= 'strtrDefaultX' ;
my $configFile = catfile( $fromFolder, 'strtr_cfg', "$strSpace.trans.properties" ) ;
# my $inventTrans = '1';
my $inventTrans ;
if ( exists( $ENV{'strtr_inventtrans'} ) and defined( $ENV{'strtr_inventtrans'} ) ) {
  $inventTrans = $ENV{'strtr_inventtrans'} ;
} else {
  $inventTrans ||= '1' ;
}
my %config ;
# my $extractor ;
my $translator ;
my $translations ;
my $inventions ;

sub main {
  if ( @ARGV ) {
    $toFolder = pop( @ARGV ) ;
  }
  if ( @ARGV ) {
    $fromFolder = pop( @ARGV ) ;
  }
  if ( @ARGV ) {
    $configFile = pop( @ARGV ) ;
  }
  if ( @ARGV ) {
    $inventTrans = pop( @ARGV ) ;
  }
  if ( $DEBUG1 ) {
      print "toFolder '$toFolder'.\n" ;
      print "fromFolder '$fromFolder'.\n" ;
      print "configFile '$configFile'.\n" ;
      print "inventTrans '$inventTrans'.\n" ;
  }
  
  # use Config::Properties ;
  
  %config = loadConfig($configFile) ;
  # $extractor = StringExtractor->new({'inventTrans' => '1'}) ;
  my $configDefaultsDir = $ENV{'strtr_defaults'} ;
  $configDefaultsDir ||= './strtr.defaults' ;
  my $configDir = $ENV{'strtr_config'} ;
  $configDir ||= './config' ;
  # TODO: Add distinction between configDir (really the fromDir) and the defaultConfigDir.
  $translator = Strtr->new({
    'configDefaultsDir' => "$configDefaultsDir",
    'configDir' => "$configDir",
    'words' => \%config,
    'inventTrans' => $inventTrans,
  }) ;
  doDir('.', $toFolder) ;
  # TODO: Add a param to put the .meta.strtr folder under ${build}/../log instead of ${build}.
  writeConfig( "$toFolder/.meta.strtr/transd.properties", $translations ) ;
  writeConfig( "$toFolder/.meta.strtr/invented.properties", $inventions ) ;
  

} # End sub main.

#

sub writeConfig {
  my( $outfile, $hash1 ) = @_ ;
  my $reverse = {} ;
  my $hashX = $hash1 ;
  my $fh ;
  open( $fh, '>', $outfile ) or die( "Failed to open outfile '$outfile': $!.\n" ) ;
  {
    my $key ;
    foreach $key ( sort( keys( %$hashX ) ) ) {
      my $val = $hashX->{$key} ;
      print $fh "$key = $val\n" ;
      # Difference from the next clause:
      $reverse->{ $val } = $key ;
      # End of difference.
    }
  }
  close( $fh ) ;
  
  # TODO:  Add a param to turn off/on reverse file.
  # Reverse!
  $hashX = $reverse ;
  # $outfile = 'reverse.' . $outfile ;
  $outfile =~ s{[\/\\]([^\/\\]+)$}{/reverse.$1} ;
  open( $fh, '>', $outfile ) or die( "Failed to open outfile '$outfile': $!.\n" ) ;
  {
    my $key ;
    foreach $key ( sort( keys( %$hashX ) ) ) {
      my $val = $hashX->{$key} ;
      print $fh "$key = $val\n" ;
    }
  }
  close( $fh ) ;
  
  # TODO: Make sure all translations, including invented ones end up in transd.properties
  #  but also put nothing but invented translations into invented.transd.properties.
  return() ;
}
sub loadConfig {
  # Not quite a .properties file per http://en.wikipedia.org/wiki/.properties .
  # (Doesn't allow newlines in values or whitespace-delimited "key value" pairs -- must use '=' or ':'.)
  # (Also doesn't do the Unicode escapes.)
  my $file = shift( @_ ) ;
  my %config = () ;
  my @lines ;
  my $fh ;
  open( $fh, '<', $file ) or die( "Failed to open $file: $!.\n" ) ;
    my $line ;
    while ( $line = readline( $fh ) ) {
      chomp( $line ) ;
      next() if ( $line =~ /^\s*[#!]/ ) ;
      # if ( $line =~ /^\s*([^=:\s]([^=:]+[^=:\s])?)\s*[=:]\s*([^=:\s]([^=:]+[^=:\s])?)\s*$/ ) {
      if ( $line =~ /^\s*([^=:\s]([^=:]*[^=:\s])?)\s*[=:]\s*([^\s](.*[^\s])?)\s*$/ ) {
        my $key = $1 ;
        # my $key2 = $2 ;
        my $val1 = $3 ;
        $key =~ s{[\\](\s)}{$1}g ;
        $key =~ s{[\\]([=:!#\\])}{$1}g ;
        $val1 =~ s{[\\]([=:!#\\])}{$1}g ;
        if ( $DEBUG1 ) {
          print "line q{$line}\n" ;
          print "  key '$key'\n" ;
          # print "  key2 '$key2'\n" ;
          print "  val1 '$val1'\n" ;
        }
        $config{$key} = $val1 ;
      } elsif ($line =~ /^\s*$/ ) {
        ;
      } else {
        print STDERR "Trouble parsing line:\n  q{$line}.\n" ;
      }
    }
    # @lines = readline($fh) ;
  close( $fh ) ;
  return( %config ) ;
}
sub doDir {
  my $dir = shift( @_ ) ;
  my $root = shift( @_ ) ;
  my $dirX = catfile( $fromFolder, $dir ) ;
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
    my $out = "$toFolder/$dir/$x" ;
    # make_path("$toFolder/$dir" ) ;
    # print "Made path $toFolder/$dir (x = '$x') .\n" ;
    if ( -d $d ) {
      next() if ($d =~ m{[\/\\]?strtr_cfg$} ) ;
      doDir( $dX, $root ) ;
      $translations = $translator->translateFromFileTo( $d, $out, $root ) ;
    # } elsif ( ( $x =~ /\.debug$/ ) or ( $x =~ /\.ob(xml)?\.xml$/ ) ) {
      # # make_path("$toFolder/$dir" ) ;
      # copy($d,$out) or die "Copy failed: $!";
    } else {
      # make_path("$toFolder/$dir" ) ;
      print "\n\n" ;
      print "$d $x\n" ;
      my $cmd = "translator->translateFromFileTo( $d, $out, $root )" ;
      print "cmd q{$cmd}\n" ;
      $translations = $translator->translateFromFileTo( $d, $out, $root ) ;
      print "\n\n" ;
    }
    $inventions = $translator->getInventedWords() ;
  }
  return() ;
}

#

main() ;
exit( 0 ) ;

#
