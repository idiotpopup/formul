##################################################################################################
##                                                                                              ##
##  >> Input Field Checking <<                                                                  ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'check_fields.pl'} = 'Release 1.6';

use Test::Input;


##################################################################################################
## Field Validation

sub ValidateRequiredFields (@)
{
  foreach my $name (@_)
  {
    $_ = param($name);
    if(! defined or length == 0) { Action_Error($MSG[ERROR_INPUTREQ].$RETURN_HTML) };
  }
}

sub ValidateRequired (@) #(ARRAY Fields)
{
  foreach(@_)
  {
    if(not defined or length == 0) { Action_Error($MSG[ERROR_INPUTREQ].$RETURN_HTML) }
  }
}


sub ValidateLength#(STRING Title, STRING FieldName, NUMBER Size)
{ my (undef, $Name, $Size) = @_;
  if (length($_[0]) > $Size)
  {
    Action_Error("$MSG[ERROR_SIZE1]$Name$MSG[ERROR_SIZE2] (" . length($_[0]) . ">$Size) <BR>\n    $MSG[ERROR_SIZE3]$RETURN_HTML");
  }
}


sub ValidateNumber#(STRING Number, STRING FieldName)
{ my ($Number, $Name) = @_;
  if (! IsNumber($Number))
  {
    Action_Error("$MSG[ERROR_NUMBER1]$Name$MSG[ERROR_NUMBER2] <BR>\n    $MSG[ERROR_NUMBER3]$RETURN_HTML");
  }
}

sub ValidateNumberFields#(STRING Email)
{ # RULE: we assume the field is already checked for 'has contents'

  foreach my $name (@_)
  {
    my $Number = param($name);
    next if(! defined $Number || $Number eq '');
    if (! IsNumber($Number))
    {
      Action_Error("$MSG[ERROR_NUMBER1]$name$MSG[ERROR_NUMBER2] <BR>\n    $MSG[ERROR_NUMBER3]$RETURN_HTML");
    }
  }
}



sub ValidateRange#(NUMBER Number, STRING Name, NUMBER Min, NUMBER Max)
{ my ($Number, $Name, $Min, $Max) = @_;
  ValidateNumber($Number, $Name);
  if(! InRange($Number, $Min, $Max))
  {
    Action_Error("$MSG[ERROR_NUMBER1]$Name$MSG[ERROR_NUMBER2] <BR>\n    $MSG[ERROR_RANGE]$RETURN_HTML");
  }
}

sub ValidateURL#(STRING URL, STRING Title)
{ my ($URL, $Title) = @_;
  if (! IsURL($URL))
  {
    Action_Error("$MSG[ERROR_URL1] <BR>\n    $MSG[ERROR_URL2]$RETURN_HTML");
  }
  if ($URL eq '' && $Title ne '')
  {
    Action_Error($MSG[ERROR_URLREQ].$RETURN_HTML);
  }
}


sub ValidateEmail#(STRING Email)
{ my ($Email) = @_;
  if (! IsEmail($Email))
  {
    Action_Error("$MSG[ERROR_EMAIL1] <BR>\n    $MSG[ERROR_EMAIL2]$RETURN_HTML");
  }
}


sub ValidateEmailFields#(STRING Email)
{ # RULE: we assume the field is already checked for 'has contents'
  foreach my $name (@_)
  {
    my $Email = param($name);
    next if(! defined $Email || $Email eq '');
    if (! IsEmail($Email))
    {
      Action_Error("$MSG[ERROR_EMAIL1] <BR>\n    $MSG[ERROR_EMAIL2]$RETURN_HTML");
    }
  }
}


sub ValidateNewPassword#(STRING NewPassword, STRING ConfirmPassword)
{ my ($NewPassword, $ConfirmPass) = @_;
  if (length($NewPassword) < 6)       { Action_Error($MSG[ERROR_PASSLEN].$RETURN_HTML, 1); }
  if ($NewPassword ne $ConfirmPass)   { Action_Error($MSG[ERROR_PASSNE].$RETURN_HTML, 1); }
}


sub ValidatePath#(STRING PathLocation)
{ my ($Path) = @_;
  if (! -e $Path)
  {
    Action_Error("$MSG[ERROR_PATHLOC1]$Path$MSG[ERROR_PATHLOC2]$RETURN_HTML");
  }
}



1;
