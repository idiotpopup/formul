##################################################################################################
##                                                                                              ##
##  >> Lock Topics <<                                                                           ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_locktopic.pl'} = 'Release 1.0';

LoadSupport('db_topics');
LoadSupport('db_groups');
LoadSupport('check_security');
LoadSupport('dlg_confirm');


#################################################################################################
## Check access and examine parameters

ValidateMemberCookie();


# Get the information from the parameters
my ($Topic)     = (param('topic') || '');
my @TopicInfo   = dbGetTopicInfo($Topic, 1);
my @SubjectInfo = dbGetSubjectInfo($TopicInfo[DB_TOPIC_SUBJECT], 1);

# Validate acccess
ValidateSubjectAccess($SubjectInfo[DB_SUBJECT_GROUPS], $SubjectInfo[DB_SUBJECT_MODERATORS]);
ValidateSubjectEditAccess($SubjectInfo[DB_SUBJECT_MODERATORS]);



#################################################################################################
## Lock Topic


sub Show_LockTopicDialog ()
{
  # Show a confirm dialog
  Show_ConfirmDialog($MSG[SUBTITLE_LOCK], ($TopicInfo[DB_TOPIC_LOCKED] ? $MSG[LOCK_CONFIRMUN] : $MSG[LOCK_CONFIRM]));
}


sub Action_LockTopic ()
{
  # Test the confirmation; or redirect back
  Action_Confirm();


  # Lock/Unlock the topic
  $TopicInfo[DB_TOPIC_LOCKED] = ! $TopicInfo[DB_TOPIC_LOCKED];
  dbSaveTopicInfo(@TopicInfo);

  # Log print
  my $ActionLog = ($TopicInfo[DB_TOPIC_LOCKED] ? 'UNLOCKTOPIC' : 'LOCKTOPIC');
  print_log($ActionLog, $XForumUser, "TOPIC=$Topic");

  # Redirect to the topic
  print redirect("$THIS_URL?show=topic&page=1&topic=$Topic");
  exit;
}

1;
