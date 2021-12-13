##################################################################################################
##                                                                                              ##
##  >> Sticky Topics <<                                                                         ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_sticktopic.pl'} = 'Release 1.3';

LoadSupport('db_topics');
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
ValidateAdminAccess();



#################################################################################################
## Lock Topic


sub Show_StickTopicDialog ()
{
  # Show a confirm dialog
  Show_ConfirmDialog($MSG[SUBTITLE_STICK], ($TopicInfo[DB_TOPIC_STICKY] ? $MSG[STICK_CONFIRMUN] : $MSG[STICK_CONFIRM]));
}


sub Action_StickTopic ()
{
  # Test the confirmation; or redirect back
  Action_Confirm();

  # Lock/Unlock the topic
  $TopicInfo[DB_TOPIC_STICKY] = ! $TopicInfo[DB_TOPIC_STICKY];
  dbSaveTopicInfo(@TopicInfo);

  # Bump to top...
  dbTopicMoveToTop($Topic, $TopicInfo[DB_TOPIC_SUBJECT], 1);

  # Log print
  my $ActionLog = ($TopicInfo[DB_TOPIC_STICKY] ? 'UNSTICKTOPIC' : 'STICKTOPIC');
  print_log($ActionLog, $XForumUser, "TOPIC=$Topic");

  # Redirect to the subject
#  print redirect("$THIS_URL?show=subject&page=1&subject=$TopicInfo[DB_TOPIC_SUBJECT]");
  print redirect("$THIS_URL?show=topic&page=1&topic=$Topic");
  exit;
}

1;
