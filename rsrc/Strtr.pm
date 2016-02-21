
package Strtr ;

use strict ; use warnings ;

use File::Path qw(make_path);
use File::Copy ;
use File::Basename ;
use File::Spec::Functions ;
use Data::Dumper ;
# use lib './lib' ;
# use CompConfig ;
# use InGeneral ;


my $DEBUG = '' ;
my $DEBUG1 = '' ;
my $DEBUG2 = '' ;
my $DEBUG3 = 1 ;
my $DEBUG3_flag = '' ;

sub new
{
  my( $class, $config ) = @_ ;
  my @newWordCharsetFirst = ( 'A'..'Z', 'a'..'z' ) ;
  my @newWordCharset = ( '1'..'9', 'A'..'Z', 'a'..'z',  ) ;
  my $self = {
    #'perlSplitter' => qr{[\[\]\s~`'"{}()<>\$\@\%\*\&#=\\/,.!?;:^+|\-]+},
    'perlSplitter' => qr{[^_a-zA-Z0-9]+},
    #'perlIgnore' => qr{^(\d+|__END__|\s*|use|sub|my|print)$},
    # 'perlIgnore' => qr{^(\d+|\s*)$},
    'perlIgnore' => qr{^(\d+|\s*|[_a-zA-Z])$},
    'newWordCharsetFirst' => \@newWordCharsetFirst,
    'newWordCharset' => \@newWordCharset,
    'configDefaultsDir' => './strtr.defaults',
    'configDir' => './config',
    'inventTrans' => '',
    'words' => {},
    'invented' => {},
    'notInvented' => {},
    'specialIgnores' => {},
    '' => '',
    } ;
  my $x ;
  foreach $x ( 'configDefaultsDir', 'configDir', 'inventTrans', 'words' ) {
    if ( exists($config->{ $x }) and defined( $config->{ $x } ) ) {
      $self->{ $x } = $config->{ $x } ;
    }
  }
  # $self->{'usualIgnores'} = loadSpecialIgnores( catfile( $self->{'configDir'}, '_ignore.totr.cfg' ) );
  my $f ;
  
  $f = catfile( $self->{'configDefaultsDir'}, 'ignore.no.trans.txt' ) ;
  $self->{'usualIgnoresDefault'} = {} ;
  if ( -f $f ) {
    # $self->{'usualIgnoresDefault'} = loadSpecialIgnores( catfile( $self->{'configDefaultsDir'}, 'ignore.no.trans.txt' ) );
    $self->{'usualIgnoresDefault'} = loadSpecialIgnores( $f );
  }
  
  $f = catfile( $self->{'configDir'}, 'ignore.no.trans.txt' ) ;
  $self->{'usualIgnores'} = {} ;
  if ( -f $f ) {
    # $self->{'usualIgnores'} = loadSpecialIgnores( catfile( $self->{'configDir'}, 'ignore.no.trans.txt' ) );
    $self->{'usualIgnores'} = loadSpecialIgnores( $f );
  }
  
  bless( $self, $class ) ;
  return( $self ) ;
} # end sub new

###

sub _debug
{
  print $_[0] if ( $DEBUG ) ;
} # end sub _debug

sub extract
{
  my $extractedHash ;
  # my( $self, $content ) = @_ ;
  my( $self, @content ) = @_ ;
  my $perlSplitter = $self->{ 'perlSplitter' } ;
  my $perlIgnore = $self->{ 'perlIgnore' } ;
  # my %words = () ;
  my $wordsRef = $self->{ 'words' } ;
  my @newWordCharsetFirst = @{ $self->{ 'newWordCharsetFirst' } } ;
  my @newWordCharset = @{ $self->{ 'newWordCharset' } } ;
  my $counter = 1 ;
  # my @lines = split( /(\015\012|\012|\015)/, $content ) ;
  my $line ;
  # foreach $line ( @lines )
  foreach $line ( @content )
  {
    if ( $line =~ /\A(\015\012|\012|\015)\z/ ) {
      my $chars = $1 ;
      $self->{'newfile'} .= $chars ;
      print "Adding newline characters q{$chars}.\n" if ( $DEBUG1 ) ;
    } else {
      my @linewords = split( /$perlSplitter/, $line ) ;
      map { catchWord( $_ ) } 
        grep { !/$perlIgnore/ } @linewords ;
      my $translatedLine = '' ;
      my $wordX ;
      foreach $wordX ( split( /($perlSplitter)/m, $line ) ) {
        if ( ( $wordX =~ /$perlSplitter/ ) or ( $wordX =~ /$perlIgnore/ ) ) {
          $translatedLine .= $wordX ;
        } elsif ( exists( $self->{ 'usualIgnoresDefault' }{ $wordX } )
          and defined( $self->{ 'usualIgnoresDefault' }{ $wordX } )
        ) {
          print "Word '$wordX' is a usualIgnoresDefault word.\n" if ( $DEBUG1 ) ;
          $translatedLine .= $wordX ;
        } elsif ( exists( $self->{ 'usualIgnores' }{ $wordX } )
          and defined( $self->{ 'usualIgnores' }{ $wordX } )
        ) {
          print "Word '$wordX' is a usualIgnores word.\n" if ( $DEBUG1 ) ;
          $translatedLine .= $wordX ;
        } elsif ( exists( $self->{ 'specialIgnores' }{ $wordX } )
          and defined( $self->{ 'specialIgnores' }{ $wordX } )
        ) {
          print "Word '$wordX' is a specialIgnores word.\n" if ( $DEBUG1 ) ;
          $translatedLine .= $wordX ;
        } elsif ( exists($wordsRef->{ $wordX }) and defined($wordsRef->{ $wordX }) ) {
          $translatedLine .= $wordsRef->{ $wordX } ;
        } else {
          print "Why hasn't this word, '$wordX', been caught?\n" ;
          $translatedLine .= $wordX ;
        }
      }
      # if ( $translatedLine !~ /[\r\n]+$/m ) {
        # print "Really?  No newlines: q{$translatedLine}?\n" if ( $DEBUG1 ) ;
        # # $translatedLine .= "\n" ;
      # } else {
        # print "Really?  Plenty newlines: q{$translatedLine}?\n" if ( $DEBUG1 ) ;
      # }
      $self->{'newfile'} .= "$translatedLine" ;
    }
    
  }

  sub catchWord
  {
    # my( $self, $word ) = @_ ;
    # my %words = %{ $self->{ 'words' } } ;
    my( $word ) = @_ ;
    #print "catchWord: word='$word'\n" ; 
    my $DEBUG3_on = '' ;
    if ( $DEBUG3 and ( $word eq 'xyzzy' ) ) {
      print "File: " . $self->{ '_tmp_infile' } . "\n" ;
      $DEBUG = 1 ;
      $DEBUG3_on = 1 ;
    }
    if ( exists( $self->{ 'usualIgnoresDefault' }{ $word } )
      and defined( $self->{ 'usualIgnoresDefault' }{ $word } )
      )
    {
      print "Word '$word' ignored per default usual ignores file.\n" if ( $DEBUG3_on ) ;
      ; # Ignored per default usual ignores file.
    } elsif ( exists( $self->{ 'usualIgnores' }{ $word } )
      and defined( $self->{ 'usualIgnores' }{ $word } )
      )
    {
      print "Word '$word' ignored per usual ignores file.\n" if ( $DEBUG3_on ) ;
      ; # Ignored per usual ignores file.
    }
    elsif ( exists( $self->{ 'specialIgnores' }{ $word } )
      and defined( $self->{ 'specialIgnores' }{ $word } )
      )
    {
      print "Word '$word' ignored per special ignores file.\n" if ( $DEBUG3_on ) ;
      ; # Ignored per special ignores file.
    }
    elsif ( exists( $wordsRef->{ $word } )
      and defined( $wordsRef->{ $word } )
      )
    {
      if ( $DEBUG3_on ) {
        print "catchWord old word: '$word' (now '".$wordsRef->{ $word }."').\n" ;
      }
      ; # Already caught.
    }
    else
    {
      if ( $self->{ 'inventTrans' } ) {
        $wordsRef->{ $word } = makeWord( $counter ) ;
        $self->{ 'invented' }{$word} = $wordsRef->{ $word } ;
      } else {
        # $wordsRef->{ $word } = 1 ;
        $wordsRef->{ $word } = $word ;
        $self->{ 'notInvented' }{$word} = 1 ;
      }
      $counter += 1 ;
      _debug( "catchWord new word: '$word' (now '".$wordsRef->{ $word }."').\n" ) ;
    }
    if ( $DEBUG3_on ) {
      $DEBUG = '' ;
      $DEBUG3 = '' ;
      $DEBUG3_flag = 1 ;
      $DEBUG3_on = '' ;
    }
    return() ;
  } # end sub catchWord

  sub makeWord
  {
    my $word = '' ;
    my( $integer ) = @_ ;
    my $cf = scalar( @newWordCharsetFirst ) ;
    my $cn = scalar( @newWordCharset ) ;
    my $cs = $cf + $cn ;
    my $cdiff = $cf - $cn ;
    print "  cdiff '$cdiff', integer '$integer'\n" if ( $DEBUG2 ) ;
    my $firstLoop = 1 ;
    while ( $integer > 0 )
    {
      print "    " if ( $DEBUG2 ) ;
      #$integer = $integer - 1 ;
      my $mod ;
      my $divcf = int( ( $integer - 1 ) / $cf ) ;
      if ( $divcf == 0 )
      {
        print "yes char 1, " if ( $DEBUG2 ) ;
        $mod = ( $integer - 1 ) % $cf ;
        $integer = $divcf ;
        $word = $newWordCharsetFirst[ $mod ] . $word ;
      }
      else
      {
        print "not char 1, " if ( $DEBUG2 ) ;
        #$integer -= $cf ;
        print "int '$integer', " if ( $DEBUG2 ) ;
        #my $dividend = $integer - 1 - $cf + $cdiff + 0 ;
        my $dividend = $integer - 1 - $cf ;
        my $divcn = int( ( $dividend ) / $cn ) ;
        print "dividend '$dividend', divcn '$divcn', " if ( $DEBUG2 ) ;
        $mod = ( $dividend ) % $cn ;
        $integer = int( ( $integer - $cdiff - 1 ) / $cn ) ;
        $word = $newWordCharset[ $mod ] . $word ;
      }
      print "mod '$mod', word '$word', new int '$integer'.\n" if ( $DEBUG2 ) ;
    }
    return( $word ) ;
  } # end sub makeWord
  
  
  # $extractedHash = \%words ;
  # return( $extractedHash ) ;
  return( $wordsRef ) ;
} # end sub extract


# sub extractFromFile
# {
  # my $extractedHash = {} ;
  # my( $self, $infilename ) = @_ ;
  # my $content = loadfile( $infilename ) ;
  # $extractedHash = $self->extract( $content ) ;
  # return( $extractedHash ) ;
# } # end sub extract

# sub extractFromFolder
# {
  # my $extractedHash = {} ;
  # my( $self, $infoldername ) = @_ ;
  # my @dircontent = loaddir() ;
  # my $dirhandle ;
  # open( $dirhandle, $infoldername ) or die( "Failed top" ) ;
  # my $content = loadfile( $infilename ) ;
  # $extractedHash = $self->extract( $content ) ;
  # return( $extractedHash ) ;
# } # end sub extract

# sub extractToFile
# {
  # my $extractedHash = {} ;
  # my( $self, $content, $outfilename ) = @_ ;
  # $extractedHash = $self->extract( $content ) ;
  # mkfile( $outfilename, sortedSimpleHashDumper( $extractedHash ) ) ;
  # return( $extractedHash ) ;
# } # end sub extract

sub translateFromFileTo
{
  my $extractedHash = {} ;
  my( $self, $infilename, $outfilename, $root ) = @_ ;
  if ( ( -f $infilename ) and
    ( ( $infilename =~ /\.debug$/ ) or ( $infilename =~ /\.ob(xml)?\.xml$/ ) ) ) {
    my $newoutbase = basename($outfilename) ;
    my $newoutfile = dirname($outfilename) ;
    $newoutfile =~ s/^\Q$root\E[\\\/]// ;
    $self->{'newfile'}='' ;
    $extractedHash = $self->extract( $newoutfile ) ;
    $newoutfile = $self->{'newfile'} ;
    # print "Special file (root $root, dir $newoutfile, base $newoutbase).\n" ;
    $newoutfile = catfile($root, $newoutfile, $newoutbase) ;
    make_path( dirname( $newoutfile ) ) ;
    copy($infilename, $newoutfile) or die "Copy from '$infilename' to '$outfilename' failed: $!\n" ;
  } else {
    if ( $DEBUG3 ) {
      $self->{ '_tmp_infile' } = $infilename ;
    }
    my $extension = getFileExtension( $infilename ) ;
    # my $configFile = $self->{'configDir'} . "/$extension.totr.cfg" ;
    my $configFile = $self->{'configDir'} . "/$extension.fileext.ignores.txt" ;
    if ( ! -f $configFile ) {
      $configFile = $self->{'configDefaultsDir'} . "/$extension.fileext.ignores.txt" ;
    }
    if ( -f $configFile ) {
      $self->{ 'specialIgnores' } = loadSpecialIgnores( $configFile ) ;
      # print "Found specialIgnores file $configFile.\n" if ( $DEBUG1 ) ;
    }
    # $extractedHash = $self->extract( $content ) ;
    my $newoutfile = $outfilename ;
    $newoutfile =~ s/^\Q$root\E[\\\/]// ;
    $self->{'newfile'}='' ;
    $extractedHash = $self->extract( $newoutfile ) ;
    $newoutfile = $self->{'newfile'} ;
    $outfilename = catfile( $root, $newoutfile ) ;
    print "Infile $infilename became '$outfilename'.\n" ;
    if ( -d $infilename ) {
      make_path( $outfilename ) ;
    } else {
      make_path( dirname( $outfilename ) ) ;
      # my $content = loadfile( $infilename ) ;
      my @content = loadfile( $infilename ) ;
      $self->{'newfile'}='' ;
      $extractedHash = $self->extract( @content ) ;
      # mkfile( $outfilename, sortedSimpleHashDumper( $extractedHash ) ) ;
      mkfile( $outfilename, $self->{'newfile'} ) ;
      # $self->{'newfile'}='' ;
      $self->{ 'specialIgnores' } = {} ;
      $DEBUG3 = 1 if ( $DEBUG3_flag ) ;
    }
  }
  return( $extractedHash ) ;
} # end sub translateFromFileTo

sub getInventedWords
{
  my( $self ) = @_ ;
  return( $self->{ 'invented' } ) ;
} # end sub getInventedWords

sub getNotInventedWords
{
  my( $self ) = @_ ;
  return( $self->{ 'notInvented' } ) ;
} # end sub getNotInventedWords

sub loadSpecialIgnores {
  my $file = shift( @_ ) ;
  my %config = () ;
  my @lines ;
  my $fh ;
  open( $fh, '<', $file ) or die( "Failed to open $file: $!.\n" ) ;
    my $line ;
    while ( $line = readline( $fh ) ) {
      chomp( $line ) ;
      next() if ( $line =~ /^\s*[#!]/ ) ;
      map { $config{$_}=1; } split( /\s+/, $line ) ;
    }
  close( $fh ) ;
  return( \%config ) ;
}


###



# General-able subs:

sub escapeSingleQ
{
  my $escapedStr ;
  my( $str1 ) = @_ ;
  $escapedStr = $str1 ;
  $escapedStr =~ s/[']/\\'/g ;
  return( $escapedStr ) ;
} # end sub escapeSingleQ

sub getFileExtension {
  my $extension = '' ;
  my $filename = shift( @_ ) ;
  $filename ||= '' ;
  if ( $filename =~ /[.]([^.\\\/]+)$/ ) {
    $extension = $1 ;
  }
  return( $extension ) ;
}

sub loadfile
{
  my( $filename ) = @_ ;
  my $filehandle ;
  open( $filehandle, '<', $filename ) or die( "Failed to open file '' for reading:  '$!'." ) ;
  my @lines = <$filehandle> ;
  close( $filehandle ) ;
  if ( wantarray() )
  {
    return( @lines ) ;
  }
  return( join( "\n", @lines ) ) ;
} # end sub loadfile

sub mkfile
{
  my( $filename, $content ) = @_ ;
  my $filehandle ;
  open( $filehandle, '>', $filename ) or die( "Failed to open file '$filename' for writing:  '$!'." ) ;
  print $filehandle $content ;
  close( $filehandle ) ;
  return() ;
} # end sub mkfile

sub sortedSimpleHashDumper
{
  my $output = "{\n" ;
  my $hashref ;
  $hashref = shift( @_ ) if ( 'HASH' eq ref( $_[0] ) ) ;
  if ( not( defined( $hashref ) ) )
  {
    my %hash1 = @_ ;
    $hashref = \%hash1 ;
  }
  my $key1 ;
  foreach $key1 ( sort( keys( %$hashref ) ) )
  {
    my $key2 = escapeSingleQ( $key1 ) ;
    my $val1 = $hashref->{ $key1 } ;
    my $val2 = escapeSingleQ( $val1 ) ;
    $output .= "  '$key2' => '$val2',\n" ;
  }
  $output .= "}" ;
  return( $output ) ;
} # end sub sortedSimpleHashDumper



###



1 ;

#

__END__

sub makeWord_old
{
  my $word = '' ;
  my( $integer ) = @_ ;
  print "  integer '$integer'\n" ;
  my $firstChar = 1 ;
  while ( $integer > 0 )
  {
    #$firstChar = 1 if ( $integer <= scalar( @newWordCharsetFirst ) ) ;
    my $denom = scalar( @newWordCharset ) ;
    $denom = scalar( @newWordCharsetFirst ) if ( $firstChar ) ;
    my $mod = $integer % $denom ;
    $mod = $mod - 1 ;
    $integer = $integer - 1 ;
    $integer = int( $integer / $denom ) ;
    my $letter = $newWordCharset[ $mod ] ;
    $letter = $newWordCharsetFirst[ $mod ] if ( $firstChar ) ;
    $word = $letter . $word ;
    $firstChar = '' ;
    print "    denom '$denom', mod '$mod', letter '$letter', word '$word', new int '$integer'.\n" ;
  }
  return( $word ) ;
} # end sub makeName_old

#

1 ;

#
