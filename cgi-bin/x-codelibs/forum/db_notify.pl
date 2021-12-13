##################################################################################################
##                                                                                              ##
##  >> Central Database Core Routines <<                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

use strict;

$VERSIONS{'db_notify.pl'} = 'Release 1.4';


##################################################################################################
## Topics Index Database


# Filenames for the topic data files
sub FileName_Notify ($) { return "$DATA_FOLDER${S}topics${S}".NameGen($_[ID]).".eml";  }

# Actually dbAddNotification(), but that's a too long name.

sub dbAddNotify ($$)
{ my($Topic, $Member) = @_;

  my $Notify = new File::PlainIO(FileName_Notify($Topic), MODE_RDWR, "Can't add notification for $Member at topic $Topic\n");
  {
    # Check if the member exists
    while(defined $Notify->readline())
    {
      my @NotifyInfo = dbGetNotifyInfo($_);
      if($NotifyInfo[DB_NOTIFY_MEMBER] eq $Member)
      {
        $Notify->close();
        return;
      }
    }

    # Not found...
    my @Notify;
    $Notify[DB_NOTIFY_MEMBER]   = $Member;
    $Notify[DB_NOTIFY_PREVDATE] = 0;

    $Notify->seekeof() or die "Can't seek to EOF to add a new notification for $Member at topic $Topic\n";
    $Notify->writeline(EscapeNotifyArray(@Notify));
    $Notify->close();
  }
}

sub dbDelNotifyMember ($$)
{ my($Topic, $Member) = @_;

  # Here, we don't test whether the member
  # is found. We just assure that it doesn't
  # exist anymore in the file.

  ## BEGIN INNER SUBROUTINE ##
  my $RemoveSub =
  sub
  {
    my @NotifyInfo = dbGetNotifyInfo($_);
    $_ = undef if($NotifyInfo[DB_NOTIFY_MEMBER] eq $Member);
  };
  ## END INNER SUBROUTINE ##


  my $Notify = new File::PlainIO(FileName_Notify($Topic), MODE_RDWR, "Can't remove notification for $Member at topic $Topic\n");
     $Notify->update($RemoveSub);
  if(($Notify->stat)[7] == 0) { $Notify->unlink(); }
  else                        { $Notify->close();  }
}

sub dbHasNotify ($$)
{ my($Topic, $Member) = @_;

  my $Notify = new File::PlainIO(FileName_Notify($Topic), MODE_READ);
  if(defined $Notify)
  {
    while(defined $Notify->readline())
    {
      my @NotifyInfo = dbGetNotifyInfo($_);
      if($NotifyInfo[DB_NOTIFY_MEMBER] eq $Member)
      {
        $Notify->close();
        return 1;
      }
    }
    $Notify->close();
  }
  return 0;
}

sub dbShouldNotify ($@)
{ my($Topic, @Notification) = @_;

  my $Member      = $Notification[DB_NOTIFY_MEMBER];
  my $AllViews    = dbGetMemberViews($Member, [$Topic]);  # Hash pointer with topic views
  my $LastView    = ($AllViews->{$Topic} || 0);           # This topic view
  my $LastNotify  = $Notification[DB_NOTIFY_PREVDATE];    # Last time notified.

  return ($LastNotify < $LastView);  # Notify IF user checked the last change
}


sub dbGetNotifyInfo ($)
{ my($FileLine) = @_;

  # Get the info
  my @NotifyInfo = split(/\|/, ($FileLine || ''), DB_POST_FIELDS);

  # Default values... the entire structure, because it's retreived by a split()
  $NotifyInfo[DB_NOTIFY_MEMBER]   ||= '';
  $NotifyInfo[DB_NOTIFY_PREVDATE] ||= 0;

  return @NotifyInfo;
}

sub EscapeNotifyArray (@)
{ my @A = @_;
  foreach(@A) { s/\|/\&#124;/g; }  # Replace | with a HTML escape code: #124;
  return join('|', @A);
}


sub dbDoNotify ($$)
{ my($Topic, $TopicLink, $Poster) = @_;

  my $NotifyFile = FileName_Notify($Topic);
  my $CAN_EMAIL  = ($MAIL_TYPE && $WEBMASTER_MAIL && dbTopicExist($Topic) && -e $NotifyFile);
  my $TimeNow    = SaveTime();

  if($CAN_EMAIL)
  {
    my $Message = <<EMAIL_MESSAGE;
from: Webmaster<$WEBMASTER_MAIL>
subject: $FORUM_TITLE $MSG[FORUM_NOTIFY1]
X-Mailer: INet::Mailer Script for Perl

$MSG[FORUM_NOTIFY2]
$MSG[FORUM_NOTIFY3]

$MSG[FORUM_NOTIFY4]: $TopicLink
$MSG[FORUM_NOTIFY5]
EMAIL_MESSAGE


    my %Seen;
    my %Send;

    ## BEGIN INNER SUBROUTINE #
    my $FindNotify =
    sub
    {
      my @NotifyInfo = dbGetNotifyInfo($_);
      my $Member     = $NotifyInfo[DB_NOTIFY_MEMBER];

      # Invalid or already seen?
      if(! dbMemberExist($Member) || $Seen{$Member})
      {
        $_ = undef;
        return;
      }

      return if $Member eq $Poster;     # Don't inform the poster
      return if $MemberBanned{$Member}; # Don't inform anyone banned
#?    return if $MemberOnline{$Member}; # Don't inform anyone online
      $Seen{$Member} = 1;               # We've seen him

      # Notify if we should so.
      if(dbShouldNotify($Topic, @NotifyInfo))
      {
        my($Name, $Email) = dbGetMemberName($Member, 0,1);
        return if ! $Email;  # Invalid member properly

        # Remember we need to send him an e-mail
        $Send{$Member} = [($Name, $Email)];

        # Update stats
        $_ = EscapeNotifyArray($Member, $TimeNow);
      }
    };
    ## END INNER SUBROUTINE ##


    ## BEGIN CHILD THREAD ##
    my $MailNotify =
    sub
    {
      # Open notification list and update
      my $Notify = new File::PlainIO($NotifyFile, MODE_RDWR, "Can't read notification list");
         $Notify->update($FindNotify);
         $Notify->close();

      my $From = $WEBMASTER_MAIL;

      # Initialize variables for mailer
      if(my($PROG, $SMTP) = SendForumMail_Init($From))  # Init, and return $PROG, $SMTP parameter
      {
        # Initialize mailer
        my $mail = new INet::Mailer($PROG, $SMTP, $MAIL_TYPE);
        my($Status, $Error) = $mail->open();
        SendForumMail_Check($Status, $Error, $PROG, $SMTP, "", "", "All Subscribed Members ($Topic)", $From);


        # Send that e-mail after the file is free again.
        while(my($Member, $Info) = each %Send)
        {
          my($Name, $Email) = @$Info;
          my $To = "to: $Name<$Email>";

          ($Status, $Error) = $mail->send("$To\n$Message", $From, $Email);
          SendForumMail_Check($Status, $Error, $PROG, $SMTP, $Email, $Member, $Name, $From);
        }


        # Close mailer
        ($Status, $Error) = $mail->close();
        SendForumMail_Check($Status, $Error, $PROG, $SMTP, "", "", "All Subscribed Members ($Topic)", $From);
      }
    };
    ## END CHILD THREAD ##


    my $Success = call_as_thread($MailNotify);
    if(! $Success)
    {
      if($@) { &$MailNotify() }  # fork failed!
      else   { print_log("MAILERR", '', "ERROR=forking properly failed TOPIC=$Topic: ERROR=$!") }
    }
  }
}

1;