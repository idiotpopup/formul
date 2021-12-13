##################################################################################################
##                                                                                              ##
##  >> Error Handling <<                                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_errors.pl'} = 'Release 1.4';

LoadSupport('html_template');

##################################################################################################
## Fatal Errors

sub fatal_error ($;$)
{ my ($Text, $ErrMsg) = @_;

  $Text   ||= '';
  $ErrMsg ||= '';
  my $wm    = sprint_webmaster_HTML();
  my $Time  = '['.gmtime(time).' GMT]';


  # Make error only display once.
  my(@Errors) = dbGetFileContents("$DATA_FOLDER${S}lasterr.log", FILE_NOERROR);
  {
    my $ErrMsg = $ErrMsg;
    $ErrMsg    =~ s/\n/<BR>/g;
    if($XForumUser ne 'admin' && (! $Errors[ERROR_LAST] || $Errors[ERROR_LAST] ne $ErrMsg))
    {
      print_log('ERROR','', $ErrMsg . " MEMBER=" . ($XForumUser || 'none/unknown'));
      $Errors[ERROR_LAST] = $ErrMsg;
      dbSetFileContents("$DATA_FOLDER${S}lasterr.log", 'error log file', @Errors);
    }
  }


  # Display standard error ans debug page...
  my $CGIVer         = ($VERSIONS{'cgiscript'} || '?');
  my $ServerSoftware = (server_software || '?');
  if ($ErrMsg)
  {
    $ErrMsg =~ s/$LINEBREAK_PATTERN/<BR>/g;
    $ErrMsg = "\n      Error Message: <I>$ErrMsg</I><BR><BR>";
  }

  # Header
  CGI::cache(1);
  print_header;
  print_header_HTML("An fatal error occured", "Fatal Error!") unless($TemplateLoaded);
  print_bodystart_HTML();

  print <<ERROR_MSG;
  <BLOCKQUOTE>
    <P><FONT face="Arial" size="+2"><B>$Text</B></FONT></P>
    This CGI program has stopped running due an unexpected error, and properly did not complete it's task. <BR>
    Please <EM>don't press the refresh button!</EM>
    It properly makes things only worse.
    <P>
    For help, please send mail to $wm, giving this error message, <BR>
    the time and date of the error and what you did before the error occured.
    <P>
    <HR>
    <FONT face="Arial">
      <B>Diagnostics</B><BR><BR>$ErrMsg
        X-Forum Version: <I>$CGIVer</I><BR>
        Perl Version: <I>$]</I><BR>
        <HR>
      </FONT>
    </BLOCKQUOTE>
ERROR_MSG
  print_footer_HTML();
}



##################################################################################################
## When error found in action...

sub action_error ($;$) #([STRING CustomError][, BOOLEAN Security])
{ my ($CustomError, $Security) = @_;

  my($wm) = sprint_webmaster_HTML();

  if (defined $CustomError)
  {
    # Show Custom error
    CGI::cache(1);
    print_header;
    print_header_HTML("Warning", $MSG[ ($Security ? ERROR_SECURITY : ERROR_NORMAL) ]);
    print_bodystart_HTML();

    # Print the warning...
    print <<HTML_ERROR;
    <P><IMG src="$IMAGE_URLPATH/icons/error.gif" width="16" height="16" border="0" alt="!" title="">
    $CustomError
    <P>
    $MSG[ERROR_HELP1] $wm,
    $MSG[ERROR_HELP2]
HTML_ERROR
  }
  else
  {
    # Show general error message. User properly tries out what the script does with weird parameters
    CGI::cache(1);
    print_header;
    print_header_HTML("Parameter Error", "Error", "10; url=$THIS_URL");
    print_bodystart_HTML();

    # Parameter Error, please start at the startpage, redirected in 10 secs.
    print <<HTML_ERROR;
    <P><IMG src="$IMAGE_URLPATH/icons/error.gif" width="16" height="16" border="0" alt="!" title="">
    $MSG[ERROR_GENERAL]
    <P>
    $MSG[ERROR_STARTPAGE]
    $MSG[ERROR_HELP1] $wm,
    $MSG[ERROR_HELP2]
    <P>
    $MSG[ERROR_REDIRECT]
HTML_ERROR
  }

  # Footer
  print_footer_HTML();
}


1;
