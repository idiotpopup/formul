##################################################################################################
##                                                                                              ##
##  >> Modifications to Posts <<                                                                ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_editpost.pl'} = 'Release 1.3';

LoadSupport('db_topics');
LoadSupport('db_posts');
LoadSupport('db_members');
LoadSupport('db_groups');
LoadSupport('check_security');
LoadSupport('check_fields');



#################################################################################################
## Check access and examine parameters

ValidateMemberCookie();

# Get parameters and the data strcutures
my ($Topic, $Post)           = (param('topic') || '', param('post') || '');
my @TopicInfo                = dbGetTopicInfo($Topic, 1);
my @SubjectInfo              = dbGetSubjectInfo($TopicInfo[DB_TOPIC_SUBJECT], 1);
my($PostContents, @PostInfo) = dbGetPostTest($Topic, $Post);
my $TopicPage                = dbGetPostPage($Post);

# Do we have access?
ValidateSubjectAccess($SubjectInfo[DB_SUBJECT_GROUPS], $SubjectInfo[DB_SUBJECT_MODERATORS]);
ValidatePostEditAccess($SubjectInfo[DB_SUBJECT_MODERATORS], $PostInfo[DB_POST_POSTER], $TopicInfo[DB_TOPIC_LOCKED]);



#################################################################################################
## Show Edit Post

sub Show_EditPostDialog ()
{
  LoadSupport('html_xbbcedit');

  # Build HTML Header
  print_header;
  print_header_HTML($MSG[SUBTITLE_EDITPOST], $MSG[SUBTITLE_EDITPOST], undef, $XBBC_JS);

  # Interface...
  print_toolbar_HTML();
  print_treelevel_HTML(
                        "?show=subject&page=1&subject=$TopicInfo[DB_TOPIC_SUBJECT]"  => $SubjectInfo[DB_SUBJECT_TITLE],
                        "?show=topic&page=$TopicPage&topic=$Topic"                   => $TopicInfo[DB_TOPIC_TITLE],
                        "?show=editpost&topic=$Topic&post=$Post"                     => $MSG[SUBTITLE_EDITPOST]
                      );
  print_bodystart_HTML();

  # XBBC Editor printed
  print_XBBCEditor_HTML(
                        'editpost', $MSG[ACTION_SAVE],
                                    $MSG[ADDPOST_TITLE],
                                    $PostInfo[DB_POST_TITLE],
                                    $PostInfo[DB_POST_ICON],
                                    $PostContents,
                                    undef,
                                    $PostInfo[DB_POST_POSTER] ne $XForumUser
                       );
}


sub Action_EditPost ()
{
  LoadModule('HTML::EscapeASCII;');
  LoadSupport('db_notify');

  # Get Field Values
  my $Title = (param('title') || '');
  my $Msg   = (param('msg')   || '');
  my $Icon  = (param('icon')  || 'default');
  my $Notify = (param('notify') ? 1 : 0);

  # Make Checks
  ValidateRequired($Title, $Msg);
  ValidateLength($Title, $MSG[ADDPOST_TITLE], 80);
  ValidateLength($Msg, $MSG[XBBC_MESSAGE], $POST_MAX);


  # Make Preview if value of submit button contains the word preview...
  if (param('submit_preview'))
  {
    LoadSupport('dlg_postpreview');
    Show_PostPreview($Msg => $Title, $XForumUser, $Icon, $Topic, $Post, $PostInfo[DB_POST_DATE], $PostInfo[DB_POST_POSTER]);
  }
  elsif(param('submit_post'))
  {
    # Get And Format Fields
    my $Time   = SaveTime();

    FormatFieldHTML($Title);

    # Make the post structure
    $PostInfo[DB_POST_TITLE]         = $Title;
    $PostInfo[DB_POST_LASTMODMEMBER] = $XForumUser;
    $PostInfo[DB_POST_LASTMODDATE]   = $Time;
    $PostInfo[DB_POST_ICON]          = $Icon;


    # Get load the post data file, and update two fields in it.
    dbEditPosts($Topic, $Post => $Msg, @PostInfo);


    # Update the topic data aswell, IF this is the first post.
    if($Post == 1)
    {
      $TopicInfo[DB_TOPIC_TITLE] = $Title;
      $TopicInfo[DB_TOPIC_ICON]  = $Icon;
      dbSaveTopicInfo(@TopicInfo);
    }

    # Print log
    print_log("EDITPOST", $XForumUser, "TOPIC=$Topic POST=$Post");


    # Notification
    if($PostInfo[DB_POST_POSTER] eq $XForumUser)
    {
      if($Notify) { dbAddNotify($Topic, $XForumUser) }
      else        { dbDelNotifyMember($Topic, $XForumUser) }
    }


    # Redirect
    print redirect("$THIS_URL?show=topic&page=$TopicPage&topic=$Topic"); # hash location not allowed in redirect header?!
    exit;
  }
  else
  {
    Action_Error();
  }
}


1;
