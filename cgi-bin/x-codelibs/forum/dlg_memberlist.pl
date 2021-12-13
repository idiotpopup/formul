##################################################################################################
##                                                                                              ##
##  >> Memberlist Display <<                                                                    ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_memberlist.pl'} = 'Release 1.5';

LoadSupport('db_stats');
LoadSupport('db_members');
LoadSupport('html_tables');
LoadSupport('html_fields');
LoadSupport('html_members');
LoadSupport('check_security');


##################################################################################################
## Check Access

ValidateMemberCookie();


my @STYLE_INDEX = ('40',  'right', $FONT_STYLE);
my @STYLE_NAME  = (undef, 'left',  $FONTEX_STYLE);
my @STYLE_DATE  = ('190', 'right', q[size="1"]);
my @STYLE_INET  = ('130', 'left',  $FONT_STYLE);
my @STYLE_POSTS = ('50',  'right', $FONT_STYLE);
my @STYLE_BAR   = ('50',  'left',  $FONT_STYLE);


my %MembersInfo   = ();
my %SortOptions   = (
                      'login'     => $MSG[LOGIN_ACCOUNT],
                      'names'     => $MSG[MEMBERLIST_NAME],
                      'postnum'   => $MSG[MEMBER_POSTS],
                      'register'  => $MSG[MEMBER_REGDATE],
                      'lastpost'  => $MSG[MEMBER_LASTPOST],
                      'lastlogin' => $MSG[MEMBER_LASTLOGIN],
                    );
my $DateConstant;
my %DateConstants = (
                      'register'  => DB_MEMBER_REGDATE,
                      'lastpost'  => DB_MEMBER_LASTPOSTDATE,
                      'lastlogin' => DB_MEMBER_LASTLOGINDATE,
                    );
my %DateOptions   = (
                      'register'  => $MSG[MEMBER_REGDATE],
                      'lastpost'  => $MSG[MEMBER_LASTPOST],
                      'lastlogin' => $MSG[MEMBER_LASTLOGIN],
                    );


##################################################################################################
## User List Dialog

sub Show_MemberListDialog ()
{
  # Get additional Information
  my $Sort    = (param('sort')    || 'postnum');
  my $Reverse = (param('reverse') || 0);
  my @Members = dbGetMembers();


  # HTML Header
  print_header;
  print_header_HTML($MSG[SUBTITLE_MEMBERLIST], $MSG[SUBTITLE_MEMBERLIST], undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML("?show=memberlist" => $MSG[SUBTITLE_MEMBERLIST]);
  print_bodystart_HTML();


  my @Stat = dbGetStats();  # Will be updated if incorrect (autorestore)


  # Do we have got any names?
  if (defined $Members[0])
  {
    # Get all the information from the members
    my $TopPostNum = 0;
    foreach my $Member (@Members)
    {
      $MembersInfo{$Member} = [ dbGetMemberInfo($Member) ];

      if(${$MembersInfo{$Member}}[DB_MEMBER_POSTNUM] > $TopPostNum)
      {
        $TopPostNum = ${$MembersInfo{$Member}}[DB_MEMBER_POSTNUM]
      }
    }



    # Convert the date parameter
    my $Date         = $Sort;
       $Date         = param('date') || '' if not exists $DateOptions{$Date};
       $Date         = 'lastpost'          if not exists $DateOptions{$Date};
    my $MSG_DATE     = $DateOptions{$Date} || $MSG[MEMBERLIST_DATE];
       $DateConstant = $DateConstants{$Date};
    $Date = 'lastpost' if not defined $DateConstant;




    # Sort the login names, so we can make the list after it.
    my $SortRe = ($Reverse ? 2 : 1);
    my $SortTo = "$Sort$SortRe";
       if($SortTo eq 'postnum1') { @Members = sort postnum1 @Members }
    elsif($SortTo eq 'postnum2') { @Members = sort postnum2 @Members }
    elsif($SortTo eq 'names1')   { @Members = sort names1   @Members }
    elsif($SortTo eq 'names2')   { @Members = sort names2   @Members }
    elsif($SortTo eq 'login1')   { @Members = sort login1   @Members }
    elsif($SortTo eq 'login2')   { @Members = sort login2   @Members }
    elsif($Sort   eq $Date)
    {
       if($SortRe == 1)          { @Members = sort dates1   @Members }
       if($SortRe == 2)          { @Members = sort dates2   @Members }
    }
    else                         { @Members = sort login1   @Members }





    # Print sort input fields
    print qq[    <NOBR><B>$MSG[MEMBERLIST_SORT]:</B> \[</NOBR>\n];
    my $CurOption  = 0;
    my $NumOptions = scalar keys %SortOptions;
    my $Reverse2   = ($Reverse ? 0 : 1);
    foreach my $SortMethod (sort hashvalue keys %SortOptions)
    {
      if($SortMethod eq $Sort)
      {
        my $URL = "$THIS_URL?show=memberlist&sort=$SortMethod&reverse=$Reverse2&date=$Date";
        print qq[    <NOBR><A href="$URL" onClick="location.replace('$URL');return false"><B>$SortOptions{$SortMethod}</B></A>]
      }
      else
      {
        my $URL = "$THIS_URL?show=memberlist&sort=$SortMethod&reverse=0&date=$Date";
        print qq[    <NOBR><A href="$URL" onClick="location.replace('$URL');return false">$SortOptions{$SortMethod}</A>]
      }
      $CurOption++;
      if($CurOption < $NumOptions) { print " |</NOBR>\n" }
      else                         { print " ]</NOBR>\n" }
    }
    {
      my $URL = "$THIS_URL?show=memberlist&sort=$Sort&reverse=$Reverse2&date=$Date";
      print qq[    <NOBR><A href="$URL" onClick="location.replace('$URL');return false"><I>$MSG[MEMBERLIST_REVERSE]</I></A></NOBR><P>\n];
      print qq[\n];
    }



    # Build up header of HTML table page
    print_tableheader_HTML(
                            $TABLE_MAX_HTML,
                            $MSG[MEMBERLIST_INDEX]     => $STYLE_INDEX[0],
                            $MSG[MEMBERLIST_NAME]      => $STYLE_NAME[0],
                            $MSG_DATE                  => $STYLE_DATE[0],
                            $MSG[MEMBERLIST_INTERNET]  => $STYLE_INET[0],
                            $MSG[MEMBER_POSTS]         => $STYLE_POSTS[0]+$STYLE_BAR[0] . '" colspan="2'
                          );


    my $I = 1;
    my $MemberNum = 0;
    my $TableNum  = @Members+1;

    # Make the member table
    foreach my $Member (@Members)
    {
      # Copy the memberinfo, so we don't get irritated by the pointers.
      my @MemberInfo = @{ $MembersInfo{$Member} };


      if (! dbMemberInvalid($Member, @MemberInfo))
      {
        # Tested later for stats
        $MemberNum++;

        # Determine the HTML codes for the post-percentage bar
        # Show the percents relative to the top poster as status
        my $Bar = '&nbsp;';
        if ($TopPostNum > 0)
        {
          my $BarSize = ($MemberInfo[DB_MEMBER_POSTNUM] / $TopPostNum) * 50; # max 50 pixels
             $BarSize = 1 if($BarSize > 0 && $BarSize < 1);
          if($BarSize >= 1)
          {
            # Make the HTML codes, if the bar size is acceptable.
            $BarSize = int($BarSize + 0.5);
            $Bar = qq[<IMG src="$IMAGE_URLPATH/bar.gif" width="$BarSize" height="19" border="0" hspace="0" vspace="0">];
          }
        }


        # Formet the gender field
        my $UnknownGender               = ($MemberInfo[DB_MEMBER_GENDER] != 1 && $MemberInfo[DB_MEMBER_GENDER] != 2);
        $MemberInfo[DB_MEMBER_GENDER]   = member_gender_HTML($MemberInfo[DB_MEMBER_GENDER])
                                        . ($UnknownGender ? qq[<IMG src="$IMAGE_URLPATH/empty.gif" width="11" height="11">] : '');

        # Format the date
        my $MemberDate                  = DispTime($MemberInfo[$DateConstant]);

        # Add online image
        my $StatusIcons = '';
        $StatusIcons .= qq[<IMG src="$IMAGE_URLPATH/icons/connected.gif" width="16" height="16" border="0" alt="$MSG[MEMBER_ONLINE]">] if($MemberOnline{$Member});
        $StatusIcons .= qq[<IMG src="$IMAGE_URLPATH/icons/banned.gif" width="16" height="16" border="0" alt="$MSG[MEMBER_ISBANNED]">] if($MemberBanned{$Member});

        # E-mail is not shown if it's private
        if( $MemberInfo[DB_MEMBER_PRIVATE])
        {
          $MemberInfo[DB_MEMBER_EMAIL]  = "";
        }
        else
        {
          $MemberInfo[DB_MEMBER_EMAIL]  = member_emailicon_HTML($MemberInfo[DB_MEMBER_EMAIL], $MemberInfo[DB_MEMBER_PRIVATE]);
        }

        # Internet Items
        my $URLIcon                     = member_websiteicon_HTML($MemberInfo[DB_MEMBER_WEBURL], $MemberInfo[DB_MEMBER_URLTITLE]);
        $MemberInfo[DB_MEMBER_ICQ]      = member_ICQonline_HTML($MemberInfo[DB_MEMBER_ICQ]);
        $MemberInfo[DB_MEMBER_MSN]      = member_MSN_HTML($MemberInfo[DB_MEMBER_MSN]);
        $MemberInfo[DB_MEMBER_AIM]      = member_AIM_HTML($MemberInfo[DB_MEMBER_AIM]);
        $MemberInfo[DB_MEMBER_YIM]      = member_YIM_HTML($MemberInfo[DB_MEMBER_YIM])
                                        . member_YIMonline_HTML($MemberInfo[DB_MEMBER_YIM]);

        # Print his table row
        print qq[        <TR>\n];
        print_tablecell_HTML(($Reverse ? $TableNum-$I : $I),   @STYLE_INDEX);
        print_tablecell_HTML( "<NOBR>"
                            . qq[$MemberInfo[DB_MEMBER_GENDER] ]
                            . sprint_memberlink_HTML($Member)
                            . "</NOBR>",
                                                               @STYLE_NAME);
        print_tablecell_HTML("<NOBR>$MemberDate</NOBR>",       @STYLE_DATE);
        print_tablecell_HTML((
                              $MemberInfo[DB_MEMBER_EMAIL]
                            . $URLIcon
                            . $MemberInfo[DB_MEMBER_ICQ]
                            . $MemberInfo[DB_MEMBER_MSN]
                            . $MemberInfo[DB_MEMBER_AIM]
                            . $MemberInfo[DB_MEMBER_YIM]
                            . $StatusIcons) || '&nbsp',        @STYLE_INET);
        print_tablecell_HTML($MemberInfo[DB_MEMBER_POSTNUM],   @STYLE_POSTS);
        print_tablecell_HTML($Bar,                             @STYLE_BAR);
        print qq[        </TR>\n];

        $I++;
      }
    }
    print qq[    </TABLE>\n];


    # Autorestore the number of members
    if($Stat[DB_STAT_MEMBERNUM] != $MemberNum)
    {
      # Autorestore stats
      $Stat[DB_STAT_MEMBERNUM] = $MemberNum;
      dbSaveStats(@Stat);
    }
  }
  else
  {
    # This member's database is empty
    print <<FORUM_INDEX_EMPTY_ERROR;
    $MSG[MEMBERLIST_EMPTY] <BR>
FORUM_INDEX_EMPTY_ERROR

    if($Stat[DB_STAT_MEMBERNUM] != 0)
    {
      # Autorestore the number of members
      $Stat[DB_STAT_MEMBERNUM] = 0;
      dbSaveStats(@Stat);
    }
  }


  # Footer
  print_footer_HTML();
}


##################################################################################################
## Sort "%SortOptions" hash...

sub hashvalue
{
  $SortOptions{$a} cmp $SortOptions{$b} ||
                $a cmp $b
}


##################################################################################################
## Sort postnum...

sub postnum1
{
  (${ $MembersInfo{$b} }[DB_MEMBER_POSTNUM] ||  0) <=> (${ $MembersInfo{$a} }[DB_MEMBER_POSTNUM] || 0)  ||
     (${ $MembersInfo{$a} }[DB_MEMBER_NAME] || '') cmp (${ $MembersInfo{$b} }[DB_MEMBER_NAME] || '')    ||
                                       $a  cmp  $b
}

sub postnum2
{
  (${ $MembersInfo{$a} }[DB_MEMBER_POSTNUM] ||  0) <=> (${ $MembersInfo{$b} }[DB_MEMBER_POSTNUM] || 0)  ||
     (${ $MembersInfo{$b} }[DB_MEMBER_NAME] || '') cmp (${ $MembersInfo{$a} }[DB_MEMBER_NAME] || 0)     ||
                                               $b  cmp  $a
}

##################################################################################################
## Sort names...

sub names1
{
     (${ $MembersInfo{$a} }[DB_MEMBER_NAME] || '') cmp (${ $MembersInfo{$b} }[DB_MEMBER_NAME] || '')    ||
                                               $a  cmp  $b
}

sub names2
{
     (${ $MembersInfo{$b} }[DB_MEMBER_NAME] || '') cmp (${ $MembersInfo{$a} }[DB_MEMBER_NAME] || '')    ||
                                               $b  cmp  $a
}

##################################################################################################
## Sort dates...

sub dates1
{
      (${ $MembersInfo{$b} }[$DateConstant] || 0) cmp (${ $MembersInfo{$a} }[$DateConstant] || 0)       ||
                                              $a  cmp  $b
}

sub dates2
{
      (${ $MembersInfo{$a} }[$DateConstant] || 0) cmp (${ $MembersInfo{$b} }[$DateConstant] || 0)       ||
                                              $b  cmp  $a
}


##################################################################################################
## Sort login...

sub login1 { $a cmp $b }
sub login2 { $b cmp $a }

1;
