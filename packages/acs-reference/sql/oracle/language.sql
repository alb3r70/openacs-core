--
-- packages/acs-reference/sql/language.sql
--
-- @author jon@arsdigita.com
-- @creation-date 2000-11-21
-- @cvs-id $Id$
--


-- ISO 639
create table language_codes (
    language_id char(2)
        constraint language_codes_language_id_pk
        primary key,
    name varchar(100)
        constraint language_codes_name_uq
        unique
        constraint language_codes_name_nn
        not null
);

comment on table language_codes is '
    This is data from the ISO 639 standard on language codes.
';

comment on column language_codes.language_id is '
    This is the ISO standard language code
';

comment on column language_codes.name is '
    This is the English version of the language name. 
    I don''t want to get crazy here!
';

-- now register this table with the repository
declare
    v_id integer;
begin
    v_id := acs_reference.new(
        table_name     => upper('language_codes'),
        source         => 'ISO 639',
        source_url     => 'http://www.iso.ch',
        effective_date => sysdate
    );
commit;
end;
/


-- add some data
insert into language_codes values ('aa','Afar');
insert into language_codes values ('ab','Abkhazian');
insert into language_codes values ('af','Afrikaans');
insert into language_codes values ('am','Amharic');
insert into language_codes values ('ar','Arabic');
insert into language_codes values ('as','Assamese');
insert into language_codes values ('ay','Aymara');
insert into language_codes values ('az','Azerbaijani');
insert into language_codes values ('ba','Bashkir');
insert into language_codes values ('be','Byelorussian');
insert into language_codes values ('bg','Bulgarian');
insert into language_codes values ('bh','Bihari');
insert into language_codes values ('bi','Bislama');
insert into language_codes values ('bn','Bengali; Bangla');
insert into language_codes values ('bo','Tibetan');
insert into language_codes values ('br','Breton');
insert into language_codes values ('ca','Catalan');
insert into language_codes values ('co','Corsican');
insert into language_codes values ('cs','Czech');
insert into language_codes values ('cy','Welsh');
insert into language_codes values ('da','Danish');
insert into language_codes values ('de','German');
insert into language_codes values ('dz','Bhutani');
insert into language_codes values ('el','Greek');
insert into language_codes values ('en','English');
insert into language_codes values ('eo','Esperanto');
insert into language_codes values ('es','Spanish');
insert into language_codes values ('et','Estonian');
insert into language_codes values ('eu','Basque');
insert into language_codes values ('fa','Persian');
insert into language_codes values ('fi','Finnish');
insert into language_codes values ('fj','Fiji');
insert into language_codes values ('fo','Faeroese');
insert into language_codes values ('fr','French');
insert into language_codes values ('fy','Frisian');
insert into language_codes values ('ga','Irish');
insert into language_codes values ('gd','Scots Gaelic');
insert into language_codes values ('gl','Galician');
insert into language_codes values ('gn','Guarani');
insert into language_codes values ('gu','Gujarati');
insert into language_codes values ('ha','Hausa');
insert into language_codes values ('hi','Hindi');
insert into language_codes values ('hr','Croatian');
insert into language_codes values ('hu','Hungarian');
insert into language_codes values ('hy','Armenian');
insert into language_codes values ('ia','Interlingua');
insert into language_codes values ('ie','Interlingue');
insert into language_codes values ('ik','Inupiak');
insert into language_codes values ('in','Indonesian');
insert into language_codes values ('is','Icelandic');
insert into language_codes values ('it','Italian');
insert into language_codes values ('iw','Hebrew');
insert into language_codes values ('ja','Japanese');
insert into language_codes values ('ji','Yiddish');
insert into language_codes values ('jw','Javanese');
insert into language_codes values ('ka','Georgian');
insert into language_codes values ('kk','Kazakh');
insert into language_codes values ('kl','Greenlandic');
insert into language_codes values ('km','Cambodian');
insert into language_codes values ('kn','Kannada');
insert into language_codes values ('ko','Korean');
insert into language_codes values ('ks','Kashmiri');
insert into language_codes values ('ku','Kurdish');
insert into language_codes values ('ky','Kirghiz');
insert into language_codes values ('la','Latin');
insert into language_codes values ('ln','Lingala');
insert into language_codes values ('lo','Laothian');
insert into language_codes values ('lt','Lithuanian');
insert into language_codes values ('lv','Latvian, Lettish');
insert into language_codes values ('mg','Malagasy');
insert into language_codes values ('mi','Maori');
insert into language_codes values ('mk','Macedonian');
insert into language_codes values ('ml','Malayalam');
insert into language_codes values ('mn','Mongolian');
insert into language_codes values ('mo','Moldavian');
insert into language_codes values ('mr','Marathi');
insert into language_codes values ('ms','Malay');
insert into language_codes values ('mt','Maltese');
insert into language_codes values ('my','Burmese');
insert into language_codes values ('na','Nauru');
insert into language_codes values ('ne','Nepali');
insert into language_codes values ('nl','Dutch');
insert into language_codes values ('no','Norwegian');
insert into language_codes values ('oc','Occitan');
insert into language_codes values ('om','(Afan) Oromo');
insert into language_codes values ('or','Oriya');
insert into language_codes values ('pa','Punjabi');
insert into language_codes values ('pl','Polish');
insert into language_codes values ('ps','Pashto, Pushto');
insert into language_codes values ('pt','Portuguese');
insert into language_codes values ('qu','Quechua');
insert into language_codes values ('rm','Rhaeto-Romance');
insert into language_codes values ('rn','Kirundia');
insert into language_codes values ('ro','Romanian');
insert into language_codes values ('ru','Russian');
insert into language_codes values ('rw','Kinyarwanda');
insert into language_codes values ('sa','Sanskrit');
insert into language_codes values ('sd','Sindhi');
insert into language_codes values ('sg','Sangro');
insert into language_codes values ('sh','Serbo-Croatian');
insert into language_codes values ('si','Singhalese');
insert into language_codes values ('sk','Slovak');
insert into language_codes values ('sl','Slovenian');
insert into language_codes values ('sm','Samoan');
insert into language_codes values ('sn','Shona');
insert into language_codes values ('so','Somali');
insert into language_codes values ('sq','Albanian');
insert into language_codes values ('sr','Serbian');
insert into language_codes values ('ss','Siswati');
insert into language_codes values ('st','Sesotho');
insert into language_codes values ('su','Sundanese');
insert into language_codes values ('sv','Swedish');
insert into language_codes values ('sw','Swahili');
insert into language_codes values ('ta','Tamil');
insert into language_codes values ('te','Tegulu');
insert into language_codes values ('tg','Tajik');
insert into language_codes values ('th','Thai');
insert into language_codes values ('ti','Tigrinya');
insert into language_codes values ('tk','Turkmen');
insert into language_codes values ('tl','Tagalog');
insert into language_codes values ('tn','Setswana');
insert into language_codes values ('to','Tonga');
insert into language_codes values ('tr','Turkish');
insert into language_codes values ('ts','Tsonga');
insert into language_codes values ('tt','Tatar');
insert into language_codes values ('tw','Twi');
insert into language_codes values ('uk','Ukrainian');
insert into language_codes values ('ur','Urdu');
insert into language_codes values ('uz','Uzbek');
insert into language_codes values ('vi','Vietnamese');
insert into language_codes values ('vo','Volapuk');
insert into language_codes values ('wo','Wolof');
insert into language_codes values ('xh','Xhosa');
insert into language_codes values ('yo','Yoruab');
insert into language_codes values ('zh','Chinese');
insert into language_codes values ('zu','Zulu');

commit;
-- end language.sql