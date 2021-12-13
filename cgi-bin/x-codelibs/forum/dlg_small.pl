##################################################################################################
##                                                                                              ##
##  >> Small dialogs <<                                                                         ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_small.pl'} = 'Release 1.6';

LoadSupport('html_interface');


##################################################################################################
## Help files

sub Show_HelpDialog ()
{
  my $Topic = (param('help') || 'forum');

  # Preload some HTML
  my($wm) = sprint_webmaster_HTML(0, 1);
  $wm = <<HELP_NOTE;
    <P>
    $MSG[HELP_MORE1] $wm, $MSG[HELP_MORE2] ($Topic), $MSG[HELP_MORE3]
HELP_NOTE


  # Get help filename
  my $HelpFile = "$LANG_FOLDER${S}$LANGID${S}$Topic.hlp";

  my $HelpTopicLink = ($Topic ne 'forum' ? "&help=$Topic" : '');

  # Print HTML
  print_header;
  print_header_HTML($MSG[SUBTITLE_HELP], $MSG[SUBTITLE_HELP]);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        "?show=help$HelpTopicLink" => $MSG[SUBTITLE_HELP]
                      );
  print_bodystart_HTML();
  print <<HELP_HEADER;
    [ <A href="$THIS_URL?show=help&help=help">$MSG[HELP_TOPICS]</A> | <A href="javascript:history.go(-1)">$MSG[ACTION_GOBACK]</A> ]
    <P>
HELP_HEADER


  # Print the help file
  if (! -e $HelpFile)
  {
    print "    $MSG[HELP_UNAVAILABLE]\n";
  }
  else
  {
    # Read in one line each.
    # Not the normal slurping.
    my $Help = new File::PlainIO($HelpFile, MODE_READ, "Can't open help documentation for '$Topic'");
    print "    $_\n" while defined $Help->readline();
    $Help->close();;
  }

  # Footer Text
  print "\n$wm";
  print_footer_HTML();
 }



##################################################################################################
## Display some credits on direct request

sub Show_AboutDialog ()
{
  print redirect("$THIS_URL?show=help&help=about");
}


1;
