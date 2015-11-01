*Change IMPORTCASE to ALL instead of "FIRST 1051220" if you want.
GET DATA  /TYPE=TXT
  /FILE="C:\path\Hack the Grid\CMU-Enernoc\combined.csv"
  /ENCODING='Locale'
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  siteid A40
  meterid F1.0
  dttm A25
  demand_kWh F5.2.
CACHE.
EXECUTE.
DATASET NAME NonCMUData WINDOW=FRONT.
DATASET ACTIVATE NonCMUData.
COMPUTE Year=NUMBER(CHAR.SUBSTR(dttm,1,4),F4.0).
COMPUTE Month=NUMBER(CHAR.SUBSTR(dttm,6,2),F2.0).
COMPUTE Day=NUMBER(CHAR.SUBSTR(dttm,9,2),F2.0).
COMPUTE Hour=NUMBER(CHAR.SUBSTR(dttm,12,2),F2.0).
COMPUTE Minute=NUMBER(CHAR.SUBSTR(dttm,15,2),F2.0).
FORMATS Year(F4.0) Month(F2.0) Day(F2.0) Hour(F2.0) Minute(F2.0).
EXECUTE.

DELETE VARIABLES  dttm.

COMPUTE MinInDay = Hour*60+Minute.
FORMATS MinInDay (F4.0).
EXECUTE.

DATASET DECLARE MonthlyStats.
AGGREGATE
  /OUTFILE='MonthlyStats'
  /BREAK=siteid meterid Year Month
  /Month5minMean=MEAN(demand_kWh) 
  /MonthPeak 'Peak 5 min usage per month'=MAX(demand_kWh) 
  /MonthlyTotal=SUM(demand_kWh) 
  /NumObsv 'Number of observations in month'=NU(demand_kWh).

DATASET ACTIVATE MonthlyStats.
*Remove months with <=1 day of data.
FILTER OFF.
USE ALL.
SELECT IF (NumObsv > 288).
EXECUTE.

COMPUTE PeakOverMean=MonthPeak / Month5minMean.
EXECUTE.

DATASET ACTIVATE MonthlyStats.
DATASET DECLARE MeterStats.
AGGREGATE
  /OUTFILE='MeterStats'
  /BREAK=siteid meterid
  /NumObsv 'Number of observations in month'=SUM(NumObsv)
  /PeakOverMeanAvg 'Average peak over mean'=MEAN(PeakOverMean)
  /PeakOverMeanMax 'Max peak over mean'=MAX(PeakOverMean).
DATASET ACTIVATE MeterStats.

*----------------------------------------------------------------.

GET FILE='C:\path\Hack the Grid\CMU-Enernoc\SiteAttributes.sav'. 
DATASET NAME SiteAttributes WINDOW=FRONT.  

DATASET ACTIVATE MeterStats.
STAR JOIN
  /SELECT t0.meterid, t0.NumObsv, t0.PeakOverMeanAvg, t0.PeakOverMeanMax, t1.lat, t1.lng, 
    t1.industry, t1.subindustry, t1.Country, t1.City
  /FROM * AS t0
  /JOIN 'SiteAttributes' AS t1
    ON t0.siteid=t1.siteid
  /OUTFILE FILE=*.


SORT CASES BY PeakOverMeanAvg(D).
*----------------------------------------------------------------.


DATASET ACTIVATE NonCMUData.

DATASET COPY  m7c2ed833bfafc168f8056bffe03b9486m2.
DATASET ACTIVATE  m7c2ed833bfafc168f8056bffe03b9486m2.
FILTER OFF.
USE ALL.
SELECT IF ((siteid = "7c2ed833bfafc168f8056bffe03b9486")  & (meterid = 2)).
EXECUTE.
DATASET ACTIVATE  NonCMUData.

DATASET ACTIVATE m7c2ed833bfafc168f8056bffe03b9486m2.
COMPUTE MinInMonth=MinInDay+((Day-1)*24*60).
EXECUTE.
FORMATS MinInMonth (F5.0).

FREQUENCIES VARIABLES=Demand_kWh
  /ORDER=ANALYSIS.

COMPUTE Classes=TRUNC(demand_kWh,0.04)/.04.
EXECUTE.
FORMATS Classes (F3.0).

COMPUTE Residual=demand_kWh-Classes*.04.
EXECUTE.
FORMATS Residual (F18.16).

FREQUENCIES VARIABLES=Residual
  /ORDER=ANALYSIS.
*From the above table, we see that 96.4% of all readings are a multiple of .04. 

*Visualize within-day usage.
USE ALL. 
COMPUTE filter_$=(Residual = 0). 
VARIABLE LABELS filter_$ 'Residual = 0 (FILTER)'. 
VALUE LABELS filter_$ 0 'Not Selected' 1 'Selected'. 
FORMATS filter_$ (f1.0). 
FILTER BY filter_$. 
EXECUTE.

* Chart Builder.
GGRAPH
  /GRAPHDATASET NAME="graphdataset" VARIABLES=MinInDay Classes MISSING=LISTWISE REPORTMISSING=NO
  /GRAPHSPEC SOURCE=INLINE.
BEGIN GPL
  SOURCE: s=userSource(id("graphdataset"))
  DATA: MinInDay=col(source(s), name("MinInDay"))
  DATA: Classes=col(source(s), name("Classes"))
  GUIDE: axis(dim(1), label("MinInDay"))
  GUIDE: axis(dim(2), label("Classes"))
  ELEMENT: point(position(MinInDay*Classes))
END GPL.
 
* Chart Builder: Histogram of classes.
GGRAPH 
  /GRAPHDATASET NAME="graphdataset" VARIABLES=Classes MISSING=LISTWISE REPORTMISSING=NO 
  /GRAPHSPEC SOURCE=INLINE. 
BEGIN GPL 
  SOURCE: s=userSource(id("graphdataset")) 
  DATA: Classes=col(source(s), name("Classes")) 
  GUIDE: axis(dim(1), label("Classes")) 
  GUIDE: axis(dim(2), label("Frequency")) 
  ELEMENT: interval(position(summary.count(bin.rect(Classes))), shape.interior(shape.square)) 
END GPL.
