##################################################################################################
##                                                                                              ##
##  >> Delete Topics <<                                                                         ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_delmember.pl'} = 'Release 1.6';

LoadSupport('check_security');
LoadSupport('db_members');
LoadSupport('dlg_confirm');

ValidateAdminAccess();


#################################################################################################
## Check access and examine parameters

my $Member      = (param('member') || '');
my @MemberInfo  = dbGetMemberInfo($Member, 1);




#################################################################################################
## Show Add Topic

sub Show_DeleteMemberDialog ()
{
  # Show the confirmation dialog
  Show_ConfirmDialog($MSG[SUBTITLE_DELMEMBER], $MSG[DELMEMBER_CONFIRM]);
}




sub Action_DeleteMember ()
{
  # Test for the confirmation of the previous dialog
  Action_Confirm();

  LoadSupport('check_fields');

  dbDelMember($Member);

  # Log print and redirect
  print_log("DELMEMBER", undef, "MEMBER=$Member NAME=$MemberInfo[DB_MEMBER_NAME] EMAIL=$MemberInfo[DB_MEMBER_EMAIL] PRIVATE=$MemberInfo[DB_MEMBER_PRIVATE]");
  print redirect("$THIS_URL?show=memberlist&sort=postnum&reverse=1");
  exit;
}

1;
