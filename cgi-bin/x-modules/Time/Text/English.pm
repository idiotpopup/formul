##################################################################################################
##                                                                                              ##
##  >> Names for Time Elements <<                                                               ##
##  For Interal Use Only.                                                                       ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

package Time::Text::English;
use strict;
use vars qw($VERSION @Days @ShortMonths @LongMonths);
$VERSION = 1.00;


##################################################################################################
## Time element names

@Days        = qw(Sun Mon Tue Wed Thu Fri Sat);
@ShortMonths = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@LongMonths  = qw(January February March April May June July August September October November December);

1;

__DATA__

=head1 SYNOPSIS

  For internal use only; this package should by loaded as
  use Time::Text qw(LanguageName);

=cut