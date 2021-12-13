##################################################################################################
##                                                                                              ##
##  >> HTML Generators for member icons and status symbols <<                                   ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'html_members.pl'} = 'Release 1.6';

LoadSupport('db_members');
LoadSupport('html_interface');


##################################################################################################
# Predefined regexps

my $IconRegExp = qr/.+\.(gif|jpg|png)$/;
my $HTTPRegExp = qr/^http(s?):\/\//;



##################################################################################################
## HTML Strings that can be used for member display

sub member_icon_HTML ($$$) #(STRING IconFile, STRING Name, STRING IconTitle) >> STRING IconHTML
{ my ($Icon, $Name, $IconTitle) = @_;
  return '' if (! $Icon);

  if ($Icon !~ m/$IconRegExp/)  { $Icon = "$Icon.gif"; }

  if($Icon =~ m/$HTTPRegExp/)
  {
    return '' unless $ALLOW_ICONURL;
  }
  else
  {
    $Icon = "$IMAGE_URLPATH/membericons/$Icon";
  }

  return qq[<IMG src="$Icon" border="0" alt="$MSG[HTML_MEMBERICON]" title="$Name"><BR>$IconTitle];
}


sub member_gender_HTML ($) #(NUMBER GenderIndex) >> STRING IconHTML
{ my ($Gender) = @_;
  return '' if (! $_[0]);

  my $Icon = (  '',
                $MSG[MEMBER_GENDER_M],
                $MSG[MEMBER_GENDER_F]
             )[$Gender];
  $Icon ||= '';

  return '' if ($Icon eq '');

  my $IconFile = ('', 'male', 'female')[$Gender];
  return qq[<IMG src="$IMAGE_URLPATH/icons/${IconFile}_small.gif" width="11" height="11" title="$Icon">];
}


sub member_website_HTML ($;$) #(STRING URL, STRING Title) >> STRING IconHTML
{ my ($WebURL, $URLTitle) = @_;
  $URLTitle = ($URLTitle || $WebURL);
  return '' if (! $_[0]);
  return sprint_button_HTML('Website' => qq[$WebURL" target="_blank], 'website', $URLTitle);
}


sub member_websiteicon_HTML ($;$) #(STRING URL, STRING Title) >> STRING IconHTML
{ my ($WebURL, $URLTitle) = @_;
  $URLTitle = ($URLTitle || $WebURL);
  return '' if (! $_[0]);
  return qq[<A href="$WebURL" class="icon" target="_blank"><IMG src="$IMAGE_URLPATH/icons/website.gif" border="0" width="16" height="16" title="$URLTitle ($WebURL)"></A>];
}


sub member_email_HTML ($$)  #(STRING Email, BOOLEAN Private) >> STRING IconHTML
{ my ($Email, $Private) = @_;
  return '' if (! $_[0]);
  return ($Private ? sprint_button_HTML($MSG[BUTTON_EMAIL] => "javascript:alert('$MSG[HTML_PRIVATEEMAIL]');", 'email', $MSG[HTML_EMAILHIDDEN])
                   : sprint_button_HTML($MSG[BUTTON_EMAIL] => "mailto:$Email?subject=$FORUM_TITLE\%20member\%20says\%20HI!", 'email', "$MSG[HTML_MAILTO]: $Email") );
}


sub member_emailicon_HTML ($$) #(STRING Email, BOOLEAN Private) >> STRING IconHTML
{ my ($Email, $Private) = @_;
  return '' if (! $_[0]);
  return ($Private ? qq[<A href="javascript:alert('$MSG[HTML_PRIVATEEMAIL]');" class="icon"><IMG src="$IMAGE_URLPATH/icons/email.gif" border="0" width="16" height="16" title="$MSG[HTML_EMAILHIDDEN]"></A>]
                   : qq[<A href="mailto:$Email?subject=$FORUM_TITLE\%20member\%20says\%20HI!" class="icon"><IMG src="$IMAGE_URLPATH/icons/email.gif" border="0" width="16" height="16" title="$MSG[HTML_MAILTO]: $Email"></A>] );
}


sub member_ICQonline_HTML ($) #(NUMBER ICQ) >> STRING IconHTML
{ my ($ICQ) = @_;
  return '' if (! $_[0]);
  return qq[<IMG src="http://wwp.icq.com/scripts/online.dll?icq=$ICQ&img=5" onError="if(! this.first) { this.src='$IMAGE_URLPATH/icons/icq-error.gif'; this.first=true; }" border="0" width="18" height="18" alt="$ICQ" title="$MSG[MEMBER_ICQ]: $ICQ" NOCACHE NOSAVE>];
}


sub member_ICQadd_HTML ($$) #(NUMBER ICQ, STRING Name) >> STRING IconHTML
{ my ($ICQ, $Name) = @_;
  return '' if (! $_[0]);
  return qq[<A href="http://wwp.icq.com/scripts/search.dll?to=$ICQ" class="icon" target="_blank"><IMG src="$IMAGE_URLPATH/icons/icqadd.gif" width="16" height="16" border="0" title="$MSG[HTML_ICQADD]" align="top"><FONT color="$FONT_COLOR" size="1">$MSG[HTML_ICQADD]</FONT></A>];
}

sub member_MSN_HTML ($) #(NUMBER MSN) >> STRING IconHTML
{ my ($MSN) = @_;
  return '' if (! $_[0]);
  return qq[<IMG src="$IMAGE_URLPATH/icons/msn.gif" border="0" width="16" height="16" alt="$MSN" title="$MSG[MEMBER_MSN]: $MSN">];
}

sub member_AIM_HTML ($) #(STRING AIM) >> STRING IconHTML
{ my ($AIM) = @_;
  return '' if (! $_[0]);
  return qq[<A href="aim:goim?screenname=].escape($AIM).qq[&message=Hi.+Are+you+there?" class="icon" target="_blank"><IMG src="$IMAGE_URLPATH/icons/aim.gif" border="0" width="16" height="16" alt="$MSG[HTML_AIM]" title="$MSG[HTML_AIMSEND] ($AIM)"></A>];
}

sub member_AIMadd_HTML ($$) #(STRING AIM, STRING Name) >> STRING IconHTML
{ my ($AIM, $Name) = @_;
  return '' if (! $_[0]);
  return qq[<A href="aim:addbuddy?screenname=].escape($AIM) .qq[" class="icon" target="_blank"><IMG src="$IMAGE_URLPATH/icons/aimadd.gif" width="15" height="18" border="0" title="$MSG[HTML_AIMADD] ($AIM)" align="top"><FONT color="$FONT_COLOR" size="1">$MSG[HTML_AIMADD]</FONT></A>];
}




sub member_YIM_HTML ($) #(STRING YIM) >> STIRNG IconHTML
{ my ($YIM) = @_;
  return '' if (! $_[0]);
  return qq[<A href="http://edit.yahoo.com/config/send_webmesg?.target=].escape($YIM).qq[" class="icon" target="_blank"><IMG src="$IMAGE_URLPATH/icons/yim.gif" border="0" width="16" height="16" alt="$MSG[HTML_YIM]" title="$MSG[HTML_YIMSEND] ($YIM)"></A>];
}


sub member_YIMonline_HTML ($) #(NUMBER YIM) >> STRING IconHTML
{ my ($YIM) = @_;
  return '' if (! $_[0]);
  return qq[<IMG src="http://opi.yahoo.com/online?u=].escape($YIM).qq[&m=g&t=0" onError="if(! this.first) { this.src='$IMAGE_URLPATH/icons/yim-error.gif'; this.first=true; }" border="0" width="14" height="14" alt="$YIM" title="$MSG[MEMBER_YIM]: $YIM" NOCACHE NOSAVE>];
}


1;
