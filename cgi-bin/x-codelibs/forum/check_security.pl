##################################################################################################
##                                                                                              ##
##  >> Input Field Checking <<                                                                  ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'check_security.pl'} = 'Release 1.6';


##################################################################################################
## Security Checks

# Check whether the login cookie is OK (when only one arg passed),
# or check input fields.
# You can also force that the member should a specific one.

sub ValidateMemberAccess ($;$$) #(STRING Member[, STRING PasswordParam][, STRING RealMember])
{ my ($Member, $Password, $RealMember) = @_;

  # Get member info
  LoadSupport('db_members');

  $RealMember    = ($RealMember || $Member);
  my @MemberInfo = dbGetMemberInfo($RealMember);

  # Validate
  if (defined $Password)
  {
    ValidatePassword($Member, $Password, $RealMember, $MemberInfo[DB_MEMBER_PASSWORD]);
  }
  else
  {
    ValidatePassword($XForumUser, $XForumPass, $RealMember, $MemberInfo[DB_MEMBER_PASSWORD], 1);
  }
}

sub ValidateRealMemberAccess ()
{
  if($XForumUser eq '') { Action_Error($MSG[GUEST_NOACCESS]) }
}

sub ValidateLoggedIn ()
{
  if($XForumUser eq '') { Action_Error($MSG[ERROR_LOGIN]) }
}

sub ValidateMemberCookie (;$)
{ my ($RealMember) = @_;

  LoadSupport('db_members');

  $RealMember      = ($RealMember || $XForumUser);
  if($XForumUser eq '') { Action_Error($MSG[ERROR_LOGIN]) }

  my @MemberInfo   = dbGetMemberInfo($RealMember);
  ValidatePassword($XForumUser, $XForumPass, $RealMember, $MemberInfo[DB_MEMBER_PASSWORD], 1);
}


# Check whether user is logged in as admin
sub ValidateAdminAccess ()
{
  if ($XForumUser ne 'admin') { Action_Error($MSG[ERROR_ADMINLOGIN], 1);}
  ValidatePassword($XForumUser, $XForumPass, 'admin', $ADMIN_PASS, 1);
}


# Test which groups or moderators are allowed to read the subject
sub ValidateSubjectAccess ($$)
{ my ($AllowGroups, $AllowModerators) = @_;

  if(index($AllowGroups, 'everyone') != -1) { return }
  if($XForumUser eq '')                     { Action_Error($MSG[MEMBER_NOACCESS], 1) }
  if ($XForumUser eq 'admin')               { return }

  foreach my $Moderator (split(/,/, $AllowModerators))
  {
    return if ($XForumUser eq $Moderator);
  }

  foreach my $Group (split(/,/, $AllowGroups))
  {
    my @GroupInfo = dbGetGroupInfo($Group);
    if(! dbGroupInvalid($Group, @GroupInfo))
    {
      for(my $I = DB_GROUP_MEMBERS; $I < @GroupInfo; $I++)
      {
        return if ($GroupInfo[$I] eq $XForumUser);
      }
    }
  }

  Action_Error($MSG[MEMBER_NOACCESS], 1);
}



# Test which moderators can edit the subject
sub ValidateSubjectEditAccess
{ my($Moderators) = @_;
  if    ($XForumUser eq 'admin')                         { ValidateAdminAccess(); }
  elsif (dbIsSubjectModerator($Moderators, $XForumUser)) { ValidateMemberCookie(); }
  else { Action_Error($MSG[MEMBER_NOACCESS].$RETURN_HTML, 1); }
}


sub ValidatePostEditAccess
{ my($Moderators, $Poster, $Locked) = @_;
  if    ($XForumUser eq 'admin')                         { ValidateAdminAccess(); }
  elsif (dbIsSubjectModerator($Moderators, $XForumUser)) { ValidateMemberCookie(); }
  elsif ($Poster && $XForumUser eq $Poster)
  {
    Action_Error($MSG[TOPIC_ISLOCKED]) if ($Locked);
    ValidateMemberCookie();
  }
  else { Action_Error($MSG[MEMBER_NOACCESS].$RETURN_HTML, 1);}
}

sub ValidateMemberEditAccess
{ my($Member) = @_;
  if    ($XForumUser eq 'admin') { ValidateAdminAccess(); }
  elsif ($XForumUser eq $Member) { ValidateMemberAccess($XForumUser); }
  else  { Action_Error($MSG[EDITMEMBER_LOGIN].$RETURN_HTML, 1); }
}



# Check password: Members and Passwords need to be equal.
# If password guess is already crypted, the last arg should be true.
sub ValidatePassword ($$$$;$) #(STRING UserGuess, STRING PasswordGuess, STRING RealName, STRING RealCryptedPassword[, BOOLEAN PassGuessIsCrypted])
{ my ($NameGuess, $PasswordGuess, $Name, $Password, $IsCrypted) = @_;

  if(($PasswordGuess || '') ne '')
  {
    if (defined $Name && ($NameGuess || '') ne '')
    {
      ValidateBanMember($NameGuess);

      my $CryptedPassword = ($IsCrypted ? $PasswordGuess : crypt_pass($PasswordGuess || '', $Password));

      if($NameGuess eq 'admin')
      {
        my $Action = param('action') || '';
        return if($Action eq 'addmember');
        return if($CryptedPassword eq $ADMIN_PASS && dbMemberExist('admin'));
      }
      elsif($NameGuess eq $Name)
      {
        return if ($CryptedPassword eq $Password);
      }
    }


    # Print information in log and show error
    # Don't save the PASSXS error in a user's log file; it could be someone else trying to hack in.
    $Name  = ($Name  || '<no name>');
    print_log("PASSXS", '', "NAME=$Name FROM=" . (referer() || '<NO REFERER>') . " USERGUESS=$NameGuess");
  }
  Action_Error($MSG[ERROR_PASSWORD].$RETURN_HTML, 1);
}


1;
