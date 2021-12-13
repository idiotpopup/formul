##################################################################################################
##                                                                                              ##
##  >> Interface HTML Parts <<                                                                  ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'html_interface.pl'} = 'Release 1.6';

use Time::Text($LANGUAGE);


##################################################################################################
## HTML Generators using the template

sub print_treelevel_HTML (@) #(HASH(Parameter, Title))
{
  if($LOCBAR_HIDE || (@_ == 0 && ! $LOCBAR_LASTURL))
  {
    TemplateSetReplace('LOCATION' => '');
    return;
  }

  my $FolderType = (@_ == 0 ? 'open' : 'closed');
  my $TreeLevelHTML = qq[    <B><NOBR>\n] .
                      qq[      <IMG src="$IMAGE_URLPATH/folders/folder_$FolderType.gif" width="16" height="16"> <A href="$THIS_URL">$FORUM_TITLE</A><BR>\n];
  my $ShowLogFolder = 0;

  for (my $I=0; $I<@_; $I = $I + 2)
  {
    my $IsLast = ($I == (@_ - 2));

    if($ShowLogFolder)    { $FolderType = 'logfolder_open' }
    elsif($IsLast)        { $FolderType = 'folder_open'    }
    else                  { $FolderType = 'folder_closed'  }

    my $Param = $_[$I]     || '[ERROR: NO Link]';
    my $Title = $_[$I + 1] || '[ERROR: No Title]';

    $Title = qq[<A href="$THIS_URL$Param">$Title</A>] unless $IsLast && ! $LOCBAR_LASTURL;

    if($Param eq "?show=admin_logfiles") { $ShowLogFolder = 1 }

    $TreeLevelHTML .= qq[      ];
    $TreeLevelHTML .= qq[<IMG src="$IMAGE_URLPATH/treelevel/nonode.gif" width="] . (16 * $I / 2) . qq[" height="16">]     if ($I > 0);
    $TreeLevelHTML .= qq[<IMG src="$IMAGE_URLPATH/treelevel/lastnode.gif" width="16" height="16"> ]
                    . qq[<IMG src="$IMAGE_URLPATH/folders/$FolderType.gif" width="16" height="16"> ]
                    . qq[$Title<BR>\n];
  }
  $TreeLevelHTML .= qq[    </NOBR></B>];

  print_TemplateUntil('LOCATION' => $TreeLevelHTML);
}





sub print_toolbar_HTML (@) #(ARRAY OtherLinks)
{ my $Show   = (param('show') || '');

  # Toolbar
  my $ToolBarHTML = qq[    <TABLE $TABLE_TBRSTYLE><TR>\n];

  # Home, search
  $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_HOME] => $THIS_URL, 'home', $MSG[BUTTON_HOME_INFO]). qq[ </TD>\n]; #unless ($Show eq '');
# $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_SEARCH] => "$THIS_URL?show=search", 'search', $MSG[BUTTON_SEARCH_INFO]). qq[ </TD>\n];

  # Help
  if ($Show ne 'help')
  {
    my $Topic = ($Show || param('action') || '');
    $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_HELP] => "$THIS_URL?show=help" . (($Topic ne '') ? "&help=$Topic" : ''), 'helpbook', $MSG[BUTTON_HELP_INFO]) .qq[ </TD>\n];
  }
  else
  {
    $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_HELP] => "$THIS_URL?show=help&help=help", 'helptip', $MSG[BUTTON_HELP_INFO]) .qq[ </TD>\n] unless((param('help') || '') eq 'help');
  }

  # Profile, Admin, Login, Register Logout
  if (($XForumUser ne '') && ($XForumPass ne ''))
  {
    $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_PROFILE] => "$THIS_URL?show=member&member=$XForumUser", 'profile', "$MSG[BUTTON_PROFILE_INFO] $MSG[BUTTON_PROFILE_YOU]") . qq[ </TD>\n] unless($Show eq 'member' && (param('member') || '') eq $XForumUser);

    if($Show ne 'messages')
    {
      my $Icon = 'inbox';
         $Icon = 'inboxnew' if(dbMemberHasNewMsg($XForumUser));
      $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_MESSAGES] => "$THIS_URL?show=messages&folder=inbox", $Icon, $MSG[BUTTON_MESSAGES_INFO]) . qq[ </TD>\n];
    }
    $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_ADMIN] => "$THIS_URLSEC?show=admin_center", 'admin', $MSG[BUTTON_ADMIN_INFO]) . qq[ </TD>\n] unless ($XForumUser ne 'admin' || $Show eq 'admin_center');
    $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_LOGOUT] => "$THIS_URL?show=logout", 'logout', $MSG[BUTTON_LOGOUT_INFO]) . qq[ </TD>\n];
  }
  else
  {
    $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_REGISTER] => "$THIS_URL?show=addmember", 'register', $MSG[BUTTON_REGISTER_INFO]) . qq[ </TD>\n] unless ($Show eq 'addmember');
    $ToolBarHTML .= qq[      <TD align="center">] . sprint_button_HTML($MSG[BUTTON_LOGIN] => "$THIS_URL?show=login", 'login', $MSG[BUTTON_LOGIN_INFO]) . qq[ </TD>\n] unless ($Show eq 'login');
  }


  # Create the footer toolbar
  my $ToolbarFooterHTML = '';
  if (@_)
  {
    foreach my $Link (@_)
    {
      $ToolbarFooterHTML .= qq[      <TD align="center">$Link </TD>\n];
    }

    # Add it to the current toolbar
#   Not anymore in X-Forum 1.02
#   Now this string is written after the
#    $ToolBarHTML .= $ToolbarFooterHTML;
  }

  # Close toolbar and print
  $ToolBarHTML .= qq[    </TR></TABLE>];


  # Print Toolbar
  if ($ToolbarFooterHTML ne '')
  {
    my $TABLE_TBRSTYLE = $TABLE_TBRSTYLE;
    $TABLE_TBRSTYLE    =~ s/ align="(.+?)"/ align="right"/i;

    $ToolbarFooterHTML = <<FOOTER_TOOLBAR_HTML;
    <TABLE width="90%" border="0" cellspacing="0" cellpadding="0"><TR><TD>
    <TABLE $TABLE_TBRSTYLE><TR>
$ToolbarFooterHTML    </TR></TABLE>
    </TD></TR></TABLE>
FOOTER_TOOLBAR_HTML
    chomp $ToolbarFooterHTML;
  }

  TemplateSetReplace('TOOLBARSMALL' => $ToolbarFooterHTML);
  print_TemplateUntil('TOOLBAR' => $ToolBarHTML);
}






sub sprint_button_HTML ($$$$) #(STRING Link STRING IconName, STRING IconTitle, STRING IconText) >> STRING HTML
{ my ($Text, $Link, $Icon, $Title) = @_;
  return qq[<FONT size="2"><A href="$Link" class="CommandButton"><NOBR><IMG src="$IMAGE_URLPATH/icons/$Icon.gif" width="16" height="16" border="0" alt="$Text" title="$Title" align="top"><FONT color="$BTNT_COLOR">$Text</FONT></NOBR></A></FONT>];
}



sub DispTime ($)
{
  return $MSG[HTML_NA] if(($_[0] || 0) == 0);
  return gmtimestr($_[0]);
}


1;
