##################################################################################################
##                                                                                              ##
##  >> Timezone Names for Time::Zones <<                                                        ##
##  For Interal Use Only.                                                                       ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

package Time::Zones::English;
use strict;
use vars qw(%Names $VERSION);
$VERSION = 1.00;


##################################################################################################
## Timezone names

%Names = (
'GMT'   => '(GMT) Casablanca, Monrovia',
'GDST'  => '(GMT) Greenwich Mean Time: Dublin, Edinburgh, Lisbon, London',
'WEUR'  => '(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna',
'CEUR1' => '(GMT+01:00) Belgrade, Bratislava, Budapest, Ljubljana, Prague',
'ROM'   => '(GMT+01:00) Brussels, Copenhagen, Madrid, Paris',
'CEUR2' => '(GMT+01:00) Sarajevo, Skopje, Sofija, Vilnius, Warsaw, Zagreb',
'WCAFR' => '(GMT+01:00) West Central Africa',
'GTB'   => '(GMT+02:00) Athens, Istanbul, Minsk',
'EEUR'  => '(GMT+02:00) Bucharest',
'EGYPT' => '(GMT+02:00) Cairo',
'SAFR'  => '(GMT+02:00) Harare, Pretoria',
'FLE'   => '(GMT+02:00) Helsinki, Riga, Tallinn',
'JERUS' => '(GMT+02:00) Jerusalem',
'ARAB1' => '(GMT+03:00) Baghdad',
'ARAB2' => '(GMT+03:00) Kuwait, Riyadh',
'RUSS'  => '(GMT+03:00) Moscow, St. Petersburg, Volgograd',
'EAFR'  => '(GMT+03:00) Nairobi',
'IRAN'  => '(GMT+03:30) Tehran',
'ARAB3' => '(GMT+04:00) Abu Dhabi, Muscat',
'CAUCA' => '(GMT+04:00) Baku, Tbilisi, Yerevan',
'AFGH'  => '(GMT+04:30) Kabul',
'EKAT'  => '(GMT+05:00) Ekaterinburg',
'WASIA' => '(GMT+05:00) Islamabad, Karachi, Tashkent',
'INDIA' => '(GMT+05:30) Calcutta, Chennai, Mumbai, New Delhi',
'NEPAL' => '(GMT+05:45) Kathmandu',
'NCAS'  => '(GMT+06:00) Almaty, Novosibirsk',
'CASIA' => '(GMT+06:00) Astana, Dhaka',
'SRI'   => '(GMT+06:00) Sri Jayawardenepura',
'MYAN'  => '(GMT+06:30) Rangoon',
'SEAS'  => '(GMT+07:00) Bangkok, Hanoi, Jakarta',
'NASIA' => '(GMT+07:00) Krasnoyarsk',
'CHINA' => '(GMT+08:00) Beijing, Chongqing, Hong Kong, Urumqi',
'NEAS'  => '(GMT+08:00) Irkutsk, Ulaan Bataar',
'MALAY' => '(GMT+08:00) Kuala Lumpur, Singapore',
'WAUS'  => '(GMT+08:00) Perth',
'TAIPE' => '(GMT+08:00) Taipei',
'JAPAN' => '(GMT+09:00) Osaka, Sapporo, Tokyo',
'KOREA' => '(GMT+09:00) Seoul',
'YAKUT' => '(GMT+09:00) Yakutsk',
'CAUS'  => '(GMT+09:30) Adelaide',
'AUSC'  => '(GMT+09:30) Darwin',
'EAUS'  => '(GMT+10:00) Brisbane',
'AUSE'  => '(GMT+10:00) Canberra, Melbourne, Sydney',
'WPAS'  => '(GMT+10:00) Guam, Port Moresby',
'TASM'  => '(GMT+10:00) Hobart',
'VLAD'  => '(GMT+10:00) Vladivostok',
'CPAS'  => '(GMT+11:00) Magadan, Solomon Is., New Caledonia',
'NZEA'  => '(GMT+12:00) Auckland, Wellington',
'FIJI'  => '(GMT+12:00) Fiji, Kamchatka, Marshall Is.',
'TONGA' => '(GMT+13:00) Nuku\'alofa',
'AZORE' => '(GMT-01:00) Azores',
'CAPE'  => '(GMT-01:00) Cape Verde Is.',
'MATL'  => '(GMT-02:00) Mid-Atlantic',
'ESAM'  => '(GMT-03:00) Brasilia',
'SAME'  => '(GMT-03:00) Buenos Aires, Georgetown',
'GREEN' => '(GMT-03:00) Greenland',
'NEWF'  => '(GMT-03:30) Newfoundland',
'ALTL'  => '(GMT-04:00) Atlantic Time (Canada)',
'SAMW'  => '(GMT-04:00) Caracas, La Paz',
'PASSA' => '(GMT-04:00) Santiago',
'SAPAS' => '(GMT-05:00) Bogota, Lima, Quito',
'EAST'  => '(GMT-05:00) Eastern Time (US & Canada)',
'USEAS' => '(GMT-05:00) Indiana (East)',
'CAM'   => '(GMT-06:00) Central America',
'CENTR' => '(GMT-06:00) Central Time (US & Canada)',
'MEX'   => '(GMT-06:00) Mexico City',
'CANC'  => '(GMT-06:00) Saskatchewan',
'USMOU' => '(GMT-07:00) Arizona',
'MOUNT' => '(GMT-07:00) Mountain Time (US & Canada)',
'PAS'   => '(GMT-08:00) Pacific Time (US & Canada); Tijuana',
'ALASK' => '(GMT-09:00) Alaska',
'HAWAI' => '(GMT-10:00) Hawaii',
'SAMOA' => '(GMT-11:00) Midway Island, Samoa',
'DATE'  => '(GMT-12:00) Eniwetok, Kwajalein',
);

1;

__DATA__

=head1 SYNOPSIS

  For internal use only; this package should by loaded as
  use Time::Zones qw(LanguageName);

=cut