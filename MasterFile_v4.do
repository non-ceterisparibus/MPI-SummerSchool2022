**** OPHI Summer School 2022 ****
**** Working group session on indicator analysis ****
**** These are just examples to introduce some key commands, and compute redundancy measures ****

clear all

* Adjust paths
cd "H:/OPHI22/data and do files"

use "SWZ_2014_merged_v4.dta"

svyset psu [w=hhweight], strata(stratum) singleunit(scaled)
* Declare survey design for dataset; adjust psu, weight, and strata variables as needed

lab def dep 0 "Non Deprived" 1 "Deprived"
lab def yesno 0 "No" 1 "Yes"
lab def noyes 1 "No" 0 "Yes"

* -----------------------------------------------------------------------------
* UNIVERSE OF INDICATOR
* -----------------------------------------------------------------------------
/*
--------------------------------------------------------------------------------
Dimensions					| Indicators 
----------------------------+---------------------------------------------------
Living Standard				| Water
							| Sanitation
							| Electricity
							| Assets
----------------------------+---------------------------------------------------
Education					| Highest Level of HH (year of schooling)
							| Lagged education of Children (school-aged)
----------------------------+------------------------------------------------
Health						| Children Nutrition (Undernourished)
							| Children Vaccination
							| Children Mortality
							| Using iodised Salt

* -----------------------------------------------------------------------------
* LIVING STANDARD
* -----------------------------------------------------------------------------


* WATER
A household is non deprived if: it has piped water, public tap, tube well or 
borehole, protected well, protected spring, rainwater, or bottled water

A household is deprived if: it gets water from an unprotected well, 
unprotected spring; river/dam/stream/pond/canal; tanker truck, 
cart with small tank, other 
*/

lookfor  water
codebook ws1, tab(20)
// Recoding
recode  ws1 (11/14=0)(21/31=0)(41=0)(51=0)(91=0)(32/42=1)(61/81=1)(96=1)(99=.), gen(hh_d_water)
lab var  hh_d_water "Household deprived in Access to Safe Water"
lab val hh_d_water dep
tab ws1 hh_d_water, miss

// Creating variable at the household level
tabulate hh_d_water, miss // Sample statistics
svy: tab hh_d_water, miss // Population statistics (<ind the difference with the line above)

* SANITATION
lookfor  toilet
codebook ws8, tab(20)
/*
 A household is non deprived if: it flush to piped sewer system, septic tank,pit (latrine)
 , Ventilated Improved Pit latrine, Pit latrine with slab,
 
A household is deprived if: it flush to somewhere else, unknown place, 
pit latrine without slab / Open pit / Incomplete latrineun, No facility, Other
*/
// Recoding
recode  ws8 (11/13=0)(21/22=0)(14/15=1)(23/95=1)(96=1)(99=.), gen(hh_d_toilet)
lab var  hh_d_toilet "Household deprived in Access to Proper Sanitation"
lab val hh_d_toilet dep
tab ws8 hh_d_toilet, miss

// Creating variable at the household level
tabulate hh_d_toilet, miss // Sample statistics
svy: tab hh_d_toilet, miss // Population statistics (<ind the difference with the line above)

svy: tab hh_d_water hh_d_toilet

/*
----------------------------------------
Household |
deprived  |
in Access |RECODE of ws8 (Type of toilet
to Safe   |          facility)          
Water     | Non Depr  Deprived     Total
----------+-----------------------------
 Non Depr |    .6241     .0963     .7204
 Deprived |    .1982     .0814     .2796
          | 
    Total |    .8224     .1776         1
----------------------------------------
R0-measure 0.0814/min(.2796, .1776) = 0.458 (45.8%)
*/


* -----------------------------------------------------------------------------
* ELECTRICITY 
* -----------------------------------------------------------------------------
// lookfor cooking
// lookfor electricity
// codebook hc8a
codebook hc6
/*
A household is non deprived if having both electricity and clean cooking fuel: 
it flush to piped sewer system, septic tank,pit (latrine)
 , Ventilated Improved Pit latrine, Pit latrine with slab,
 
A household is deprived if: it flush to somewhere else, unknown place, 
pit latrine without slab / Open pit / Incomplete latrineun, No facility, Other

 tabulation:  Freq.   Numeric  Label
                         4,334         1  Electricity
                         1,597         2  Liquefied Petroleum Gas (LPG)
                             1         3  Natural gas
                            10         4  Biogas
                           158         5  Kerosene / Paraffin
                             8         6  Coal / Lignite
                            52         7  Charcoal
                        14,810         8  Wood
                            34         9  Straw / Shrubs / Grass
                            16        10  Animal dung
                             4        95  No food cooked in household
*/

// Recoding
recode hc8a (1=0) (2=1), gen(hh_d_electric)
lab var  hh_d_electric "Household deprived in Access to Electricity"
lab val hh_d_electric dep
tab hc8a hh_d_electric, miss

// recode hc6 (1/4=0)(95=0) (5/10=1), gen(hh_d_cookfuel)
// lab var  hh_d_cookfuel "Household deprived in Access to Clean Cooking Fuel"
// lab val hh_d_cookfuel dep
// tab hc6 hh_d_cookfuel, miss

// Creating variable at the household level
tabulate hh_d_electric, miss // Sample statistics
svy: tab hh_d_electric, miss

// tabulate hh_d_cookfuel, miss // Sample statistics
// svy: tab hh_d_cookfuel, miss


// svy: tab hh_d_electric hh_d_cookfuel

/* Redundancy measures
-------------------------------
Household |
deprived  |
in Access | Household deprived 
to        | in Access to Clean 
Electrici |    Cooking Fuel    
ty        |     0      1  Total
----------+--------------------
        0 | .3288  .2814  .6102
        1 | .0394  .3504  .3898
          | 
    Total | .3682  .6318      1
-------------------------------
	- 35% of the population are deprived in both indicators simultaneously
	- 63.2% are deprived in clean cooking fuel, while 39% are deprived in electricity. 
	-  R0-measure 0.3504/min(0.3898, .6318) = 0.899 (89.9%) of the electricity deprived population are also
		deprived in cooking fuel
	We drop the cooking fuel
*/

* -----------------------------------------------------------------------------
* 			ASSETS
* -----------------------------------------------------------------------------
/* 
	ASSETS
A household is deprived if it has fewer than 5 basic assets in house and no transportation vehicle.
Assets included: radio, television, refrigerator, bed, table, chair, bicycle, 
motorbike (high correlation w bike), car truck */

describe hc8*
desc hc9*
codebook hc8b hc8c hc8d hc8e hc8j hc8f hc8h hc8i hc9c hc9d hc9e hc9f

// Loops allow execution of the same command for a sequence of variables, numbers or other lists	
foreach var in hc8b hc8c hc8d hc8e hc8j hc8f hc8h hc8i hc9c hc9e{
	recode `var' (2=0 "No")(1=1 "Yes")(9=.), gen (asset_`var')
}
	//Labels defined and missing values replaced
	
codebook asset_*

egen n_assets = rowtotal(asset_hc*), missing
svy: tab n_assets, miss
/*
   n_assets |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |        190        1.19        1.19
          1 |        699        4.36        5.55
          2 |      1,185        7.40       12.94
          3 |      1,642       10.25       23.19
          4 |      2,397       14.96       38.15
          5 |      2,537       15.83       53.98
          6 |      2,345       14.64       68.62
          7 |      3,590       22.41       91.03
          8 |      1,212        7.56       98.59
          9 |        226        1.41      100.00
------------+-----------------------------------
      Total |     16,023      100.00
*/
* Using the car or motorbike as transport
// codebook hc9d hc9f
tab hc9f hc9d, missing
gen asset_vehicle = (hc9f==1 | hc9d==1) if hc9f !=9 | hc9d != 9

/* Members of the household are considered deprived in assets 
if the household owns less than 5 basic assets and doesnt own any vehicle.*/
gen hh_d_assets = (n_assets<5 & asset_vehicle == 0) if n_assets!=. & asset_vehicle !=.
lab var hh_d_assets "Household deprived in Assets Ownership"
lab val hh_d_assets dep

svy: tab n_assets hh_d_assets // These are statistics AT THE POPULATION LEVEL 
table n_assets asset_vehicle hh_d_assets // These are descriptives statistics AT THE SAMPLE LEVEL only

tab hh_d_assets, miss // Sample statistics
svy: tab hh_d_assets, miss // Population statistics (<ind the difference with the line above)



* -----------------------------------------------------------------------------
* HEALTH
* -----------------------------------------------------------------------------
* Household member's age

gen child5 = (hl6 <5 ) if hl6 !=.
lab var child5 "Child under 5 years old"
bys hh_id: egen hh_child5 = max(child5)
lab var hh_child5 "Household has child under 5 y.o"

gen child17 = (hl6 <17 ) if hl6 !=.
lab var child17 "Child under 17 years old"
bys hh_id: egen hh_child17 = max(child17)
lab var hh_child17 "Household has child under 17 y.o"

gen child3 = (hl6<3) if hl6!=.
lab var child3 "Child under 3 years old"
bys hh_id: egen hh_child3 = max(child3)
lab var hh_child3 "Household has child 0-3"

bysort hh_id: egen hh_minage = min(hl6) 	//Household min age
* -----------------------------------------------------------------------------
* 	CHILDREN
* -----------------------------------------------------------------------------
/*The country also experienced a decline on routine immunisation and PMTCT coverage from 87.7 percent in 
2014 to 70 percent and 83 percent respectively in 2017
	
Child is deprived if received less than 14 vaccines doses / 16 doses 
		VACCINATION 
*/
local vaccines im3bm im3p0m im3p1m im3p2m im3p3m im3p4m im3pcv1m im3pcv2m im3pcv3m im3d1m im3d2m im3d3m im3m1m im3m2m im3v1m im3v2m  

foreach  var of local vaccines {
	recode `var' (0=0 "No")(1/12=1 "Yes")(44/4444=1  "Yes") (97/9997=.), gen (vacc_`var')
}
egen n_vaccs = rowtotal(vacc_im3*), missing
lab var n_vaccs "Number of Vaccination Child under 3"
tab n_vaccs,m
tab n_vaccs if child3 ==1
/*
Child under 5 vaccination ( No information on vaccination of children from 6 to 18)
Children under 5 are deprived if they have no vaccines
*/
gen hh_cvacc  = .
replace hh_cvacc= 0 if hh_child3 ==0		// If no child under 3
replace hh_cvacc = 1 if n_vaccs < 14 & child3 ==1
* We want to raise the immunisation coverage to fully vaccinated
lab var hh_cvacc "Did children receive at least 14 vaccine doses"
lab val hh_cvacc noyes


bysort hh_id: egen hh_d_cvacc = max(hh_cvacc)
lab var hh_d_cvacc "Children under 3 in the Household deprived in Vaccination"
lab val hh_d_cvacc dep
svy: tab hh_d_cvacc, miss

* CHILD MORTALITY
/* Household is deprived  if there is child under 5 died o
*/


*CM(Corinne): the new version (4) of the Stata dofile includes all the data from the bh file, but it is reshaped, so the variables below are different. The below should work:

//Create variable that will take value 1 if a woman had a child who died and that child was under 5 when he/she died, value 0 if woman had a birth but didn't have a child under 5 who died in the past 12 months, and . if the person didn't give birth
gen cm_u5 = ((bh9c1<60) | (bh9c2<60) | (bh9c3<60) | (bh9c4<60) | (bh9c5<60) | (bh9c6<60) | (bh9c7<60) | (bh9c8<60) | (bh9c9<60) | (bh9c10<60) | (bh9c11<60) | (bh9c12<60) | (bh9c13<60) ) if women_BH==1
//Replace real missings
replace cm_u5 = . if ((bh51==2 & bh9c1==.) | (bh52==2 & bh9c2==.) | (bh53==2 & bh9c3==.) | (bh54==2 & bh9c4==.) | (bh55==2 & bh9c5==.) | (bh56==2 & bh9c6==.) | (bh57==2 & bh9c7==.) | (bh58==2 & bh9c8==.) | (bh59==2 & bh9c9==.) | (bh510==2 & bh9c10==.) | (bh511==2 & bh9c11==.) | (bh512==2 & bh9c12==.) | (bh513==2 & bh9c13==.) ) & women_BH==1
//Create household-level indicator
bys hh_id: egen hh_cm_u5 = max(cm_u5)
//Create variable to identify households without eligible pop (women who have ever given birth)
bys hh_id: egen hh_women_BH = max(women_BH)
*Note: could also use variable cm1. In this dataset, everyone who answered yes to cm1 is also in the bh file
//Make households without eligible pop non-deprived
replace hh_cm_u5 = 0 if hh_women_BH!=1

// Total child dead in the house
bysort hh_id: egen hh_child_dead =  total(cdead)

gen hh_d_csurv = (hh_child_dead > 0)  if hh_child_dead !=.
replace hh_d_csurv=0 if ceb ==0
lab var hh_d_csurv "Household deprived in the Ability of Raising Young Child (Under 5 mortality)"
lab val hh_d_csurv dep
svy: tab hh_d_csurv, miss 

* 
* NUTRITION
* 
/* The indicator takes value 0 if the household has no child under 5 who 
has either height-for-age or weight-for-age that is under 2 stdev below 
the median. It also takes value 0 for the households that have no eligible 
children. The indicator takes a value of missing only if all eligible 
children have missing information in their respective nutrition variable. */

	
* UNDERNOURISHED CHILDREN
gen underweight = (_zwei < -2.0) 
replace underweight = . if _zwei == . | _fwei==1
lab var underweight  "Child is undernourished (weight-for-age) 2sd - WHO"
tab underweight, miss


gen stunting = (_zlen < -2.0)
replace stunting = . if _zlen == . | _flen==1
lab var stunting "Child is stunted (length/height-for-age) 2sd - WHO"
tab stunting, miss


gen wasting = (_zwfl < - 2.0)
replace wasting = . if _zwfl == . | _fwfl == 1
lab var wasting  "Child is wasted (weight-for-length/height) 2sd - WHO"
tab wasting, miss

* Construct nutrition indicator for child
gen hh_cnutri = (underweight==1 | stunting==1) if underweight !=. | stunting !=.
lab var hh_cnutri "Children Nutrition (malnourished)"
lab val hh_cnutri dep

bysort hh_id: egen hh_d_cnutri = max(hh_cnutri)
replace hh_d_cnutri=0 if hh_child5 ==0		// If no child under 5
lab var hh_d_cnutri "Household deprived in Children Nutrition (malnourished)"
lab val hh_d_cnutri dep
tab hh_d_cnutri child5
svy: tab hh_d_cnutri, miss 

* Deprived breastfeedding

* Ever breastfeed - Never-breadfed proportion is small 
// // Recoding
// recode bd2 (2=1)(1=0)(else=.), g(n_breastfeeding)
// lab var n_breastfeeding "Child was never breastfed"
// lab val n_breastfeeding yesno
//
// *CM: for the MPI, you need to bysort the individual-level indicator above, to create the indicator at the hh-level
// bys hh_id: egen hh_everbf = max(n_breastfeeding)
// replace hh_everbf = 0 if hh_child3==0
//
// tab hh_everbf, miss // Sample statistics
// svy: tab hh_everbf, miss
/*
 
  hh_everbf |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |     20,048       95.36       95.36
          1 |        834        3.97       99.32
          . |        142        0.68      100.00
------------+-----------------------------------
      Total |     21,024      100.00

----------------------
hh_everbf | proportion
----------+-----------
        0 |      .9549
        1 |      .0381
        . |       .007
          | 
    Total |          1
----------------------
*/


*	USING IODISED SALT
/* Deprived if PPM lower than 15 and salt is not found in household
*/
recode si1 (1/2=0)(4=0)(3=1)(5/9=.), g(hh_d_idosalt)
lab var hh_d_idosalt "Household deprived in Iodine Salt"
lab val hh_d_idosalt dep
tab si1 hh_d_idosalt, missing

* -----------------------------------------------------------------------------
* EDUCATION
* -----------------------------------------------------------------------------

* -----------------------------------------------------------------------------
* SCHOOLING - ACCESS
* -----------------------------------------------------------------------------
/* 
Swaziland's school system consists of twelve school years. 
The seven years of elementary or "Junior School" (Grades 1 to 7) culminate in the Swaziland Primary Certificate.
 The three years of junior secondary school (High School - Forms I to III) culminate in the Junior Certificate (J.C.).
 The two years of higher secondary school (High School - Forms IV to V)
 lead to the Cambridge Overseas School Certificate (C.O.S.C.) at the Ordinary Level (O levels).
 */

// Construct variable on years of education for all (using information on level and grade)
tab ed4b ed4a, m
codebook ed4a ed4b
clonevar sch_grade = ed4b
replace sch_grade = . if sch_grade >7 					
*fixing 97 98 values
gen sch_yrs = cond(ed4a==1,sch_grade, cond(ed4a==2, 7+sch_grade, cond(ed4a==3, 10+sch_grade, cond(ed4a==4, 12+sch_grade, . ))))

* Max schooling level in the HH
bys hh_id: egen sch_mlev = max(sch_yrs)
replace sch_mlev = cond(helevel==1, 7, cond(helevel==2, 10, cond(helevel==3,12,cond(helevel==4,16,.)))) if sch_mlev ==. 
*replace with helevel if missing, assume that head finishing that level
gen hh_d_school = (sch_mlev < 11 ) if sch_mlev !=.		
* align with NDP wanting to increasing secondary education 
lab var hh_d_school "Household deprive in Years of Schooling (no one having secondary schooling)"
lab val hh_d_school dep

tab hh_d_school, miss // Sample statistics
svy: tab hh_d_school, miss // Population statistics
/*
----------------------
Household |
deprive   |
in Years  |
of        |
Schooling |
(no one   |
having    |
secondary |
schooling |
)         | proportion
----------+-----------
 Non Depr |        .51
 Deprived |        .49
          | 
    Total |          1
----------------------

*/
* -----------------------------------------------------------------------------
* SCHOOLING LAGGED
* -----------------------------------------------------------------------------

* Schooling delayed comparing with the suggested schooling level (year of schooling)
egen sch_age = anymatch(hl6), values(6 7 8 9 10 11 12 13 14 15 16 17) // school-aged for general education up to grade 7th
/*
----------------------
hl6 == 6  |
7 8 9 10  |
11 12 13  |
14 15 16  |
17        | proportion
----------+-----------
        0 |      .6895
        1 |      .3105
          | 
    Total |          1
----------------------

*/
gen sch_lev = hl6 - 5 // suggested schooling level (current age - starting age of schooling )

* Schooling grade (cummulative)
clonevar sch_cgrade = ed6b
replace sch_cgrade =. if sch_cgrade > 7 				// fix 97 98 values
gen sch_yrs_c = cond(ed6a==1,sch_cgrade, cond(ed6a==2, 7+sch_cgrade, cond(ed6a==3, 10+sch_cgrade, cond(ed6a==4, 12+sch_cgrade, . ))))
lab var sch_yrs_c "Actual year of schooling cummulated (children)"

* Construct indicator for household having children with lagged year of schooling 
gen sch_lagged = sch_lev - sch_cgrade if sch_age == 1 	// number of year of schooling lagged
replace sch_lagged =0 if sch_lagged <0					// fixing negative values
lab var sch_lagged "Number of year of schooling lagged"


/*
           | hl6 == 6 7 8 9 10 11
           |          12
 sch_lagged|         0          1 |     Total
-----------+----------------------+----------
         0 |         0      1,545 |     1,545 
         1 |         0      1,319 |     1,319 
         2 |         0        660 |       660 
         3 |         0        250 |       250 
         4 |         0         67 |        67 
         5 |         0         16 |        16 
         6 |         0          9 |         9 
         . |    16,882        276 |    17,158 
-----------+----------------------+----------
     Total |    16,882      4,142 |    21,024 
*/
* HH with no school-aged children is non deprived
bysort hh_id: egen hh_sch_age = max(sch_age)
lab var hh_sch_age "Household having school-aged children"
lab val hh_sch_age yesno

gen hh_schlag = (sch_lagged > 2 ) if sch_lagged !=. 
* most school lag indicators only consider an individual deprived if they are 2 or more years older than their expected age
replace hh_schlag = 0 if hh_sch_age ==0 	//fixing the HH w.o school-aged children
lab var hh_schlag "Lagged school-aged children"

* Indicator lagged schooling children
bys hh_id: egen hh_d_schlag = max(hh_schlag)
lab var hh_d_schlag "Household having children with lagged years of schooling "
lab val hh_d_schlag dep


tab hh_d_schlag, miss 	// Sample statistics
svy: tab hh_d_schlag , miss 	// population statistics
/*
----------------------
Household |
having    |
children  |
with      |
lagged    |
years of  |
schooling | proportion
----------+-----------
 Non Depr |      .5823
 Deprived |      .3946
        . |      .0231
          | 
    Total |          1
----------------------
*/

* -----------------------------------------------------------------------------
* Retained Sample
* -----------------------------------------------------------------------------

/* Missing values */
cap ssc install mdesc
mdesc hh_d_*

/*
    Variable    |     Missing          Total     Percent Missing
----------------+-----------------------------------------------
     hh_d_water |           3         21,024           0.01
    hh_d_toilet |          23         21,024           0.11
   hh_d_elect~c |           0         21,024           0.00
    hh_d_assets |           0         21,024           0.00
     hh_d_cvacc |       4,542         21,024          21.60
     hh_d_csurv |           0         21,024           0.00
    hh_d_cnutri |       1,523         21,024           7.24
   hh_d_idosalt |          66         21,024           0.31
    hh_d_school |           0         21,024           0.00
    hh_d_schlag |         404         21,024           1.92
----------------+-----------------------------------------------
*/

/* Retain relevant sample (full information) */
egen n_miss=rowmiss(hh_d_*)
* Adjust to indicators that will be used in the MPI structure

/* Calculate retained sample */
tab n_miss // Unweighted
svy: tab n_miss // Weighted
                                                
. /*
----------------------
   n_miss | proportion
----------+-----------
        0 |      .7656
        1 |      .1615
        2 |      .0718
        3 |      .0011
          | 
    Total |          1
----------------------
*/

keep if n_miss==0

save "SWZ_2014_dataprep.dta", replace


* -----------------------------------------------------------------------------
*  association & redundancy measures
* 
* -----------------------------------------------------------------------------

// assoc [w=hhweight], dep(hh_d_*)


/*
----------------------------------------------------------------------------------------------------------------------------
             | hh_d_wa~r  hh_d_to~t  hh_d_el~c  hh_d_as~s  hh_d_cv~c  hh_d_cs~v  hh_d_cn~i  hh_d_id~t  hh_d_sc~l  hh_d_sc~g 
-------------+--------------------------------------------------------------------------------------------------------------
  hh_d_water |         .                                                                                                    
 hh_d_toilet |     0.475          .                                                                                         
hh_d_elect~c |     0.608      0.700          .                                                                              
 hh_d_assets |     0.476      0.612      0.785          .                                                                   
  hh_d_cvacc |     0.468      0.470      0.440      0.390          .                                                        
  hh_d_csurv |     0.306      0.248      0.447      0.376      0.433          .                                             
 hh_d_cnutri |     0.373      0.306      0.491      0.406      0.759      0.299          .                                  
hh_d_idosalt |     0.568      0.554      0.555      0.594      0.618      0.633      0.611          .                       
 hh_d_school |     0.624      0.697      0.694      0.707      0.512      0.615      0.611      0.606          .            
 hh_d_schlag |     0.781      0.794      0.737      0.673      0.749      0.767      0.785      0.643      0.715          . 
----------------------------------------------------------------------------------------------------------------------------
          hd |     0.272      0.178      0.384      0.335      0.368      0.162      0.197      0.643      0.484      0.670 
----------------------------------------------------------------------------------------------------------------------------
Cramer's V
----------------------------------------------------------------------------------------------------------------------------
             | hh_d_wa~r  hh_d_to~t  hh_d_el~c  hh_d_as~s  hh_d_cv~c  hh_d_cs~v  hh_d_cn~i  hh_d_id~t  hh_d_sc~l  hh_d_sc~g 
-------------+--------------------------------------------------------------------------------------------------------------
  hh_d_water |         .      0.212      0.281      0.183      0.126      0.034      0.112     -0.096      0.171      0.145 
 hh_d_toilet |     0.212          .      0.302      0.273      0.099      0.081      0.128     -0.086      0.198      0.123 
hh_d_elect~c |     0.281      0.302          .      0.585      0.088      0.057      0.109     -0.145      0.331      0.113 
 hh_d_assets |     0.183      0.273      0.585          .      0.032      0.038      0.074     -0.071      0.315      0.005 
  hh_d_cvacc |     0.126      0.099      0.088      0.032          .      0.059      0.401     -0.039      0.043      0.128 
  hh_d_csurv |     0.034      0.081      0.057      0.038      0.059          .      0.113     -0.009      0.115      0.091 
 hh_d_cnutri |     0.112      0.128      0.109      0.074      0.401      0.113          .     -0.032      0.125      0.121 
hh_d_idosalt |    -0.096     -0.086     -0.145     -0.071     -0.039     -0.009     -0.032          .     -0.075     -0.076 
 hh_d_school |     0.171      0.198      0.331      0.315      0.043      0.115      0.125     -0.075          .      0.094 
 hh_d_schlag |     0.145      0.123      0.113      0.005      0.128      0.091      0.121     -0.076      0.094          . 
----------------------------------------------------------------------------------------------------------------------------

N=16023
*/


