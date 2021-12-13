##################################################################################################
##                                                                                              ##
##  >> Post Preview <<                                                                          ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_postpreview.pl'} = 'Release 1.3';

LoadSupport('html_template'); # This is a dialog form a HTTP POST request
LoadSupport('html_posts');
LoadSupport('html_tables');
LoadSupport('xbbc_convert');


##################################################################################################
## Show Post Preview

sub Show_PostPreview ($$$;$) #(STRING Message, STRING Title, STRING TopicID)
{ my(undef, $Title, $Poster, $Icon, $Topic, $PostIndex, $OriginalDate, $OriginalPoster) = @_;


  $PostIndex ||= 0;


  my $IsEditSample = ($OriginalDate && $OriginalPoster);
  my $EditDate     = undef;
  my $EditPoster   = undef;

  # Whoa. This is Perl.
  ($IsEditSample ? $EditDate   : $OriginalDate)   = time;
  ($IsEditSample ? $EditPoster : $OriginalPoster) = $Poster;


  # header HTML
  print_header;
  print_header_HTML($MSG[SUBTITLE_PREVIEW], $MSG[SUBTITLE_PREVIEW]);
  print_bodystart_HTML();

  # Determine some HTML blocks...
  my $MemberInfo   = sprint_memberinfo_HTML($OriginalPoster);
  my $PostHeader   = sprint_postinfo_HTML($PostIndex, $OriginalDate, $EditDate, $EditPoster);
  my $PostContents = FormatFieldXBBC($_[0], $Topic);
  my $FooterIcons  = sprint_button_HTML("$MSG[BUTTON_EDITPOST] - $MSG[ACTION_RETURN]" => qq[javascript:self.close()], 'modifycarset', $MSG[BUTTON_EDITPOST_INFO]);

  # Print the sample
  print_post_HTML($Title, $OriginalPoster, $Icon, $PostIndex, 1, 1, $MemberInfo, $PostHeader, $PostContents, $FooterIcons);

  print <<JS_RETURN;
    <P align="center"><A href="javascript:window.close()">$MSG[ACTION_RETURN]</A></P>
JS_RETURN

  # Footer
  print_footer_HTML();
}


1;
