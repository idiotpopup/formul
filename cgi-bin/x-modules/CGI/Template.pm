package CGI::Template;

#
#       Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved
#
#       webmaster@codingdomain.com
#       http://www.codingdomain.com
#

use strict;
use Fcntl qw(:DEFAULT :flock);


######################################################################################################
## Make the file settings...

BEGIN
{
  use Exporter  ();
  use vars      qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

  $VERSION      = 1.00;
  @ISA          = qw(Exporter);

  @EXPORT       = qw(&TemplateLoad @HTML $Line $LABEL &TemplateSetReplace &print_TemplateUntil &print_TemplateUntilLabel &print_TemplateUntilEOF);
  @EXPORT_OK    = ();
  %EXPORT_TAGS  = ();
}

use vars qw(@HTML $Line $LABEL);

$LABEL = 'TEMPLATE';
my %TemplateReplace = ();


##################################################################################################

sub TemplateLoad($)
{
  sysopen(TEMPLATE, $_[0], O_RDONLY) or return undef;
    flock(TEMPLATE, LOCK_SH);
      @HTML = <TEMPLATE>;
    flock(TEMPLATE, LOCK_UN);
  close(TEMPLATE);
  $Line = 0;
  return 1;
}


##################################################################################################
## Searches the template for tags and replaces them.
## This routine might be called several times, but then
## it just continues searching where it stopped before.

sub print_TemplateHTML#(STRING ExpectedCode, STRING ReplaceCode)
{ my ($SearchCode, $ReplaceHTML) = @_;

  if(not defined @HTML) { die "Template not loaded, or loading failed!\n"; }

  return if ($Line > @HTML); # All Done Already!
  my $Code;
  my $TagLabel = '%' . $LABEL . '::'; ## Don't handle longer comments ( <!------LABEL:: )
  my $TagSize = length($TagLabel);

  foreach my $I ($Line..@HTML-1)
  {
    # Find <!--LABEL:: tags
    my $PosStart = index($HTML[$I], $TagLabel);
    if ($PosStart != -1)
    {
      # Find begin of code and begin of closing tag %
      my $PosCodeStart = $PosStart + $TagSize;
      my $PosCodeEnd = index($HTML[$I], '%', $PosCodeStart + 1);
      if ($PosCodeEnd != -1)
      {
        # Find Code
        my $PosEnd = $PosCodeEnd + 1; # 1 = length of endcode;
        $Code = substr($HTML[$I], $PosCodeStart, $PosCodeEnd - $PosCodeStart);

        if ($SearchCode && $Code eq $SearchCode)
        {
          # Replace with HTML if this is what we're looking for.
          $HTML[$I] = substr($HTML[$I], 0, $PosStart) . $ReplaceHTML . substr($HTML[$I], $PosEnd);
          if ($HTML[$I] eq "\n") { $HTML[$I] = ''; }
        }
        elsif (exists $TemplateReplace{$Code})
        {
          # Replace with hash value if this is just a simple text line (like webmaster or copyright).
          $HTML[$I] = substr($HTML[$I], 0, $PosStart) . $TemplateReplace{$Code} . substr($HTML[$I], $PosEnd);
          if ($HTML[$I] eq "\n") { $HTML[$I] = ''; }
          $Code = undef; redo; # Reset and Redo this line.
        }
        else
        {
          # Remove the code, we can't do anything with it!
          $HTML[$I] = substr($HTML[$I], 0, $PosStart) . substr($HTML[$I], $PosEnd);
          $Code = undef; # Reset code; either for loop redo, else for for-loop at next line
          if ($HTML[$I] eq "\n") { $HTML[$I] = ''; }
          else { redo; } # Redo this line.
        }
      }

      return if($Code && $Code eq 'BODY');
      if((index($HTML[$I], $TagLabel) == -1)) # Unless more codes on same line...
      {
        $Line = $I + 1;  # For next call.
        print $HTML[$I]; # Print current (maybe modified) line.
      }
      return if defined $Code; # Next match done by next call
    }
    else
    {
      $Line = $I + 1;  # For next call.
      print $HTML[$I]; # Print current HTML line.
    }
  }

  # We're done search. We should be in to print_footer_HTML routine.
  # Otherwise, this routine has been called too many times, or code tags are missing.
}


##################################################################################################
## The Calls you should use

sub TemplateSetReplace ($$) #(STRING SearchTag, STRING ReplaceTag)
{ $TemplateReplace{$_[0]} = $_[1]; }

sub print_TemplateUntil ($$) #(STRING SearchTag, STRING ReplaceHTML)
{ &print_TemplateHTML($_[0] => $_[1]); }

sub print_TemplateUntilLabel ($) #(STRING SearchTag)
{ &print_TemplateHTML($_[0] => ''); }

sub print_TemplateUntilEOF ()
{ &print_TemplateHTML(); }


##################################################################################################




1;


__END__

=head1 NAME

CGI::Template - Easy to use template parser

=head1 SYNOPSIS

  use CGI::Template;

  TemplateLoad('template.html') or die "Can't load: $!";

  # Add default a search-replace for %TEMPLATE::COPYRIGHT%
  TemplateSetReplace('COPYRIGHT' => $Copyright);

  # Prints out until %TEMPLATE::LABEL% is found, and replaces it by 'Hi There!'.
  # The label should exist, or else the entire template is printed out first.
  print_TemplateUntil('TITLE'    => 'Script using a template');
  print_TemplateUntil('TOOLBAR'  => $ToolbarHTML);
  print_TemplateUntil('LOCATION' => $LocationHTML);

  # Continues Prints the template until the %TEMPLATE::BODY% label
  # is found, where out script may print it's HTML output ;-)
  print_TemplateUntilLabel('BODY');

  print "Hi there! This is my script using a template";
  ...
  More perl code
  ...
  print "End of script HTML code in body part of the HTML";

  # Prints the remaining lines of the template
  print_TemplateUntilEOF();

  exit;


=head1 DESCRIPTION

Template parser that can be useful in any CGI script. The functions import
a template file, and labels will be used to print out until a certain position.
In this way, your CGI script can always look like all your other HTML pages,
without the need to hack into the CGI script's code looking for printed lines.

=head2 Exported Functions and Variables

=over

=item TemplateLoad(TemplateFileName)

Loads the template file. The file contents will be saved into the variable
@CGI::Template::HTML.

=item TemplateSetReplace( 'SOMETAG' => 'REPLACEMENT' )

Predefines some labels to be replaced. THis could include copyright information and
other small repetetive texts, like titles and file paths labels. The replacements
will be saved and used when printing the template with one of the functions below.

=item print_TemplateUntil( 'SOMETAG' => 'REPLACEMENT' )

This will print out the template tekst UNTIL %TEMPLATE::SOMETAG% is found
in the template text. That code will be replaced by the 'REPLACEMENT' value.
Any tags found before the 'SOMETAG' will be replaced,
if the replacement has been defined by a TemplateSetReplace call.
Otherwise, that code will be deleted!
Thus, it's important to have frequently used tags defined before this call.
This call is very useful for printing out the template to (for example)
<HEAD> tags. Then using normal print commands to print other text
that will follow (like <TITLE> and <META> tags), or printing to
a %TEMPLATE::FOOTER% location where a generated footer could be printed.

=item print_TemplateUntilLabel( 'SOMETAG' )

This subroutine works in the same way, with one difference.
The tag will be deleted in stead of being replaced.
This subroutine is actually a synonym for print_TemplateUntil('SOMETAG' => '');
If you mark a position in the template where the body of the webpage
should be printed, this will (for example) print everything until that location.

=item print_TemplateUntilEOF()

The last subroutine prints out the rest of what is left of the template lines.
Every (known) tag that has been defined will be replaced.

=item $CGI::Template::LABEL

Variable where the text 'TEMPLATE' is saved by default. This is the first
part of the template label that should be found, like in %TEMPLATE::SOMETAG%.
Change it if you prefer a less original name.

=item @CGI::Template::HTML

The template codes that are being filled by a TemplateLoad call.
You can change these codes at run time.

=item $CGI::Template::Line

The current line of the template printing.
Can be used to modify the template HTML codes array.

=back

=head1 AUTHOR

        Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

        webmaster@codingdomain.com
        http://www.codingdomain.com

=cut