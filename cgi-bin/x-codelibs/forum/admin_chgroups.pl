##################################################################################################
##                                                                                              ##
##  >> Administrator Change Subjects <<                                                         ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'admin_chgroups.pl'} = 'Release 1.3';

LoadSupport('db_groups');
LoadSupport('check_security');


##################################################################################################
## Check for admin member access.

ValidateAdminAccess();



my @REQ_FIELDS_GROUP = qw(title members);




##################################################################################################
## Admin: Add Group


sub Show_AdminAddGroupDialog
{
  LoadSupport('html_fields');

  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Add a Membergroup]', 'Admin Center <FONT size="-1">[Add a Membergroup]</FONT>', undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'            =>  'Admin Center',
                        '?show=admin_addsubject'        =>  'Add a Membergroup'
                      );
  print_bodystart_HTML();

  print_inputfields_HTML(
                          $TABLE_600_HTML               => undef,1,
                          'action'                      => 'admin_addgroup',
                        );
  print_required_TEST(@REQ_FIELDS_GROUP);
  print_editcells_HTML(
                        'New Membergroup' => 1,
                        $REQ_HTML.'Group Title'         => qq[<INPUT type="text" class="CoolText" name="title" size="60" maxlength="40">],
                        $REQ_HTML.'Members'             => sprint_memberfield_HTML('members', 12),
                        'Group ID'                      => qq[<INPUT type="text" class="CoolText" name="group" size="60" maxlength="40">]
                      );
  print_buttoncells_HTML('Add');
  print_footer_HTML();
}





sub Action_AdminAddGroup
{
  LoadSupport('db_members');
  LoadSupport('check_fields');
  LoadModule('HTML::EscapeASCII;');


  # Get Field values
  my $Title   = (param('title')   || '');
  my $Group   = (param('group')   || '');

  my @Members = param('members');

  $Group = NameGen($Title) if ($Group eq '');


  # Preform Field Checks
  ValidateRequiredFields(@REQ_FIELDS_GROUP);
  ValidateRequired($Group);
  ValidateLength($Title, 'Title', 40);


  # Check for existance of subject's data folder
  if ( dbGroupExist($Group))
  {
    Action_Error(qq[There is already a membergroup created using a simular id!! <BR>\n]
               . qq[    Note that the ID could be automatically generated, if the field's value is left empty.<BR>\n]
               . qq[    Please change your title of the membergroup!$RETURN_HTML]
                );
  }

  # Make the subject

  my @GroupInfo;
  {
    $GroupInfo[ID]             = $Group;
    $GroupInfo[DB_GROUP_TITLE] = $Title;
    push @GroupInfo, ParseMembers(@Members);
    FormatFieldHTML($GroupInfo[DB_GROUP_TITLE]);
  }
  dbMakeGroup($Group);
  dbSaveGroupInfo(@GroupInfo);

  # Log print and redirect
  print_log("ADDGROUP",'', "GROUP=$Group");

  print redirect("$THIS_URLSEC?show=admin_center");
}






##################################################################################################
## Admin: Edit Subjects

sub Show_AdminEditGroupDialog
{
  LoadSupport('html_fields');
  LoadModule('HTML::EscapeASCII;');

  # Get Subject Suggestion (for example, for non javascript browsers)
  my $DefaultGroup = (param('group') || '');
  my @Groups       = dbGetGroups();

  if(@Groups == 0 || (@Groups == 1 && $Groups[0] eq 'everyone'))
  {
    Action_Error('There are no groups to edit!');
  }


  # Define JavaScript
  my $JS = <<ADMIN_EDITGROUP_JS;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      function Group(Title, GroupID, Members)
      {
        // 'Subject Structure' for array
        this.title   = Title;
        this.groupid = GroupID;
        this.members = Members;
      }

      function SaveChanges(Form)
      {
        if (Changed && confirm("You have unsaved changes. Save changes now?"))
        {
          Form.submit();
          Changed = false;
          return true;
        }
        return false;
      }

      function LoadGroup(Form, Select)
      {
        // RULE: We assume that the fields are sorted like found in the array
        if(! SaveChanges(Form))
        {
          var GroupID = Select.options[Select.selectedIndex].value;
          for (var I = 0; I < Groups.length; I++)
          {
            if (Groups[I].groupid == GroupID)
            {
              // Change fields
              Form.group.value  = Groups[I].groupid;
              Form.title.value  = Groups[I].title;
              var Members       = Groups[I].members.split("|");

              SelectOptions(Form.members, Members, true);

              Changed           = false;   // There are no changes anymore.
              return true;
            }
          }
          if (confirm("The membergroup could not be found!\\nShould this page be reloaded to obtain the membergroup information?"))
          {
            window.location.href = "$THIS_URLSEC?show=admin_editgroup&group=" + GroupID;
          }
        }
        return false;
      }

      var Groups = new Array();
ADMIN_EDITGROUP_JS


  # Get Groups, and make JavaScript array and HTML codes.
  my $I              = 0;
  my @Options        = ();
  my $SelectedOption = 0;
  my ($DefaultTitle, @DefaultMembers);


  group:foreach my $Group (@Groups)
  {
    # Get additional info for the Subject
    next group if ($Group eq 'everyone');

    my @GroupInfo = dbGetGroupInfo($Group);
    if (! dbGroupInvalid($Group, @GroupInfo))
    {
      {
        my @GroupInfo = @GroupInfo; # New copy in this block
        FormatFieldText($GroupInfo[DB_GROUP_TITLE]);

        my $Members   = join('|', @GroupInfo[DB_GROUP_MEMBERS..@GroupInfo-1]);

        for($GroupInfo[DB_GROUP_TITLE], $Members)
        {
          s/"/\\"/g; # No quotes
          s/'/\\'/g;
          s/\\/\\\\/g;
          s/\n/\\n/g;
        }
        $JS .= qq[      Groups[$I] = new Group('$GroupInfo[DB_GROUP_TITLE]', '$Group', '$Members');\n];
      }


      if ($DefaultGroup eq $Group)
      {
        push @Options, $Group => $GroupInfo[DB_GROUP_TITLE];
        $SelectedOption = $I;
      }
      else
      {
        push @Options, $Group => $GroupInfo[DB_GROUP_TITLE];
      }


      if ($I == $SelectedOption)
      {
        $DefaultTitle   = $GroupInfo[DB_GROUP_TITLE];
        @DefaultMembers = @GroupInfo[DB_GROUP_MEMBERS..@GroupInfo-1];
      }
    }

    $I++;
  }

  # End JavaScript
  $JS .= <<ADMIN_EDITGROUP_JS;

      var Changed = false;
      var CurrentGroup = $SelectedOption;
    // --></SCRIPT>
ADMIN_EDITGROUP_JS


  my $NOJS_WARNING = <<NO_JS;
    <NOSCRIPT>
      Note that this dialog will work a lot easier when you've turned JavaScript on, or install a browser that supports JavaScript!<BR>
      <EM>You can't use the select box!</EM>
      <P>
      <B> Edit a Group: </B><BR>
NO_JS
  for(my $I = 0; $I < @Options; $I=$I+2)
  {
    $NOJS_WARNING .= qq[    <A href="$THIS_URL?show=admin_editgroup&group=$Options[$I]">$Options[$I+1]</A><BR>\n];
  }

  $NOJS_WARNING .= qq[    </NOSCRIPT>\n];




  if(! defined $DefaultTitle)
  {
    Action_Error('There are no groups to edit!');
  }


  # HTML
  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Edit Membergroups]', 'Admin Center <FONT size="-1">[Edit Membergroups]</FONT>', undef, $JS.$FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'      =>  'Admin Center',
                        '?show=admin_editgroup'   =>  'Edit a Membergroup'
                      );
  print_bodystart_HTML();
  print $NOJS_WARNING;

  print_inputfields_HTML(
                          $TABLE_600_HTML         =>  q[onReset="Changed=false;"],1,
                          'action'                => 'admin_editgroup',
                          'group'                 => $DefaultGroup || $Options[0],
                        );
  print_required_TEST(@REQ_FIELDS_GROUP);
  print_editcells_HTML(
                        'Edit a Membergroup'      => 1,
                        'Choose Membergroup'      => sprint_selectfield_HTML(qq[groupjs" onChange="LoadGroup(this.form, this);], $DefaultGroup, \@Options)
                      );
  print_editcells_HTML(
                        'Group Properties' => 1,
                        $REQ_HTML.'Group Title'   => qq[<INPUT type="text" class="CoolText" name="title" size="60" maxlength="40" value="$DefaultTitle" onChange="Changed=true;">],
                        $REQ_HTML.'Members'       => sprint_memberfield_HTML('members" onChange="Changed=true', 12, \@DefaultMembers)
                      );
  print_buttoncells_HTML('Save');
  print_footer_HTML();
}





sub Action_AdminEditGroup
{
  LoadSupport('check_fields');
  LoadModule('HTML::EscapeASCII;');

  # Get Field values
  my $Group    = (param('group')    || '');
  my $NextShow = (param('groupjs')  || $Group);
  my $Title    = (param('title')    || '');
  my @Members  = param('members');
  my @Members  = ParseMembers(@Members);


  # Preform Field Checks
  ValidateRequiredFields(@REQ_FIELDS_GROUP);
  ValidateRequired($Group);
  ValidateLength($Title, 'Title', 40);

  # Check for existance of subject's data folder and edit the group
  dbGroupCanUpdate($Group);

  my @GroupInfo                 = ();
  $GroupInfo[ID]             = $Group;
  $GroupInfo[DB_GROUP_TITLE] = $Title;
  push @GroupInfo, @Members;
  FormatFieldHTML($GroupInfo[DB_GROUP_TITLE]);
  dbSaveGroupInfo(@GroupInfo);


  # Log print and redirect
  print_log("EDITGROUP",'', "GROUP=$Group");

  print redirect("$THIS_URLSEC?show=admin_editgroup&group=$NextShow");
  exit;
}





##################################################################################################
## Make Array of member text field


sub ParseMembers
{
  LoadSupport('db_members');

  my @RetMembers   = ('admin');
  my %AddedMembers = ('admin' => 1);

  foreach my $Member (@_)
  {
    if(! $AddedMembers{$Member} && length($Member))
    {
      $AddedMembers{$Member} = 1;
      push @RetMembers, $Member   unless dbMemberFileInvalid($Member);
    }
  }

  return @RetMembers;
}



1;
