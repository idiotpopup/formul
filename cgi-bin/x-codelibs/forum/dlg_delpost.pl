##################################################################################################
##                                                                                              ##
##  >> Modifications to Posts <<                                                                ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_editpost.pl'} = 'Release 1.1';

LoadSupport('db_topics');
LoadSupport('db_posts');
LoadSupport('db_members');
LoadSupport('db_groups');
LoadSupport('check_security');
LoadSupport('check_fields');
LoadSupport('dlg_confirm');


#################################################################################################
## Check access and examine parameters


ValidateMemberCookie();

# Get the parameter information
my $Topic                    = (param('topic') || '');
my $Post                     = (param('post')  || '');
my @TopicInfo                = dbGetTopicInfo($Topic, 1);
my @SubjectInfo              = dbGetSubjectInfo($TopicInfo[DB_TOPIC_SUBJECT], 1);
my($PostContents, @PostInfo) = dbGetPostTest($Topic, $Post);

# Do we have access?
ValidateSubjectAccess($SubjectInfo[DB_SUBJECT_GROUPS], $SubjectInfo[DB_SUBJECT_MODERATORS]);
ValidatePostEditAccess($SubjectInfo[DB_SUBJECT_MODERATORS]);




#################################################################################################
## Show Edit Post

sub Show_DeletePostDialog ()
{
  # Show the confirm dialog
  Show_ConfirmDialog($MSG[SUBTITLE_DELPOST], $MSG[DELPOST_CONFIRM]);
}


sub Action_DeletePost ()
{
  # Test the confirmation dialog
  Action_Confirm();

  # Get the posts
  my @Posts = dbGetPosts($Topic, 1);

  dbClearupPosts( \@Posts );


  # We need the correct postnum, or the argorithm fails.
  my $SaveSubject = 0;
  my $PostNum     = dbCountPosts(\@Posts);


  # Update the topic if needed.
  if($PostNum != $TopicInfo[DB_TOPIC_POSTNUM])
  {
    $TopicInfo[DB_TOPIC_POSTNUM] = $PostNum;
  }


  # If there is just one topic, redirect this request to
  # the topic deletion handler routine
  if($PostNum == 1)
  {
    LoadSupport('dlg_deltopic');
    Action_DeleteTopic();
    exit;
  }


  # Remove the post
  dbDelPost( $Post, \@Posts );
  $TopicInfo[DB_TOPIC_POSTNUM]--;



  # This is possible now, because the dbDelPost routine
  # updates and validates the entire array.
  # Now we can assume that 'scalar @Posts' is correct...
  my $LastPost = (@Posts / 2);

  if($Post >= $LastPost)
  {
    # Update the subject stats.
    if($SubjectInfo[DB_SUBJECT_LASTPOSTTOPIC] == $Topic)
    {
      my @PostInfo = dbGetPostInfo(\@Posts, $LastPost);
      $SubjectInfo[DB_SUBJECT_LASTPOSTER]   = $PostInfo[DB_POST_POSTER];
      $SubjectInfo[DB_SUBJECT_LASTPOSTDATE] = $PostInfo[DB_POST_DATE];
      $SaveSubject = 1;
    }
  }


  # Save the data
  dbSavePosts($Topic, \@Posts);
  dbSaveTopicInfo(@TopicInfo);
  dbSaveSubjectInfo(@SubjectInfo) if ($SaveSubject);


  # Log print
  print_log("DELETEPOST", undef, "TOPIC=$Topic POST=$Post TITLE=$PostInfo[DB_POST_TITLE] USER=$XForumUser");

  # Get the page we redirect to
  $Post = ($Post < $TopicInfo[DB_TOPIC_POSTNUM] ? $Post - 1 : $TopicInfo[DB_TOPIC_POSTNUM]);
  my $TopicPage = dbGetPostPage($Post);

  # Redirect
  print redirect("$THIS_URL?show=topic&page=$TopicPage&topic=$Topic"); # hash location not allowed in redirect header?!
  exit;
}



1;
