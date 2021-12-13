##################################################################################################
##                                                                                              ##
##  >> Changing Member Passwords <<                                                             ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_editpassword.pl'} = 'Release 1.6';

LoadSupport('db_members');
LoadSupport('check_security');

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
my @REQ_FIELDS_EDITPASSWORD = qw(password0 password password2);



##################################################################################################
## Show Edit Member Dialog

sub Show_EditPasswordDialog ()
{
  ValidateLoggedIn();

  LoadSupport('html_fields');


  # HTML
  CGI::cache(1);
  print_header;
  print_header_HTML("$MSG[SUBTITLE_EDITPASSWORD] '$MemberInfo[DB_MEMBER_NAME]'", "$MSG[SUBTITLE_EDITPASSWORD] '$MemberInfo[DB_MEMBER_NAME]'", undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        "?show=memberlist"                  => $MSG[SUBTITLE_MEMBERLIST],
                        "?show=member&member=$Member"       => "$MSG[SUBTITLE_MEMBER] '$MemberInfo[DB_MEMBER_NAME]'",
                        "?show=editpassword&member=$Member" => "$MSG[SUBTITLE_EDITPASSWORD] '$MemberInfo[DB_MEMBER_NAME]'"
                      );
  print_bodystart_HTML();


  # Have we got a member name?
  if (defined $MemberInfo[DB_MEMBER_NAME])
  {
    my $MSG_PASSWORD = ($XForumUser eq 'admin' ? $MSG[PASSWORD_ADMIN] : $MSG[PASSWORD_OLD]);

    # Print the input fields
    print qq[    $MSG[EDITPASSWORD_LOGIN]\n];
    print_inputfields_HTML(
                            $TABLE_600_HTML               => undef,1,
                            'action'                      => 'editpassword',
                            'member'                      => $Member,
                          );

    print_required_TEST(@REQ_FIELDS_EDITPASSWORD);

    print_editcells_HTML(
                          $MSG[GROUP_EDITPASSWORD]        => 1,
                          $REQ_HTML.$MSG_PASSWORD         => qq[<INPUT type="password" class="CoolText" name="password0" size="60">],
                          $REQ_HTML.$MSG[REGISTER_PASS1]  => qq[<INPUT type="password" class="CoolText" name="password"  size="60">],
                          $REQ_HTML.$MSG[REGISTER_PASS2]  => qq[<INPUT type="password" class="CoolText" name="password2" size="60">],
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




sub Action_EditPassword ()
{
  LoadSupport('check_fields');
  LoadSupport('dlg_loginout');


  # Get Field Values
  my $Password0    = (param('password0') || '');
  my $Password1    = (param('password')  || '');  # For the Action_Login
  my $Password2    = (param('password2') || '');


  # Password (current/admin) check
  if($XForumUser eq 'admin') { ValidatePassword($XForumUser, $Password0, 'admin', $ADMIN_PASS); }
  else                       { ValidatePassword($Member, $Password0, $XForumUser, $XForumPass); }


  # Preform Checks
  ValidateRequiredFields(@REQ_FIELDS_EDITPASSWORD);
  ValidateNewPassword($Password1, $Password2);


  # Make the data structure
  $MemberInfo[DB_MEMBER_PASSWORD] = crypt_pass($Password1);


  if($Member eq 'admin')
  {
    my $newpass =
    my $Error = <<ERROR;
    $MSG[EDITPASSWORD_NOADMIN]

    <BLOCKQUOTE><CODE>\$ADMIN_PASS = q[$MemberInfo[DB_MEMBER_PASSWORD]];</CODE></BLOCKQUOTE>
ERROR
    Action_Error($Error, 1);
  }


  # Save it into the file...
  dbSaveMemberInfo(@MemberInfo);


  # Redirect
  if($XForumUser eq 'admin')
  {
    # Administrator Redirect
    print redirect("$THIS_URL?show=member&member=$Member");
    exit;
  }
  else
  {
    # You need a new cookie
    Action_Login("$THIS_URL?show=member&member=$Member");
  }
}


1;
