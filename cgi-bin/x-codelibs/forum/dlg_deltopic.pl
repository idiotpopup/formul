##################################################################################################
##                                                                                              ##
##  >> Delete Topics <<                                                                         ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_movetopic.pl'} = 'Release 1.0';

LoadSupport('db_topics');
LoadSupport('db_posts');
LoadSupport('db_groups');
LoadSupport('check_security');
LoadSupport('dlg_confirm');


#################################################################################################
## Check access and examine parameters


ValidateMemberCookie();

my $Topic       = (param('topic') || '');
my @TopicInfo   = dbGetTopicInfo($Topic, 1);
my @SubjectInfo = dbGetSubjectInfo($TopicInfo[DB_TOPIC_SUBJECT], 1);


# Do you have access?
ValidateSubjectAccess($SubjectInfo[DB_SUBJECT_GROUPS], $SubjectInfo[DB_SUBJECT_MODERATORS]);
ValidateSubjectEditAccess($SubjectInfo[DB_SUBJECT_MODERATORS]);




#################################################################################################
## Show Add Topic

sub Show_DeleteTopicDialog ()
{
  # Show the confirmation dialog
  Show_ConfirmDialog($MSG[SUBTITLE_DELTOPIC], $MSG[DELTOPIC_CONFIRM]);
}




sub Action_DeleteTopic ()
{
  # Test for the confirmation of the previous dialog
  Action_Confirm();


  LoadSupport('check_fields');


  # Get Information for transfer of topic
  my @Topics = dbGetTopics($TopicInfo[DB_TOPIC_SUBJECT]);
  my $I      = 0;
  my $Found  = 0;


  if(@Topics == 1)
  {
    # There is just one topic in this subject
    if($Topics[0] eq $Topic)
    {
      # Remove the topic index file
      dbDelTopics($TopicInfo[DB_TOPIC_SUBJECT], 1, $TopicInfo[DB_TOPIC_POSTNUM]);

      # Erase all the information in the subject
      $SubjectInfo[DB_SUBJECT_LASTPOSTER]    = '';
      $SubjectInfo[DB_SUBJECT_LASTPOSTDATE]  = 0;
      $SubjectInfo[DB_SUBJECT_LASTPOSTTOPIC] = 0;
      $Found = 1;
    }
  }
  else
  {
    topicsearch:foreach my $InTopic (@Topics)
    {
      if($InTopic == $Topic)
      {
        # Topic found! delete it.
        splice(@Topics, $I, 1) == $Topic or die "Can't remove topic from subject '$TopicInfo[DB_TOPIC_SUBJECT]'\n";
        dbSaveTopics($TopicInfo[DB_TOPIC_SUBJECT] => @Topics);

        # Erase the topic information....?
        if($Topic == $SubjectInfo[DB_SUBJECT_LASTPOSTTOPIC])
        {
          $SubjectInfo[DB_SUBJECT_LASTPOSTER] = '';
          $SubjectInfo[DB_SUBJECT_LASTPOSTDATE] = 0;
          $SubjectInfo[DB_SUBJECT_LASTPOSTTOPIC] = 0;
        }

        $Found = 1;
        last topicsearch;
      }
      $I++;
    }
  }

  if(! $Found) { die "Can't remove topic from subject '$TopicInfo[DB_TOPIC_SUBJECT]'. Topic not found\n"; }


  # Update the subject
  $SubjectInfo[DB_SUBJECT_TOPICNUM]--;
  dbSaveSubjectInfo(@SubjectInfo);

  # Delete the topic and post file
  dbDelTopic($Topic, $TopicInfo[DB_TOPIC_POSTNUM]);


  # Log print and redirect
  print_log("DELTOPIC", undef, "TOPIC=$Topic TITLE=$TopicInfo[DB_TOPIC_TITLE] USER=$XForumUser");
  print redirect("$THIS_URL?show=subject&page=1&subject=$TopicInfo[DB_TOPIC_SUBJECT]");
  exit;
}

1;
