##################################################################################################
##                                                                                              ##
##  >> Modifications to Member Accounts <<                                                      ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

use strict;

$VERSIONS{'dlg_addmember.pl'} = 'Release 1.4';

LoadSupport('db_members');


# Fields used by JavaScript and X-Forum validation functions
my @REQ_FIELDS_SIGNUP   = qw(name email member password password2);
my @EMAIL_FIELDS_SIGNUP = qw(email);


my $CAN_EMAIL = ($MAIL_TYPE && $WEBMASTER_MAIL);


##################################################################################################
## Show Add Member Dialog

sub Show_AddMemberDialog
{
  LoadSupport('html_members');
  LoadSupport('html_fields');


  # HTML Header
  CGI::cache(1);
  print_header;
  print_header_HTML($MSG[SUBTITLE_REGISTER], $MSG[SUBTITLE_REGISTER], undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML("?show=addmember"=>$MSG[SUBTITLE_REGISTER]);
  print_bodystart_HTML();


  # Input fields
  print_inputfields_HTML(
                          $TABLE_600_HTML               => undef,1,
                          'action'                      => 'addmember',
                        );
  print_required_TEST(@REQ_FIELDS_SIGNUP);
  print_email_TEST(@EMAIL_FIELDS_SIGNUP);


  # Not al of these fields are displayed every time
  my @Personal_HTML  = (
                         $REQ_HTML.$MSG[MEMBER_DISPNAME] => qq[<INPUT type="text" class="CoolText" name="name" size="60">],
                         $REQ_HTML.$MSG[MEMBER_EMAIL]    => qq[<INPUT type="text" class="CoolText" name="email" size="60">],
                         $MSG[MEMBER_HIDECHECK]          => qq[<INPUT type="checkbox" class="CoolBox" name="private"><FONT size="1"> $MSG[MEMBER_HIDEINFO]</FONT>]
                       );
  push @Personal_HTML,   $MSG[MEMBER_WELCOME]            => qq[<INPUT type="checkbox" class="CoolBox" name="welcome" CHECKED><FONT size="1"> $MSG[MEMBER_WELCOMEINFO]</FONT>] if($CAN_EMAIL);


  print_editcells_HTML(
                        $MSG[GROUP_PERSONAL]            => 1,
                        @Personal_HTML
                      );
  print_editcells_HTML(
                        $MSG[GROUP_ACCOUNTINFO]         => 1,
                        $REQ_HTML.$MSG[REGISTER_LOGIN]  => qq[<INPUT type="text" class="CoolText" name="member" size="60">],
                        $REQ_HTML.$MSG[REGISTER_PASS1]  => qq[<INPUT type="password" class="CoolText" name="password"  size="60">],
                        $REQ_HTML.$MSG[REGISTER_PASS2]  => qq[<INPUT type="password" class="CoolText" name="password2" size="60">]
                      );


  print_editcells_HTML(
                        $MSG[GROUP_LICENCE],            => 0,
                      );




  #### WARNING: NO-STANDARD-FUNCTION-USE; This won't be updated when &print_editcells_HTML() is updated ####
  print <<LICENCE_HTML;
        <TR><TD colspan="2" width="600"><FONT size="-1">
              $MSG[REGISTER_LICENCE1]
              <P>$MSG[REGISTER_LICENCE2]
              <P>$MSG[REGISTER_LICENCE3]
              <P>$MSG[REGISTER_LICENCE4]
              <P>$MSG[REGISTER_LICENCE5]
              <P>$MSG[REGISTER_LICENCE6]
            </FONT></TD></TR>
LICENCE_HTML

  print_editcells_HTML(
                        undef                          , 1,
                        $REQ_HTML.$MSG[REGISTER_LICENCE] => qq[<FONT size="2"><NOBR><INPUT type="radio" class="CoolBox" name="agree" value="1"> $MSG[ACTION_AGREE]</NOBR> <NOBR><INPUT type="radio" class="CoolBox" name="agree" value="0" CHECKED> $MSG[ACTION_DECLINE]</NOBR></FONT>],
                      );
  print_buttoncells_HTML(
                          $MSG[ACTION_REGISTER]         => undef,
                          $MSG[ACTION_RESET]            => undef,
                        );
  print_footer_HTML();
}




sub Action_AddMember
{
  LoadSupport('check_fields');
  LoadSupport('dlg_loginout');


  # Get Field Values
  my $Name      = (param('name')          || '');
  my $Email     = (param('email')         || '');
  my $Private   = (param('private')     ? 1 : 0);
  my $Welcome   = (param('welcome')     ? 1 : 0);
  my $Member    = (param('member')        || '');
  my $Password1 = (param('password')      || '');
  my $Password2 = (param('password2')     || '');
  my $Agree     = (param('agree')       ? 1 : 0);


  # Preform Checks
  ValidateRequiredFields(@REQ_FIELDS_SIGNUP);
  ValidateEmailFields(@EMAIL_FIELDS_SIGNUP);
  ValidateNewPassword($Password1, $Password2);
  if (! $Agree) { Action_Error($MSG[REGISTER_NOTAGREE]); }


  # Check for Unique
  $Member = NameGen($Member);
  if (dbMemberExist($Member,1))    { Action_Error("$MSG[REGISTER_EXISTS] <BR>\n    $MSG[REGISTER_CHOOSE]$RETURN_HTML"); }
  if($Member =~ m/^[^a-z]/)        { Action_Error("$MSG[REGISTER_IDCHAR] <BR>\n    $MSG[REGISTER_CHOOSE]$RETURN_HTML"); }


  # Check for admin account name (to become admin, your crypted password needs to be $ADMIN_PASS)
  if ($Member eq 'admin')
  {
    LoadSupport('check_security');
    ValidatePassword($Member, $Password1, 'admin', $ADMIN_PASS, 0);
  }


  # Make the member and log
  dbMakeMember($Member => $Name, $Password1, $Email, $Private);
  print_log("ADDUSER", '', "NAME=$Name ID=$Member MAIL=$Email PRIVATE=$Private");


  # Send a welcome e-mail???
  if($Welcome && $CAN_EMAIL)
  {
    my $Message = <<EMAIL_MESSAGE;
to: $Name<$Email>
from: Webmaster<$WEBMASTER_MAIL>
subject: $FORUM_TITLE $MSG[FORUM_WELCOME1]
X-Mailer: INet::Mailer Script for Perl

$MSG[FORUM_WELCOME2]
$MSG[FORUM_WELCOME3]

$MSG[LOGIN_ACCOUNT]\t: $Member
$MSG[LOGIN_PASSWORD]\t: $Password2

$MSG[FORUM_WELCOME4]: $THIS_URL?show=login
$MSG[FORUM_WELCOME5] ($WEBMASTER_MAIL)
EMAIL_MESSAGE
    SendForumMail($Email, $Message, $Member, $Name);
  }

  # Redirect
  Action_Login("$THIS_URL?show=editmember&member=$Member");
}

1;
