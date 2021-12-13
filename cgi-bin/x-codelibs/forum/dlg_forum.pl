##################################################################################################
##                                                                                              ##
##  >> Display of Forum/Subjects <<                                                             ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_forum.pl'} = 'Release 1.6';

LoadSupport('db_stats');
LoadSupport('db_subjects');
LoadSupport('db_members');
LoadSupport('html_tables');


my @STYLE_TITLE     = ('',      'left',              $FONTEX_STYLE);
my @STYLE_TOPICS    = ('70',    'right',             q[size="1"]);
my @STYLE_RPOST     = ('150',   '',                  q[size="1"]);
my @STYLE_MODERATOR = ('120',   'left',              q[size="1"]);



##################################################################################################
## Forum: Subject Index

sub Show_Forum ()
{
  # Get additional Information
  my @Subjects = dbGetSubjects();


  # HTML Header
  print_header;
  print_header_HTML(undef, $MSG[SUBTITLE_FORUM], undef);
  print_toolbar_HTML();
  print_treelevel_HTML();
  print_bodystart_HTML();



  # Do we have got any names?
  if (@Subjects)
  {
    my $TopicNum = 0;
    my @Stat = dbGetStats();

    # Print a welcome message if the user is guest
    print qq[    $MSG[GUEST_LOGIN_REQUEST] <BR>\n] if ($XForumUser eq '');



    my $NewMember = '';
    if($Stat[DB_STAT_NEWMEMBER])
    {
      my $TwoDaysLater = $Stat[DB_STAT_NEWMEMBERDATE] + 4 * 24 * 3600;
      if(time() < $TwoDaysLater                    # Don't display after 2 days
      && dbMemberExist($Stat[DB_STAT_NEWMEMBER]))  # Don't display when deleted.
      {
        $NewMember = "\n      $MSG[MEMBER_WELCOME]: " . sprint_memberlink_HTML($Stat[DB_STAT_NEWMEMBER]) . "<BR>";
      }
    }

    print <<STATISTICS;
    <P align="right">$NewMember
      $MSG[STAT_MEMBERS]: $Stat[DB_STAT_MEMBERNUM] &nbsp;&#149;&nbsp;
      $MSG[STAT_TOPICS]: $Stat[DB_STAT_TOPICNUM]  &nbsp;&#149;&nbsp;
      $MSG[STAT_POSTS]: $Stat[DB_STAT_POSTNUM]
    </P>


STATISTICS


    #Build up header of HTML table page
    print qq[    $TABLE_MAX_HTML\n];
#    print_tableheader_HTML(
#                            $TABLE_MAX_HTML,
#                            $MSG[SUBJECT_TITLE]      => $STYLE_TITLE[0],
#                            $MSG[TOPIC_LASTPOST]     => $STYLE_RPOST[0],
#                            $MSG[SUBJECT_MODERATORS] => $STYLE_MODERATOR[0],
#                          );



    # Build up subject table rows
    subject:foreach my $Subject (@Subjects)
    {
      if(dbSubjectIsTitle($Subject))
      {
        print qq[      <TR bgcolor="$TABLHEAD_COLOR">\n];
        print qq[        <TD align="left"><FONT size="4" color="$TABLFONT_COLOR">$Subject</FONT></TD>\n];
        print qq[        <TD align="center" width="$STYLE_TOPICS[0]"><B><FONT size="2" color="$TABLFONT_COLOR">$MSG[TOPIC_NUM]</FONT></B></TD>\n];
        print qq[        <TD align="center" width="$STYLE_RPOST[0]"><B><FONT size="2" color="$TABLFONT_COLOR">$MSG[TOPIC_LASTPOST]</FONT></B></TD>\n];
        print qq[        <TD align="center" width="$STYLE_MODERATOR[0]"><B><FONT size="2" color="$TABLFONT_COLOR">$MSG[SUBJECT_MODERATORS]</FONT></B></TD>\n];
        print qq[      </TR>\n];
        next subject;
      }


      # Get additional info for the Subject
      my @SubjectInfo = dbGetSubjectInfo($Subject);

      if (! dbSubjectInvalid($Subject, @SubjectInfo))
      {
        $TopicNum += $SubjectInfo[DB_SUBJECT_TOPICNUM];

        # Make moderator list.
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


        # Display
        my $Image = $SubjectInfo[DB_SUBJECT_ICON];
        if($Image eq '')
        {
          if($SubjectInfo[DB_SUBJECT_GROUPS] eq 'everyone')
          {
            $Image = 'public';
          }
          else
          {
            $Image = 'private';
          }
        }
        $SubjectInfo[DB_SUBJECT_TITLE] = qq[<IMG src="$IMAGE_URLPATH/subjecticons/$Image.gif" width="16" height="16"> ]
                                       . qq[<A href="$THIS_URL?show=subject&page=1&subject=$Subject">$SubjectInfo[DB_SUBJECT_TITLE]</A></FONT>]
                                       . qq[<FONT size="1">];

        # Show a NEW icon??
        if ($XForumUser ne '' && $SubjectInfo[DB_SUBJECT_LASTPOSTTOPIC])
        {
          my $Views = dbGetMemberViews($XForumUser, [ $SubjectInfo[DB_SUBJECT_LASTPOSTTOPIC] ]);
          my $SubjectViews = ($Views->{$SubjectInfo[DB_SUBJECT_LASTPOSTTOPIC]} || 0);

          if($SubjectViews < $SubjectInfo[DB_SUBJECT_LASTPOSTDATE]   # There are more posts
          && $XForumUser  ne $SubjectInfo[DB_SUBJECT_LASTPOSTER])    # You didn't post it (extra test), needed sometimes
          {
            $SubjectInfo[DB_SUBJECT_TITLE] .= qq[ <IMG src="$IMAGE_URLPATH/icons/new.gif" width="22" height="9" border="0">];
          }
        }


        # Format the last-post-name field
        $SubjectInfo[DB_SUBJECT_LASTPOSTDATE] = DispTime($SubjectInfo[DB_SUBJECT_LASTPOSTDATE]);


        # Print the subject table row.
        print qq[      <TR>\n];
        print_tablecell_HTML(
                              qq[$SubjectInfo[DB_SUBJECT_TITLE]<BR>]
                            . qq[$SubjectInfo[DB_SUBJECT_DESCRIPTION]]
                             => @STYLE_TITLE
                            );
        my $lastposter  = "";
           $lastposter .= qq[<NOBR>] . sprint_memberlink_HTML($SubjectInfo[DB_SUBJECT_LASTPOSTER]) . qq[</NOBR> ] if($SubjectInfo[DB_SUBJECT_LASTPOSTER]);
           $lastposter .= qq[<NOBR>$SubjectInfo[DB_SUBJECT_LASTPOSTDATE]</NOBR>];
        print_tablecell_HTML($SubjectInfo[DB_SUBJECT_TOPICNUM],  @STYLE_TOPICS);
        print_tablecell_HTML($lastposter,                        @STYLE_RPOST);
        print_tablecell_HTML($ModeratorList,                     @STYLE_MODERATOR);
        print qq[      </TR>\n];
      }
    }
    print qq[    </TABLE>\n];


    # Autorestore the number of topics if they are incorrect
    if($TopicNum != $Stat[DB_STAT_TOPICNUM])
    {
      $Stat[DB_STAT_TOPICNUM] = $TopicNum;
      dbSaveStats(@Stat);
    }
  }
  else
  {
    # No subjects set up by the adminstrator yet!
    print "    $MSG[FORUM_EMPTY]\n";
    LoadSupport('installation');
    print_installinfo_HTML();
  }


  # Footer
  print_footer_HTML();
}




1;
