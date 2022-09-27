**** OPHI Summer School 2022 ****

*********************************
*** REVIEWED IN PREVIOUS SESSIONS
*********************************

clear all
global path_in "H:/OPHI22/data and do files" 	  
global path_out "H:/OPHI22/data and do files"
* Adjust path

cd $path
use "$path_in/SWZ_2014_dataprep.dta", clear

svyset psu [w=hhweight], strata(stratum)
* Adjust psu, weight, and strata variables as needed

set type double // Specifies precision for decimal points; don't need to adjust

/* Disaggregation: To disaggregate, one just has to repeat the necessary 
estimation commands for all relevant subgroups in the disaggregation variable

For this dofile, you only need to manually adjust the following, all in the 
"setting parameters" section:
(1) disaggregation variables for population subgroups of interest. If these are 
not already available in the dataset, you will need to create them now, before 
running the rest of the code
(2) list of indicators
(3) poverty cutoffs
 */
 
* -----------------------------------------------------------------------------
* Variables for disaggregation
* -----------------------------------------------------------------------------

codebook hh7
clonevar region = hh7

codebook hh6
clonevar area = hh6

codebook hl4
clonevar sex = hl4

* -----------------------------------------------------------------------------
* Set parameters
* -----------------------------------------------------------------------------

global groups region area
* Adjust disaggregation variables

global indic hh_d_water hh_d_toilet hh_d_electric hh_d_assets hh_d_cvacc hh_d_csurv hh_d_cnutri hh_d_idosalt hh_d_school hh_d_schlag
* Adjust list of indicators

global sel_k 25 33 50
* Adjust selected poverty cutoffs (k)

* -----------------------------------------------------------------------------
* Uncensored Headcount Ratios: Percentage of the population deprived in each 
* indicator
* -----------------------------------------------------------------------------
/* These ratios are estimated first because they are independent of indicator 
weights and the chosen multidimensional povery cutoff */
	
foreach g of global groups {
	svy: mean $indic, over(`g')
}

* -----------------------------------------------------------------------------
* Setting indicator weights
* -----------------------------------------------------------------------------
/* Change the below according to the desired specification. Remember that the 
sum of weights MUST be equal to 1 or 100% */

foreach var in hh_d_water hh_d_toilet hh_d_electric hh_d_assets hh_d_cvacc hh_d_csurv hh_d_cnutri hh_d_idosalt {	
	gen w_`var' = 1/12 
	* 1/3 in each dimension, divided for 4 indicators
	lab var w_`var' "Weight `var'"
}

foreach var in hh_d_school hh_d_schlag{	
	gen w_`var' = 1/6
	lab var w_`var' "Weight `var'"
}

* -----------------------------------------------------------------------------
* Weighted deprivation matrix 
* -----------------------------------------------------------------------------
/* Multiply the deprivation matrix by the weight of each indicator */ 

foreach var of global indic {
	gen	g0_w_`var' = `var' * w_`var'
	lab var g0_w_`var' "Weighted Deprivation of `var'"
}

* -----------------------------------------------------------------------------
* Counting vector
* -----------------------------------------------------------------------------
/* Generate the vector of INDIVIDUAL weighted deprivation scores, 'c' */

egen c_vector = rowtotal(g0_w_*)
lab var c_vector "Counting Vector"

* -----------------------------------------------------------------------------
* Identification of the poor 
* -----------------------------------------------------------------------------
/* Identify the poor at different poverty cutoffs (i.e. different k) */

forvalue k = 1(1)100 {
	gen mdp_`k' = (c_vector >= `k'/100)
	lab var mdp_`k' "Poverty Identification with k=`k'%"
}

* -----------------------------------------------------------------------------
* Censored counting vector
* -----------------------------------------------------------------------------
/* Generate the censored counting vector of individual weighted deprivation 
score, 'c(k)', providing a score of zero if a person is not poor */

forvalue k = 1(1)100  {
	gen cens_c_vector_`k' = c_vector
	replace cens_c_vector_`k' = 0 if mdp_`k'==0 
}

* -----------------------------------------------------------------------------
* Censored deprivation matrix 
* -----------------------------------------------------------------------------
/* Generate the censored deprivation matrix, replacing deprivations as 0 if the 
person is non-poor */

foreach k of global sel_k {
	foreach var of global indic {
		gen g0_`k'_`var' = `var'
		replace g0_`k'_`var' = 0 if mdp_`k'==0
	}
}

save "$path_out/estimation.dta", replace 

*********************************
*** ROBUSTNESS COMMANDS
*********************************

*------------------------------------------------------------------
*------------------------------------------------------------------
codebook area 
* 2 subnational areas
cap ssc install distinct
distinct area
local n_area =r(ndistinct)
* Number of distinct subnational regions

local kval 30 40 50 
* Set of plausible k-values. We will compare k=30; k=40; k=50

foreach k of local kval { 
	mat C=J(1,5,.) // Initialize Matrix
		foreach p1 of numlist 1/`n_area' {
			foreach p2 of numlist 1/`n_area' {
				if `p1'<`p2' { 
				* Avoid unnecessary computations
					gen pair=1 if area ==`p1'
					replace pair=2 if area ==`p2'
					svy: mean cens_c_vector_`k', over(pair) 
					* Computes the MPI for each district
					mat E=[e(b)]
					test _b[cens_c_vector_`k':1]=_b[cens_c_vector_`k':2] 
					* Stata 15 or below
// 					test c.cens_c_vector_`k'@1.pair=c.cens_c_vector_`k'@2.pair  // Stata 16 or above
					mat B=[`p1',`p2',E[1,1...],r(p)]
					mat C=[C\B] 
					*adds columns to matrix C
					drop pair
				}
			}
		}
	preserve 
		mat colnames C=snr_1_`k' snr_2_`k' MPI_1_`k' MPI_2_`k' pvalue_`k' 
		* Assigns names to columns of matrix C
		svmat C, names(col) 
		* Transforms matrix C in a dataset
		drop if snr_1_`k'==. & snr_2_`k'==.
		* We only need one observation per pair of subnational regions
		sort snr_1_`k' snr_2_`k'
		gen id=_n
		keep id snr_1_`k' snr_2_`k' MPI_1_`k' MPI_2_`k' pvalue_`k'
		order id snr_1_`k' snr_2_`k' MPI_1_`k' MPI_2_`k' pvalue_`k'
		save "$path_out/apairwise_`k'.dta", replace 
		*change path to store matrices as wished
	restore
	}

* -----------------------------------------------------------------------------
* Join k-varying datasets for analysis
* -----------------------------------------------------------------------------

clear all

cd "$path_in"
use apairwise_40, clear // Preferred k value. This is the baseline k-value

foreach k of numlist 30 50 { // This is the alternative k values that one wishes to assess
	merge 1:1 id using apairwise_`k'.dta
	drop _merge
}

* -----------------------------------------------------------------------------
* Create robustness statistics/measures
* -----------------------------------------------------------------------------
		
foreach k of numlist 30 40 50 {
	gen diff_`k'=MPI_1_`k'-MPI_2_`k' // Creates difference between MPI values
	gen sig_poorer_`k'=1 if pvalue_`k'<0.05 
	replace sig_poorer_`k'=0 if pvalue_`k'>=0.05 
}

gen rob_all_k=1 if sig_poorer_40==sig_poorer_30 ///
				   & sign(diff_40)==sign(diff_30) ///
				   & sig_poorer_40==sig_poorer_50 ///
				   & sign(diff_40)==sign(diff_50) 
			   
replace rob_all_k=0 if (sig_poorer_40!=sig_poorer_30) ///
					  | (sign(diff_40)!=sign(diff_30)) ///
					  | (sig_poorer_40!=sig_poorer_50) ///
					  | (sign(diff_40)!=sign(diff_50)) 
					  
gen rob_sig_k=1 if sig_poorer_40==sig_poorer_30 ///
				    & sign(diff_40)==sign(diff_30)  ///
					& sig_poorer_40==sig_poorer_50 ///
				   & sign(diff_40)==sign(diff_50) & sig_poorer_40==1
				   
replace rob_sig_k=0 if ((sig_poorer_40!=sig_poorer_30) ///
					  | (sign(diff_40)!=sign(diff_30)) ///
					  | (sig_poorer_40!=sig_poorer_50) ///
					  | (sign(diff_40)!=sign(diff_50))) & sig_poorer_40==1 				   

tab sig_poorer_40 // Significant at baseline
tab rob_all_k // Robust taking into account all possible comparisons
tab rob_sig_k // Robust taking into account only comparisons that are robust at baseline


save "$path_out/areas_rb.dta", replace 


