package CGI::Location;

#
#       Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved
#
#       webmaster@codingdomain.com
#       http://www.codingdomain.com
#

use strict;
sub IIS_CHANGE_PATH(){  1  }


######################################################################################################
## Make the file settings...


BEGIN
{
  use vars '$VERSION', '@VARNAMES';
  $VERSION = 1.07;
  @VARNAMES = qw($THIS_PATH $THIS_URL $THIS_SITE $THIS_NOPR_SITE $SERVER_NAME $PORT $THIS_URLPATH $THIS_DOCROOT $THIS_SCRIPT $THIS_URLUPPATH $THIS_UPPATH $IIS $IISVER $THIS_OS $S);
}

use vars @VARNAMES;


######################################################################################################
## Parse a file path routine...

sub ParseFilePath($;$)
{ my $pos = rindex($_[0], ($_[1] || '/'));
  return '..'                   if $_[0] eq '.';
  return substr($_[0], 0, $pos) if $pos > -1;
  return '.';
}



######################################################################################################
## Detect the script's location...
my $THIS_WEBSS = ($ENV{'SERVER_SOFTWARE'} || 'cmdline');
my($IIS, $Ver) = ($THIS_WEBSS =~ m[(IIS)/(\d+\.\d+)]);

$IIS            = uc($IIS) eq 'IIS';
$IISVER         = $Ver;

unless ($THIS_OS = $^O)
{
  require Config;
  $THIS_OS = $Config::Config{'osname'} || '';
}

my $THIS_OS_OLD = $THIS_OS;

if    ($THIS_OS =~ /^MSWin/i) { $THIS_OS = 'WIN32'; }   # $S = \
elsif ($THIS_OS =~ /^dos/i)   { $THIS_OS = 'DOS';   }   # $S = \
elsif ($THIS_OS =~ /^os2/i)   { $THIS_OS = 'OS2';   }   # $S = \
elsif ($THIS_OS =~ /^MacOS/i) { $THIS_OS = 'MAC';   }   # $S = :
elsif ($THIS_OS =~ /^VMS/i)   { $THIS_OS = 'VMS';   }   # $S = /
elsif ($THIS_OS =~ /^epoc/i)  { $THIS_OS = 'EPOC';  }   # $S = /
else                          { $THIS_OS = 'UNIX';  }   # $S = /


my $THIS_LOCAL  = $ENV{'SCRIPT_FILENAME'} || $0;
$THIS_SCRIPT    = $ENV{'SCRIPT_NAME'}     || '';

# Least of two values...
sub Min ($$)
{
  return ($_[0] < $_[1]) ?
          $_[0] : $_[1];
}

my $EndIndex = Min(length($THIS_SCRIPT), length($THIS_LOCAL));
my $I;

if($THIS_LOCAL =~ m[^/\w] || $THIS_LOCAL =~ m[/cgi-bin/])
{
  # Simple but effective solution for /~username/ URL-paths
  # and other typical UNIX tricks...like situations such as:
  #  Program = /home/<login>/cgi-bin/x-forum.cgi
  #  URL     = /~<login>/cgi-bin/x-forum.cgi
  $S = '/';
}
else
{
  # Test strings for difference... get separator
  char:for($I = -1; $I > -$EndIndex; $I--)
  {
    my $CGIChar  = substr($THIS_SCRIPT,  $I, 1);
    my $PerlChar = substr($THIS_LOCAL,   $I, 1);

    if($CGIChar ne $PerlChar)
    {
      $S = $PerlChar;
      last char;
    }
  }

  $S = '/' if(! defined $S);
}

my $FIRST = 1;
sub refresh
{
  my %overrule = @_;

  if(defined $overrule{'S'})
  {
    $S = $overrule{'S'};
  }
  else
  {
    testsep();
  }

  # All other values.
  $THIS_PATH      = $overrule{'THIS_PATH'}      || ParseFilePath($THIS_LOCAL, $S);
  $THIS_UPPATH    = $overrule{'THIS_UPPATH'}    || ParseFilePath($THIS_PATH, $S);
  $THIS_DOCROOT   = $overrule{'THIS_DOCROOT'}   || $ENV{'DOCUMENT_ROOT'} || $THIS_UPPATH;

  $THIS_SCRIPT    = $overrule{'THIS_SCRIPT'}    || $ENV{'SCRIPT_NAME'}     || '';
  $PORT           = $overrule{'SERVER_PORT'}    || $ENV{'SERVER_PORT'}   || 80;
  $SERVER_NAME    = $overrule{'SERVER_NAME'}    || ($ENV{'HTTP_HOST'}    || $ENV{'SERVER_NAME'} || $ENV{'SERVER_ADDR'} || 'localhost');
  $SERVER_NAME    =~ s/:\d+$//;  # Remove the port number

  $THIS_NOPR_SITE = "$SERVER_NAME" . (($PORT == 80)? "" : ":$PORT");
  $THIS_SITE      = "http://$THIS_NOPR_SITE";
  $THIS_URL       = "$THIS_SITE$THIS_SCRIPT";

  $THIS_URLPATH   = $overrule{'THIS_URLPATH'}   || ParseFilePath($THIS_SCRIPT, '/');
  $THIS_URLUPPATH = $overrule{'THIS_URLUPPATH'} || ParseFilePath($THIS_URLPATH, '/');
}

sub testsep
{
  if($S =~ m/[a-zA-Z0-9\-\+_~]/)
  {
    print "Content-type: text/html\n\n";
    my $CGI_S   = substr($THIS_SCRIPT, $I, 1);
    my $Local_S = substr($THIS_LOCAL,  $I, 1);
    print <<ERROR;
<H1> Auto path detection failed! </H1>
Please report this error to the <A href="mailto:webmaster\@codingdomain.com">coding domain</A> website,
including the following detection info.
<P>
<B>Detection Info:</B>
<PRE>
\$THIS_LOCAL  = $THIS_LOCAL
\$THIS_SCRIPT = $THIS_SCRIPT
\$0           = $0
\$EndIndex    = $EndIndex
\$S           = $S
\$Local_S     = $Local_S
\$CGI_S       = $CGI_S
\$THIS_OS     = $THIS_OS ($THIS_OS_OLD)
\$THIS_WEBSS  = $THIS_WEBSS
\$I           = $I from the right bound
\$]           = Perl $]
</PRE>
<P>
You can overrule the path separator detection, by loading this module in the following way:<BR>
<CODE>use CGI::Location (S => '/');</CODE>
ERROR
    die "Autodetection aborted due fatal error!\n";
    exit;
  }
}



if ($IIS && $IISVER <= 5.0)
{
  # Fix proplem with require 'file' lines in MS-IIS.
  # That webserver assumes all CGI scripts are located at the www root!

  # What is the current-dir in IIS??
  # All paths are relative to this.
  require Cwd;
  my $CurDir = Cwd::cwd();
  $CurDir =~ s~/~$S~g unless($S eq '/');
  $THIS_DOCROOT = $CurDir;

  if(IIS_CHANGE_PATH)
  {
    # IF use lib is used, there may be relative paths in @INC that need to
    # be converted.
    if(exists $INC{'lib.pm'})
    {
      my %Original = map { $_ => 1 } @lib::ORIG_INC;
      my $UpCurDir = ParseFilePath($CurDir, $S);
      my $S        = "[/\\$S]";

      my $INC_SEP  = '/';   # Path separator used in @INC
      my %Updated;          # Update for %INC

      path:for(my $I=0; $I<@INC; $I++)
      {
        my $Path = $INC[$I];

        if(! $Original{$Path})
        {
          # added using 'use lib'
          my $NewPath = $Path;
          $NewPath    =~ s*/*$S*g;

          # Convert the paths
          if   ($NewPath =~ m*^$S*)           { next path                                  } # Absolute path
          elsif(($THIS_OS eq 'WIN32' ||
                 $THIS_OS eq 'DOS')
             && $NewPath =~ m*^[A-Z]\:$S*)    { next path                                  } # Absolute M$ path
          elsif($NewPath =~ m*^.$S*)          { $NewPath = $CurDir   . substr($NewPath, 1) } # Current directory
          elsif($NewPath =~ m*^..$S*)         { $NewPath = $UpCurDir . substr($NewPath, 2) } # Previous directory
          elsif(-d "$CurDir$S$NewPath")       { $NewPath = "$CurDir$S$NewPath"             } # Current directory
          else                                { next path                                  } # next.

          # Update
          $INC[$I] = $NewPath;

          # Add this so we can update %INC later
          $NewPath =~ s*\Q$S*$INC_SEP*g;
          $Updated{$Path} = $NewPath;
         }
      }

      # Against memory leaks.
      foreach my $OldPath (keys %Updated)
      {
        foreach (values %INC)
        {
          s/^\Q$OldPath/$Updated{$OldPath}/;
        }
      }
    }

    push(@INC, $CurDir);                 # Program may expect IIS bug (for example in the use statements using the curdir)
    push(@INC, $THIS_PATH);        # Program should also look in this directory (as it should be)
    chdir($THIS_PATH);             # Change directory, so all file-routines work perfectly
  }
}

sub import
{
  my $self     = shift;
  my $realself = __PACKAGE__;
  my %overrule = @_;

  refresh(%overrule)  if(%overrule || $FIRST);
  $FIRST = 0;


  # Importing the variable names
  no strict 'refs';
  my($ch, $sym);
  my $caller = caller;
  foreach('&ParseFilePath', @VARNAMES)
  {
    ($ch, $sym) = unpack('a1a*', $_);
    if($ch eq '$' && defined $overrule{$sym})
    {
      ${$realself."::$sym"} = $overrule{$sym};
    }

    *{$caller."::$sym"} =
        (  $ch eq "\$" ? \$   {$realself."::$sym"}
         : $ch eq "\@" ? \@   {$realself."::$sym"}
         : $ch eq "\%" ? \%   {$realself."::$sym"}
         : $ch eq "\*" ? \*   {$realself."::$sym"}
         : $ch eq "\&" ? \&   {$realself."::$sym"}
         : do {
             require Carp;
             Carp::croak("'$ch$sym' is not a valid variable name");
     });
  }
}


1;


__END__

=head1 NAME

CGI::Location - CGI Location Detection

=head1 SYNOPSIS

  use CGI::Location;

  print "Current URL is: $THIS_URL";
  print "Website home page is: $THIS_SITE/index.html";


=head1 DESCRIPTION

This module makes any CGI program capable of detecting
their own location, so no variables needs to be set anymore!

=head2 Variables added to the main package

=over

=item $THIS_PATH

The current path of the script based on the $0 variable, eg /httpd/www/you/cgi-bin

=item $THIS_UPPATH

The higher path where the current script is found, eg: /httpd/www/you

=item $THIS_DOCROOT

The document root directory.

=item $THIS_URL

The current URL of the script, eg: http://www.you.com/cgi-bin/script.cgi

=item $THIS_SITE

The current website the script is located, eg: http://www.you.com
The http:// prefix is assumed, not detected!

=item $THIS_NOPR_SITE

Same as previous item, but without the http:// prefix.

=item $SERVER_NAME

The internet name of the computer, eg: www.you.com

=item $PORT

The port of the webserver, undef for default (is 80) and any other
value when a different port is being used.

=item $THIS_URLPATH

The path from the current URL, eq: /cgi-bin

=item $THIS_URLUPPATH

The higher path from the current URL, eg: a empty string if $THIS_URLPATH has the value /cgi-bin

=item $THIS_SCRIPT

The path+filename of the current URL, eg: /cgi-bin/script.cgi

=item $S

The path separator used to separate paths at the webserver's filesystem.

=item $THIS_OS

A extra feature. This is the OS name. Unlike $^O, this string is less detailed,
and easier to use in a string test.

=item $IIS, $IISVER

True if the current webserver used is the 'Internet Information Server' is used.
This variable can be useful to fix problems caused by some assumptions that server makes.
However, it appears that IIS/5.1 has some fixes at this point. That's why this module also
provides the $IISVER variable.

=back

=head2 Exported Functions and Variables

=over

=item ParseFilePath(Filename, [PathSeparator])

Extracts the path from a filename, using a specified path separator, or the default value.

=item @CGI::Location::VARNAMES

Contains a list of all exported variable names.

=back

=head2 Internet Information Server Issues

The Internet Information Server from Microsoft has some nasty bugs in it. Therefore
the $IIS and $IISVER variables are available. Some of the errors caused in the IIS server
are fixed in the 5.1 release. In previous releases, the current-directory pointed to the
www-root directory. This resulted in difficult problems concerning require/open/use lines
depending on the current directory variable.
After loading this module, your @INC, %INC and "current directory" will be changed to make
the rest of the script work exactly the same for each server.
so all your C<require> and C<open> lines in your scripts will then work as they should be.
Include files that were expected at the www-root directory (because of that bug) will still work correctly,
since this path is also added to the @INC array.

=head1 BUGS

=over

=item Assumtions

This module relies very much on the Environment variabels and a bit on the $0, used by the webserver software.

The protocol is assumed to be http:// but a no-protocol variable is avaible aswell.

The path separator used in %INC, is assumed to be a slash (/).

=back

=head1 Overruling Detection

Even this module can't detect everything correctly in all circumstances.
For example, when a CGI script is called from a shtml directive.
Almost all variables can be overruled. To overrule a variable, provide an
alternative value at the import statement. For example:

  use CGI::Location (S => '/');
  use CGI::Location (THIS_PATH   => '/website/cgi-bin');
  use CGI::Location (THIS_SCRIPT => '/cgi-bin/script.cgi', SERVER_NAME => 'www.me.com');

Most of such modifications will change other variables aswell, since they are
determined from other pieces of information. If you ever need to overrule something,
try overruling one of these variables first: S, THIS_PATH, THIS_SCRIPT, SERVER_NAME, PORT.

=head1 AUTHOR

        Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

        webmaster@codingdomain.com
        http://www.codingdomain.com

=cut