##################################################################################################
##                                                                                              ##
##  >> Administrator Repair Database <<                                                         ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



# TODO: Check banned members


use strict;
use Benchmark;


# Everything we want to let run first!


$VERSIONS{'admin_repair.pl'} = 'Release 1.6';


# This code assumes that all database files
# are flat, files.


my $FIX_COLOR = "#FF0000";

my $DIR_INDEX    = "$DATA_FOLDER";
my $DIR_SUBJECTS = "$DATA_FOLDER${S}subjects";
my $DIR_TOPICS   = "$DATA_FOLDER${S}topics";
my $DIR_MESSAGES = "$DATA_FOLDER${S}messages";
my $DIR_POSTS    = "$DATA_FOLDER${S}posts";
my $DIR_MEMBERS  = "$DATA_FOLDER${S}members";
my $DIR_GROUPS   = "$DATA_FOLDER${S}groups";
my $DIR_SETTINGS = "$DATA_FOLDER${S}settings";

my $EXT_SUBJECT  = "sub";
my $EXT_TOPICS   = "in";
my $EXT_TOPIC    = "top";
my $EXT_POST     = "pst";
my $EXT_MSG_IN   = "msg";
my $EXT_MSG_SENT = "snt";
my $EXT_MEMBER   = "mbr";
my $EXT_VIEWS    = "lxs";  # Older version: lat
my $EXT_FOOTER   = "ftr";
my $EXT_GROUP    = "grp";
my $EXT_BANNED   = "ban";


LoadSupport('db_groups');
LoadSupport('db_members');
#LoadSupport('db_messages');
LoadSupport('db_posts');
LoadSupport('db_stats');
LoadSupport('db_subjects');
LoadSupport('db_topics');


my $IsRepairing = -e "$DATA_FOLDER${S}x-forum.repair";
sub Action_AdminRepairOn   { dbSetFileContents("$DATA_FOLDER${S}x-forum.repair", q[Can't activate repair mode], q[If this file exists, the forum is being repaired!]) };
sub Action_AdminRepairOff  { unlink("$DATA_FOLDER${S}x-forum.repair") or die "Can't turn off repair mode: $!\n"; }

my $ok = 1;
sub printok  ()      { print "All OK\n" if $ok }
sub printpar ($)     { print "\n$_[0]...\n"; $ok=1 }
sub printmsg ($)     { print "$_[0]\n" }
sub printnow ($)     { print "$_[0]...\n" }
sub printfix ($$)    { print qq[<FONT color="$FIX_COLOR">$_[0]</FONT>  - $_[1]...\n]; $ok=0 }
sub ArrayAsHash (\@) { return map { $_ => 1 } @{$_[0]} }



##################################################################################################
## Admin: Repair Database

sub Action_AdminDoRecount
{
  if($IsRepairing) { die "The database is being repaired right now!\n" }

  local($|) = 1;
  Action_AdminRepairOn();

  my $StartTime = new Benchmark;
  printnow "Analysing";


  my @Stat        = dbGetStats();


  my $StatUpdated = 0;   # Did we discover any changes?
  my %Subjects=();       # Subject names linked to an index number used in %TopicSeenIn
  my %TopicSeenIn;       # Topics seen in subject, element value (number) is a key of %Subjects, uses less memory
  my %TopicDeleted;      # Topics that should be ingored
  my %TopicSticky;       # Topics that are sticky
  my %MemberFileSeen;    # Member files seen

  my %SubjectTopicNum;   # The number of topics



  # The sequence wherein this is checked is very important.
  # Some code parts rely on facts discovered by other parts.
  # That also implies that the next codepart can assume
  # that a certain check has been made (like exists, is valid)




  #________________________________#
  #                                #
  # Repair the subject index       #
  #________________________________#
  #                                #


  {
    printpar "Checking subjects";

    my @SubjectFiles = GetDatabaseFiles($DIR_SUBJECTS, $EXT_SUBJECT, 1);
    my @ResultIndex;
    my @SubjectIndex;
    my $IndexUpdated = 0;
    my $SubjectsRebuild = 0;
    my %SubjectSeen;
    my $I = 0;


    if(! dbSubjectIndexExist() )
    {
      #  The subject file does not exist.
      #  We rebuild it

      if(@SubjectFiles)
      {
        printfix "Subject index not found", "Rebuilding";
        my @SubjectIndex  = ('Subjects', map { "--$_" } @SubjectFiles);

        $IndexUpdated    = 1;
        $SubjectsRebuild = 1;

        # This is not where the story ends.
        # The subjects also need to be analysed.
        # We don't edit the resultindex here!
      }
    }
    else
    {
      @SubjectIndex = dbGetSubjects();
    }


    # Check all files in the index, remove them (aswell)
    # from the index if they are invalid
    #

    my %SubjectFiles  = ArrayAsHash(@SubjectFiles);

    foreach my $Subject (@SubjectIndex)
    {
      if(! dbSubjectIsTitle($Subject))
      {
        if(! $SubjectsRebuild && ! exists $SubjectFiles{$Subject} )
        {
          # Subject found in the index does not exist
          #

          printfix "Subject ID '$Subject' does not exist", "Removing from subject index";
          $IndexUpdated=1;
        }
        elsif(! $SubjectsRebuild && $SubjectSeen{$Subject} )
        {
          # Subject already found in the index
          #

          printfix "Subject Index already contains subject ID '$Subject'", "Removing from subject index";
          $IndexUpdated=1;
        }
        elsif(dbSubjectFileInvalid($Subject))
        {
          # Subject file is invalid
          #

          RemoveFile('subject', $DIR_SUBJECTS, $Subject, $EXT_SUBJECT);
          $IndexUpdated=1;
        }
        else
        {
          # Add to the result index
          #

          push @ResultIndex, "--$Subject";
          $SubjectSeen{$Subject} = 1;
          $Subjects{$Subject} = $I++;    # For later use...
        }
      }
      else
      {
        # The subject is a title
        #

        push @ResultIndex, "$Subject"
      }
    }



    # Are there more subjects that aren't located in the index?
    #

    my $Seen = keys %SubjectSeen;

    if(@SubjectFiles > $Seen)
    {
      my $AddedTitle = 0;
      foreach my $Subject (@SubjectFiles)
      {
        if(! exists $SubjectSeen{$Subject} )
        {
          if(dbSubjectFileInvalid($Subject))
          {
            # Not in the index, but it's invalid aswell
            #

            RemoveFile('subject', $DIR_SUBJECTS, $Subject, $EXT_SUBJECT)
          }
          else
          {
            # Add to the index
            #

            printfix "Subject ID '$Subject' not used in the subjects index", "Adding";
            push @ResultIndex, "Reparation at ".localtime unless $AddedTitle;
            push @ResultIndex, "--$Subject";
            $AddedTitle = 1;
            $IndexUpdated=1;
          }
        }
      }
    }


    # Any changes to the index?
    #

    if($IndexUpdated)
    {
      dbSaveSubjects(@ResultIndex);
      printmsg "Subject index updated";
    }
  }
  printok;






  #________________________________#
  #                                #
  # Repair the topics              #
  #________________________________#
  #                                #

  {
    printpar "Checking topics";

    my @TopicFiles   = GetDatabaseFiles($DIR_TOPICS, $EXT_TOPIC);
    my $TopicNum     = 0;
    my $PostNum      = 0;
    my $LargestTopic = 0;  # For the DB_STAT_TOPICID constant in contents.stat


    # Check if the post and topic files both exist
    #

    my $TOPIC = 1;              # 0001
    my $POST  = 2;              # 0010
    my $BOTH  = $TOPIC | $POST; # 0011

    my @PostFiles  = GetDatabaseFiles($DIR_POSTS,  $EXT_POST);
    my %Seen;

    foreach (@TopicFiles) { $Seen{$_} |= $TOPIC }  # Binary OR (0|1=1)
    foreach (@PostFiles)  { $Seen{$_} |= $POST  }  # Binary OR (1|2=3, 0|2=2)


    while( my($Topic, $Seen) = each %Seen )
    {
      if($Seen != $BOTH)
      {
        # Is the topic or the post missing?
        #

        my $TopicMissing = ($Seen & $TOPIC) == 0;  # Binary AND (2&2=2, 2&1=0)
        my $PostMissing  = ($Seen & $POST)  == 0;  # Binary AND (1&2=1, 1&1=1)

        if($TopicMissing)
        {
          # The topic.top is missing
          #

          RemoveFile('post', $DIR_POSTS, $Topic, $EXT_POST);
          printmsg "Note: the post file did not belong to any topic";
          $TopicDeleted{$Topic} = 1;
        }
        elsif($PostMissing)
        {
          # The topic.pst is missing
          #

          RemoveFile('topic', $DIR_TOPICS, $Topic, $EXT_TOPIC);
          printmsg "Note: the topic file did not have any posts";
          $TopicDeleted{$Topic} = 1;
        }
        else
        {
          # Damn!
          #

          die "Error in binary logic: $TOPIC (=TOPIC) + $POST (=POST) = $Seen ; BOTH=$BOTH\n"
        }
      }
      else
      {
        my @TopicInfo = dbGetTopicInfo($Topic, 0);

        if(dbTopicInvalid($Topic, @TopicInfo))
        {
          # Is the topic invalid?
          #

          RemoveFile('topic', $DIR_TOPICS, $Topic, $EXT_TOPIC);
          $TopicDeleted{$Topic} = 1;
        }
        elsif((stat(FileName_Posts($Topic)))[7] == 0)
        {
          # Are the posts invalid?
          #

          RemoveFile('topic', $DIR_TOPICS, $Topic, $EXT_TOPIC);
          RemoveFile('post', $DIR_POSTS, $Topic, $EXT_POST);
          printmsg "Note: no data found in the post file";
          $TopicDeleted{$Topic} = 1;
        }
        else
        {
          # Add to the stats
          #

          my $TopicPostNum           = dbCountFilePosts($Topic);
          $PostNum                  += $TopicPostNum;

          if($TopicInfo[DB_TOPIC_POSTNUM] != $TopicPostNum)
          {
            printfix "The nubmer of posts was invalid in topic '$Topic'", "Repairing";
            $TopicInfo[DB_TOPIC_POSTNUM] = $TopicPostNum;
            dbSaveTopicInfo(@TopicInfo);
          }



          $TopicNum++;                                                            # Add total topics
          $SubjectTopicNum{$TopicInfo[DB_TOPIC_SUBJECT]}++;                       # Add subject topics
          $TopicSeenIn{$Topic}       = $Subjects{$TopicInfo[DB_TOPIC_SUBJECT]};   # Save topic-subject combination
          $TopicSticky{$Topic}       = 1 if $TopicInfo[DB_TOPIC_STICKY];          # Save sticky info (only if sticky)
          $LargestTopic              = $Topic if ($Topic > $LargestTopic);        # Save largest topic id number
        }
      }
    }



    # Check if the stats need to be updated
    #

    if($TopicNum != $Stat[DB_STAT_TOPICNUM])
    {
      printfix "Total number of topics invalid (not $Stat[DB_STAT_TOPICNUM] but $TopicNum)", "Repairing";
      $Stat[DB_STAT_TOPICNUM] = $TopicNum;
      $StatUpdated = 1;
    }

    if($PostNum != $Stat[DB_STAT_POSTNUM])
    {
      printfix "Total number of posts invalid (not $Stat[DB_STAT_POSTNUM] but $PostNum)", "Repairing";
      $Stat[DB_STAT_POSTNUM] = $PostNum;
      $StatUpdated = 1;
    }

    if($LargestTopic > $Stat[DB_STAT_TOPICID])
    {
      printfix "There is a problem with the topic ID generator", "Repairing";
      $Stat[DB_STAT_TOPICID] = $LargestTopic;
      $StatUpdated = 1;
    }
  }
  printok;






  #________________________________#
  #                                #
  # Repair the topic indexes       #
  #________________________________#
  #                                #

  {
    printpar "Checking topic indexes";

    my @IndexFiles = GetDatabaseFiles($DIR_SUBJECTS, $EXT_TOPICS);
    my %SubjectIDs = reverse %Subjects; # Only for small hashes

    foreach my $Subject (@IndexFiles)
    {
      if(! exists $Subjects{$Subject} )
      {
        # An subject.in file is found, but the subject.sub
        # file does not exist
        #

        RemoveFile('topic index', $DIR_SUBJECTS, $Subject, $EXT_TOPICS);
        printmsg "Note: Subject ID ($Subject) does not exist!";
      }
      else
      {
        # Check the topics from the subject
        #

        my @Topics  = dbGetTopics($Subject);
        my $Updated = 0;
        my @NewTopics;
        my %TopicSeen;
        my $FirstStickyIndex;
        my $I = 0;


        while(my $Topic = shift @Topics)
        {
          if(exists $TopicDeleted{$Topic})
          {
            # Ignore the topic
            #

            printmsg "Topic ID '$Topic' has been removed, and is deleted from the index now";
            $Updated = 1;
          }
          elsif(! dbTopicExist($Topic))
          {
            # Topic located in the index does not exist
            #

            printfix "Topic ID '$Topic' in subject '$Subject' does not exist", "Removed";
            $Updated = 1;
          }
          elsif($SubjectIDs{$TopicSeenIn{$Topic}} ne $Subject)
          {
            # The topic should be located in a different index
            #

            printfix "Topic ID '$Topic' is already used in subject '$SubjectIDs{$TopicSeenIn{$Topic}}'", "Removing from '$Subject'";
            $Updated = 1;
          }
          elsif(exists $TopicSeen{$Topic})
          {
            # The topic is already located in this index
            #

            printfix "Topic ID '$Topic' is already used in this subject ($Subject)", "Removing";
            $Updated = 1;
          }
          else
          {
            # Add topic to this (maybe modified) index
            #

            push @NewTopics, $Topic;
            $TopicSeen{$Topic} = 1;
            $FirstStickyIndex = $I if $TopicSticky{$Topic};
            $I++;
          }
        }


        # Are there any topics we didn't add to the index?
        # But should be?
        #

        my @AddTopics;

        topic:while( my($Topic,$SubjectID) = each %TopicSeenIn )
        {
          next topic if $TopicSeen{$Topic};

          if($SubjectIDs{$SubjectID} eq $Subject)
          {
            # Add to this subject!
            #

            printfix "Subject index '$Subject' did not contain topic '$Topic'", "Added";
            push @AddTopics, $Topic;
            $TopicSeen{$Topic} = 1;
          }
        }


        # Check the topic num
        #

        my @SubjectInfo = dbGetSubjectInfo($Subject, 0);
        $SubjectTopicNum{$Subject} ||= 0;

        if($SubjectInfo[DB_SUBJECT_TOPICNUM] != $SubjectTopicNum{$Subject})
        {
          printfix "Topic amount stat for subject '$Subject' was invalid (not $SubjectInfo[DB_SUBJECT_TOPICNUM] but $SubjectTopicNum{$Subject})", "Repairing";
          $SubjectInfo[DB_SUBJECT_TOPICNUM] = $SubjectTopicNum{$Subject};
          dbSaveSubjectInfo(@SubjectInfo);
        }



        # Are there any updates?
        #

        if(@AddTopics)
        {
          if(! defined $FirstStickyIndex) { dbSaveTopics($Subject => @AddTopics, @NewTopics) }
          elsif($FirstStickyIndex == 0)   { dbSaveTopics($Subject => @AddTopics, @NewTopics) }
          else                            { dbSaveTopics($Subject => @NewTopics[0..$FirstStickyIndex-1], @AddTopics, @NewTopics[$FirstStickyIndex..@NewTopics-1]) }

          printmsg "Saving topic index for subject '$Subject'";
        }
        elsif($Updated)
        {
          dbSaveTopics($Subject => @NewTopics);
          printmsg "Saving topic index for subject '$Subject'";
        }
      }
    }
  }
  printok;











  #________________________________#
  #                                #
  # Repair the member index        #
  #________________________________#
  #                                #

  {
    printpar "Checking member files";

    my @Members;
    my @MemberFiles = GetDatabaseFiles($DIR_MEMBERS, $EXT_MEMBER);
    my $MemberNum;

    foreach my $Member (@MemberFiles)
    {
      if(dbMemberFileInvalid($Member))
      {
        RemoveFile('member', $DIR_MEMBERS, $Member, $EXT_MEMBER)
      }
      else
      {
        push @Members, $Member;
        $MemberFileSeen{$Member} = 1;
      }
    }

    $MemberNum = @Members;

    if(! dbMemberIndexExist() )
    {
      printfix "Member index not found!", "Rebuilding";
      dbSaveMembers(@Members);
    }
    elsif(dbMemberCount(1) != $MemberNum)
    {
      printfix "Member index containes invalid entries", "Removed";
      dbSaveMembers(@Members);
    }

    if($MemberNum != $Stat[DB_STAT_MEMBERNUM])
    {
      printfix "Total number of members invalid (not $Stat[DB_STAT_MEMBERNUM] but $MemberNum)", "Repairing";
      $Stat[DB_STAT_MEMBERNUM] = $MemberNum;
      $StatUpdated = 1;
    }
  }
  printok;





  #________________________________#
  #                                #
  # Repair the member groups       #
  #________________________________#
  #                                #

  # The members have already been tested, so we
  # don't need to test is they are valid aswell.

  {
    printpar "Checking member groups";

    my @GroupFiles = GetDatabaseFiles($DIR_GROUPS, $EXT_GROUP);
    my @Groups     = ('everyone');

    foreach my $Group (@GroupFiles)
    {
      if($Group eq 'everyone')
      {
        RemoveFile('group', $DIR_GROUPS, $Group, $EXT_GROUP);
        printmsg "Note: the 'everyone' group is a virtual group.";
      }
      elsif(dbGroupFileInvalid($Group))
      {
        RemoveFile('group', $DIR_GROUPS, $Group, $EXT_GROUP)
      }
      else
      {
        push @Groups, $Group;

        # Check the group members
        my %MemberSeen;
        my $Updated = 0;
        my ($ID, $Title, @Members) = dbGetGroupInfo($Group, 1);
        my @GroupInfo = ($ID, $Title);

        while(my $Member = shift @Members)
        {
          if($MemberSeen{$Member})
          {
            printfix "Group file '$Title' ($ID) has another entry for member '$Member'", "Removed";
            $Updated = 1;
          }
          elsif(! exists $MemberFileSeen{$Member})
          {
            printfix "Group file '$Title' ($ID) has an unknown member entry named '$Member'", "Removed";
            $Updated = 1;
          }
          else
          {
            $MemberSeen{$Member} = 1;
            push @GroupInfo, $Member;
          }
        }

        dbSaveGroupInfo(@GroupInfo) if($Updated);
      }
    }

    if(! dbGroupIndexExist() )
    {
      printfix "Membergroup index not found!", "Rebuilding";
      dbSaveGroups(@Groups);
    }
    elsif(dbGroupCount(1) != @Groups)
    {
      printfix "Membergroup index containes invalid entries", "Removed";
      dbSaveGroups(@Groups);
    }
  }
  printok;






  #________________________________#
  #                                #
  # Stats                          #
  #________________________________#
  #                                #

  {
    printpar "Checking statistics";
    if($StatUpdated)
    {
      printmsg "Some stats have been updated";
      dbSaveStats(@Stat);
    }
    else
    {
      printok;  # Because we didn't use the printfix sub
    }
  }



  #________________________________#
  #                                #
  # End                            #
  #________________________________#
  #                                #

  print qq[\nTotal process took] . timestr(timediff(new Benchmark, $StartTime)) . qq[\n];

  Action_AdminRepairOff();
}










##################################################################################################
## Get the datafiles from an extension

sub GetDatabaseFiles ($$;$)
{ my($Dir, $Extension, $Sort) = @_;
  my @Files;

  opendir(PATH, $Dir) or die "Can't browse to directory $Dir: $!";
  {
    @Files = map  { s/\Q.$Extension\E$//; $_ }  # Replace the extension (; $_ returns that result, not the success code of the s///)
             grep { /\Q.$Extension\E$/ }        # Only files with that extension
             readdir PATH;                      # Get the files

    @Files = sort
             {
               uc($a) cmp uc($b);
             }
             @Files if($Sort);
  }
  closedir(PATH);

  return @Files;
}



##################################################################################################
## Remove a file to a fix_removed folder

sub RemoveFile ($$$$)
{ my($Title, $OldDir, $OldFile, $OldExt) = @_;
  my $FixDir = "fix_removed";
  my $NewDir = "$DATA_FOLDER${S}$FixDir";
  my $OldLoc = "$OldDir${S}$OldFile.$OldExt";
  my $NewLoc = "$NewDir${S}$OldFile.$OldExt";

  if(! -e $NewDir) { mkdir($NewDir, 0777) or die "Can't create the folder '$NewDir' to move $Title '$OldFile' to: $!\n" }
  if(  -e $NewLoc) { die "Can't move $Title '$OldLoc' to folder '$NewDir': Destination file already exists\n"; }

  rename $OldLoc => $NewLoc or die "Can't move '$OldLoc' to folder '$NewDir': $!\n";
  printfix "Invalid file for $Title '$OldFile'", "Moved to '$FixDir'";
}



1;