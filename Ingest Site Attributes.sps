
GET DATA  /TYPE=TXT 
  /FILE="C:\path\Hack the Grid\CMU-Enernoc\siteattributes.csv" 
  /ENCODING='Locale' 
  /DELCASE=LINE 
  /DELIMITERS="," 
  /QUALIFIER='"' 
  /ARRANGEMENT=DELIMITED 
  /FIRSTCASE=2 
  /IMPORTCASE=ALL 
  /VARIABLES= 
  siteid A34 
  lat F17.13 
  lng F17.13 
  industry A30 
  subindustry A50 
  timezone A25. 
CACHE. 
EXECUTE. 
DATASET NAME SiteAttributes WINDOW=FRONT.

DATASET ACTIVATE SiteAttributes.
COMPUTE SlashPos=CHAR.INDEX(timezone,'/').
EXECUTE.
FORMATS SlashPos (F2.0).

STRING  Country (A18).
STRING  City (A18).
COMPUTE City=CHAR.SUBSTR(timezone,SlashPos+1).
COMPUTE Country=CHAR.SUBSTR(timezone,1,SlashPos-1).
EXECUTE.
DELETE VARIABLES timezone SlashPos.
*---------------------------------------------------------------------.
