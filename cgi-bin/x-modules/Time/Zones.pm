##################################################################################################
##                                                                                              ##
##  >> Timezone Convert Routines <<                                                             ##
##  This is a public libary that can be loaded for any Perl Program.                            ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

# A special thanks to the creators of tzedit.exe,
# found on the Win98 CD-Rom\Reskit\Config\tzedit.exe
# Without their tool, I wouldn't got all the data
# and timezone-ins and outs required
# for creating this package (and sub-packages)


package Time::Zones;


use strict;

BEGIN
{
  use Exporter  ();
  use vars      qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  use vars      qw(%Settings %Names);

  $VERSION      = 1.00;
  @ISA          = qw(Exporter);

  @EXPORT       = qw(&tztime &timezones &tzkeys &tznames);
  @EXPORT_OK    = ();
  %EXPORT_TAGS  = (
                    'timeelements' => [qw(SEC MIN HOUR DAY MONTH YEAR WEEKDAY YEARDAY ISDST)],
                    'days'         => [qw(SUN MON TUE WED THU FRI SAT)],
                    'months'       => [qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC)]
                  );
}

sub import
{
  my $package  = shift;
  my $language = shift;

  if(defined $language)
  {
    my $class  = "Time::Zones::" . ucfirst(lc($language));

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
      *Names = \%{"$class\::Names"}
    }
  }
  else
  {
    %Names = ();
  }

  Time::Zones->export_to_level(1);
}


# Constants for the %Settings hash
sub SUN(){  0  }
sub MON(){  1  }
sub TUE(){  2  }
sub WED(){  3  }
sub THU(){  4  }
sub FRI(){  5  }
sub SAT(){  6  }

sub JAN(){  0  }
sub FEB(){  1  }
sub MAR(){  2  }
sub APR(){  3  }
sub MAY(){  4  }
sub JUN(){  5  }
sub JUL(){  6  }
sub AUG(){  7  }
sub SEP(){  8  }
sub OCT(){  9  }
sub NOV(){  10 }
sub DEC(){  11 }

# localtime and gmtime constants.
sub SEC()    {  0  }
sub MIN()    {  1  }
sub HOUR()   {  2  }
sub DAY()    {  3  }
sub MONTH()  {  4  }
sub YEAR()   {  5  }
sub WEEKDAY(){  6  }
sub YEARDAY(){  7  }
sub ISDST()  {  8  }


##################################################################################################
## Size of certains dates.

my $SEC   = 1;
my $MIN   = 60  * $SEC;
my $HOUR  = 60  * $MIN;
my $DAY   = 24  * $HOUR;
my $WEEK  = 7   * $DAY;
my $YEAR1 = 365 * $DAY;
my $YEAR2 = 366 * $DAY;

my @MONTHLENGTH = qw( 31 28 31 30  31  30  31  31  30  31  30  31);
my @MONTHSTART1 = qw(  1 32 60 90 121 151 182 213 244 274 305 335); # 335+31=366 (represents first day of month 13, so it's OK)
my @MONTHSTART2 = qw(  1 32 61 91 122 152 183 214 245 275 306 336);


##################################################################################################
## Timezone settings

# Syntax of timezone hash-array:
#                 Time Zone Offset
#  'CODE' => [( [+-]H,M )],
#
#               Time Zone   Start DST (Nth weekday)   End of DST             DST Offset
#  'CODE' => [( [+-]H,M,    [1st-5th],DAY,MON,H,M,S,  [1-5],DAY,MON,H,M,S,   [+-]H,M )],

%Settings = (
'GMT'   => [ + 0, 0 ],
'GDST'  => [ + 0, 0, 5,SUN,FEB,  1,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'WEUR'  => [ + 1, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'CEUR1' => [ + 1, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'ROM'   => [ + 1, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'CEUR2' => [ + 1, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'WCAFR' => [ + 1, 0 ],
'GTB'   => [ + 2, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'EEUR'  => [ + 2, 0, 5,SUN,MAR,  0,0,0, 5,SUN,SEP,  1,0,0, + 1, 0 ],
'EGYPT' => [ + 2, 0, 1,FRI,MAY,  2,0,0, 5,WED,SEP,  2,0,0, + 1, 0 ],
'SAFR'  => [ + 2, 0 ],
'FLE'   => [ + 2, 0, 5,SUN,FEB,  3,0,0, 5,SUN,OCT,  4,0,0, + 1, 0 ],
'JERUS' => [ + 2, 0 ],
'ARAB1' => [ + 3, 0, 1,SUN,APR,  3,0,0, 1,SUN,OCT,  4,0,0, + 1, 0 ],
'ARAB2' => [ + 3, 0 ],
'RUSS'  => [ + 3, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'EAFR'  => [ + 3, 0 ],
'IRAN'  => [ + 3,30, 1,SUN,FEB,  3,0,0, 4,TUE,SEP,  2,0,0, + 1, 0 ],
'ARAB3' => [ + 4, 0 ],
'CAUCA' => [ + 4, 0 ],
'AFGH'  => [ + 4,30 ],
'EKAT'  => [ + 5, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'WASIA' => [ + 5, 0 ],
'INDIA' => [ + 5,30 ],
'NEPAL' => [ + 5,45 ],
'NCAS'  => [ + 6, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'CASIA' => [ + 6, 0 ],
'SRI'   => [ + 6, 0 ],
'MYAN'  => [ + 6,30 ],
'SEAS'  => [ + 7, 0 ],
'NASIA' => [ + 7, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'CHINA' => [ + 8, 0 ],
'NEAS'  => [ + 8, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'MALAY' => [ + 8, 0 ],
'WAUS'  => [ + 8, 0 ],
'TAIPE' => [ + 8, 0 ],
'JAPAN' => [ + 9, 0 ],
'KOREA' => [ + 9, 0 ],
'YAKUT' => [ + 9, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'CAUS'  => [ + 9,30, 5,SUN,OCT,  2,0,0, 5,SUN,FEB,  2,0,0, + 1, 0 ],
'AUSC'  => [ + 9,30 ],
'EAUS'  => [ +10, 0 ],
'AUSE'  => [ +10, 0, 5,SUN,OCT,  2,0,0, 5,SUN,FEB,  2,0,0, + 1, 0 ],
'WPAS'  => [ +10, 0 ],
'TASM'  => [ +10, 0, 1,SUN,OCT,  2,0,0, 5,SUN,FEB,  2,0,0, + 1, 0 ],
'VLAD'  => [ +10, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'CPAS'  => [ +11, 0 ],
'NZEA'  => [ +12, 0, 1,SUN,OCT,  2,0,0, 3,SUN,FEB,  2,0,0, + 1, 0 ],
'FIJI'  => [ +12, 0 ],
'TONGA' => [ +13, 0 ],
'AZORE' => [ - 1, 0, 5,SUN,FEB,  2,0,0, 5,SUN,OCT,  3,0,0, + 1, 0 ],
'CAPE'  => [ - 1, 0 ],
'MATL'  => [ - 2, 0, 5,SUN,FEB,  2,0,0, 5,SUN,SEP,  2,0,0, + 1, 0 ],
'ESAM'  => [ - 3, 0, 3,SUN,OCT,  2,0,0, 2,SUN,FEB,  2,0,0, + 1, 0 ],
'SAME'  => [ - 3, 0 ],
'GREEN' => [ - 3, 0, 1,SUN,APR,  2,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'NEWF'  => [ - 3,30, 1,SUN,APR,  2,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'ALTL'  => [ - 4, 0, 1,SUN,APR,  2,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'SAMW'  => [ - 4, 0 ],
'PASSA' => [ - 4, 0, 2,SAT,OCT,  0,0,0, 2,SAT,FEB,  0,0,0, + 1, 0 ],
'SAPAS' => [ - 5, 0 ],
'EAST'  => [ - 5, 0, 1,SUN,APR,  2,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'USEAS' => [ - 5, 0 ],
'CAM'   => [ - 6, 0 ],
'CENTR' => [ - 6, 0, 1,SUN,APR,  2,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'MEX'   => [ - 6, 0, 1,SUN,APR,  2,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'CANC'  => [ - 6, 0 ],
'USMOU' => [ - 7, 0 ],
'MOUNT' => [ - 7, 0, 1,SUN,APR,  2,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'PAS'   => [ - 8, 0, 1,SUN,APR,  2,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'ALASK' => [ - 9, 0, 1,SUN,APR,  2,0,0, 5,SUN,OCT,  2,0,0, + 1, 0 ],
'HAWAI' => [ -10, 0 ],
'SAMOA' => [ -11, 0 ],
'DATE'  => [ -12, 0 ],
);




##################################################################################################
## Calc Timezone

# Usage:
# my @TimeArray  = tztime($EpochSeconds, $ToZone);
# my $TextTime   = tztime($EpochSeconds, $ToZone);

sub tztime ($;$)
{ my ($ToZone, $EpochTime) = @_;

  # Some Assertions...
  if(($ToZone || '') eq '')         { return undef }
  if(not exists $Settings{$ToZone}) { return undef }


  # Default actions...
  if(not defined $EpochTime)        { $EpochTime = time(); }
  if( $ToZone eq 'GMT')             { return gmtime($EpochTime); }


  # Initialize variables
  my @NewTime;
  my $NewIsDST = 0;
  my (
       $TZHour,$TZMin,
       $TZDST_NDay,$TZDST_WDay,$TZDST_Mon,$TZDST_Hour,$TZDST_Min,$TZDST_Sec,
       $TZSTD_NDay,$TZSTD_WDay,$TZSTD_Mon,$TZSTD_Hour,$TZSTD_Min,$TZSTD_Sec,
       $TZDST_AddHour,$TZDST_AddMin
     ) = @{$Settings{$ToZone}};


  # Convert GMT to the timezone specified.
  $EpochTime += ($TZHour * $HOUR) + ($TZMin * $MIN);    # We just offset Greenwich!
  @NewTime    = gmtime($EpochTime);                     # No Timezone or DST conversion is done in GMT


  # Test for DST
  if(defined $TZDST_AddHour)
  {
    # Find the start of the year in seconds from epoch...
    my $YearStart     = $EpochTime - $NewTime[SEC]*$SEC - $NewTime[MIN]*$MIN - $NewTime[HOUR]*$HOUR - $NewTime[YEARDAY]*$DAY;

    # Get the day-number of the Nth day in the year, as defined by the timezone
    my $DSTStartDate  = $DAY * getNthDay($YearStart, $TZDST_NDay, $TZDST_WDay, $TZDST_Mon, $NewTime[YEAR]);
    my $DSTEndDate    = $DAY * getNthDay($YearStart, $TZSTD_NDay, $TZSTD_WDay, $TZSTD_Mon, $NewTime[YEAR]);

    # Determine 3 locations (DSTbegin,current,DSTend) in the year we will compare later...
       $DSTStartDate += ($TZDST_Hour * $HOUR) + ($TZDST_Min * $MIN);
       $DSTEndDate   += ($TZSTD_Hour * $HOUR) + ($TZSTD_Min * $MIN);
    my $NowInYear     = ($NewTime[YEARDAY] * $DAY) + ($NewTime[HOUR] * $HOUR) + ($NewTime[MIN] * $MIN) + ($NewTime[SEC] * $SEC);


    # Precondition...
    if($DSTStartDate == $DSTEndDate)
    {
      warn "Invalid Timezone: $ToZone";
    }


    # Find out if the $NowInYear falls between the DST part.
    # Note that DSTbegin could be september, and DSTend march!!
    if ($DSTStartDate < $DSTEndDate)
    {
      if($DSTStartDate <= $NowInYear && $NowInYear < $DSTEndDate)
      {
        $EpochTime += ($TZDST_AddHour * $HOUR) + ($TZDST_AddMin * $MIN);
        @NewTime    = gmtime($EpochTime);
        $NewIsDST   = 1;
      }
    }
    else
    {
      my $YearEndSec = (isLeapYear($NewTime[YEAR]) ? $YEAR2 : $YEAR1);
      if((0 <= $NowInYear && $NowInYear < $DSTEndDate) || ($DSTStartDate <= $NowInYear && $NowInYear <= $YearEndSec))
      {
        $EpochTime += ($TZDST_AddHour * $HOUR) + ($TZDST_AddMin * $MIN);
        @NewTime    = gmtime($EpochTime);
        $NewIsDST   = 1;
      }
    }
  }


  # Return the tztime
  if(wantarray)
  {
    push @NewTime, $NewIsDST;
    return @NewTime;
  }
  return scalar gmtime($EpochTime);
}



##################################################################################################
## Sorting timezones

sub tzkeys ()
{
  return keys %Settings;
}

sub tznames (;$)
{
  return \%Names unless @_;
  return $Names{$_[0]};
}

sub timezones($$)
{
  if(! defined $_[0] && ! defined $_[1]) {
    my @c = caller();
    die 'Perl $] does not support that syntax (use sort { timezones($a, $b) } @array; instead) '."at $c[1] line $c[2]\n";
  }

  my $a_setting = $Settings{$_[0]};
  my $b_setting = $Settings{$_[1]};

  return $$a_setting[0] <=> $$b_setting[0] ||
         $$a_setting[1] <=> $$b_setting[1] ||
          $Names{$_[0]} cmp $Names{$_[1]}  ||
                  $_[0] cmp $_[1];
}


##################################################################################################
## Private helper functions


# Getting the Nth day of a month. (example: 3th sunday in march,2001)

sub getNthDay ($$$$$;$)
{ my ($Start, $N, $WeekDay, $Month, $StartYear) = @_;

  # Fill in optional parameters
  if( not defined $StartYear) { $StartYear = (gmtime($Start))[YEAR]; }

  # Find the beginning of the specified month
  if(isLeapYear($StartYear)) { $Start += $MONTHSTART1[$Month] * $DAY; }
  else                       { $Start += $MONTHSTART2[$Month] * $DAY; }

  # Convert epoch seconds into values we can work with.
  my @CalcTime = gmtime($Start);

  # Find the first day.
  $Start += (($CalcTime[WEEKDAY] - $WeekDay) % $WEEK) * $DAY;
  @CalcTime = gmtime($Start);

  for(my $I = $N; $I > 1; $I++)
  {
    my $StartTest = $Start + ($WEEK * $I);
    @CalcTime = gmtime($StartTest);
    if($CalcTime[MONTH] == $Month)
    {
      $Start = $StartTest;
      last;
    }
  }

  # Return.
  return $CalcTime[YEARDAY];
}


sub isLeapYear ($)
{
  # A year is a leap year when:
  # - It can be divided by 4.
  # - You should also be able to devide it by 400 when it's a "century change"
  return 1 if(($_[0] % 4 == 0) && ($_[0] % 100 == 0 ? ($_[0] % 400 == 0) : 1));
  return 0;
}

1;


## EOF
##################################################################################################

__END__

=head1 NAME

Time::Zones - Converting times to different timezones.

=head1 SYNOPSIS

  # Importing methods.
  use Time::Zones;
  use Time::Zones qw(English);
  use Time::Zones qw(Dutch);

  # Getting different timezone values
  my @GMTTimeArray   = tztime("GMT");   # same as gmtime()
  my @WestEuropeTime = tztime("WEUR");  # +01:00
  my @AlaskaTime     = tztime("ALASK"); # -09:00
  my @NepalTime      = tztime("NEPAL"); # +05:45

  # Printing all timezone names sorted.
  my @tzConstants    = sort timezones tzkeys();
  my $nameshash      = tznames();
  foreach my $tz (@tzConstants) {
    print $nameshash->{$tz} . "\n";
  }


=head1 DESCRIPTION

This module provides a tztime() function in your namespace.
This function works exactly like the gmtime() and localtime() functions
defaultly available in Perl. The difference however, is the fact that
it accepts a timezone id as first parameter.

When a language parameter is provided, the module attemps to load
timezone names from a language file. The hash will be available
as the %Time::Zones::Names variable. The language file however,
should be present at the users system (Time::Zones::LanguageName)

=head2 Exported Functions

=over

=item tztime("CONSTANT"[, TIME])

Behaves exactly like the build-in functions gmtime() and localtime().
The first parameter simply refers to a key in
the %Time::Zones::Settings or %Time::Zones::Names hash.
The second, optional parameter contains the epoch-seconds-time,
like the value returned by the time() function.
If this value is omitted, the current time() return value will be used.

In scalar context, the function will return a time string, just like gmtime() and localtime().
For more details about the return values, please check the documentation of localtime() or gmtime().

=item tzkeys()

Returns all the timezone setting identifiers, like GMT, WEUR. ALASK, NEPAL.
In fact, this value is the same as "keys %Time::Zones::Settings".

=item timezones

This is a comparing algorithm that can used to sort the timezones.
The function compares the timezone offsets of two timezone keys.
two timezone keys.

  Example1:   my @tzsort = sort timezones tzkeys() # As Of Perl 5.005;
  Example2:   my @tzsort = sort { timezones($a, $b) } tzkeys();

=item tznames([ID])

There are two different ways of using this function. If you provide the
ID parameter, the function will return the name (a scalar) for the ID.
The function returns a reference to the timezone names hash when the
first parameter is omitted. You can use that reference when you
need to know much more of those names, theirby saving a lot of function calls.

=begin text

  my $names  = tznames();       # Getting a hash reference
  my $weur1a = $names->{WEUR};  # Using that reference
  my $weur1b = tznames->{WEUR}; # Same, not saving the reference
  my $weur2  = tznames("WEUR"); # Using tznames' return value

=end text

=back

=head2 Available Module Variables

=over

=item %Time::Zones::Settings

A hash containing the timezone settings.
The settings from the Windows (!) "tzedit.exe" program have been used for this.
The hash consists of the following key/values:

  CONSTANT_ID => DATA_ARRAY_REFERENCE  #1: Basic Structure
  "CONSTANT"  => [( DATA_ARRAY )]      #2: Written in Perl

The data array has one of the following formats:

=begin text

  Time Zone Offset from GMT, without any DST.
  [+-]H,M

  Offset    Start DST (Nth weekday)   End of DST            DST Offset
  [+-]H,M,  [1st-5th],DAY,MON,H,M,S,  [1-5],DAY,MON,H,M,S,  [+-]H,M

=end text

=item %Time::Zones::Names

This hash is filled only when the Time::Zones module is loaded with the language parameter.
It can be used in your user-interface to display a appropriate name for the timezone constants.
The data in this hash can also be retreived using the tzkeys() and tznames() functions.

=back

=head2 Exported Tags

The following tags can be exported aswell.
This loads some constants, also used internally in this module, into your namespace.

=over

=item :timeelements

Names for the elements for the array returned by localtime(), gmtime() and tztime().
The names are: SEC, MIN, HOUR, DAY, MONTH, YEAR, WEEKDAY, YEARDAY, ISDST

=item :days

Names for the day elements. (sunday=0, monday=1, etc.)
The names are: SUN, MON, TUE, WED, THU, FRI, SAT

=item :months

Names for the month elements (January=0, etc.)
The names are: JAN, FEB, MAR, APR, MAY, JUN, JUL, AUG, SEP, OCT, NOV, DEC

=back

=head1 AUTHOR

        Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

        webmaster@codingdomain.com
        http://www.codingdomain.com

=cut