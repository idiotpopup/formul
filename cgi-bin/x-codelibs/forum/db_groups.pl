##################################################################################################
##                                                                                              ##
##  >> Central Database Core Routines <<                                                        ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'db_groups.pl'} = 'Release 1.4';



##################################################################################################
## Members Database Index



sub FileName_Group ($)  { return "$DATA_FOLDER${S}groups${S}".NameGen($_[ID]).".grp"; }
sub FileName_Groups ()  { return "$DATA_FOLDER${S}groups.lst"; }


# Note: group everyone.grp is virtual and referers to members.lst



sub dbMakeGroup ($)
{
  dbSetFileContents(FileName_Group($_[ID]), "Can't create new membergroup database" => $_[ID]);

  # Update the groups database
  if (! dbGroupIndexExist())
  {
    # Initialize for the first time
    dbSetFileContents(FileName_Groups, "Can't save membergroup index database" => 'everyone', $_[ID]);
  }
  else
  {
    # Append data
    dbAppendFileContents(FileName_Groups, "Can't update membergroup index database" => $_[ID]);
  }
}



# Get the groups
sub dbGetGroups()
{
  if ( dbGroupIndexExist()) { return dbGetFileContents(FileName_Groups, FILE_NOERROR); }
  else                      { return ('everyone'); }
}

sub dbSaveGroups()          { dbSetFileContents(FileName_Groups, "Can't update member group index" => @_); }




##################################################################################################
## Members


sub dbSaveGroupInfo ($$@)
{
  return if ! dbGroupCanUpdate(@_);
  dbSetFileContents(FileName_Group($_[ID]), "Can't update database for membergroup '$_[ID]'" => @_);
}



sub dbGetGroupInfo ($;$$)
{ my ($Group, $Error) = @_;
  my @GroupInfo;

  if($Group eq 'everyone')
  {
    # Get the memberlis
    if ($Error && ! dbMemberIndexExist())
    {
      Action_Error($MSG[GROUP_NOTEXIST]);
    }

    @GroupInfo = dbGetFileContents(FileName_Members(), FILE_NOERROR);

    # Put the everyone,text at the begin of the array
    unshift @GroupInfo, 'everyone', $MSG[GROUP_EVERYONE];
  }
  else
  {
    # Get the filename
    if ($Error && ! dbGroupExist($Group))
    {
      Action_Error($MSG[GROUP_NOTEXIST]);
    }

    # Get the data
    @GroupInfo = dbGetFileContents(FileName_Group($Group), FILE_NOERROR, DB_GROUP_FIELDS);
    if ($Error && dbGroupInvalid($Group, @GroupInfo))
    {
      die "The database of the membergroup '$Group' is corrupted!\n"
        . "Please contact the webmaster to fix the problem.\n";
    }
  }

  # Return
  return @GroupInfo;
}


##################################################################################################
## Faster routine if we only need to know the member's name

sub dbGetGroupName ($;$)
{ my ($Group, $Error) = @_;

  return '' if($Group eq '');

  if ($Error && ! dbGroupExist($Group))
  {
    Action_Error($MSG[GROUP_NOTEXIST])
  }

  if($Group eq 'everyone') { return $MSG[GROUP_EVERYONE]; }


  # Open and validate
  # This call loads in less of the member's database.
  my(@GroupInfo)       = dbGetFileContents(FileName_Group($Group), undef, 0, 0, 1 + DB_GROUP_TITLE);

  # Assign to the hash.
  if(! dbGroupInvalid($Group, @GroupInfo))
  {
    return $GroupInfo[DB_GROUP_TITLE];
  }
  else
  {
    return "?? $Group ??";
  }
}

sub dbGetGroupNames ()
{
  my @Groups     = dbGetGroups();
  my %GroupNames;

  foreach my $Group (@Groups)
  {
    $GroupNames{$Group} = dbGetGroupName($Group);
  }


  return map
         {
           $_, $GroupNames{$_}
         }
         sort
         {
           $GroupNames{$a}  cmp  $GroupNames{$b} ||
                        $a  cmp  $b
         }
         @Groups;
}



##################################################################################################
## Tests for portability

sub dbGroupExist ($)
{
  if($_[ID] eq 'everyone')
  {
    return -e FileName_Members();
  }
  else
  {
    return -e FileName_Group($_[ID]);
  }
}

sub dbGroupCanUpdate (@)
{
  if ($_[ID] eq 'everyone')          { die "Can't update database for membergroup '$_[ID]': Read Only Group\n"; }
  if (not -e FileName_Group($_[ID])) { Action_Error($MSG[GROUP_NOTEXIST]); }
  return 1;
}

sub dbGroupIndexExist () { return -e FileName_Groups() }
sub dbGroupInvalid ($@)  { return ($_[ID] || '') eq '' || $_[ID] ne ($_[ID + 1] || ''); }
sub dbGroupCount (;$)    { return dbCountEntries(FileName_Groups(), $_[0]) }

sub dbGroupFileInvalid ($)
{
  return dbGroupExist($_[ID])
      && dbGroupInvalid($_[ID], dbGetFileContents(FileName_Group($_[ID]), FILE_NOERROR, 0, 0, 1));
}

1;
