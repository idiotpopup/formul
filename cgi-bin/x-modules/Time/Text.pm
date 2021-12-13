##################################################################################################
##                                                                                              ##
##  >> Time Display Routines <<                                                                 ##
##  This is a public libary that can be loaded for any Perl Program.                            ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################


package Time::Text;


use strict;

BEGIN
{
  use Exporter  ();
  use vars      qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  use vars      qw(@Days @ShortMonths @LongMonths);

  $VERSION      = 1.01;
  @ISA          = qw(Exporter);

  @EXPORT       = qw(&localtimestr &gmtimestr);
  @EXPORT_OK    = ();
  %EXPORT_TAGS  = ();
}

sub import
{
  my $package  = shift;
  my $language = shift || 'English';

  if(defined $language)
  {
    my $class  = "Time::Text::" . ucfirst(lc($language));

    no strict 'refs';
    if(! defined @{"$class\::VERSION"}) # Load once...
    {
      eval "require $class";
      if($@)
      {
        my @c=caller;
        chomp $@;
        die "Language ($language) not found at $c[1] line $c[2]: $@\n";
      }
      *Days        = \@{"$class\::Days"};
      *ShortMonths = \@{"$class\::ShortMonths"};
      *LongMonths  = \@{"$class\::LongMonths"};
    }
  }
  else
  {
    my @c=caller;
    die "Language ($language) not found at $c[1] line $c[2]\n";
  }

  Time::Text->export_to_level(1);
}


##################################################################################################
## Displaying time strings

sub localtimestr (;$) { return timestr(defined $_[0] ? localtime($_[0]) : localtime()) }
sub gmtimestr    (;$) { return timestr(defined $_[0] ?    gmtime($_[0]) :    gmtime()) }


##################################################################################################
## Internal helper

sub timestr (@)
{ my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = @_;

  $year += 1900;
  $mday = " $mday" if ($mday < 10);
  $sec  = "0$sec"  if ($sec  < 10);
  $min  = "0$min"  if ($min  < 10);
  $hour = "0$hour" if ($hour < 10);
  $year = " $year" if ($year < 1000);

  $Days[$wday]       .= " " if length($Days[$wday]) == 2;
  $ShortMonths[$mon] .= " " if length($ShortMonths[$mon]) == 2;

  return "$Days[$wday] $ShortMonths[$mon] $mday $hour:$min:$sec $year";
}


1;


## EOF
##################################################################################################

__END__

=head1 NAME

Time::Text - Displaying time as text

=head1 SYNOPSIS

  # Importing methods.
  use Time::Text;
  use Time::Text qw(English);
  use Time::Text qw(Dutch);

  # Method Calling
  print localtimestr();
  print localtimestr(time + 60);
  print gmtimestr();

=head1 DESCRIPTION

This module provides two methods to work with time-strings in your program.
In fact, the result is exactly as when calling the localtime() and gmtime()
functions in a scalar context. However, this module accepts a language
parameter when importing. This turns the strings produced by the functions
also appear in that specific language.

This module attempts to load the language specified (or english by default)
from a Time::Text::LanguageName module.

=head2 Exported Functions

=over

=item localtimestr([TIME]), gmtimestr([TIME])

Behaves exactly like the build-in functions gmtime() and localtime(),
called in a scalar context.

=item @Time::Text::Days, @Time::Text::ShortMonths, @Time::Text::LongMonths

These array's are filled with the language-specific strings
loaded when the module is imported. They are used by the exported functions.

=back

=head1 AUTHOR

        Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

        webmaster@codingdomain.com
        http://www.codingdomain.com

=cut