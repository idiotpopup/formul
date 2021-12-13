##################################################################################################
##                                                                                              ##
##  >> Member Display <<                                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_member.pl'} = 'Release 1.6';

LoadSupport('db_members');
LoadSupport('html_fields');
LoadSupport('html_members');
LoadSupport('xbbc_convert');

use Time::Zones($LANGUAGE);


##################################################################################################
## Examine parameters

my $Member     = (param('member') || '');

# Because dbGetMemberInfo also allows guests.
Action_Error($MSG[MEMBER_NOTEXIST]) unless dbMemberExist($Member);

my @MemberInfo = dbGetMemberInfo($Member, 1);


if($XForumUser ne '')
{
  LoadSupport('check_security');
  ValidateMemberCookie();
}



##################################################################################################
## Show member

sub Show_Member ()
{
  # Get additional information
  my $Footer = dbGetMemberFooter($Member);


  # JavaScript to make the confirm() dialogs, using a hidden input-form
  # to do some actions from this document.
  my $MEMBER_JS = <<MEMBER_JS;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      function DeleteMember()
      {
        if(confirm("$MSG[DELMEMBER_CONFIRM]"))
        {
          // We use a hidden form to make the POST request.
          document.placeholder.elements['action'].value = 'delmember';
          document.placeholder.submit();
        }
        return false;
      }
    // --></SCRIPT>
MEMBER_JS


  # HTML
  print_header;
  print_header_HTML("$MSG[SUBTITLE_MEMBER] '$MemberInfo[DB_MEMBER_NAME]'", "$MSG[SUBTITLE_MEMBER] '$MemberInfo[DB_MEMBER_NAME]'", undef, $MEMBER_JS);


  # If we have the member info
  if ($MemberInfo[DB_MEMBER_NAME] ne '')
  {
    my @Buttons;
    push @Buttons, sprint_button_HTML($MSG[BUTTON_EDITMEMBER]   => "$THIS_URL?show=editmember&member=$Member",      'modifypencil',   $MSG[BUTTON_EDITMEMBER_INFO])                             if    ($XForumUser eq $Member || $XForumUser eq 'admin');
    push @Buttons, sprint_button_HTML($MSG[BUTTON_EDITPASSWORD] => "$THIS_URL?show=editpassword&member=$Member",    'modifypassword', $MSG[BUTTON_EDITPASSWORD_INFO])                           if    ($XForumUser eq $Member || $XForumUser eq 'admin');
    push @Buttons, sprint_button_HTML($MSG[BUTTON_COMPOSETO]    => "$THIS_URL?show=compose&action=new&to=$Member",  'msgsend',       "$MSG[BUTTON_COMPOSETO_INFO] $MemberInfo[DB_MEMBER_NAME]") unless($XForumUser eq $Member || $XForumUser eq '');
    push @Buttons, sprint_button_HTML($MSG[BUTTON_LOGFILE]      => "$THIS_URL?show=admin_logfiles&logfile=$Member", 'logfile',        $MSG[BUTTON_LOGFILE_INFO])                                if ($XForumUser eq 'admin');
    push @Buttons, sprint_button_HTML($MSG[BUTTON_DELETE]       => qq[$THIS_URL?show=delmember&member=$Member" onClick="return DeleteMember()], 'deletemember',  $MSG[BUTTON_DELETE_INFO])      if ($XForumUser eq 'admin' && $Member ne 'admin');

    print_toolbar_HTML(@Buttons);
    print_treelevel_HTML(
                          "?show=memberlist"             => $MSG[SUBTITLE_MEMBERLIST],
                          "?show=member&member=$Member"  => "$MSG[SUBTITLE_MEMBER] '$MemberInfo[DB_MEMBER_NAME]'"
                        );
    print_bodystart_HTML();




    # Format Fields:

    # Gender
    my $GenderText                    = (('', "$MSG[MEMBER_GENDER_M] ", "$MSG[MEMBER_GENDER_F] ")[$MemberInfo[DB_MEMBER_GENDER]] || '');
    $MemberInfo[DB_MEMBER_GENDER]     = $GenderText
                                      . member_gender_HTML($MemberInfo[DB_MEMBER_GENDER]);

    # Icon
    #$MemberInfo[DB_MEMBER_ICON]       = member_icon_HTML($MemberInfo[DB_MEMBER_ICON], $MemberInfo[DB_MEMBER_NAME], qq[<FONT size="2">$MemberInfo[DB_MEMBER_ICON]</FONT>])
    $MemberInfo[DB_MEMBER_ICON]       = member_icon_HTML($MemberInfo[DB_MEMBER_ICON], $MemberInfo[DB_MEMBER_NAME], '')
                                     || $MSG[MEMBER_NOICON];



    # Email
    my $EmailAddress                  = ($MemberInfo[DB_MEMBER_PRIVATE] ? " <I>$MSG[MEMBER_EMAIL_HIDE]</I>" : ($MemberInfo[DB_MEMBER_EMAIL] ? " $MemberInfo[DB_MEMBER_EMAIL]" : $MSG[HTML_NA]));
    $MemberInfo[DB_MEMBER_EMAIL]      = member_emailicon_HTML($MemberInfo[DB_MEMBER_EMAIL], $MemberInfo[DB_MEMBER_PRIVATE])
                                      . $EmailAddress;


    # Internet Fields
    my $URLIcon                       = member_websiteicon_HTML($MemberInfo[DB_MEMBER_WEBURL], $MemberInfo[DB_MEMBER_URLTITLE]);

    $MemberInfo[DB_MEMBER_URLTITLE]   = "$URLIcon " . (
                                          $MemberInfo[DB_MEMBER_URLTITLE] || $MemberInfo[DB_MEMBER_WEBURL]
                                        )                                                  unless ($URLIcon eq '');
    $MemberInfo[DB_MEMBER_ICQ]        = member_ICQonline_HTML($MemberInfo[DB_MEMBER_ICQ])
                                      . " $MemberInfo[DB_MEMBER_ICQ] "
                                      . member_ICQadd_HTML($MemberInfo[DB_MEMBER_ICQ],
                                                           $MemberInfo[DB_MEMBER_NAME])    unless ($MemberInfo[DB_MEMBER_ICQ] eq '');
    $MemberInfo[DB_MEMBER_MSN]        = member_MSN_HTML($MemberInfo[DB_MEMBER_MSN])
                                      . " $MemberInfo[DB_MEMBER_MSN]"                      unless ($MemberInfo[DB_MEMBER_MSN] eq '');
    $MemberInfo[DB_MEMBER_AIM]        = member_AIM_HTML($MemberInfo[DB_MEMBER_AIM])
                                      . " $MemberInfo[DB_MEMBER_AIM] "
                                      . member_AIMadd_HTML($MemberInfo[DB_MEMBER_AIM],
                                                           $MemberInfo[DB_MEMBER_NAME])    unless ($MemberInfo[DB_MEMBER_AIM] eq '');
    $MemberInfo[DB_MEMBER_YIM]        = member_YIM_HTML($MemberInfo[DB_MEMBER_YIM])
                                      . " $MemberInfo[DB_MEMBER_YIM] "
                                      . member_YIMonline_HTML($MemberInfo[DB_MEMBER_YIM])  unless ($MemberInfo[DB_MEMBER_YIM] eq '');
    $Footer                           = qq[<FONT size="-1">\n        ]
                                      . FormatFieldXBBC($Footer)
                                      . qq[\n      </FONT>]                                unless ($Footer eq '');


    # Birthdate
    my $BirthDate = '';
    if ($MemberInfo[DB_MEMBER_BIRTHMONTH])
    {
      $BirthDate .= $Time::Text::LongMonths[$MemberInfo[DB_MEMBER_BIRTHMONTH] - 1];
      $BirthDate .= ' '.$MemberInfo[DB_MEMBER_BIRTHDAY] if ($MemberInfo[DB_MEMBER_BIRTHDAY]);
    }
    $BirthDate .= ($BirthDate ? ', ':'') . $MemberInfo[DB_MEMBER_BIRTHYEAR] if($MemberInfo[DB_MEMBER_BIRTHYEAR]);


    # Make a list of general fields
    my @GeneralFields;
    if ($XForumUser ne '')
    {
      # All general fields are filled now, IF the user is not a guest.
      @GeneralFields = (
                         $MSG[MEMBER_LOGINNAME]   => $MemberInfo[ID],
                         $MSG[MEMBER_REGDATE]     => DispTime($MemberInfo[DB_MEMBER_REGDATE]),
                         $MSG[MEMBER_LASTLOGIN]   => DispTime($MemberInfo[DB_MEMBER_LASTLOGINDATE]),
                         $MSG[MEMBER_ONLINE]      => ($MemberOnline{$Member} ? $MSG[CONFIRM_YES] : $MSG[CONFIRM_NO])
                                                   . ($MemberBanned{$Member} ? ", $MSG[MEMBER_ISBANNED]!" : ''),
                         $MSG[MEMBER_GENDER]      => $MemberInfo[DB_MEMBER_GENDER],
                         $MSG[MEMBER_BIRTHDAY]    => $BirthDate,
                         $MSG[MEMBER_COUNTRY]     => $MemberInfo[DB_MEMBER_COUNTRY],
                         $MSG[MEMBER_MOREINFO]    => $MemberInfo[DB_MEMBER_MOREINFO],
                       );

      # Add the timezone aswell IF we have it.
      if ($MemberInfo[DB_MEMBER_TIMEZONE] ne '')
      {
        my $TZTime = (scalar tztime($MemberInfo[DB_MEMBER_TIMEZONE]) || '');
        push @GeneralFields, $MSG[FORUM_TIME]     => DispTime(time),
                             $MSG[MEMBER_TIME]    => $TZTime         unless($TZTime eq '');
      }
    }



    # This is the hidden placeholder used by the JavaScript above.
    # It is used to submit data, without requesting the confirm page
    # from this CGI script first.
    print <<HIDDEN_DELETE_FORM;
    <!---- BEGIN placeholder for JavaScript ---->
    <FORM name="placeholder" method="POST" action="$THIS_URL">
      <INPUT type="hidden" name="action" value="">
      <INPUT type="hidden" name="member" value="$Member">
      <INPUT type="hidden" name="confirmback" value="$THIS_URL?show=memberlist">
      <INPUT type="hidden" name="submit_yes" value="$MSG[CONFIRM_YES]">
    </FORM>
    <!---- END of placeholder ---->

HIDDEN_DELETE_FORM


    # Print all the fields at the screen.
    print qq[    $TABLE_600_HTML\n];
    print_fieldcells_HTML(
                           $MSG[GROUP_FORUMDISP]  => 1,
                           $MSG[MEMBER_DISPNAME]  => $MemberInfo[DB_MEMBER_NAME],
                           $MSG[MEMBER_ICON]      => $MemberInfo[DB_MEMBER_ICON],
                           $MSG[MEMBER_ICONTITLE] => $MemberInfo[DB_MEMBER_ICONTITLE],
                           $MSG[MEMBER_POSTS]     => $MemberInfo[DB_MEMBER_POSTNUM],
                           $MSG[MEMBER_FOOTER]    => $Footer
                         );
    print_fieldcells_HTML(
                           $MSG[GROUP_GENERAL]    => 1,
                           @GeneralFields
                         ) unless(@GeneralFields == 0);
    print_fieldcells_HTML(
                           $MSG[GROUP_INTERNET]   => 0,
                           $MSG[MEMBER_EMAIL]     => $MemberInfo[DB_MEMBER_EMAIL],
                           $MSG[MEMBER_ICQ]       => $MemberInfo[DB_MEMBER_ICQ],
                           $MSG[MEMBER_MSN]       => $MemberInfo[DB_MEMBER_MSN],
                           $MSG[MEMBER_AIM]       => $MemberInfo[DB_MEMBER_AIM],
                           $MSG[MEMBER_YIM]       => $MemberInfo[DB_MEMBER_YIM],
                           $MSG[MEMBER_WEBSITE]   => $MemberInfo[DB_MEMBER_URLTITLE]
                         );
    print qq[    </TABLE>\n];
  }
  else
  {
    # We have no database information about this member....
    print_toolbar_HTML();
    print_bodystart_HTML();
    print "    $MSG[MEMBER_EMPTY]\n";
  }
  print_footer_HTML();
}


1;
