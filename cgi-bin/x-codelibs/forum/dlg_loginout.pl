##################################################################################################
##                                                                                              ##
##  >> Login / Logout Support <<                                                                ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_loginout.pl'} = 'Release 1.6';


my @REQ_FIELDS_LOGIN = qw(member password);


# If cookies can be assigned in a redirect header... set to true.
# I can't get it working.
sub FAST_LOGIN(){ 0 }



##################################################################################################
## Login Dialog

sub Show_LoginDialog ()
{
  LoadSupport('html_fields');


  # Determine where we should redirect you to if you're logged in
  my $NextPage = param('nextpage');
  if(! $NextPage)
  {
    $NextPage = (referer || $THIS_URL);
    if($NextPage !~ m/^\Q$THIS_URL/) { $NextPage = $THIS_URL; }
  }


  # Remember me option
  my @RememberMe = ();
  if($CAN_KEEPLOGIN)
  {
    @RememberMe = ($MSG[LOGIN_REMEMBER]  => qq[<INPUT type="checkbox" class="CoolBox" name="remember"><FONT size="1"> $MSG[LOGIN_REMEMBER_INFO]]);
  }


  # Print HTML header
  CGI::cache(1);
  print_header;
  print_header_HTML($MSG[SUBTITLE_LOGIN], $MSG[SUBTITLE_LOGIN], undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML('?show=login'  =>  $MSG[SUBTITLE_LOGIN]);
  print_bodystart_HTML();


  # Display some tips
  print <<SHOW_LOGIN;
    $MSG[LOGIN_REGTIP] <BR>
    $MSG[LOGIN_EXITTIP]
    $MSG[MEMBER_ABUSE] <BR>
SHOW_LOGIN


  # The input fields
  print_inputfields_HTML(
                          $TABLE_600_HTML               => undef,1,
                          'action'                      => 'login',
                          'nextpage'                    => $NextPage,
                        );
  print_required_TEST(@REQ_FIELDS_LOGIN);
  print_editcells_HTML(
                        $MSG[GROUP_ACCOUNTINFO]         => 1,
                        $REQ_HTML.$MSG[LOGIN_ACCOUNT]   => qq[<INPUT type="text" class="CoolText" name="member" size="60">],
                        $REQ_HTML.$MSG[LOGIN_PASSWORD]  => qq[<INPUT type="password" class="CoolText" name="password" size="60">],
                                  @RememberMe,
                      );
  print_buttoncells_HTML(
                          $MSG[ACTION_LOGIN]            => undef,
                          $MSG[ACTION_RESET]            => undef,
                        );

  # Footer
  print_footer_HTML();
}





sub Action_Login (;$) #([STRING NextPage])
{
  LoadSupport('html_template'); # This is a dialog form a HTTP POST dialog
  LoadSupport('html_interface');
  LoadSupport('check_fields');
  LoadSupport('check_security');
  LoadSupport('db_members');



  # Get field values
  my $Member   = NameGen(param('member')   || '');
  my $Password =        (param('password') || '');
  my $Remember =        (param('remember') ? 1 : 0) && $CAN_KEEPLOGIN;
  ValidateRequiredFields(@REQ_FIELDS_LOGIN);


  # Get Member Info
  my @MemberInfo = dbGetMemberInfo($Member, 0, 1);


  ##!! SHA1 IMPLEMENTATION !!##

  # Test it.
#  if(! is_sha1($MemberInfo[DB_MEMBER_PASSWORD])
#  && ! dbMemberInvalid($Member, @MemberInfo))
#  {
#    # Convert the password to...
#    # SHA1 ;-)
#    my $OldCrypted = crypt($Password, $MemberInfo[DB_MEMBER_PASSWORD]);
#    ValidatePassword($Member, $OldCrypted, $MemberInfo[ID], $MemberInfo[DB_MEMBER_PASSWORD], 1);
#
#    $MemberInfo[DB_MEMBER_PASSWORD] = crypt_pass($Password);
#    dbSaveMemberInfo(@MemberInfo);
#  }
#  else
#  {
    # Just Validate it.
    ValidatePassword($Member, $Password, $MemberInfo[ID], $MemberInfo[DB_MEMBER_PASSWORD]);
#  }


  # Determine what the next page should be, based on received parameters.
  my $NextPage = ($_[0] || param('nextpage') || '');
  if (! $NextPage) { $NextPage = $1 if (query_string =~ m/nextpage=(.*)&?/); } # Get literally from the QUERY_STRING
  else             { $NextPage = escape($NextPage); }                          # Escape the retreived parameter


  # Set cookie
  my $UserCookie = MakeMemberUserCookie($Member, $Remember);
  my $PassCookie = MakeMemberPassCookie($MemberInfo[DB_MEMBER_PASSWORD], $Remember);


  # Next page: login test
  my $TestLocation = "$THIS_URL?show=logintest&nextpage=$NextPage";

  if(FAST_LOGIN)
  {
    # This is not accepted for some strange reason,.
    print redirect(-url => $TestLocation, -cookie => [$UserCookie, $PassCookie]);
    exit;
  }
  else
  {
    # This works perfectly.
    print_header(-cookie => [$UserCookie, $PassCookie]);

    # Print redirection page; cookie won't be accepted in redirect header.
    # This page redirects the browser to a test where the cookie is checked for existance.
    print_header_HTML($MSG[SUBTITLE_LOGIN], $MSG[SUBTITLE_LOGIN2], "0; url=$TestLocation");
    print_bodystart_HTML();
    print <<LOGIN_HTML;
    $MSG[LOGIN_WAIT] <BR>
    <P>
    $MSG[LOGIN_TEST] <BR>
    $MSG[LOGIN_ALT1] <A href="$TestLocation">$MSG[LOGIN_ALT2]</A> $MSG[LOGIN_ALT3]
LOGIN_HTML
    print_footer_HTML();
  }
}




sub Show_LoginTest ()
{
  # Get the parameters
  my $NextPage = (param('nextpage') || $THIS_URL);


  # Did the browser accept the cookie, and is it stored correctly.
  if ($XForumUser eq '' || $XForumPass eq '')
  {
    Action_Error($MSG[LOGIN_FAIL]);
  }


  # Save the last login date to the member database file
  my @MemberInfo = dbGetMemberInfo($XForumUser, 1);

  # Save last succesful login date.
  $MemberInfo[DB_MEMBER_LASTLOGINDATE] = SaveTime();
  dbSaveMemberInfo(@MemberInfo);


  # Redirect
  print redirect($NextPage);
  exit;
}




##################################################################################################
## Logout dialog

sub Show_LogoutDialog ()
{
  # More interface is required this time.
  LoadSupport('html_interface');


  # There is no reason to update visitors.log;
  # That's done when we enter the next page...

  # Set cookie to empty cookie
  my $XForumUser = MakeMemberUserCookie('');
  my $XForumPass = MakeMemberPassCookie('');
  print_header(-cookie => [$XForumUser,$XForumPass]);

  # Print redirection page; cookie won't be accepted in redirect header.
  print_header_HTML($MSG[SUBTITLE_LOGOUT], $MSG[SUBTITLE_LOGOUT2], "0; url=$THIS_URL");
  print_bodystart_HTML();

  # Please wait while loggin out...
  print <<LOGOUT_DIALOG;
    $MSG[LOGOUT_WAIT]
    <P>
    <A href="$THIS_URL">$MSG[LOGOUT_RETURN]</A>.
LOGOUT_DIALOG

# Footer
  print_footer_HTML();
}




##################################################################################################
## Cookie Stuff

sub MakeMemberUserCookie ($;$) #(STRING Member) >> OBJECT Cookie
{ my ($Member, $Remember) = @_;
  my $THIS_URLPATH = ($FORUM_ISOLATED ? $THIS_URLPATH : '/');
  return cookie(-name => 'XForumUser', -value => 'log:out', -path => $THIS_URLPATH, -expires => 'Thu, 01-Jan-1970 00:00:01 GMT') if (($Member ||'') eq '');
  return cookie(-name => 'XForumUser', -value => $Member,   -path => $THIS_URLPATH, -expires => '+1M') if $Remember;
  return cookie(-name => 'XForumUser', -value => $Member,   -path => $THIS_URLPATH);
}

sub MakeMemberPassCookie ($;$) #(STRING CryptedPassword) >> OBJECT Cookie
{ my ($CryptedPassword, $Remember) = @_;
  my $THIS_URLPATH = ($FORUM_ISOLATED ? $THIS_URLPATH : '/');
  return cookie(-name => 'XForumPass', -value => 'logout',         -path => $THIS_URLPATH, -expires => 'Thu, 01-Jan-1970 00:00:01 GMT') if (($CryptedPassword ||'') eq '');
  return cookie(-name => 'XForumPass', -value => $CryptedPassword, -path => $THIS_URLPATH, -expires => '+1M') if $Remember;
  return cookie(-name => 'XForumPass', -value => $CryptedPassword, -path => $THIS_URLPATH);
}

1;