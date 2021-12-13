##################################################################################################
##                                                                                              ##
##  >> Modifications to Member Accounts <<                                                      ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_editmember.pl'} = 'Release 1.6';

LoadSupport('db_members');
LoadSupport('check_security');

use Time::Text($LANGUAGE);
use Time::Zones($LANGUAGE);


##################################################################################################
## Check access and examine parameters


# Validate!
ValidateRealMemberAccess();
ValidateMemberCookie();


# Get member info
my $Member     = param('member') || '';
my @MemberInfo = dbGetMemberInfo($Member, 1);


# Do you have access?
ValidateMemberEditAccess($Member);


# Fields used by JavaScript and perl validation functions
my @REQ_FIELDS_EDITMEMBER   = qw(name email);
my @EMAIL_FIELDS_EDITMEMBER = qw(email msn);
my @INT_FIELDS_EDITMEMBER   = qw(icq birthday birthmonth birthyear);




##################################################################################################
## Show Edit Member Dialog

sub Show_EditMemberDialog ()
{
  ValidateLoggedIn();

  LoadSupport('html_fields');


  # Header JavaScript for Icon More Button
  my $JS = <<SHOW_ICON_JAVASCRIPT;
    <SCRIPT language="JavaScript" type="text/javascript"><!-- Hide from js-challenged browsers
      function ShowIcons(InputForm)
      {
        var IconWin = window.open('$THIS_URL?show=iconlist&javascript=1', 'XForumIconWindow', 'scrollbars,resizable,status,left=5,top=30,width=630,height=430');
        IconWin.XForumField = InputForm.icon;
      }
    // --></SCRIPT>
SHOW_ICON_JAVASCRIPT



  # HTML
  CGI::cache(1);
  print_header;
  print_header_HTML("$MSG[SUBTITLE_MEMBER] '$MemberInfo[DB_MEMBER_NAME]'", "$MSG[SUBTITLE_EDITMEMBER] '$MemberInfo[DB_MEMBER_NAME]'", undef, $JS.$FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        "?show=memberlist"                => $MSG[SUBTITLE_MEMBERLIST],
                        "?show=member&member=$Member"     => "$MSG[SUBTITLE_MEMBER] '$MemberInfo[DB_MEMBER_NAME]'",
                        "?show=editmember&member=$Member" => "$MSG[SUBTITLE_EDITMEMBER] '$MemberInfo[DB_MEMBER_NAME]'"
                      );
  print_bodystart_HTML();


  # Have we got a member name?
  if (defined $MemberInfo[DB_MEMBER_NAME])
  {
    # Get additional information
    my $Footer = dbGetMemberFooter($Member);


    # Display text when personal avatars are not allowed
    my $MSG_ICON_SELECT = ($ALLOW_ICONURL ? $MSG[EDITMEMBER_ICON] : $MSG[EDITMEMBER_ICON2]);


    # Find out which checkboxes are checked.
    my @GENDER_CHECKED = ('', '', '');
    $GENDER_CHECKED[$MemberInfo[DB_MEMBER_GENDER]] = ' CHECKED';
    $MemberInfo[DB_MEMBER_PRIVATE] = ($MemberInfo[DB_MEMBER_PRIVATE] ? ' CHECKED' : '');


    # Make the select box for the months
    my @MonthOptions = ('', '');
    foreach my $Month (1..12)
    {
      push @MonthOptions, $Month, $Time::Text::LongMonths[$Month-1];
    }
    my $MonthSel = sprint_selectfield_HTML('birthmonth" class="AutoSize', $MemberInfo[DB_MEMBER_BIRTHMONTH] || -1 => \@MonthOptions);
    undef @MonthOptions;


    # Make the text for the timezone select box
    my $names     = tznames();
    my @TimeZones = tzkeys();
    if($] >= 5.006) { @TimeZones = sort   timezones           @TimeZones; }
    else            { @TimeZones = sort { timezones($a, $b) } @TimeZones; }
       @TimeZones = map {
                      $_ => $names->{$_};
                    }
                    @TimeZones;
    unshift @TimeZones, '' => "";



    # Print more howto select an icon information if you don't have JavaScript
    print <<EDIT_MEMBER;
    <NOSCRIPT>
      $MSG[EDITMEMBER_NOJS]
      $MSG[EDITMEMBER_HOWTO1] <A href="$THIS_URL?show=iconlist&javascript=0" target="_blank">$MSG[EDITMEMBER_HOWTO2]</A>
      $MSG[EDITMEMBER_HOWTO3]
    </NOSCRIPT>
EDIT_MEMBER


    # Print the input fields
    print_inputfields_HTML(
                            $TABLE_600_HTML               => q[name="editmbr"],1,
                            'action'                      => 'editmember',
                            'member'                      => $Member,
                          );

    print_required_TEST(@REQ_FIELDS_EDITMEMBER);
    print_email_TEST(@EMAIL_FIELDS_EDITMEMBER);
    print_int_TEST(@INT_FIELDS_EDITMEMBER);

    print_editcells_HTML(
                          $MSG[GROUP_FORUMDISP]           => 1,
                          $REQ_HTML.$MSG[MEMBER_DISPNAME] => qq[<INPUT type="text" class="CoolText" name="name" size="60" value="$MemberInfo[DB_MEMBER_NAME]">],
                          $MSG_ICON_SELECT                => qq[<INPUT type="text" class="CoolTextIn" name="icon" size="50" value="$MemberInfo[DB_MEMBER_ICON]"><INPUT type="button" class="CoolButtonIn" value="$MSG[ACTION_MORE]" onClick="ShowIcons(this.form);">],
                          $MSG[MEMBER_ICONTITLE]          => qq[<INPUT type="text" class="CoolText" name="title" size="60" value="$MemberInfo[DB_MEMBER_ICONTITLE]">],
                          $MSG[MEMBER_FOOTER]             => qq[<TEXTAREA name="footer" class="small" ROWS="4" COLS="45">$Footer</TEXTAREA>]
                        );
    print_editcells_HTML(
                          $MSG[GROUP_GENERAL]             => 1,
                          $MSG[MEMBER_GENDER]             => qq[<FONT size="1"><INPUT type="radio" class="CoolBox" name="gender" value="0"$GENDER_CHECKED[0]> $MSG[MEMBER_GENDER_X] <INPUT type="radio" class="CoolBox" name="gender" value="1"$GENDER_CHECKED[1]> $MSG[MEMBER_GENDER_M] <INPUT type="radio" class="CoolBox" name="gender" value="2"$GENDER_CHECKED[2]> $MSG[MEMBER_GENDER_F] </FONT>],
                          $MSG[MEMBER_BIRTHDAY]           => qq[$MonthSel - <INPUT type="text" name="birthday" size="2" maxlength="2" value="$MemberInfo[DB_MEMBER_BIRTHDAY]"> - <INPUT type="text" name="birthyear" size="4" maxlength="4" value="$MemberInfo[DB_MEMBER_BIRTHYEAR]"> <FONT size="1">(MMMM dd yyyy)],
                          $MSG[MEMBER_COUNTRY]            => qq[<INPUT type="text" class="CoolText" name="country" size="60" value="$MemberInfo[DB_MEMBER_COUNTRY]">],
                          $MSG[MEMBER_MOREINFO]           => qq[<INPUT type="text" class="CoolText" name="moreinfo" size="60" value="$MemberInfo[DB_MEMBER_MOREINFO]">],
                          $MSG[MEMBER_TIMEZONE]           => sprint_selectfield_HTML('timezone', $MemberInfo[DB_MEMBER_TIMEZONE], \@TimeZones)
                        );
    print_editcells_HTML(
                          $MSG[GROUP_MESSENGING]          => 1,
                          $REQ_HTML.$MSG[MEMBER_EMAIL]    => qq[<INPUT type="text" class="CoolText" name="email" size="60" value="$MemberInfo[DB_MEMBER_EMAIL]">],
                          $MSG[MEMBER_HIDECHECK]          => qq[<INPUT type="checkbox" class="CoolBox" name="private"$MemberInfo[DB_MEMBER_PRIVATE]><FONT size="1"> $MSG[MEMBER_HIDEINFO]</FONT>],
                          $MSG[MEMBER_ICQ]                => qq[<INPUT type="text" class="CoolText" name="icq" size="60" value="$MemberInfo[DB_MEMBER_ICQ]">],
                          $MSG[MEMBER_MSN]                => qq[<INPUT type="text" class="CoolText" name="msn" size="60" value="$MemberInfo[DB_MEMBER_MSN]">],
                          $MSG[MEMBER_AIM]                => qq[<INPUT type="text" class="CoolText" name="aim" size="60" value="$MemberInfo[DB_MEMBER_AIM]">],
                          $MSG[MEMBER_YIM]                => qq[<INPUT type="text" class="CoolText" name="yim" size="60" value="$MemberInfo[DB_MEMBER_YIM]">]
                        );
    print_editcells_HTML(
                          $MSG[GROUP_WEBSITE]             => 1,
                          $MSG[MEMBER_WEBSITE_N]          => qq[<INPUT type="text" class="CoolText" name="websitename" size="60" value="$MemberInfo[DB_MEMBER_URLTITLE]">],
                          $MSG[MEMBER_WEBSITE_U]          => qq[<INPUT type="text" class="CoolText" name="website" size="60" value="$MemberInfo[DB_MEMBER_WEBURL]">]
                        );
    print_buttoncells_HTML(
                            $MSG[ACTION_CHANGE]           => undef,
                            $MSG[ACTION_RESET]            => undef,
                          );
  }
  else
  {
    print "    $MSG[MEMBER_EMPTY]\n"

  }


  # Footer
  print_footer_HTML();
}




sub Action_EditMember ()
{
  LoadSupport('check_fields');
  LoadModule('HTML::EscapeASCII;');


  # Get Field Values
  my $Name         = (param('name')         || '');
  my $Email        = (param('email')        || '');
  my $Private      = (param('private')    ? 1 : 0);
  my $Gender       = (param('gender')       ||  0);
  my $TimeZone     = (param('timezone')     || '');
  my $Country      = (param('country')      || '');
  my $BirthDay     = (param('birthday')     || '');
  my $BirthMonth   = (param('birthmonth')   || '');
  my $BirthYear    = (param('birthyear')    || '');
  my $ICQ          = (param('icq')          || '');
  my $MSN          = (param('msn')          || '');
  my $AIM          = (param('aim')          || '');
  my $YIM          = (param('yim')          || '');
  my $WebsiteName  = (param('websitename')  || '');
  my $Website      = (param('website')      || '');
  my $Icon         = (param('icon')         || '');
  my $IconTitle    = (param('title')        || '');
  my $MoreInfo     = (param('moreinfo')     || '');
  my $Footer       = (param('footer')       || '');



  # Preform Checks
  ValidateRequiredFields(@REQ_FIELDS_EDITMEMBER);
  ValidateEmailFields(@EMAIL_FIELDS_EDITMEMBER);
  ValidateNumberFields(@INT_FIELDS_EDITMEMBER);

  # Some fields of the birthday are suddently required, if you provide more detailled info.
  ValidateRequired($BirthMonth) if($BirthDay);
  ValidateRequired($BirthYear)  if($BirthMonth);

  # Same for website name / URL
  ValidateURL($Website, $WebsiteName) if ($Website);

  if(! $ALLOW_ICONURL
  &&(  $Icon =~ m[/] || IsURL($Icon)))
  {
    Action_Error($MSG[EDITMEMBER_NOURL], 1);
  }

  # We require some login in the year / month
  my $Year = (gmtime())[5] + 1900;
  ValidateRange($BirthMonth, $MSG[MEMBER_BIRTHDAY], 1 => 12)              if($BirthMonth);
  ValidateRange($BirthYear , $MSG[MEMBER_BIRTHDAY], $Year - 200 => $Year) if($BirthYear); # Logic year required


  # Cool check for the birthday.
  # We check what kind of value the day can have, based on the month and leap years.
  if($BirthDay)
  {
    $BirthDay       = int($BirthDay); # Removes the pre-zero's aswell
    my $MonthLength = $MONTHLENGTH[$BirthMonth - 1];

    if( ($BirthMonth       == 2)    # Februari
    &&  ($BirthYear % 4    == 0)    # Year can be divided by 4
    &&  ($BirthYear % 100  == 0)    # If it's a begin of century (eg. 1900)
         ? ($BirthYear % 400 == 0)  # it must also be divisable by 400
         : (1)                      # Otherwise, that doesn't matter (returns true)
      ) { $MonthLength++ }

    ValidateRange($BirthDay, $MSG[MEMBER_BIRTHDAY], 1 => $MonthLength);
  }


  # Make the data structure
  $MemberInfo[DB_MEMBER_NAME]       = $Name;
  $MemberInfo[DB_MEMBER_EMAIL]      = $Email;
  $MemberInfo[DB_MEMBER_PRIVATE]    = $Private;
  $MemberInfo[DB_MEMBER_GENDER]     = $Gender;
  $MemberInfo[DB_MEMBER_COUNTRY]    = $Country;
  $MemberInfo[DB_MEMBER_TIMEZONE]   = $TimeZone;
  $MemberInfo[DB_MEMBER_BIRTHDAY]   = $BirthDay;
  $MemberInfo[DB_MEMBER_BIRTHMONTH] = $BirthMonth;
  $MemberInfo[DB_MEMBER_BIRTHYEAR]  = $BirthYear;
  $MemberInfo[DB_MEMBER_WEBURL]     = $Website;
  $MemberInfo[DB_MEMBER_URLTITLE]   = $WebsiteName;
  $MemberInfo[DB_MEMBER_ICON]       = $Icon;
  $MemberInfo[DB_MEMBER_ICONTITLE]  = $IconTitle;
  $MemberInfo[DB_MEMBER_ICQ]        = $ICQ;
  $MemberInfo[DB_MEMBER_MSN]        = $MSN;
  $MemberInfo[DB_MEMBER_AIM]        = $AIM;
  $MemberInfo[DB_MEMBER_YIM]        = $YIM;
  $MemberInfo[DB_MEMBER_MOREINFO]   = $MoreInfo;

  # Save it into the file...
  FormatFieldHTML(@MemberInfo);
  dbSaveMemberInfo(@MemberInfo);
  dbSaveMemberFooter($Member => $Footer);


  # Redirect
  print redirect("$THIS_URL?show=member&member=$Member");
  exit;
}


1;
