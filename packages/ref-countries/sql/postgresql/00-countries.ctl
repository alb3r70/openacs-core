copy countries from '[acs_root_dir]/packages/ref-countries/sql/common/countries.dat' 
[ad_decode [db_version] "7.2" "delimiters" "delimiter"] ';' 
[ad_decode [db_version] "7.2" "with null as" "null"] ''
