##################################################################################################
##                                                                                              ##
##  >> Display of Forum/Subject and Topics <<                                                   ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_subject.pl'} = 'Release 1.6';

LoadSupport('check_security');
LoadSupport('check_fields');
LoadSupport('db_topics');
LoadSupport('db_members');
LoadSupport('db_groups');
LoadSupport('html_tables');

my @STYLE_TITLE = ('',   '',      qq[size="2"]);
my @STYLE_REPLY = ('70', 'right', qq[size="1"]);
my @STYLE_VIEWS = ('70', 'right', qq[size="1"]);
my @STYLE_TIMES = ('150', '',     qq[size="1"]);


##################################################################################################
## Subject

sub Show_Subject ()
{
  # Get additional information
  my $Subject          = param('subject')  || '';
  my $Page             = param('page')     || 1;
  my @SubjectInfo      = dbGetSubjectInfo($Subject, 1);
  my @Topics           = dbGetTopics($Subject);
  my $SubjectChange    = 0;
  my @ToolbarButtons;


  # Check the access
  ValidateSubjectAccess($SubjectInfo[DB_SUBJECT_GROUPS], $SubjectInfo[DB_SUBJECT_MODERATORS]);
  ValidateNumber($Page, $MSG[ISNUM_PAGE]);


  # Autorestore Statics if it appears to be incorrect!
  if (@Topics != $SubjectInfo[DB_SUBJECT_TOPICNUM])
  {
    $SubjectInfo[DB_SUBJECT_TOPICNUM] = @Topics;
    $SubjectChange = 1;
  }


  # Calc num pages and test
  my $Pages = dbGetSubjectPages(undef, $SubjectInfo[DB_SUBJECT_TOPICNUM]);
  if ($Page < 1 || $Page > $Pages)
  {
    Action_Error($MSG[PAGE_OVERFLOW]);
  }

  # Determine toolbar buttons
  push @ToolbarButtons, sprint_button_HTML($MSG[BUTTON_NEWTOPIC] => "$THIS_URL?show=addtopic&subject=$Subject", 'newtopic', $MSG[BUTTON_NEWTOPIC_INFO]) unless($GUEST_NOPOST && $XForumUser eq '' && $GUEST_NOBTN);
  push @ToolbarButtons, sprint_button_HTML($MSG[BUTTON_MOVEALL]  => "$THIS_URL?show=movetopics&subject=$Subject", 'movetopics', $MSG[BUTTON_MOVETOPICS_INFO]) if($XForumUser eq 'admin' && defined $Topics[0]);

  # Determine moderator list
  my $ModeratorList = '';
  foreach my $Moderator (split(/,/, $SubjectInfo[DB_SUBJECT_MODERATORS]))
  {
    if (length($Moderator || ''))
    {
      my $Name = dbGetMemberName($Moderator, 0);
      $ModeratorList .= ', ' if(length($ModeratorList));
      $ModeratorList .= "<NOBR>" . sprint_memberlink_HTML($Moderator) . "</NOBR>";
    }
  }


  # HTML Header
  print_header;
  print_header_HTML($SubjectInfo[DB_SUBJECT_TITLE], $MSG[SUBTITLE_SUBJECT]);
  print_toolbar_HTML(@ToolbarButtons);
  print_treelevel_HTML(
                        qq[?show=subject&page=1&subject=$Subject] => $SubjectInfo[DB_SUBJECT_TITLE]
                      );
  print qq[    <P>\n    <B>$MSG[SUBJECT_MODERATORS]:</B> <FONT size="1">$ModeratorList</FONT>\n];
  print_bodystart_HTML();


  # Print the topics
  if (defined $Topics[0])
  {
    # Calc start and end value
    my $Start = ($Page - 1) * $PAGE_TOPICS;
    my $End   = $Start + $PAGE_TOPICS;
    $End      = $SubjectInfo[DB_SUBJECT_TOPICNUM] if ($End > $SubjectInfo[DB_SUBJECT_TOPICNUM]);


    print_subjectpages_HTML($Subject, $Pages, $Page);


    # Get topic views
    my $Views;
    $Views = dbGetMemberViews($XForumUser, \@Topics) unless($XForumUser eq '');


    # Build up topics table header
    print_tableheader_HTML(
                            $TABLE_MAX_HTML,
                            $MSG[TOPIC_TITLE]      => $STYLE_TITLE[0],
                            $MSG[TOPIC_REPLIES]    => $STYLE_REPLY[0],
                            $MSG[TOPIC_VIEWS]      => $STYLE_VIEWS[0],
                            $MSG[TOPIC_STARTEDBY]  => $STYLE_TIMES[0],
                            $MSG[TOPIC_LASTPOST]   => $STYLE_TIMES[0],
                          );


    # Little complex... for the FOR statement
    my $ForBegin = ($SubjectInfo[DB_SUBJECT_TOPICNUM] - $Start - 1);
    my $ForEnd   = ($SubjectInfo[DB_SUBJECT_TOPICNUM] - $End - 1);

    topic:for (my $I = $ForBegin; $I > $ForEnd; $I--)
    {
      # Get the topic
      my $Topic = $Topics[$I];
      last topic if(! defined $Topic);
      next topic if($Topic eq '');

      # Get additional information of the topic
      my @TopicInfo = dbGetTopicInfo($Topic, 0);
      if (! dbTopicInvalid($Topic, @TopicInfo))
      {
        if ($TopicInfo[DB_TOPIC_LASTPOSTDATE] > $SubjectInfo[DB_SUBJECT_LASTPOSTDATE])
        {
          # Autorestore Statics if it appears to be incorrect!
          $SubjectInfo[DB_SUBJECT_LASTPOSTER]   = $TopicInfo[DB_TOPIC_LASTPOSTER];
          $SubjectInfo[DB_SUBJECT_LASTPOSTDATE] = $TopicInfo[DB_TOPIC_LASTPOSTDATE];
          $SubjectChange = 1;
        }


        # Get statistics and determine what icon should be used
        my ($ReplyNum) = $TopicInfo[DB_TOPIC_POSTNUM] - 1;

        my $Image = '';
        if    ($TopicInfo[DB_TOPIC_LOCKED]
        &&     $TopicInfo[DB_TOPIC_STICKY]) { $Image = 'lockedsticky'; }
        elsif ($TopicInfo[DB_TOPIC_LOCKED]) { $Image = 'locked';       }
        elsif ($TopicInfo[DB_TOPIC_STICKY]) { $Image = 'sticky';       }
        elsif ($ReplyNum > $HOTHOT_POSTNUM) { $Image = 'veryhottopic'; }
        elsif ($ReplyNum > $HOT_POSTNUM)    { $Image = 'hottopic';     }
        else                                { $Image = 'topic';        }


        # Modify values for display.
        $TopicInfo[DB_TOPIC_TITLE] = qq[<IMG src="$IMAGE_URLPATH/topicicons/$Image.gif" width="16" height="16"> ]
                                   . qq[<IMG src="$IMAGE_URLPATH/posticons/$TopicInfo[DB_TOPIC_ICON].gif" width="16" height="16"> &nbsp; ]
                                   . qq[<A href="$THIS_URL?show=topic&page=1&topic=$Topic">$TopicInfo[DB_TOPIC_TITLE]</A>];


        # Add the NEW icon
        if ($XForumUser ne '')
        {
          my $TopicViews = ($Views->{$Topic} || 0);

          if($TopicViews <  $TopicInfo[DB_TOPIC_LASTPOSTDATE]   # There are more posts
          && $XForumUser ne $TopicInfo[DB_TOPIC_LASTPOSTER])    # You didn't post it (extra test), needed sometimes
          {
            $TopicInfo[DB_TOPIC_TITLE] .= qq[ <IMG src="$IMAGE_URLPATH/icons/new.gif" width="22" height="9" border="0">];
          }
        }


        # Convert dates (after the new icon is made)
        $TopicInfo[DB_TOPIC_LASTPOSTDATE] = DispTime($TopicInfo[DB_TOPIC_LASTPOSTDATE]);
        $TopicInfo[DB_TOPIC_DATE]         = DispTime($TopicInfo[DB_TOPIC_DATE]);

        # Print HTML
        print qq[      <TR>\n];
        print_tablecell_HTML($TopicInfo[DB_TOPIC_TITLE]  => @STYLE_TITLE);
        print_tablecell_HTML($ReplyNum                   => @STYLE_REPLY);
        print_tablecell_HTML($TopicInfo[DB_TOPIC_VIEWS]  => @STYLE_VIEWS);
        print_tablecell_HTML("<NOBR>" . sprint_memberlink_HTML($TopicInfo[DB_TOPIC_CREATOR])    . "</NOBR> <NOBR>$TopicInfo[DB_TOPIC_DATE]</NOBR>"         => @STYLE_TIMES);
        print_tablecell_HTML("<NOBR>" . sprint_memberlink_HTML($TopicInfo[DB_TOPIC_LASTPOSTER]) . "</NOBR> <NOBR>$TopicInfo[DB_TOPIC_LASTPOSTDATE]</NOBR>" => @STYLE_TIMES);
        print qq[      </TR>\n];
      }
    }


    # Print legenda
    print <<TOPIC_FOOTER_HTML;
    </TABLE>
    <BR>

    <TABLE border="0" cellpadding="0"><TR>
      <TD><IMG src="$IMAGE_URLPATH/topicicons/topic.gif"        width="16" height="16"><FONT size="1"> $MSG[TOPIC_NORMAL]     </FONT></TD>
      <TD><IMG src="$IMAGE_URLPATH/topicicons/locked.gif"       width="16" height="16"><FONT size="1"> $MSG[TOPIC_LOCKED]     </FONT></TD>
    </TR><TR>
      <TD><IMG src="$IMAGE_URLPATH/topicicons/hottopic.gif"     width="16" height="16"><FONT size="1"> $MSG[TOPIC_HOT]        </FONT></TD>
      <TD><IMG src="$IMAGE_URLPATH/topicicons/sticky.gif"       width="16" height="16"><FONT size="1"> $MSG[TOPIC_STICKY]     </FONT></TD>
    </TR><TR>
      <TD><IMG src="$IMAGE_URLPATH/topicicons/veryhottopic.gif" width="16" height="16"><FONT size="1"> $MSG[TOPIC_VERYHOT]    </FONT></TD>
      <TD><IMG src="$IMAGE_URLPATH/topicicons/lockedsticky.gif" width="16" height="16"><FONT size="1"> $MSG[TOPIC_LOCKSTICKY] </FONT></TD>
    </TR></TABLE>
TOPIC_FOOTER_HTML


    print_subjectpages_HTML($Subject, $Pages, $Page);
  }
  else
  {
    print "    $MSG[SUBJECT_EMPTY]\n"
  }


  # Autorestore Statics if it appears to be incorrect!
  if ($SubjectChange) { dbSaveSubjectInfo(@SubjectInfo); }


  # Footer and done
  print_footer_HTML();
}


sub print_subjectpages_HTML ($$$)
{ my($Subject, $Pages, $Page) = @_;
  if ($Pages > 1)
  {
    print qq[    <B>$MSG[PAGE_COUNT]:</B>\n];
    foreach my $I (1..$Pages)
    {
      if($I == $Page) { print qq[    <A href="$THIS_URL?show=subject&page=$I&subject=$Subject"><B>$I</B></A>\n]; }
      else            { print qq[    <A href="$THIS_URL?show=subject&page=$I&subject=$Subject">$I</A>\n]; }
    }
    print qq[    <P>\n];
  }
}


1;
