##################################################################################################
##                                                                                              ##
##  >> Central Database Core Routines <<                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'db_posts.pl'} = 'Release 1.4';


##################################################################################################
## Posts in Topic

# File names
sub FileName_Posts ($) { return "$DATA_FOLDER${S}posts${S}".NameGen($_[ID]).".pst"; }



sub dbMakePost (@)
{ my ($Topic, $Title, $Member, $PostIcon, $Contents) = @_;

  LoadSupport('db_stats');
  LoadSupport('db_members');
  LoadModule('HTML::EscapeASCII;');


  # Get MemberInfo that's also being used for flood checks.
  my @TopicInfo   = dbGetTopicInfo($Topic, 1);
  my @SubjectInfo = dbGetSubjectInfo($TopicInfo[DB_TOPIC_SUBJECT], 1);
  my @MemberInfo  = dbGetMemberInfo($Member, 1);
  my $IsGuest     = dbMemberIsGuest($Member);
  my $Time        = SaveTime();


  # The post structure
  my @PostInfo;
  $PostInfo[DB_POST_TITLE]          = $Title;
  $PostInfo[DB_POST_POSTER]         = $Member;
  $PostInfo[DB_POST_DATE]           = $Time;
  $PostInfo[DB_POST_LASTMODMEMBER]  = '';
  $PostInfo[DB_POST_LASTMODDATE]    = 0;
  $PostInfo[DB_POST_IP]             = $XForumUserIP;
  $PostInfo[DB_POST_ICON]           = $PostIcon;

  # Escape characters
  EscapePostArray(@PostInfo);
  EscapePostText($Contents);

  # Save.
  my @Append = join('|', @PostInfo);
  push @Append, $Contents;

  dbAppendFileContents(FileName_Posts($Topic), "Can't create post contents file" => @Append);


  # Reload variables to original is returned,
  # and post is created first so if that fails,
  # we don't get stuck with bad statistics.
  ($Topic, $Title, $Member, $Contents) = @_;


  # Update topic/subject/member stats
  $MemberInfo[DB_MEMBER_LASTPOSTDATE]    = $Time;
  $MemberInfo[DB_MEMBER_POSTNUM]++;

  $TopicInfo[DB_TOPIC_POSTNUM]++;
  $TopicInfo[DB_TOPIC_LASTPOSTER]        = $Member;
  $TopicInfo[DB_TOPIC_LASTPOSTDATE]      = $Time;

  $SubjectInfo[DB_SUBJECT_LASTPOSTER]    = $Member;
  $SubjectInfo[DB_SUBJECT_LASTPOSTDATE]  = $Time;
  $SubjectInfo[DB_SUBJECT_LASTPOSTTOPIC] = $Topic;

  # Save it.
  dbSaveTopicInfo(@TopicInfo);
  dbSaveSubjectInfo(@SubjectInfo);
  dbSaveMemberInfo(@MemberInfo) unless($IsGuest);


  # Bump topic to top if requested
  if($TOPIC_BUMPTOTOP)
  {
    LoadSupport('db_topics'); # If not done yet. property already
    dbTopicMoveToTop($Topic => $TopicInfo[DB_TOPIC_SUBJECT], 1);
  }


  UpdatePostStat();
  UpdateGuestPostStat() if $IsGuest;
}


##################################################################################################
## Because guests can also post

sub DeterminePoster
{
  return $XForumUser if $XForumUser;

  # Guest poster
  my $Poster = param('poster');
  my $Email  = param('email');
  return "G:$Poster:$Email" if $Poster && $Email;
  return "";
}


##################################################################################################
## Get Contents

sub EscapePostArray (@)
{
  # Replace | with a HTML escape code: #124;
  s/\|/\&#124;/g foreach @_;
}

sub EscapePostText (@)
{
  s/( )*($LINEBREAK_PATTERN)/<BR>/g foreach @_;
}



sub dbGetPosts ($;$$$)
{ my ($Topic, $Error, $Start, $End) = @_;

  if ($Error && ! dbPostsExist($Topic))  { Action_Error($MSG[TOPIC_NOTEXIST]) }

  if(defined $End)   { $End = ($End - $Start) * 2; } # Length
  if(defined $Start) { $Start *= 2; }

  return dbGetFileContents(FileName_Posts($Topic), FILE_NOERROR, undef, $Start, $End);
}


sub dbEditPosts ($$$@)
{ my($Topic, $Post, undef, @PostInfo) = @_;

  my @MemberInfo = dbGetMemberInfo($PostInfo[DB_POST_LASTMODMEMBER], 1);

  if($PostInfo[DB_POST_POSTER] ne $PostInfo[DB_POST_LASTMODMEMBER]
  ||($PostInfo[DB_POST_DATE]   != $MemberInfo[DB_MEMBER_LASTPOSTDATE]))
  {
    dbMemberFloodTest($MemberInfo[ID], $MemberInfo[DB_MEMBER_LASTPOSTDATE], $PostInfo[DB_POST_LASTMODDATE]);
  }

  EscapePostArray(@PostInfo);
  EscapePostText( $_[2] );

  my @Posts = dbGetPosts($Topic, 1);
  {
    $Posts[Index_PostContents($Post)] = $_[2]; # We didn't copy that var again!
    $Posts[Index_PostInfo($Post)]     = join('|', @PostInfo);
  }
  dbSavePosts($Topic => \@Posts);

  $MemberInfo[DB_MEMBER_LASTPOSTDATE] = $PostInfo[DB_POST_LASTMODDATE];
  dbSaveMemberInfo(@MemberInfo);
}

sub dbSavePosts ($$)  # ($\@)
{ my($Topic, $Posts) = @_;
  # RULE: The posts should already exist.
  # RULE: Member flood should already be tested
  # RULE: Posts are perfect. This only saves it.
  dbSetFileContents(FileName_Posts($Topic), "Can't edit topic '$Topic' post file" => @{$Posts});
}


sub dbGetPostInfo ($$)  # (\@$)
{ my($Posts, $PostIndex) = @_;

  # Get the info
  my @PostInfo = split(/\|/, (@{$Posts}[Index_PostInfo($PostIndex)] || ''), DB_POST_FIELDS);

  # Default values... the entire structure, because it's retreived by a split()
  $_ ||= '' foreach($PostInfo[DB_POST_TITLE], $PostInfo[DB_POST_POSTER], $PostInfo[DB_POST_LASTMODMEMBER], $PostInfo[DB_POST_IP]);
  $_ ||= 0  foreach($PostInfo[DB_POST_DATE],  $PostInfo[DB_POST_LASTMODDATE]);
  $PostInfo[DB_POST_ICON] ||= 'default';

  # Return
  return @PostInfo;
}


sub dbGetPostContents ($$)  # (\@$)
{ my($Posts, $PostIndex) = @_;

  # Get thet post contents
  my $PostContents = (@{$Posts}[Index_PostContents($PostIndex)] || '');
  $PostContents    =~ s/<BR>/\n/g;

  return $PostContents;
}



# This is a routine, called many times because it's less coding in the GUI modules...
sub dbGetPostTest ($;$)
{ my($Topic, $Post) = @_;
  LoadSupport('check_fields');

  # Validate
  if ($Post eq '') { Action_Error($MSG[POST_NOTEXIST]) }
  ValidateNumber($Post, $MSG[ISNUM_PAGE]);

  # Get the data
  my @Posts        = dbGetPosts($Topic, 1, $Post-1, $Post);
  my $PostContents = dbGetPostContents(\@Posts, 1);
  my @PostInfo     = dbGetPostInfo(\@Posts, 1);
  if ($Post eq '') { Action_Error($MSG[POST_NOTEXIST]) }

  # Return
  return($PostContents, @PostInfo);
}

sub dbGetPostNoTest ($;$)
{ my($Topic, $Post) = @_;
  LoadSupport('check_fields');

  # Validate
  return if ($Post eq '');
  return if ($Post !~ m[^\d+$]);

  # Get the data
  my @Posts        = dbGetPosts($Topic, 0, $Post-1, $Post);
  my $PostContents = dbGetPostContents(\@Posts, 1);
  my @PostInfo     = dbGetPostInfo(\@Posts, 1);
  return if ($Post eq '');

  # Return
  return($PostContents, @PostInfo);
}



sub dbDelPost ($$)
{ my($Post, $Posts) = @_;

  LoadSupport('db_stats');

  # RULE: We make other fields empty
  # we don't make them empty, since that's confusing to the
  # forum users. Now we can at least indicate a previous post is deleted.
  @{$Posts}[Index_PostInfo($Post)]     = '';
  @{$Posts}[Index_PostContents($Post)] = '';


  # This removes the last empty values. I've tried other methods, but
  # this seams to work the best, considering the fact other things
  # can corrupt the file lines aswell.
  dbClearupPosts($Posts);


  UpdatePostStat(-1);
}

sub dbCountFilePosts ($;$)
{ my($PostIndex, $Error) = @_;
  my $File  = FileName_Posts($PostIndex);
  my $Lines = 0;
  my $Buffer;
  if(open(FILE, $File))
  {
    flock(FILE, LOCK_SH);
    while (sysread FILE, $Buffer, 4096)
    {
      $Buffer =~ s/\n\n\n/\n/g;
      $Lines += ($Buffer =~ tr/\n//);
    }
    close(FILE);
  }
  else
  {
    die "Can't count entries in '$File': $!" if $Error;
    return 0;
  }

  return $Lines / 2;
}

sub dbCountPosts ($) # (\@)
{ my($Posts) = @_;
  my $ArraySize = @{$Posts};
  my $PostNum = 0;

  for(my $I = 0; $I < $ArraySize; $I += 2)
  {
    $PostNum++  unless(@{$Posts}[$I] eq '' && @{$Posts}[$I+1] eq '');
  }

  return $PostNum;
}

sub dbClearupPosts ($)
{ my($Posts) = @_;

  my $PostNum = @{$Posts};

  if(($PostNum % 2) != 0)
  {
    # Something is really wrong...
    $#{$Posts}--;
    $PostNum--;
  }

  empty:for(my $I = ($PostNum/2); $I >= 1; $I--)
  {
    if(! defined $Posts->[Index_PostInfo($I)]
    || ! defined $Posts->[Index_PostContents($I)])
    {
      # Somethis really bad is goin' on. this could really
      # happen if some part of the code assigned a value
      # to a non-existing element of the array. (which creates it)
      # (for example in the dbDelPost routine)

      # If the elements didn't exist (undef), we create
      # them here, so our code restores that error,
      # and the pop() functionality works as we expect it to be.
      # no matter what we do wrong in the for loop.
      # silly, isn't it?
      $Posts->[Index_PostInfo($I)]     = undef;
      $Posts->[Index_PostContents($I)] = undef;

      # This is better that pop(), because the array is already a reference.
      $#{$Posts} -= 2;
    }
    elsif($Posts->[Index_PostInfo($I)]     eq ''
    &&    $Posts->[Index_PostContents($I)] eq '')
    {
      $#{$Posts} -= 2;
    }
    else
    {
      last empty;
    }
  }
}


# Index functions
sub Index_PostInfo ($)     { return ($_[0] - 1) * 2; }
sub Index_PostContents ($) { return ($_[0] * 2) - 1; }

sub dbGetPostPage ($)      { return return int(($_[0] - 1) / $PAGE_POSTS) + 1; }


##################################################################################################
## Portability functions

sub dbPostsExist ($)       { return -e FileName_Posts($_[0]) }


1;
