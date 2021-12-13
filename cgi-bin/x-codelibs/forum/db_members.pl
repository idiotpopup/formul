##################################################################################################
##                                                                                              ##
##  >> Central Database Core Routines <<                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'db_members.pl'} = 'Release 1.6';


my $RE_EMPTY = qr/^(\s)*$/; # A 'empty' string


##################################################################################################
## Since version 1.2 the last access time file is binary...

sub MEMBER_LXS_RECORD()  {'N'} # Network long
sub MEMBER_LXS_RECSIZE() { 4 } # bytes size for record

sub STAT_SIZE()          { 7 } # Array index


##################################################################################################
## Members Database Index

sub FileName_Member ($)  { return "$DATA_FOLDER${S}members${S}".NameGen($_[ID]).".mbr"; }
sub FileName_Members ()  { return "$DATA_FOLDER${S}members.lst"; }
sub FileName_Footer ($)  { return "$DATA_FOLDER${S}members${S}".NameGen($_[ID]).".ftr"; }

sub FileName_Views ($)   { return "$DATA_FOLDER${S}members${S}".NameGen($_[ID]).".lxs"; }

# Compatibility...
sub FileName_Access ($)  { return "$DATA_FOLDER${S}members${S}".NameGen($_[ID]).".lat"; }



##################################################################################################
## Make a new member


sub dbMakeMember ($$$$$)
{ my ($Member, $Name, $Password, $Email, $Private) = @_;

  LoadSupport('db_stats');

  # Format into HTML codes
  LoadModule('HTML::EscapeASCII;');
  FormatFieldHTML($Name);


  # Determine password
  if ($Member eq 'admin') { $Password = '';                    } # not stored in admin.dat file.
  else                    { $Password = crypt_pass($Password); }


  # Fill the array
  my @MemberInfo                  = ('') x DB_MEMBER_FIELDS;
  $MemberInfo[ID]                 = $Member;
  $MemberInfo[DB_MEMBER_NAME]     = $Name;
  $MemberInfo[DB_MEMBER_PASSWORD] = $Password;
  $MemberInfo[DB_MEMBER_EMAIL]    = $Email;
  $MemberInfo[DB_MEMBER_PRIVATE]  = $Private;
  $MemberInfo[DB_MEMBER_REGDATE]  = SaveTime();


  # Make the member's database
  dbSetFileContents(FileName_Member($Member), "Can't create new member database" => @MemberInfo);
  dbAppendFileContents(FileName_Members(),  "Can't update member index database" => $Member);


  # Update the member view data file. Every topic is assumed to be read by the new member
  my($TopicNum) = (dbGetStats())[DB_STAT_TOPICID];
  if($TopicNum) { dbMemberInitTopicViews($Member, $TopicNum); }

  UpdateMemberStat(undef,$Member);
}



sub FileName_Member ($)  { return "$DATA_FOLDER${S}members${S}".NameGen($_[ID]).".mbr"; }
sub FileName_Members ()  { return "$DATA_FOLDER${S}members.lst"; }
sub FileName_Footer ($)  { return "$DATA_FOLDER${S}members${S}".NameGen($_[ID]).".ftr"; }

sub FileName_Views ($)   { return "$DATA_FOLDER${S}members${S}".NameGen($_[ID]).".lxs"; }
sub FileName_Access ($)  { return "$DATA_FOLDER${S}members${S}".NameGen($_[ID]).".lat"; }

sub dbDelMember ($)
{ # RULE: member id is validated
  my($ID) = @_;

  LoadSupport('db_stats');
  LoadSupport('db_subjects');
  LoadSupport('db_groups');
  LoadSupport('db_messages');

  my $DeleteMember = sub
  {
    $_ = undef if $_ eq $ID;
  };

  my $DeleteMemberFromGroup = sub
  {
    $_ = undef if $_ eq $ID && $. > DB_GROUP_MEMBERS;
  };

  unlink FileName_Member($ID) or die "Can't delete member '$ID': $!";

  my $File;
  $File = new File::PlainIO(FileName_Members(), MODE_RDWR, "Can't update member list!");
  $File->update($DeleteMember);
  $File->close();

  unlink FileName_Access($ID); # Old X-Forum 1.2 file
  unlink FileName_Views ($ID);
  unlink FileName_Footer($ID);
  unlink FileName_Messages($ID);
  unlink FileName_MsgSent($ID);

  if($MemberBanned{$ID})
  {
    $File = new File::PlainIO("$DATA_FOLDER${S}settings${S}members.ban", MODE_RDWR, "Can't update banned member list");
    $File->update($DeleteMember);
    $File->close();
  }

  my @Groups = dbGetGroups();
  group:foreach my $group (@Groups)
  {
    next group if $group eq 'everyone'; # Virtual group
    $File = new File::PlainIO(FileName_Group($group), MODE_RDWR, "Can't update membergroup $group");
    $File->update($DeleteMemberFromGroup);
    $File->close();
  }

  my @Subjects = dbGetSubjects();
  subject:foreach my $Subject (@Subjects)
  {
    if(! dbSubjectIsTitle($Subject))
    {
      my @SubjectInfo = dbGetSubjectInfo($Subject);
      my $NewList = '';
      my $Update  = 0;
      foreach my $Moderator (split(/,/, $SubjectInfo[DB_SUBJECT_MODERATORS]))
      {
        if($Moderator eq $ID)
        {
          $Update = 1;
        }
        else
        {
          $NewList .= "," if length $NewList;
          $NewList .= $Moderator;
        }
      }
      if($Update)
      {
        $SubjectInfo[DB_SUBJECT_MODERATORS] = $NewList;
        dbSaveSubjectInfo(@SubjectInfo);
      }
    }
  }

  UpdateMemberStat(-1);
}


##################################################################################################
## Get the entire index

sub dbGetMembers ()   { return dbGetFileContents(FileName_Members(), FILE_NOERROR);      }
sub dbSaveMembers (@) { dbSetFileContents(FileName_Members(), 'members database' => @_); }





##################################################################################################
## Member Info

sub dbMemberIsGuest ($)
{
  return ($_[0] =~ m[^G:] ? 1 : 0);
}

sub dbSaveMemberInfo (@)
{
  # Get the filename
  if(! dbMemberExist($_[ID])) { Action_Error($MSG[MEMBER_NOTEXIST]); }

  # Validate
  if($_[DB_MEMBER_EMAIL] eq '')
  {
    # I had a little bug in a previous Beta. This prevents it from happening again.
    # I's caused by saving the memberinfo when ($XForumUser eq '' && $GUEST_NOMAIL) is true
    die "Save with blank e-mail address!\n";
  }

  # Admins don't store their password in a file
  if($_[ID] eq 'admin')
  {
    $_[DB_MEMBER_PASSWORD] = '';
  }

  # Store the new data
  dbSetFileContents(FileName_Member($_[ID]), "Can't update database for member '$_[ID]'" => @_);
}



sub dbGetMemberInfo ($;$$)
{ my ($Member, $Error, $DontHideEmail) = @_;

  my @MemberInfo;

  if(dbMemberIsGuest($Member))
  {
    my(undef, $Name, $Email) = split(/:/, $Member);

    @MemberInfo = ('') x DB_MEMBER_FIELDS;

    $MemberInfo[DB_MEMBER_NAME]  = $Name  || $MSG[HTML_NA];
    $MemberInfo[DB_MEMBER_EMAIL] = $Email || '';
  }
  else
  {
    # Get file name
    my $MemberExist = dbMemberExist($Member);
    if ($Error && ! $MemberExist)
    {
      Action_Error($MSG[MEMBER_NOTEXIST])
    }

    if($MemberExist)
    {
      # Open and validate
      @MemberInfo = dbGetFileContents(FileName_Member($Member), FILE_NOERROR, DB_MEMBER_FIELDS);
      if ($Error && dbMemberInvalid($Member, @MemberInfo))
      {
        die "The database of the member '$Member' is corrupted!\nPlease contact the webmaster to fix the problem.\n";
      }
      if ($Error && $MemberInfo[DB_MEMBER_EMAIL] eq '')
      {
        die "The e-mail entry of the member '$Member' is corrupted!\nPlease contact the webmaster to fix the problem.\n";
      }
    }

    # Set default values that only should be set for real members
    $MemberInfo[DB_MEMBER_POSTNUM]          ||= 0;
    $MemberInfo[DB_MEMBER_REGDATE]          ||= 0;
    $MemberInfo[DB_MEMBER_LASTPOSTDATE]     ||= 0;
    $MemberInfo[DB_MEMBER_LASTLOGINDATE]    ||= 0;
    $MemberInfo[DB_MEMBER_LASTMSG_RECVDATE] ||= 0;
    $MemberInfo[DB_MEMBER_LASTMSG_VIEWDATE] ||= 0;

    # Update this value, so we don't need to ask it anymore
    $MemberNames{$Member} = $MemberInfo[DB_MEMBER_NAME] if($MemberExist);


    # Change fields, determines on the type of user
    if ($Member eq 'admin')
    {
      $MemberInfo[DB_MEMBER_PRIVATE]  = 0;            # Admin e-mail is always visible
      $MemberInfo[DB_MEMBER_PASSWORD] = $ADMIN_PASS;  # Not stored into admin.mbr file!
    }
    elsif ($XForumUser eq ''
    &&     $GUEST_NOMAIL
    &&   ! $DontHideEmail)
    {
      $MemberInfo[DB_MEMBER_PRIVATE]  = 1;            # E-mail not shown
      $MemberInfo[DB_MEMBER_EMAIL]    = '';           # Clear up for safety
    }
  }


  # Set default values
  $MemberInfo[DB_MEMBER_PRIVATE]          ||= 0;
  $MemberInfo[DB_MEMBER_GENDER]           ||= 0;

  # Return
  return @MemberInfo;
}



##################################################################################################
## Faster routine if we only need to know the member's name

sub dbGetMemberName ($;$$)
{ my ($Member, $Error, $EmailToo) = @_;

  return '' if($Member eq '');

  if(dbMemberIsGuest($Member))
  {
    my($G, $Name, $Email) = split(/:/, $Member);
    $Name  ||= $MSG[HTML_NA];
    $Email ||= "";
    if($EmailToo) { return ($Name, $Email); }
    else          { return $Name; }
  }
  else
  {
    my @MemberInfo;

    if(not defined $MemberNames{$Member})
    {
      if ($Error && ! dbMemberExist($Member))
      {
        Action_Error($MSG[MEMBER_NOTEXIST])
      }

      # Open and validate
      # This call loads in less of the member's database.
      if($EmailToo) { @MemberInfo = dbGetFileContents(FileName_Member($Member), undef, 0, ID, DB_MEMBER_EMAIL + 1); }
      else          { @MemberInfo = dbGetFileContents(FileName_Member($Member), undef, 0, ID, DB_MEMBER_NAME + 1); }

      # Assign to the hash.
      if(! dbMemberInvalid($Member, @MemberInfo))
      {
        $MemberNames{$Member} = $MemberInfo[DB_MEMBER_NAME];
      }
      else
      {
        $MemberNames{$Member} = "&lt;$MSG[MEMBER_UNKNOWN] - $Member&gt;";
      }
    }

    if($EmailToo) { return ($MemberNames{$Member}, $MemberInfo[DB_MEMBER_EMAIL]); }
    else          { return $MemberNames{$Member}; }
  }
}

sub dbGetMemberNames ()
{
  my @Members     = dbGetMembers();

  foreach my $Member (@Members)
  {
    $MemberNames{$Member} = dbGetMemberName($Member);
  }


  return map
         {
           $_, $MemberNames{$_}
         }
         sort
         {
           $MemberNames{$a}  cmp  $MemberNames{$b} ||
                         $a  cmp  $b
         }
         @Members;
}



##################################################################################################
## Footer Text

sub dbGetMemberFooter ($)
{ my ($Member) = @_;

  # Test if the member exists
  return '' if dbMemberIsGuest($Member);
  if (! dbMemberExist($Member))
  {
    Action_Error($MSG[MEMBER_NOTEXIST]);
  }

  # Get the contents
  my @Footer = dbGetFileContents(FileName_Footer($Member), FILE_NOERROR);

  # Make a normal string of it.
  if (@Footer) { return join("\n", @Footer); }
  else         { return ''; }
}


sub dbSaveMemberFooter ($$)
{ my ($Member, $Footer) = @_;

  # Get the file
  if (! dbMemberExist($Member))
  {
    Action_Error($MSG[MEMBER_NOTEXIST]);
  }

  # Store the new footer, or erase the file if the new footer is empty
  if(! defined $Footer) { $Footer = ''; }

  my $FooterFile = FileName_Footer($Member);
  if( $Footer !~ m[$RE_EMPTY] )
  {
    dbSetFileContents($FooterFile, "Can't update footer for member '$Member'" => $Footer);
  }
  elsif( -e $FooterFile)
  {
    unlink($FooterFile) or dbSetFileContents($FooterFile, "Can't clear footer for member '$Member'" => '');
  }
}



##################################################################################################
## Topic Views

sub dbGetMemberViews ($$) # ($\@)
{ my($Member, $Topics) = @_;

  # We want X-Forum 1.2 to be compatible with old versions...
  my $OldFile = FileName_Access($Member);
  my $NewFile = FileName_Views($Member);

  my %Views;
  # Work with the new binary file...
  if(sysopen(LXS, $NewFile, O_RDONLY))
  {
    my $Time;
    flock(LXS, LOCK_SH);
    binmode(LXS);

    # Jump through the file, based on the topics requested.
    foreach my $Topic (sort @{$Topics})
    {
      my $Location = MEMBER_LXS_RECSIZE * ($Topic - 1);

      if(seek(LXS, $Location, 0)
      && read(LXS, $Time, MEMBER_LXS_RECSIZE))
      {
        # Got the data! Save it into the hash.
        $Views{$Topic} = unpack(MEMBER_LXS_RECORD, $Time);
      }
    }
    close(LXS);
  }
  elsif(-e $OldFile && ! -e $NewFile)  # sysopen() could fail for some other reason aswell...
  {
    # Convert the old array style into the new hash,
    # using the topic ID as key, and the time as value.
    my $I;
    %Views = map { ++$I => $_ } dbGetFileContents($OldFile, FILE_NOERROR);

    dbMemberConvertLXS($Member);
  }
  return \%Views;
}

sub dbMemberUpdateViews ($$)
{ my($Member, $Topic) = @_;
  if ($Member ne '')
  {
    # We want X-Forum 1.2 to be compatible with old versions...
    my $OldFile = FileName_Access($_[ID]);
    my $NewFile = FileName_Views($_[ID]);

    my $Location = MEMBER_LXS_RECSIZE * ($Topic - 1);
    my $TimeData = pack(MEMBER_LXS_RECORD, SaveTime());

    # Work with the new binary file...
    if(sysopen(LXS, $NewFile, O_WRONLY))
    {
      flock(LXS, LOCK_EX);
      binmode(LXS);

      if(! seek(LXS, $Location, 0))
      {
        # Empty records
        my $EmptyData = pack(MEMBER_LXS_RECORD, 0);

        # Goto EOF, and retreive that position
        seek(LXS, 0, 2) or die "Can't goto EOF in $NewFile: $!\n";
        my $EOFLocation = ((stat LXS)[STAT_SIZE]) / MEMBER_LXS_RECSIZE;
        if(int($EOFLocation) != $EOFLocation) { die "Bad binary data in $NewFile\n"; }

        for(my $I = $EOFLocation; $I < $Topic; $I++)
        {
          print $I;
          print $EmptyData; # Empty record
        }
      }

      print LXS $TimeData;

      close(LXS);
    }
    elsif(! -e $NewFile)  # sysopen() could fail for some other reason aswell
    {
      # The old (bit modified) code for the array version
      my @TopicViews = dbGetFileContents($OldFile, FILE_NOERROR);
      if (not @TopicViews)         { @TopicViews = ((0) x ($Topic - 1), SaveTime()); }
      elsif (@TopicViews < $Topic) { push @TopicViews, (0) x ($Topic - @TopicViews - 1), SaveTime(); }
      else                         { $TopicViews[$Topic - 1] = SaveTime(); }
      dbSetFileContents($OldFile, "Can't store member view list!", @TopicViews);

      dbMemberConvertLXS($Member);
    }
  }
}


sub dbMemberInitTopicViews
{ my($Member, $Topics) = @_;

  my $NewFile = FileName_Views($Member);
  my $Time    = SaveTime();


  if(open(LXS, ">$NewFile"))
  {
    flock(LXS, LOCK_EX);
    binmode(LXS);
    foreach(1..$Topics)
    {
      print LXS pack(MEMBER_LXS_RECORD, $Time);
    }
  }
  close(LXS);

}


##################################################################################################
## Flood Timeout

sub dbMemberFloodTest ($$$)
{ my($Member, $LastPostDate, $Time) = @_;

  if(dbMemberIsGuest($Member))
  {
    ## BEGIN INNER SUBROUTINE ##
    my $CheckIP =
    sub
    {
      my($FileTime, $FileIP) = split(/\|/);
      $FileTime ||= 0;
      $FileIP   ||= '';

      if($FileIP eq $XForumUserIP)
      {
        # Got it! (remove because we update later)
        $LastPostDate = $FileTime;
        $_ = undef;
      }
      elsif(($FileTime + $FLOOD_TIMEOUT) < $Time)
      {
        # This guest may post anyway, so remove it.
        $_ = undef;
      }
    };
    ## END INNER SUBROUTINE ##

    my $IPS = new File::PlainIO("$DATA_FOLDER${S}guestpost.rct", MODE_RDWR);
    if(defined $IPS)
    {
       $IPS->update($CheckIP);
       $IPS->writeline("$Time|$XForumUserIP");
       $IPS->close();
    }
  }
  else
  {
    if(! defined $LastPostDate)
    {
      ($LastPostDate) = dbGetFileContents(FileName_Member($Member), "Can't test member flood", undef, DB_MEMBER_LASTPOSTDATE, 1);
    }
  }

  $LastPostDate ||= 0;

  if(($LastPostDate + $FLOOD_TIMEOUT) >= $Time)
  {
    Action_Error("$MSG[ERROR_FLOOD1]<BR>\n    $MSG[ERROR_FLOOD2]", 1) ;
  }
}


##################################################################################################
## Has Messages?


sub dbMemberHasNewMsg ($)
{
  my $Field1;
  my $Length;

  if(DB_MEMBER_LASTMSG_RECVDATE < DB_MEMBER_LASTMSG_VIEWDATE)
  {
    $Field1 = DB_MEMBER_LASTMSG_RECVDATE;
    $Length = DB_MEMBER_LASTMSG_VIEWDATE - DB_MEMBER_LASTMSG_RECVDATE +1;
  }
  else
  {
    $Field1 = DB_MEMBER_LASTMSG_VIEWDATE;
    $Length = DB_MEMBER_LASTMSG_RECVDATE - DB_MEMBER_LASTMSG_VIEWDATE + 1;
  }

  my($LastReceived, $LastViewed) = dbGetFileContents(FileName_Member($_[ID]), FILE_NOERROR, undef, $Field1, $Length);

  return ($LastReceived || 0) > ($LastViewed || 0);
}


##################################################################################################
## Conversion ;-)

sub dbMemberConvertLXS
{ my($Member) = @_;
  my $OldFile = FileName_Access($_[ID]);
  my $NewFile = FileName_Views($_[ID]);
  my @TopicViews = dbGetFileContents($OldFile, "Can't initialize conversion for $OldFile");

  open(LXS, ">$NewFile") or die "Can't initialize conversion transfer to $NewFile: $!\n";
  flock(LXS, LOCK_EX);
  {
    foreach my $Time (@TopicViews)
    {
      print LXS pack(MEMBER_LXS_RECORD, $Time || 0);
    }
  }
  close(LXS);

  unlink($OldFile)
  or rename($OldFile => "$OldFile~")
  or die "Can't finish conversion, please delete $OldFile~ manually: $!\n";
}


##################################################################################################
## Tests for portability

sub dbMemberIndexExist ()   { return -e FileName_Members;       }
sub dbMemberInvalid (@)     { return ($_[ID] || '') eq '' || $_[ID] ne ($_[ID + 1] || ''); }
sub dbMemberCount (;$)      { return dbCountEntries(FileName_Members(), $_[0]) }

my %ExistingMembers;
sub dbMemberExist ($;$)
{
  if(! exists $ExistingMembers{$_[ID]} || $_[1])
  {
    my $exist = (-e FileName_Member($_[ID])) ? 1:0;
    $ExistingMembers{$_[ID]} = $exist unless $_[1];
    return $exist;
  }
  return $ExistingMembers{$_[ID]};
}

sub dbMemberFileInvalid ($)
{
  return dbMemberExist($_[ID])
      && dbMemberInvalid($_[ID], dbGetFileContents(FileName_Member($_[ID]), FILE_NOERROR, 0,ID,1));
}

1;
