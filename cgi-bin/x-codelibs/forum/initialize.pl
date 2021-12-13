##################################################################################################
##                                                                                              ##
##  >> Initializer <<                                                                           ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;


$VERSIONS{'initialize.pl'} = 'Release 1.6';

##################################################################################################
## Pre-define some subroutine names

sub print_header;




##################################################################################################
## Initialized in the BEGIN block

sub InitializeBegin ()
{
  # Loaded in the BEGIN block
  InitializeVariables();
  LoadSettings();
# CheckCryptAlgorithm();  # I wanted to introduce SHA-1 to X-Forum 1.3
  LoadDefaults();
  LoadConstants();
  LoadLanguage();
  ActivateErrorTrap();
}



##################################################################################################
## Initialized after the BEGIN block

sub InitializeRest ()
{
  # Can only run when some codes in the BEGIN block have been loaded
  CheckMaintainceMode();
  CheckAdminEntering();
  LoadBanSettings();
  ValidateBanIP($XForumUserIP);
  ValidateBanMember($XForumUser);
}



##################################################################################################
## Set some variables

sub InitializeVariables
{
  $|              = 1;  # Automatic buffer flushing

  my $Show        = param('show') || '';
  $XForumUser     = (cookie('XForumUser') || '');
  $XForumPass     = (cookie('XForumPass') || '');
  $XForumUserIP   = ClientIP();

  $MemberOnline{$XForumUser} = 1 unless($XForumUser eq '');                       # Other members are detected when html_template.pl is loaded.

  $CGI::DISABLE_UPLOADS = 1;                                                      # no uploads
  $LINEBREAK_PATTERN    = "\015\012|\015|\012|\r";                                # All kinds of line breaks to be converted TO \n

                      # J  F  M  A  M  J  J  A  S  O  N  D #
  @MONTHLENGTH    = qw( 31 28 31 30 31 30 31 31 30 31 30 31);

  if($Show eq 'logout')
  {
    $XForumUser = '';
    $XForumPass = '';
  }

  ReInitSec();
}

sub ReInitSec
{
  $THIS_URLSEC = ($SEC_CONNECT ? 'https://' : 'http://')
               . "$THIS_NOPR_SITE$THIS_SCRIPT";
}




##################################################################################################
## Load the settings, and default settings file

sub IsVersionConflict ($$)
{
  # Release 1.5 Revision 1: Added this sub to allow minor differences between versions
  my $ver1 = lc $VERSIONS{$_[0]} || rand() + 1;  # or assign a unique version
  my $ver2 = lc $VERSIONS{$_[1]} || rand() - 1;  # that never matches.

  ($ver1, $ver2) = sort { length($a) <=> length($b) } ($ver1, $ver2);

  return 0 if $ver1 eq $ver2;
  return 0 if
           (
             $ver1 eq 'release 1.6'
           )
           &&
           (
             $ver2 eq 'release 1.6'
           );
  return 1;
}

sub IsSettingsVersionConflict ($)
{
  my $cfg = lc $VERSIONS{'xf-settings.pl'};
  my $ver = lc $VERSIONS{$_[0]};

  return 0 if $ver eq $cfg;
  return 0 if
           (
             $cfg eq 'release 1.4'            ||
             $cfg eq 'release 1.5'            ||
             $cfg eq 'release 1.5 revision 1' ||
             $cfg eq 'release 1.5 revision 2' ||
             $cfg eq 'release 1.5 revision 3' ||
             $ver eq 'release 1.6'
           )
           &&
           (
             $ver eq 'release 1.5'            ||
             $ver eq 'release 1.5 revision 1' ||
             $ver eq 'release 1.5 revision 2' ||
             $ver eq 'release 1.5 revision 3' ||
             $ver eq 'release 1.6'
           );
  return 1;
}

sub IsLanguageVersionConflict ($)
{
  # Release 1.5 Revision 1: Added this sub to allow minor differences between language versions
  my $lang = lc $VERSIONS{$_[0]}       || rand() + 1;
  my $cgi  = lc $VERSIONS{'cgiscript'} || rand() - 1;

  return 0 if $cgi eq $lang;
  return 0 if
           (
             $lang eq 'release 1.6'
           )
           &&
           (
             $cgi eq 'release 1.6'
           );
  return 1;
}


sub LoadSettings ()
{
  require 'xf-settings.pl';
  if (IsSettingsVersionConflict('cgiscript'))
  {
    Error("Module Version Error", "Invalid Version of xf-settings.pl used. "
                                . "Version $VERSIONS{'cgiscript'} is required.");
  }
#  if(defined $BACK_COLOR)
#  {
#    # Obsolete since X-Forum 1.6
#    Error("Settings Upgrade Note", "The variable \$BACK_COLOR in 'xf-settings.pl' is obsolete since X-Forum Release 1.6. Please remove the line holding defining this value!");
#  }
}

sub LoadDefaults ()
{
  require "$DATA_FOLDER${S}settings${S}default.cfg";
  if (IsVersionConflict('default.cfg', 'cgiscript'))
  {
    Error("Module Version Error", "Invalid Version of forum${S}settings${S}default.cfg used. "
                                . "Version $VERSIONS{'cgiscript'} is required.");
  }
}


##################################################################################################
## Load the constants used.

sub LoadConstants ()
{
  LoadSupport('constants');
  if (IsLanguageVersionConflict('constants.pl'))
  {
    Error("Module Version Error", "Invalid Version of constants.pl used. "
                                . "Version $VERSIONS{'cgiscript'} is required.");
  }
}



##################################################################################################
## Load the language file

sub LoadLanguage ()
{
  eval { require "$LANG_FOLDER${S}$LANGUAGE.lang"; };
  $@ && Error("Language Pack Error", "$LANGUAGE.lang did not load due errors. "
                                   . "Please check the version of the file;"
                                   . "it needs to be $VERSIONS{'cgiscript'}!<BR><BR>$@");

  if(defined $MSG[0])
  {
    Error("Language Pack Error", "$LANGUAGE.lang has an error. "
                               . "The constant used for the assignment of the text q[$MSG[0]] is invalid!");
  }

  # Assign this string now..
  $RETURN_HTML    = qq[\n    <P>\n    $MSG[ERROR_BACK1()] <A href="javascript:history.go(-1)">$MSG[ERROR_BACK2()]</A> $MSG[ERROR_BACK3()]];
}



##################################################################################################
## Called from the language file

sub LangVerCheck ()
{
  if(IsLanguageVersionConflict('language'))
  {
    Error('Language Pack Version Error', "Invalid Version for language pack used. "
                                       . "Version $VERSIONS{'cgiscript'} for $LANGUAGE.lang is required.");
  }
}

##################################################################################################
## Load a module, when it should be loaded at a later moment

sub LoadModule ($)
{
  eval("use $_[0]");
  $@ && die "Error in loading $_[0]: $@\n";
}


##################################################################################################
## The error trap.

sub ActivateErrorTrap ()
{
  $CGI::ErrorTrap::DIALOG_SUB = \&Fatal_Error
}


##################################################################################################
## If the admin is entering the forum...

sub CheckAdminEntering ()
{
  if($XForumUser eq 'admin')
  {
    # The admin sees too much; so check cookie now!
    LoadSupport('check_security');
    ValidateMemberCookie();
  }
}


##################################################################################################
## Check Password



sub CheckCryptAlgorithm ()
{
  if(! is_sha1($ADMIN_PASS))
  {
    die "This release of X-Forum introduces a new password crypting algorithm.\n"
      . "The administrator password should be updated manually first.\n"
      . "Any other user will be prompted to change his password\n\n";
  }
}

my $FirstCrypt = 1;
sub crypt_pass ($;$)
{
#  if($FirstCrypt)
#  {
#    require Digest::SHA1;
#    Digest::SHA1->import qw(sha1_base64);
#    $FirstCrypt = 0;
#  }
#  return sha1_base64($_[0]);
  return crypt_large($_[0], ($_[1] || 'XF'));
}

sub crypt_large
{ my($password, $key) = @_;
  my $crypt = '';

  if(defined $key)
  {
    my $length = length($key);
    if($length == 1)    { $key .= "A"  }
    elsif($length == 0) { $key .= "AA" }
    else
    {
      $key = substr($key, 0, 2);

      if($length == 13)
      {
        return crypt($password, $key);
      }
    }
  }
  else
  {
    $key = 'AA';
  }


  for(my $I = 0; $I < length($password); $I+=8)
  {
    $crypt .= substr(crypt(substr($password, $I, 8), $key), 2);
  }
  return $key.$crypt;
}


#sub is_sha1 ($)
#{
#  return length($_[0]) == 27;
#}


##################################################################################################
## Check for maintaince mode.

sub CheckMaintainceMode ()
{
  if (-e "$THIS_PATH${S}x-forum.lock")
  {
    Error("Maintaince Mode", "IMPORTANT NOTE: The current version of X-Forum uses a new file location for the x-forum.lock file to activate maintaince.\n"
                           . "Instead of having the x-forum.lock file in the 'cgi-bin', you should put it in the '$DATA_FOLDER' directory.");
  }

  if (-e "$DATA_FOLDER${S}x-forum.lock"
  && ! ($XForumUser eq 'admin' && $XForumPass eq $ADMIN_PASS))
  {
    if ($XForumUser ne '')
    {
      Action_Error($MSG[FORUM_LOCKED()], 1);
    }
    else
    {
      my $Show   = param('show')   || '';
      my $Action = param('action') || '';

      if($Show   ne 'login'
      && $Show   ne 'logout'
      && $Show   ne 'logintest'
      && $Action ne 'login')
      {
        Action_Error(qq[$MSG[FORUM_LOCKED()] <A href="$THIS_URL?show=login">$MSG[BUTTON_LOGIN()]</A>], 1);
      }
    }
  }
}



##################################################################################################
# Many used subroutines, the real contents will be loaded when needed.

sub Fatal_Error         { LoadSupport('dlg_errors'); fatal_error(@_);  }
sub print_log           { LoadSupport('logprint');   WriteLog(@_);     }
sub Action_Error        { LoadSupport('dlg_errors'); action_error(@_); }
sub SaveTime            { return time(); }



##################################################################################################
# Banning members

my @BanIPs;
my @BanMembers;

sub LoadBanSettings ()
{
  @BanIPs      = dbGetFileContents("$DATA_FOLDER${S}settings${S}ips.ban",     FILE_NOERROR());
  @BanMembers  = dbGetFileContents("$DATA_FOLDER${S}settings${S}members.ban", FILE_NOERROR());

  %MemberBanned = map { $_ => 1 } @BanMembers;
}

sub ValidateBanMember($)
{ my ($Member) = @_;
  if($Member ne '' && %MemberBanned)
  {
    if($MemberBanned{$Member})
    {
      print_log('BANXS', $Member);
      Action_Error($MSG[MEMBER_BANNED()], 1);
    }
  }
}

sub ValidateBanIP($)
{
  my($ip) = @_;
  if($ip, @BanIPs)
  {
    if(IsIPInBlock($ip, @BanIPs))
    {
      Action_Error($MSG[MEMBER_BANNED()], 1);
    }
  }
}

undef @BanIPs;








##################################################################################################
## The remains of the file contains subroutines called frequently






##################################################################################################
## Count lines in a file

sub dbCountEntries ($;$)
{ my($FileName, $Error) = @_;
  my $Lines = 0;

  my $File = new File::PlainIO($FileName, MODE_READ);
  if(defined $File)
  {
    $Lines = $File->countlines();
    $File->close();
  }
  else
  {
    die "Can't count entries in '$FileName': $!" if $Error;
    return 0;
  }
  return $Lines;
}


##################################################################################################
## Generate a database filename

sub NameGen ($) #(STRING Title)
{ my $Title = lc($_[0]);
  $Title    =~ s/ /_/g;
  $Title    =~ s/[^a-zA-Z0-9_]//g;
  return    $Title;
}


##################################################################################################
## Fork helper

sub call_as_thread
{ my($child) = @_;

  if(ref($child) ne 'CODE') { die "Expected code references" }

  $@ = "";
  my $pid;
  eval                  { $pid = fork(); };# Spawn a child process that actually a copy of this process.
  if($@)                { return undef;  } # Failed, for win32 only supported since Perl 5.006
  elsif(! defined $pid) { return undef;  } # Failed.
  elsif($pid)           { return 1;      } # Parent process...
  elsif(defined $pid)                      # Child process...
  {
    ## BEGIN INNER SUBROUTINE ##
    my $ErrorsToLog =
    sub
    {
      return unless IsRealError();
      print_log("ERROR", '', "Error in child process: $_[0]");
      exit;
    };
    ## END INNER SUBROUTINE ##


    # We don't use the CGI::ErrorTrap message here.
    local($SIG{'__DIE__'})  = $ErrorsToLog;
    local($SIG{'__WARN__'}) = $ErrorsToLog;

    # Important: close STDOUT, so the CGI script caller
    # will think we're gone when the parent thread closes.
    close(STDOUT);

    &$child();
    exit;
  }
}

##################################################################################################
## E-mail a message

sub SendForumMail_Adjust ($$$)
{
  $_[0] ||= 'unknown member';
  $_[1] ||= 'no name';
  $_[2] ||= $WEBMASTER_MAIL;
}

sub SendForumMail_Init ($)
{ my($From) = @_;

  my $CAN_EMAIL = ($MAIL_TYPE && $From);

  # Send an e-mail???
  if($CAN_EMAIL)
  {
    LoadModule('INet::Mailer');
    return ($MAIL_PROG, $MAIL_HOST);
  }
  else
  {
    return undef;
  }
}

sub SendForumMail_Check ($$$$$$$$)
{ my($Status, $Error, $PROG, $SMTP, $Email, $Member, $Name, $From) = @_;
  if(defined $Status && $Status != MAIL_SUCCESS())
  {
    my $Error     = $Error     || '[undefined]';
    my $PROG      = $PROG      || '[default]';
    my $PROG      = $PROG      || '[default]';
    my $MAIL_TYPE = $MAIL_TYPE || '[undefined]';
    my $From      = $From      || '[undefined]';
    my $Email     = $Email     || '[undefined]';
    my $Name      = $Name      || '[undefined]';
    my $Member    = $Member    || '[undefined]';
    $Error =~ s/\n/<BR>/g;

    # Different error messages. One for the log, one for the 'last' message.
    my $Error1 = "STATUS=$Status ERROR=$Error TYPE=$MAIL_TYPE; PROG=$PROG SMTP=$SMTP FROM=$From TO=$Email TONAME=$Name TOMEMBER=$Member";
    my $Error2 = "$Error ($Status) TYPE=$MAIL_TYPE; PROG=$PROG SMTP=$SMTP";

    my(@Errors) = dbGetFileContents("$DATA_FOLDER${S}lasterr.log", FILE_NOERROR());
    if(! $Errors[ERROR_EMAIL()] || $Errors[ERROR_EMAIL()] ne $Error2)
    {
      print_log('MAILERR','', $Error1);

      $Errors[ERROR_EMAIL()] = $Error2;
      dbSetFileContents("$DATA_FOLDER${S}lasterr.log", 'error log file', @Errors);
    }
  }
}

sub SendForumMail ($$;$$$)
{ my($Email, $Message, $Member, $Name, $From) = @_;

  SendForumMail_Adjust($Member, $Name, $From);
  if(my($PROG, $SMTP) = SendForumMail_Init($From))
  {
    my($Status, $Error) = SendMail($PROG, $SMTP, $MAIL_TYPE, $Message, $From, $Email);
    SendForumMail_Check($Status, $Error, $PROG, $SMTP, $Email, $Member, $Name, $From);
  }
}

##################################################################################################
## Working with files

my $WRITE_MODE = 0200;
sub FILE_NOERROR(){undef}

sub dbGetFileContents ($;$$$$)
{ my ($FileName, $Title, $MinLines, $From, $Length) = @_;

  my $File = new File::PlainIO($FileName, MODE_READ, $Title);
  return if not defined $File;
  if($From)
  {
    $File->seeklineindex($From) or do { return unless $Title; die "Can't seek lines: $!" }
  }

  my @Lines = $File->readlines($Length, $MinLines);
  $File->close();
  return @Lines;
}

sub dbSetFileContents ($$@)
{
  my $FileName = shift;
  my $Title = shift;

  my $FileMode = (stat($FileName))[2];
  if (defined $FileMode && ($FileMode & $WRITE_MODE) != $WRITE_MODE)
  {
    die "The file $FileName will not be saved. It requires other file permissions\n";
  }

  my $File = new File::PlainIO($FileName, MODE_WRITE_NEW, $Title);
  return if not defined $File;

  $File->writelines(@_);
  $File->close();
}

sub dbAppendFileContents ($$@)
{
  my $FileName = shift;
  my $Title = shift;

  my $FileMode = (stat($FileName))[2];
  if (defined $FileMode && ($FileMode & $WRITE_MODE) != $WRITE_MODE)
  {
    die "The file $FileName will not be saved. It requires other file permissions\n";
  }

  my $File = new File::PlainIO($FileName, MODE_WRITE_ADD, $Title);
  return if not defined $File;
  $File->writelines(@_);
  $File->close();
}

1;