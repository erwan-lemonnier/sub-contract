#
#   $Id: check_requirements.pm,v 1.2 2008-05-08 06:57:45 erwan_lemonnier Exp $
#
#   check that all required modules are available
#

eval "use accessors"; plan skip_all => "missing module 'accessors'" if ($@);
eval "use Sub::Name"; plan skip_all => "missing module 'Sub::Name'" if ($@);

1;
