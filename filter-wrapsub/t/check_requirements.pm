#
#   $Id: check_requirements.pm,v 1.2 2007-09-28 14:22:31 erwan_lemonnier Exp $
#
#   check that all required modules are available
#

eval "use PPI"; plan skip_all => "missing module 'PPI'" if ($@);
#eval "use Filter::Util::Call"; plan skip_all => "missing module 'Filter::Util::Call'" if ($@);

1;
