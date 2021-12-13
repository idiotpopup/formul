##################################################################################################
##                                                                                              ##
##  >> Administrator Change Subjects <<                                                         ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


use strict;

$VERSIONS{'admin_chsubjects.pl'} = 'Release 1.6';

LoadSupport('db_subjects');
LoadSupport('check_security');

# Check for admin member access.
ValidateAdminAccess();


my @REQ_FIELDS_SUBJECT = qw(title description moderators groups);



##################################################################################################
## Admin: Add Subject

sub Show_AdminAddSubjectDialog
{
  LoadSupport('html_fields');

  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Add a Subject]', 'Admin Center <FONT size="-1">[Add a Subject]</FONT>', undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'       =>  'Admin Center',
                        '?show=admin_addsubject'   =>  'Add a Subject'
                      );
  print_bodystart_HTML();

  print_inputfields_HTML(
                         $TABLE_600_HTML           => undef,1,
                         'action'                  => 'admin_addsubject',
                       );
  print_required_TEST(@REQ_FIELDS_SUBJECT);
  print_editcells_HTML(
                        'New Subject'              => 1,
                        $REQ_HTML.'Subject Title'  => qq[<INPUT type="text" class="CoolText" name="title" size="60" maxlength="40">],
                                  'Subject Icon'   => sprint_subjecticons_HTML('icon',''),
                        $REQ_HTML.'Description'         => qq[<TEXTAREA name="description" class="small" ROWS="4" COLS="45"></TEXTAREA>],
                        $REQ_HTML.'Moderator List'      => sprint_memberfield_HTML('moderators', 8, ['admin']),
                        $REQ_HTML.'Allowed Groups Only' => sprint_groupfield_HTML('groups', 4, ['everyone']),
                        'Subject ID'                    => qq[<INPUT type="text" class="CoolText" name="subject" size="60" maxlength="40">]);
  print_buttoncells_HTML('Add');
  print_footer_HTML();
}


sub Action_AdminAddSubject
{
  LoadSupport('db_members');
  LoadSupport('check_fields');
  LoadModule('HTML::EscapeASCII;');

  # Get Field values
  my $Title       = (param('title')       || '');
  my $Icon        = (param('icon')        || '');
  my $Description = (param('description') || '');
  my $Subject     = (param('subject')     || '');
  my @Moderators  = param('moderators');
  my @Groups      = param('groups');

  $Subject        = NameGen($Title) if ($Subject eq '');

  $Description =~ s/$LINEBREAK_PATTERN/ /g;



  # Preform Field Checks
  ValidateRequiredFields(@REQ_FIELDS_SUBJECT);
  ValidateRequired($Subject);
  ValidateLength($Title, 'Title', 40);



  # Check for existance of subject's data folder
  if ( dbSubjectExist($Subject))
  {
    Action_Error(qq[There is already a subject created using a simular id!! <BR>\n]
               . qq[    Note that the ID could be automatically generated, if the field's value is left empty.<BR>\n]
               . qq[    Please change your title of the Subject!$RETURN_HTML]
                );
  }



  # Make the subject
  my @SubjectInfo;
  {
    $SubjectInfo[ID]                      = $Subject;
    $SubjectInfo[DB_SUBJECT_TITLE]        = $Title;
    $SubjectInfo[DB_SUBJECT_DESCRIPTION]  = $Description;
    $SubjectInfo[DB_SUBJECT_MODERATORS]   = ParseModerators(@Moderators);
    $SubjectInfo[DB_SUBJECT_GROUPS]       = ParseGroups(@Groups);
    $SubjectInfo[DB_SUBJECT_TOPICNUM]     = 0;
    $SubjectInfo[DB_SUBJECT_LASTPOSTER]   = '';
    $SubjectInfo[DB_SUBJECT_LASTPOSTDATE] = '';
    $SubjectInfo[DB_SUBJECT_ICON]         = $Icon;

    FormatFieldHTML($SubjectInfo[DB_SUBJECT_TITLE], $SubjectInfo[DB_SUBJECT_DESCRIPTION]);
  }

  dbMakeSubject($Subject);
  dbSaveSubjectInfo(@SubjectInfo);


  # Log print and redirect
  print_log("ADDSUBJECT",'', "SUBJECT=$Subject");

  if(dbSubjectCount() > 1) { print redirect("$THIS_URLSEC?show=admin_sortsubjects"); }
  else                     { print redirect("$THIS_URLSEC?show=admin_center"); }
  exit;
}




##################################################################################################
## Admin: Edit Subjects

sub Show_AdminEditSubjectDialog
{
  LoadSupport('html_fields');
  LoadModule('HTML::EscapeASCII;');

  # Get Subject Suggestion (for example, for non javascript browsers)
  my $DefaultSubject = (param('subject') || '');
  my @Subjects       = dbGetSubjects();

  if(@Subjects == 0)
  {
    Action_Error("There are no subjects to edit!");
  }



  # Define JavaScript
  my $JS = <<ADMIN_EDITSUBJECT_JS;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      function Subject(Title, Icon, Description, SubjectID, Moderators, Groups)
      {
        // 'Subject Structure' for array
        this.title       = Title;
        this.icon        = Icon;
        this.description = Description;
        this.subjectid   = SubjectID;
        this.moderators  = Moderators;
        this.groups      = Groups
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

      function LoadSubject(Form, Select)
      {
        // RULE: We assume that the fields are sorted like found in the array
        if(! SaveChanges(Form))
        {
          var SubjectID = Select.options[Select.selectedIndex].value;
          for (var I = 0; I < Subjects.length; I++)
          {
            if (Subjects[I].subjectid == SubjectID)
            {
              // Change fields
              Form.subject.value     = Subjects[I].subjectid;
              Form.title.value       = Subjects[I].title;
              Form.description.value = Subjects[I].description;
              var Icon               = Subjects[I].icon;
              var Moderators         = Subjects[I].moderators.split(",");
              var Groups             = Subjects[I].groups.split(",");

              SelectOption(Form.icon,        Icon);
              SelectOptions(Form.moderators, Moderators, true);
              SelectOptions(Form.groups,     Groups,     true);

              Changed           = false;     // There are no changes anymore.
              return true;
            }
          }
          if (confirm("The Subject could not be found!\\nShould this page be reloaded to obtain the subject information?"))
          {
            window.location.href = "$THIS_URLSEC?show=admin_editsubject&subject=" + SubjectID;
          }
        }
        return false;
      }

      var Subjects = new Array();
ADMIN_EDITSUBJECT_JS





  # Get Subjects, and make JavaScript array and HTML codes.
  my $I              = 0;
  my @Options        = ();
  my $SelectedOption = 0;

  my ($DefaultTitle, $DefaultIcon, $DefaultDescription, @DefaultModerators, @DefaultGroups);

  foreach my $Subject (@Subjects)
  {
    # Get additional info for the Subject
    if(! dbSubjectIsTitle($Subject))
    {
      my @SubjectInfo = dbGetSubjectInfo($Subject);

      if (! dbSubjectInvalid($Subject, @SubjectInfo))
      {
        {
          my @SubjectInfo = @SubjectInfo; # New copy in this block
          FormatFieldText(@SubjectInfo);

          for($SubjectInfo[DB_SUBJECT_TITLE], $SubjectInfo[DB_SUBJECT_DESCRIPTION], $SubjectInfo[DB_SUBJECT_MODERATORS], $SubjectInfo[DB_SUBJECT_GROUPS])
          {
            s/"/\\"/g; # No quotes
            s/'/\\'/g;
            s/\n/\\n/g;
          }
          $JS .= qq[      Subjects[$I] = new Subject('$SubjectInfo[DB_SUBJECT_TITLE]', '$SubjectInfo[DB_SUBJECT_ICON]', '$SubjectInfo[DB_SUBJECT_DESCRIPTION]', '$Subject', '$SubjectInfo[DB_SUBJECT_MODERATORS]', '$SubjectInfo[DB_SUBJECT_GROUPS]');\n];
        }

        if ($DefaultSubject eq $Subject)
        {
          push @Options, $Subject => $SubjectInfo[DB_SUBJECT_TITLE];
          $SelectedOption = $I;
        }
        else
        {
          push @Options, $Subject => $SubjectInfo[DB_SUBJECT_TITLE];
        }

        if ($I == $SelectedOption)
        {
          $DefaultTitle       = $SubjectInfo[DB_SUBJECT_TITLE];
          $DefaultIcon        = $SubjectInfo[DB_SUBJECT_ICON];
          $DefaultDescription = $SubjectInfo[DB_SUBJECT_DESCRIPTION];
          @DefaultModerators  = split(",", $SubjectInfo[DB_SUBJECT_MODERATORS]);
          @DefaultGroups      = split(",", $SubjectInfo[DB_SUBJECT_GROUPS]);
        }
      }
      $I++;
    }
  }

  # End of JavaScript
  $JS .= <<ADMIN_EDITSUBJECT_JS;

      var Changed = false;
    // --></SCRIPT>
ADMIN_EDITSUBJECT_JS

  my $NOJS_WARNING = <<NO_JS;
    <NOSCRIPT>
      Note that this dialog will work a lot easier when you've turned JavaScript on, or install a browser that supports JavaScript!<BR>
      <EM>You can't use the select box!</EM>
      <P>
      <B> Edit a Subject: </B><BR>
NO_JS
  for(my $I = 0; $I < @Options; $I=$I+2)
  {
    $NOJS_WARNING .= qq[    <A href="$THIS_URL?show=admin_editsubject&subject=$Options[$I]">$Options[$I+1]</A><BR>\n];
  }

  $NOJS_WARNING .= qq[    </NOSCRIPT>\n];


  if(! defined $DefaultTitle)
  {
    Action_Error("There are no subjects to edit!");
  }


  # HTML
  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Edit Subjects]', 'Admin Center <FONT size="-1">[Edit Subjects]</FONT>', undef, $JS.$FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'       =>  'Admin Center',
                        '?show=admin_editsubject'  =>  'Edit a Subject'
                      );
  print_bodystart_HTML();
  print $NOJS_WARNING;
  print_inputfields_HTML(
                          $TABLE_600_HTML          => q[onReset="Changed=false;"],1,
                          'action'                 => 'admin_editsubject',
                          'subject'                => $DefaultSubject || $Options[0],
                        );
  print_required_TEST(@REQ_FIELDS_SUBJECT);
  print_editcells_HTML(
                        'Edit a Subject'           => 1,
                        'Choose Subject'           => sprint_selectfield_HTML(qq[subjectjs" onChange="LoadSubject(this.form, this);], $DefaultSubject, \@Options)
                      );
  print_editcells_HTML(
                        'Subject Properties'       => 1,
                        $REQ_HTML.'Subject Title'  => qq[<INPUT type="text" class="CoolText" name="title" size="60" maxlength="40" value="$DefaultTitle" onChange="Changed=true;">],
                                  'Subject Icon'   => sprint_subjecticons_HTML('icon" onChange="Changed=true;', $DefaultIcon),
                        $REQ_HTML.'Description'    => qq[<TEXTAREA name="description" class="small" ROWS="4" COLS="45" onChange="Changed=true;">$DefaultDescription</TEXTAREA>],
                        $REQ_HTML.'Moderator List'      => sprint_memberfield_HTML('moderators" onChange="Changed=true;', 8, \@DefaultModerators),
                        $REQ_HTML.'Allowed Groups Only' => sprint_groupfield_HTML('groups" onChange="Changed=true;', 4, \@DefaultGroups),
                      );
  print_buttoncells_HTML('Save');
  print_footer_HTML();
}




sub Action_AdminEditSubject
{
  LoadSupport('check_fields');
  LoadModule('HTML::EscapeASCII;');

  # Get Field values
  my $Subject     = (param('subject'));
  my $NextShow    = (param('subjectjs')     || $Subject);
  my $Title       = (param('title')         || '');
  my $Icon        = (param('icon')          || '');
  my $Description = (param('description')   || '');
  my @Moderators  = param('moderators');
  my @Groups      = param('groups');


  # Preform Field Checks
  ValidateRequiredFields(@REQ_FIELDS_SUBJECT);
  ValidateRequired($Subject);
  ValidateLength($Title, 'Title', 40);

  $Description =~ s/$LINEBREAK_PATTERN/ /g;


  # Check for existance of subject's data folder and edit the subject
  my @SubjectInfo = dbGetSubjectInfo($Subject, 1);
  {
    $SubjectInfo[DB_SUBJECT_TITLE]       = $Title;
    $SubjectInfo[DB_SUBJECT_ICON]        = $Icon;
    $SubjectInfo[DB_SUBJECT_DESCRIPTION] = $Description;
    $SubjectInfo[DB_SUBJECT_MODERATORS]  = ParseModerators(@Moderators);
    $SubjectInfo[DB_SUBJECT_GROUPS]      = ParseGroups(@Groups);

    FormatFieldHTML($SubjectInfo[DB_SUBJECT_TITLE], $SubjectInfo[DB_SUBJECT_DESCRIPTION]);
  }
  dbSaveSubjectInfo(@SubjectInfo);



  # Log print and redirect
  print_log("EDITSUBJECT",'', "SUBJECT=$Subject");

  print redirect("$THIS_URLSEC?show=admin_editsubject&subject=$NextShow");
  exit;
}



##################################################################################################
## Admin: Subject Sort

sub Show_AdminSortSubjectsDialog
{
  LoadSupport('html_fields');

  my @Subjects = dbGetSubjects();
  Action_Error("The current subjects can't be re-ordered!") if(@Subjects <= 1);
  my $Subjects = join("\n", @Subjects) . "\n";

  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Restucture Subjects]', 'Admin Center <FONT size="-1">[Restucture Subjects]</FONT>', undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'        =>  'Admin Center',
                        '?show=admin_sortsubjects'  =>  'Restucture Subjects'
                      );
  print_bodystart_HTML();
  print_inputfields_HTML(
                          $TABLE_600_HTML           => undef,1,
                          'action'                  => 'admin_sortsubjects',
                        );
  print_editcells_HTML(
                        'Restucture Subjects'       => 1,
                        $REQ_HTML.'Restucture Subjects' => qq[<TEXTAREA name="subjects" class="large" ROWS="12" COLS="45">$Subjects</TEXTAREA>]
                      );
  print_buttoncells_HTML('Change');
  print_footer_HTML();
}




sub Action_AdminSortSubjects
{
  LoadSupport('check_fields');

  # Get Field values
  my $SubjectsNew = (param('subjects') || '');
  $SubjectsNew    =~ s/($LINEBREAK_PATTERN)/\n/g;


  # Preform Field Checks
  ValidateRequired('subjects' => $SubjectsNew);


  # Find out if no subject is added/missing
  my @SubjectsOld = dbGetSubjects();
  while(chomp $SubjectsNew) {}


  # Sort them
  my @OldSort = sort grep { !dbSubjectIsTitle($_) } @SubjectsOld;
  my @NewSort = sort grep { !dbSubjectIsTitle($_) } split(/\n/, $SubjectsNew);
  chomp @NewSort;


  # Compare
  foreach my $I (0..@OldSort-1)
  {
    if ($I >= @NewSort)               { Action_Error("The subject <I>$OldSort[$I]</I> seams to be missing from the subject list!"); }
    if ($NewSort[$I] ne $OldSort[$I]) { Action_Error("The subject <I>$NewSort[$I]</I> is not an existing subject or the subject <I>$OldSort[$I]</I> is missing!"); }
  }
  if (@NewSort > @OldSort)            { Action_Error("The subject <I>$NewSort[scalar @OldSort]</I> is not an existing subject!"); }
  if (@NewSort < @OldSort)            { Action_Error("Some subjects seam to be missing!"); } # Secure
  if ($SubjectsNew =~ m[^--])         { Action_Error("The subjects list should begin with a header, not a subject ID"); }



  # Make the subject
  dbSaveSubjects($SubjectsNew . "\n");


  # Log print and redirect
  print_log("SAVESUBJECTS");

  print redirect("$THIS_URLSEC?show=admin_center");
  exit;
}


##################################################################################################



sub Show_AdminDeleteSubjectDialog ()
{
  LoadSupport('html_fields');

  my @Subjects = dbGetSubjects();
  Action_Error("There are no subjects to delete!")   if(@Subjects == 0);
  Action_Error("You can't remove the last subject!") if(@Subjects == 1);

  my @Options;

  foreach my $Subject (@Subjects)
  {
    if(! dbSubjectIsTitle($Subject))
    {
      my @SubjectInfo = dbGetSubjectInfo($Subject);
      if(! dbSubjectInvalid($Subject, @SubjectInfo))
      {
        push @Options, $Subject => $SubjectInfo[DB_SUBJECT_TITLE];
      }
    }
  }

  Action_Error("There are no subjects to delete!")   if(@Options == 0);
  Action_Error("You can't remove the last subject!") if(@Options == 1);


  CGI::cache(1);
  print_header;
  print_header_HTML('Admin Center [Delete Subject]', 'Admin Center <FONT size="-1">[Delete Subject]</FONT>', undef, $FORM_JS);
  print_toolbar_HTML();
  print_treelevel_HTML(
                        '?show=admin_center'      =>  'Admin Center',
                        '?show=admin_delsubject'  =>  'Delete Subject'
                      );
  print_bodystart_HTML();
  print_inputfields_HTML(
                          $TABLE_600_HTML         => undef,1,
                          'action'                => 'admin_delsubject',
                        );
  print_editcells_HTML(
                        'Delete Subject'          => 1,
                        'Delete Subject'          => sprint_selectfield_HTML('subject',   $Options[0],  \@Options),
                        'Move Topics To'          => sprint_selectfield_HTML('subjectto', $Options[-2], \@Options),
                      );
  print_buttoncells_HTML('Delete');
  print_footer_HTML();
}


sub Action_AdminDeleteSubject ()
{
  my $Subject     = (param('subject')   || '');
  my $SubjectTo   = (param('subjectto') || '');

  if($Subject eq $SubjectTo)
  {
    Action_Error("You can't move the topics to the same subject as the one that will be deleted!");
  }

  dbDelSubject($Subject, $SubjectTo);


  print_log("DELSUBJECT", '', "SUBJECT=$Subject TOPICTO=$SubjectTo");
  print redirect("$THIS_URL?show=admin_center");
}









##################################################################################################







sub sprint_subjecticons_HTML($;$)
{
  my($name, $selected) = @_;

  my @icons;
  LoadSupport('html_fields');
  if(opendir(SUBICO, "$IMAGE_FOLDER${S}subjecticons"))
  {
    @icons = grep /\.gif$/, readdir SUBICO;
    closedir(SUBICO);

    @icons = map
             {
               s/(.+)\.gif$/$1/;
               $_ => ucfirst($_)
             }
             grep
             {
               ! /^(private|public)\.gif$/i
             }
             sort @icons;
    unshift @icons, ('' => '(Default)');
  }

  $selected = '' unless defined $selected;
  return sprint_selectfield_HTML($name, $selected, \@icons);
}



# Modify moderator string so only existing members are included,
# and syntax is correct or further use.
sub ParseModerators
{
  LoadSupport('db_members');

  my $Moderators   = ('admin');
  my %AddedMembers = ('admin' => 1);

  foreach my $Moderator (@_)
  {
    if(! $AddedMembers{$Moderator} && length($Moderator))
    {
      $AddedMembers{$Moderator} = 1;
      $Moderators   .= ",$Moderator" unless dbMemberFileInvalid($Moderator);
    }
  }
  return $Moderators;
}



# Modify group string so only existing groups are included,
sub ParseGroups
{
  LoadSupport('db_groups');

  my $Groups      = '';
  my %AddedGroups = ();

  testedgroup:foreach my $Group (@_)
  {
    if($Group eq 'everyone')
    {
      # There are no limits to viewing this subject
      $Groups = 'everyone';
      last testedgroup;
    }

    if(! $AddedGroups{$Group} && length($Group))
    {
      $AddedGroups{$Group} = 1;
      if(! dbGroupFileInvalid($Group))
      {
        $Groups .= ','   if(length($Groups));
        $Groups .= $Group;
      }
    }
  }

  return $Groups || 'everyone';
}

1;
