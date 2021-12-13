package CGI::ErrorTrap;

#
#       Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved
#
#       webmaster@codingdomain.com
#       http://www.codingdomain.com
#

use strict;

sub ERRORHIDE_THIS_PATH(){  1  }


######################################################################################################
## Make the file settings...

BEGIN
{
  use Exporter  ();
  use vars      qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DIALOG_SUB $DISPLAY_FULL);

  $VERSION      = 1.01;
  @ISA          = qw(Exporter);

  @EXPORT       = qw(&Error &IsRealError $DIALOG_SUB $DISPLAY_FULL);
  @EXPORT_OK    = ();
  %EXPORT_TAGS  = ();
}

$DISPLAY_FULL = 1;



##################################################################################################
## HTML Escape Convert

sub IsRealError ()
{
#  return if(defined $^S && $^S);

  # We should not be inside a eval() or eval{}...
  my $I = 1;
  while(my @StackInfo = caller($I++))
  {
    # my($Package, $FileName, $Line, $Subroutine, $HasArgs, $WantArray, $EvalText, $IsRequire) = @StackInfo;
    return if($StackInfo[3] eq '(eval)' || $StackInfo[1] eq '(eval)');
  }
  return 1;
}

sub Error ($;$) {
  my ($Text,$ErrMsg)=@_;

  if(not defined $ErrMsg)
  {
    return unless IsRealError();
    $ErrMsg = ($Text || $! || $@ || ''); $Text = "Unexpected Error";
  }

  if(ERRORHIDE_THIS_PATH)
  {
    HideCurrentPath($ErrMsg);
  }

  chomp $ErrMsg;
  my $ErrOSMsg = '';
  if ($! && $^E && (index($!, $ErrMsg) == -1 || $! ne $^E))
  {
    $ErrOSMsg = "\n      <I>$^E</I><BR><BR>";
  }

  my $UserPage = ((!$DISPLAY_FULL) || ($ENV{'REQUEST_METHOD'} || '') eq 'GET');

  if($UserPage && defined $DIALOG_SUB)
  {
    # We try to show the cool error dialog
    if(ref($DIALOG_SUB) eq 'CODE')
    {
      eval
      {
        &$DIALOG_SUB($Text, $ErrMsg);
      };
      if (not $@) { exit; }
      $ErrMsg .= "\n\nShowing the normal error dialog failed: $@";
    }
    else
    {
      $ErrMsg .= "\n\nShowing the normal error dialog failed: \$DIALOG_SUB should be a function pointer, not $DIALOG_SUB";
    }
  }

  # Or display standard error ans debug page...
  my($BACK_COLOR, $FONT_COLOR, $CGIVer);
  {
    no strict 'vars';
    $BACK_COLOR = ($main::BACK_COLOR || '#FFFFFF');
    $FONT_COLOR = ($main::FONT_COLOR || '#000000');
    $CGIVer = ($main::VERSIONS{'cgiscript'} || '?');
    use strict 'vars';
  }

  if($ErrMsg)
  {
    $ErrMsg =~ s/(\015\012|\015|\012|\r)/<BR>/g;
    $ErrMsg =~ s/\.{5}//g if($ErrMsg =~ m/^\.{5}/); # At f2s.com my script errors had 5 dots between the characters
    $ErrMsg = "\n      Error Message: <I>$ErrMsg</I><BR><BR>";
  }


  print qq[Content-type: text/html\015\012];
  print qq[Pragma: no-cache\015\012];
  print qq[\015\012];
  unless($UserPage)
  {
    print <<HTML_HEAD;
<HTML>
<HEAD><TITLE>CGI Script Error</TITLE></HEAD>
<BODY bgcolor="$BACK_COLOR" text="$FONT_COLOR">
HTML_HEAD
  }
  print <<ERROR_MSG;
  <BLOCKQUOTE>
    <P><FONT face="Arial" size="+2"><B>$Text</B></FONT></P>$ErrOSMsg
    <HR>
    <FONT face="Arial">
      <B>Diagnostics</B><BR><BR>$ErrMsg
      CGI Version: <I>$CGIVer</I><BR>
      Perl Version: <I>$]</I><BR>
ERROR_MSG
  unless($UserPage)
  {
    my $ServerSoftware = ($ENV{'SERVER_SOFTWARE'} || 'cmdline');
    print qq[      Server Type: <I>$^O $ServerSoftware</I><BR>\n ];
    {
      no strict 'vars';
      print qq[     Current Directory: <I>$main::THIS_PATH</I><BR>\n] unless(not defined $main::THIS_PATH);
      use strict 'vars';
    }
  }
  print <<ERROR_MSG;
      <HR>
    </FONT>
  </BLOCKQUOTE>
ERROR_MSG
print qq[</BODY>\n</HTML>\n] unless($UserPage);

exit;
}

sub HideCurrentPath
{
  no strict 'vars';
  foreach(@_)
  {
    s/\Q$main::THIS_PATH\E/\./g      unless(not defined $main::THIS_PATH);
    s/\Q$main::THIS_UPPATH\E/\.\./g  unless(not defined $main::THIS_PATH);
  }
}

sub StackTrace ()
{
  my $I = 0;
  my $Result = "";
  while(my @StackEntry = caller($I++))
  {
    CGI::ErrorTrap::HideCurrentPath($StackEntry[1]);
    $Result .= ($I < 10 ? "0$I" : $I) . " $StackEntry[1] line $StackEntry[2] ($StackEntry[0])\n";
  }
  return $Result;
}


$main::SIG{'__DIE__'}  = \&Error;
$main::SIG{'__WARN__'} = \&Error;

1;


__END__

=head1 NAME

CGI::ErrorTrap - Display advanced error messages

=head1 SYNOPSIS

  use CGI::ErrorTrap;

  [*(\{] # propertly syntax error ;-)

  warn "The program ends here!\n";
  die "HAHA!\n";

  Error('Failed to...');
  Error('Error in program X', 'Failed to...');


=head1 DESCRIPTION

Traps errors in CGI programs, and displays an better error dialog.

=head2 Functions and Variables

=over

=item Error( 'optional_title', 'error message');

This is the error handler used when errors are trapped.
The optional title will be displayed in the header of the dialog.
This subroutine can also be called as an single argument version,
like C<&Error('error message')>. The text 'Unexpected Error' will then be displayed
in stead of the title.

=item IsRealError()

This subroutine should only be called inside any $SIG{'__DIE__'} or $SIG{'__WARN__'} handler.
It returns false when the signal handler was activated inside an eval statement. Normally,
you shouldn't respond to such errors.

=item $CGI::ErrorTrap::DIALOG_SUB

If this variable is set to a code pointer, that code will be ordered to
display the error dialog. All tests and message conversions are already done.
The subroutine will get two parameters; a title and a real error message.

=item $CGI::ErrorTrap::DISPLAY_FULL

Defaultly set to True. This implies that more debugging information should be
printed at the screen. Sometimes, this value will be forced or overruled.
The value should be set to false as soon as some HTML text has been printed to the screen.

=item $main::BACK_COLOR, $main::FONT_COLOR

If these values are available, they will be used to format the error window.
If you want to display a more personal error message dialog,
you should use the $CGI::ErrorTrap::DIALOG_SUB variable.

=item $main::THIS_PATH, $main::THIS_UPPATH

These values are added by the CGI::Location module.
They won't be displayed, but they are used in a regexp to hide all
paths from the error message. It's more safe to use the message,
and it clears up the message a bit.

=back

=head2 Other Issues

Both the warn and die messages will be trapped, what I consider useful in CGI programs.
This error trap will be active, even before any BEGIN block of the main program is executed!
Thus, (almost) all error messages will be trapped, and complication errors aswell.

=head1 AUTHOR

        Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

        webmaster@codingdomain.com
        http://www.codingdomain.com

=cut