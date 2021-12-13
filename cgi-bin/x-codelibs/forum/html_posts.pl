##################################################################################################
##                                                                                              ##
##  >> Generate Strings for Displaying Posts <<                                                 ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

use strict;

$VERSIONS{'html_post.pl'} = 'Release 1.6';



##################################################################################################

my %MemberInfo;
my %MemberFooter;
my %MemberIcons;


##################################################################################################
## Not all requirements are included perhaps.

LoadSupport('html_members');



##################################################################################################
## Get The Member Infomation

sub sprint_memberinfo_HTML ($)
{ my($Member, $ModeratorList) = @_;


  if (! exists $MemberInfo{$Member})
  {
    # Get member information, and finally set the default values for it.
    my @MemberInfo    = dbGetMemberInfo($Member, 0);
    my $MemberIsGuest = dbMemberIsGuest($Member);
    my $MemberLink    = sprint_memberlink_HTML($Member);

    my $Status = '';
    my $Footer = '';

    if (! $MemberIsGuest && dbMemberInvalid($Member, @MemberInfo))
    {
      # The retreived member is unknown. That error wasn't tested in the database routine now.
      foreach(@MemberInfo) { $_ = "" }
      $MemberInfo[DB_MEMBER_NAME] = $MSG[MEMBER_UNKNOWN];
    }
    else
    {
      # Get the status
      if ($Member eq 'admin')
      {
        $Status = qq[\n        <BR>$MSG[MEMBER_ADMIN]<BR>\n       ] . qq[ <IMG src="$IMAGE_URLPATH/icons/statusadmin.gif" width="16" height="16">] x 5;
      }
      elsif($MemberIsGuest)
      {
        $Status = "\n        <BR>$MSG[HTML_GUEST]";
      }
      elsif ($ModeratorList && dbIsSubjectModerator($ModeratorList, $Member))
      {
        $Status = qq[\n        <BR>$MSG[MEMBER_MODERATOR]<BR>\n       ] . qq[ <IMG src="$IMAGE_URLPATH/icons/statusmoderator.gif" width="16" height="16">] x 5;
      }

      # Make cool icons for some items.
      $MemberInfo[DB_MEMBER_ICON]   = member_icon_HTML($MemberInfo[DB_MEMBER_ICON],      $MemberInfo[DB_MEMBER_NAME], '');
      $MemberInfo[DB_MEMBER_GENDER] = member_gender_HTML($MemberInfo[DB_MEMBER_GENDER]);
      $MemberInfo[DB_MEMBER_EMAIL]  = member_email_HTML($MemberInfo[DB_MEMBER_EMAIL],    $MemberInfo[DB_MEMBER_PRIVATE]);
      $MemberInfo[DB_MEMBER_WEBURL] = member_website_HTML($MemberInfo[DB_MEMBER_WEBURL], $MemberInfo[DB_MEMBER_URLTITLE]);

      $MemberInfo[DB_MEMBER_ICQ]     = "\n        <NOBR>" . member_ICQonline_HTML($MemberInfo[DB_MEMBER_ICQ])
                                                     ." " . member_ICQadd_HTML($MemberInfo[DB_MEMBER_ICQ], $MemberInfo[DB_MEMBER_NAME]) . "</NOBR>"  unless($MemberInfo[DB_MEMBER_ICQ]    eq '');
      $MemberInfo[DB_MEMBER_MSN]     = "\n        <NOBR>" . member_MSN_HTML($MemberInfo[DB_MEMBER_MSN]) . "</NOBR>"                                  unless($MemberInfo[DB_MEMBER_MSN]    eq '');
      $MemberInfo[DB_MEMBER_AIM]     = "\n        <NOBR>" . member_AIM_HTML($MemberInfo[DB_MEMBER_AIM])
                                                     ." " . member_AIMadd_HTML($MemberInfo[DB_MEMBER_AIM], $MemberInfo[DB_MEMBER_NAME]) . "</NOBR>"  unless($MemberInfo[DB_MEMBER_AIM]    eq '');
      $MemberInfo[DB_MEMBER_YIM]     = "\n        <NOBR>" . member_YIM_HTML($MemberInfo[DB_MEMBER_YIM])
                                                     ." " . member_YIMonline_HTML($MemberInfo[DB_MEMBER_YIM]) . "</NOBR>"          unless($MemberInfo[DB_MEMBER_YIM]     eq '');
      $MemberInfo[DB_MEMBER_GENDER]  = "\n        <NOBR>" . "$MSG[MEMBER_GENDER]: $MemberInfo[DB_MEMBER_GENDER]</NOBR>"            unless($MemberInfo[DB_MEMBER_GENDER]  eq '');
      $MemberInfo[DB_MEMBER_EMAIL]   = "\n            " . $MemberInfo[DB_MEMBER_EMAIL]                                             unless($MemberInfo[DB_MEMBER_EMAIL]   eq '');
      $MemberInfo[DB_MEMBER_POSTNUM] = "\n        <NOBR>" . "$MSG[MEMBER_POSTS]: $MemberInfo[DB_MEMBER_POSTNUM]</NOBR><BR>"        unless($MemberInfo[DB_MEMBER_POSTNUM] eq '');
      $MemberInfo[DB_MEMBER_WEBURL]  = "\n            " . $MemberInfo[DB_MEMBER_WEBURL]                                            unless($MemberInfo[DB_MEMBER_WEBURL]  eq '');
    }


    # If we have the data, make the member id stuff for the left side
    $MemberInfo{$Member} = <<MEMBER_INFO_HTML;
        <!------ Member Information of $MemberInfo[DB_MEMBER_NAME] ------>
        $MemberLink$Status<BR><BR>
        <P>$MemberInfo[DB_MEMBER_ICON]<BR>$MemberInfo[DB_MEMBER_ICONTITLE]</P>$MemberInfo[DB_MEMBER_POSTNUM]$MemberInfo[DB_MEMBER_GENDER]<BR>$MemberInfo[DB_MEMBER_ICQ]$MemberInfo[DB_MEMBER_MSN]$MemberInfo[DB_MEMBER_AIM]$MemberInfo[DB_MEMBER_YIM]
MEMBER_INFO_HTML


    my $MemberProfile = '';


    # The buttons that should always below his posts.
    # We generate them here, because we have the memberinfo now.
    if(dbMemberExist($Member))
    {
      $MemberProfile          = "\n            " . sprint_button_HTML($MSG[BUTTON_PROFILE]    => "$THIS_URL?show=member&member=$Member", 'profile', "$MSG[BUTTON_PROFILE_INFO] $MemberInfo[DB_MEMBER_NAME]");
      $MemberIcons{$Member}   =                    $MemberProfile
                                                 . $MemberInfo[DB_MEMBER_WEBURL]
                                                 . $MemberInfo[DB_MEMBER_EMAIL];
      $MemberIcons{$Member}  .= "\n            " . sprint_button_HTML($MSG[BUTTON_COMPOSETO]  => "$THIS_URL?show=compose&action=new&to=$Member",  'msgsend', "$MSG[BUTTON_COMPOSETO_INFO] $MemberInfo[DB_MEMBER_NAME]") unless($Member eq $XForumUser);
      $MemberIcons{$Member}  .= "\n            " . sprint_button_HTML($MSG[BUTTON_LOGFILE]    => "$THIS_URL?show=admin_logfiles&logfile=$Member", 'logfile', $MSG[BUTTON_LOGFILE_INFO]) if ($XForumUser eq 'admin');
    }
    elsif($MemberIsGuest)
    {
      $MemberIcons{$Member}   = $MemberInfo[DB_MEMBER_EMAIL];
    }
  }

  return $MemberInfo{$Member};
}


sub sprint_memberfooter_HTML ($)
{ my($Member) = @_;

  my $Footer = '';

  if (! exists $MemberFooter{$Member})
  {
    $Footer                 = dbGetMemberFooter($Member) unless dbMemberFileInvalid($Member);
    $MemberFooter{$Member}  = qq[\n          <BR><BR>];

    if($MemberOnline{$Member} || $MemberBanned{$Member})
    {
      $MemberFooter{$Member} .= qq[<DIV align="right">];
      $MemberFooter{$Member} .= qq[<IMG src="$IMAGE_URLPATH/icons/connected.gif" width="16" height="16" border="0" alt="$MSG[MEMBER_ONLINE]"><FONT size="-1">$MSG[MEMBER_ONLINE]</FONT>]  if $MemberOnline{$Member};
      $MemberFooter{$Member} .= qq[<IMG src="$IMAGE_URLPATH/icons/banned.gif" width="16" height="16" border="0" alt="$MSG[MEMBER_ISBANNED]"><FONT size="-1">$MSG[MEMBER_ISBANNED]</FONT>] if $MemberBanned{$Member};
      $MemberFooter{$Member} .= qq[</DIV>];
    }

    if($Footer ne '')
    {
      $MemberFooter{$Member} .= qq[\n          <HR><FONT size="-1">\n          ] . FormatFieldXBBC($Footer) . qq[</FONT>];
    }
  }

  return $MemberFooter{$Member};
}

sub sprint_membericons_HTML ($)
{ my($Member) = @_;

  if(! exists $MemberIcons{$Member})
  {
    return '';
  }

  return $MemberIcons{$Member};
}

sub sprint_ipstat_HTML ($)
{ my($IP) = @_;
  if($XForumUser eq 'admin' && $IP)
  {
    return qq[\n            <NOBR><IMG src="$IMAGE_URLPATH/icons/pc.gif" width="16" height="16" border="0" alt="IP">$IP</NOBR>];
  }
  return '';
}

sub sprint_postinfo_HTML ($$$$)
{ my($PostIndex, $PostDate, $LastModDate, $LastModMember) = @_;

  my $FirstPost = ($PostIndex == 0);
  my $Info      = "<NOBR>";

  if($FirstPost)        { $Info .= "$MSG[TOPIC_STARTED] "                         }
  elsif($PostIndex < 0) { $Info .= "$MSG[MESSAGE_RECEIVED] "                      }
  else                  { $Info .= "$MSG[POST_REPLY]$PostIndex $MSG[POST_ADDED] " }

  $Info .= DispTime($PostDate) . ' </NOBR>';

  if($LastModDate)
  {
    $LastModDate = DispTime($LastModDate);
    $Info .= "<BR>\n            "
           . "<NOBR>$MSG[POST_LASTMOD] $LastModDate $MSG[POST_BY] "
           . sprint_memberlink_HTML($LastModMember) . "</NOBR>";
  }

  return $Info;
}



sub MEMBER_INFO()  { 6 }
sub POST_HEADER()  { 7 }
sub POST_CONTENTS(){ 8 }
sub FOOTER_ICONS() { 9 }

sub print_post_HTML ($$$$$$$$$$)
{ my($Title, $Poster, $PostIcon, $PostIndex, $FirstPost, $LastPost) = @_;

  # Spacer code, but not for last post.
  my $InfoSpace    = ($LastPost ? '' : qq[<BR><BR>]);
  my $PostSpace    = ($LastPost ? '' : qq[\n        <TR><TD><BR><BR></TD></TR>]);

  my $MemberFooter = '';
  $MemberFooter = sprint_memberfooter_HTML($Poster) if($Poster && dbMemberExist($Poster));


  my $FooterIcons  = '';

  if($_[FOOTER_ICONS])
  {
    $FooterIcons  = qq[<TABLE width="100%" border="0" cellspacing="0" cellpadding="0"><TR valign="top"><TD align="left"><NOBR>]
                  . sprint_membericons_HTML($Poster)
                  . "&nbsp;\n"
                  . qq[          </NOBR></TD><TD align="right"><NOBR>\n]
                  . qq[            $_[FOOTER_ICONS]\n]
                  . qq[          </NOBR></TD></TR></TABLE>];
  }
  else
  {
    $FooterIcons = "<NOBR>" . sprint_membericons_HTML($Poster) . "\n          </NOBR>";
  }

  print qq[    <TABLE width="100%">\n] if($FirstPost);
  print <<TOPIC_POST_HTML;

      <TR><TD width="150" align="center" valign="top"><FONT size="1">
$_[MEMBER_INFO]      </FONT>$InfoSpace</TD>
      <TD valign="top"><TABLE width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
        <!------ Post $PostIndex ------>
        <TR>
          <TD bgcolor="$POSTHEAD_COLOR" width="18"><IMG src="$IMAGE_URLPATH/posticons/$PostIcon.gif" width="16" height="16" border="0"></TD>
          <TD bgcolor="$POSTHEAD_COLOR" align="center"><A name="post$PostIndex"><FONT color="$POSTCAPT_COLOR"><B>$Title</B></FONT></A></TD>
          <TD bgcolor="$POSTHEAD_COLOR" width="18">&nbsp;</TD>
        </TR><TR>
          <TD bgcolor="$POSTBODY_COLOR" width="18" valign="top">&nbsp;</TD>
          <TD bgcolor="$POSTBODY_COLOR"><FONT color="$POSTFONT_COLOR">
            <FONT size="-1">
            $_[POST_HEADER]
            </FONT><HR>
            <!------ Contents ------>
            $_[POST_CONTENTS]$MemberFooter
          </FONT></TD>
          <TD bgcolor="$POSTBODY_COLOR" width="18" valign="top">&nbsp;</TD>
        </TR><TR bgcolor="$POSTFOOT_COLOR">
        <!------ Footer Icons ------>
          <TD width="18">&nbsp;</TD>
          <TD>$FooterIcons</TD>
          <TD width="18">&nbsp;</TD>
        </TR>$PostSpace
      </TABLE></TD></TR>

TOPIC_POST_HTML
  print "    </TABLE>\n" if($LastPost);
}

1;