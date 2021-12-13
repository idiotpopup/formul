##################################################################################################
##                                                                                              ##
##  >> Central Database Core Routines <<                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'db_messages.pl'} = 'Release 1.4';


LoadSupport('db_members');



##################################################################################################
## Messages for a member

# File names
sub FileName_Messages ($) { return "$DATA_FOLDER${S}messages${S}".NameGen($_[ID]).".msg"; }
sub FileName_MsgSent  ($) { return "$DATA_FOLDER${S}messages${S}".NameGen($_[ID]).".snt"; }



sub dbSendMessage ($$$$$$) # ($\@$$$$)
{ my ($From, $ToArray, $Title, $Icon, $Contents, $SaveSent) = @_;

  LoadModule('HTML::EscapeASCII;');


  # Get MemberInfo that's also being used for flood checks.
  my $Time        = SaveTime();
  my @SenderInfo  = dbGetMemberInfo($From, 1);

  # Test for flood timeout
  dbMemberFloodTest($From, $SenderInfo[DB_MEMBER_LASTPOSTDATE], $Time);

  # The message structure
  my @MessageInfo;
  $MessageInfo[DB_MSG_TITLE]          = $Title;
  $MessageInfo[DB_MSG_SENDER]         = $From;
  $MessageInfo[DB_MSG_DATE]           = $Time;
  $MessageInfo[DB_MSG_ICON]           = $Icon;


  # Escape characters
  EscapeMessageArray(@MessageInfo);
  EscapeMessageText($Contents);

  # The array to be added.
  my @Append = (join('|', @MessageInfo), $Contents);

  receipent:foreach my $To (@{$ToArray})
  {
    next receipent if($To eq $From && $SaveSent);

    my @ReceiptInfo = dbGetMemberInfo($To, 1); # Check if he exists aswell.

    # Send the message (save it in the inbox of the receipent)
    dbAppendFileContents(FileName_Messages($To),  "Can't update inbox file for $To!"  => @Append);

    # For the 'you have new messages'
    $ReceiptInfo[DB_MEMBER_LASTMSG_RECVDATE] = $Time;
    dbSaveMemberInfo(@ReceiptInfo);
  }


  # Update member stats
  $SenderInfo[DB_MEMBER_LASTPOSTDATE]      = $Time; # For the flood control
  dbSaveMemberInfo(@SenderInfo);


  # Save a copy of the message in the sent messages folder
  if($SaveSent)
  {
    $MessageInfo[DB_MSG_SENTTO] = join(',', @{$ToArray});
    @Append = (join('|', @MessageInfo), $Contents);

    dbAppendFileContents(FileName_MsgSent($From), "Can't update sent messages folder for $From!" => @Append);
  }
}



##################################################################################################
## Get Contents

sub EscapeMessageArray (@)
{
  # Replace | with a HTML escape code: #124;
  s/\|/\&#124;/g foreach @_;
}

sub EscapeMessageText (@)
{
  s/( )*($LINEBREAK_PATTERN)/<BR>/g foreach @_;
}


sub dbGetMessages ($$;$$$)
{ my ($Member, $Sent, $Error, $Start, $End) = @_;

  if ($Error && ! dbMemberExist($Member))  { Action_Error($MSG[MEMBER_NOTEXIST]) }

  if(defined $End)   { $End = ($End - $Start) * 2; } # Length
  if(defined $Start) { $Start *= 2; }

  my $File = ($Sent ? FileName_MsgSent($Member) : FileName_Messages($Member));
  return dbGetFileContents($File, FILE_NOERROR, undef, $Start, $End);
}



sub dbSaveMessages ($$$)  # ($\@)
{ my($Member, $Sent, $Messages) = @_;
  # RULE: Member flood should already be tested
  my $File = ($Sent ? FileName_MsgSent($Member) : FileName_Messages($Member));
  my $Type = ($Sent ? 'sent' : 'received');
  dbSetFileContents($File, "Can't save $Type messages for $Member" => @{$Messages});
}



sub dbGetMessageInfo ($$)  # (\@$)
{ my($Messages, $MsgIndex) = @_;

  # Get the info
  my $MessageInfo = (@{$Messages}[Index_MessageInfo($MsgIndex)] || '');
  if($MessageInfo eq '') { Action_Error($MSG[MESSAGE_NOTEXIST]); }
  my @MessageInfo = split(/\|/, $MessageInfo, DB_MSG_FIELDS);

  # Default values... the entire structure, because it's retreived by a split()
  $_ ||= '' foreach($MessageInfo[DB_MSG_TITLE], $MessageInfo[DB_MSG_SENDER]);
  $_ ||= 0  foreach($MessageInfo[DB_MSG_DATE]);
  $MessageInfo[DB_MSG_ICON] ||= 'default';

  # Return
  return @MessageInfo;
}


sub dbGetMessageContents ($$)  # (\@$)
{ my($Message, $MsgIndex) = @_;

  # Get the message contents
  my $MsgContents = (@{$Message}[Index_MessageContents($MsgIndex)] || '');
  $MsgContents    =~ s/<BR>/\n/g;

  return $MsgContents;
}


# Some helper functions that are used when the array needs to be edited
sub dbDelMessage ($$$)
{ my($Member, $Sent, $MsgIndex) = @_;

  my @Messages = dbGetMessages($Member, $Sent, 1);


  if(@Messages == 2
  && unlink(FileName_Messages($Member)))
  {
    return;
  }

  my $FirstIndex = Index_MessageInfo($MsgIndex);
  splice(@Messages, $FirstIndex, 2);
  dbSaveMessages($Member, $Sent, \@Messages);
}



# Index functions
sub Index_MessageInfo ($)     { return ($_[0] - 1) * 2; }
sub Index_MessageContents ($) { return ($_[0] * 2) - 1; }


1;
