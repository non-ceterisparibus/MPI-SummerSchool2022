**** OPHI Summer School 2022 ****
**** Working group session on indicator analysis ****
**** These are just examples to introduce some key commands, and compute redundancy measures ****

clear all

* Adjust paths
cd "/Users/fannikovesdi/Documents"

use "SWZ_2014_merged.dta"

svyset psu [w=hhweight], strata(stratum) singleunit(scaled)
* Declare survey design for dataset; adjust psu, weight, and strata variables as needed

* -----------------------------------------------------------------------------
* WATER 
* -----------------------------------------------------------------------------
/* 
A household is non deprived if: it has piped water, public tap, tube well or 
borehole, protected well, protected spring, rainwater, or bottled water

A household is deprived if: it gets water from an unprotected well, 
unprotected spring; river/dam/stream/pond/canal; tanker truck, 
cart with small tank, other 
*/

lab def dep 0 "Non Deprived" 1 "Deprived"

lookfor  water
codebook ws1, tab(20)

// Recoding
recode   ws1 (11/31=0)(32=1)(41=0)(42=1)(51=0)(61/81=1)(91=0)(96=1)(99=.), gen(hh_d_water)
lab var  hh_d_water "Household deprived in Access to Safe Water"
lab val hh_d_water dep
tab ws1 hh_d_water, miss

// Creating variable at the household level
tabulate hh_d_water, miss // Sample statistics
svy: tab hh_d_water, miss // Population statistics (<ind the difference with the line above)

* -----------------------------------------------------------------------------
* ASSETS
* -----------------------------------------------------------------------------
/* A household is deprived if it has fewer than 2 small assets and no car.
Assets included: radio, television, refrigerator, bicycle, motorbike */

describe hc8*
desc hc9*
codebook hc8b hc8c hc8e hc9c hc9d hc9f

// Loops allow execution of the same command for a sequence of variables, numbers or other lists	
foreach var in hc8b hc8c hc8e hc9c hc9d hc9f {
	recode `var' (2=0 "No")(1=1 "Yes")(9=.), gen (asset_`var')
}
	//Labels defined and missing values replaced
	
codebook asset_*

egen n_assets = rowtotal(asset_hc8b asset_hc8c asset_hc8e asset_hc9c asset_hc9d), missing
svy: tab n_assets, miss
	
gen hh_d_assets = (n_assets<2) if n_assets!=.
svy: tab n_assets hh_d_assets // These are statistics AT THE POPULATION LEVEL 

* Using the car as veto 
codebook asset_hc9f
replace hh_d_assets = 0 if asset_hc9f==1
lab var hh_d_assets "Household deprived in Assets"
lab val hh_d_asset dep
table n_assets asset_hc9f hh_d_assets // These are descriptives statistics AT THE SAMPLE LEVEL only

tab hh_d_assets, miss // Sample statistics
svy: tab hh_d_assets, miss // Population statistics (<ind the difference with the line above)


* -----------------------------------------------------------------------------
* SCHOOLING 
* -----------------------------------------------------------------------------
/* A household is deprived if no member older than 15 has completed 5 years of schooling */

// Define the eligible age range
codebook hl6
gen age_15= hl6>15 if hl6!=.
tab age_15, m 
bysort hh_id: egen hh_age15 = max(age_15)
tab hh_age15, m 
	// 13 people live in households where no member is older than 15 

// Construct variable on years of education for all (using information on level and grade)
desc ed4b ed4a
tab ed4b ed4a, m
tab ed4b ed4a, nol m
gen d_scho = 0 if age_15==1
replace d_scho = 1 if ((ed4a==1 & ed4b<5) | (ed4a==0)) & age_15==1
replace d_scho = . if (ed4a==. & ed4b==.) & age_15==1
replace d_scho = . if ed4a>4 & age_15==1
replace d_scho = . if ed4b>96 & ed4b!=. & age_15==1
lab var d_scho "Has less than 5 years of education"
lab val d_scho dep
tab d_scho if age_15==1, m
tab ed4b ed4a if age_15==1 & d_scho==1, m 

bys hh_id: egen hh_d_school = min(d_scho)
tab hh_d_school, m // Sample statistics
replace hh_d_school=0 if hh_age15==0
lab var hh_d_school "Household deprived in Years of Schooling"
lab val hh_d_school dep

tab hh_d_school, miss // Sample statistics
svy: tab hh_d_school, miss // Population statistics (<ind the difference with the line above)

* -----------------------------------------------------------------------------
* NUTRITION 
* -----------------------------------------------------------------------------
/* A household is deprived if any child under 5 with nutritional information is underweight */

gen age_5= hl6<5 if hl6!=.
tab age_5, m 
bys hh_id: egen hh_age5 = max(age_5)
tab hh_age5, m 

gen	underweight = (_zwei < -2.0) if age_5==1
replace underweight = . if (_zwei==. | _fwei==1) & age_5==1
label define lab_uw 0"not underweight" 1"underweight"
label values underweight lab_uw
lab var underweight  "Child is underweight (weight-for-age; -2 SD)"
tab underweight if age_5==1, miss

clonevar d_nutri = underweight 
tab d_nutri, miss

bys hh_id: egen hh_d_nutri = max(d_nutri)
replace hh_d_nutri = 0 if hh_age5==0
lab var hh_d_nutri "Household deprived in Nutrition"
lab val hh_d_nutri dep

tab hh_d_nutri, miss // Sample statistics
svy: tab hh_d_nutri, miss // Population statistics (<ind the difference with the line above)

* -----------------------------------------------------------------------------
* Variables for disaggregation
* -----------------------------------------------------------------------------

codebook hh7
clonevar region = hh7

codebook hh6
clonevar area = hh6

* -----------------------------------------------------------------------------
* Retained Sample
* -----------------------------------------------------------------------------

/* Missing values */
cap ssc install mdesc
mdesc hh_d_*

/* Retain relevant sample (full information) */
egen n_miss=rowmiss(hh_d_assets hh_d_water hh_d_school hh_d_nutri)
* Adjust to indicators that will be used in the MPI structure

/* Calculate retained sample */
tab n_miss // Unweighted
svy: tab n_miss // Weighted

keep if n_miss==0

save "SWZ_2014_dataprep.dta", replace




* -----------------------------------------------------------------------------
* A simple example of association & redundancy measures
* Let us take to indictors: hh_d_water and hh_d_assets
* -----------------------------------------------------------------------------

* The R0 Measure 
	svy: tab hh_d_water hh_d_assets

	/*
	----------------------------------------
	Household |
	deprived  |
	in Access |
	to Safe   | Household deprived in Assets
	Water     | Non Depr  Deprived     Total
	----------+-----------------------------
	 Non Depr |    .4926     .2308     .7234
	 Deprived |    .1328     .1438     .2766
			  | 
		Total |    .6254     .3746         1
	----------------------------------------

	- 14.4% of the population are deprived in both indicators simultaneously
	- 27.7% are deprived in water, while 37.5% are deprived in assets. 
	- 0.1328/0.2766 = 0.4801 (48%) of the water deprived population are also
		deprived in assets. This is the R0-measure
	*/

* Cramer's V
	tab hh_d_water hh_d_assets, V // This does not take into account survey sampling

	svy: tab hh_d_water hh_d_assets
	local denom = e(r)-1
	di "Cramer's V: " sqrt(e(cun_Pear)/(e(N)*`denom'))

	/*
	. di "Cramer's V: " sqrt(e(cun_Pear)/(e(N)*`denom'))
	Cramer's V: .1855725
	- Essentially, Cramer's V is an adjusted Chi2 correlation coefficient
	*/

* -----------------------------------------------------------------------------
* Programme to compute both measures for several pairs of indicators
* run NSuppa's `assoc_program.do' dofile once and execute the one-line command:
* The underlying calculations are largely explained above. This programme has 
* 	the virtue of simplifying output. They can be easily copy-pasted elsewhere
* -----------------------------------------------------------------------------
	
assoc [w=hhweight], dep(hh_d_*)





