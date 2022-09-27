************* OPHI SUMMER SCHOOL 2022 *********
********* ESTIMATION (NAT. AGGREGATES) **********
*********** AND DIMENSIONAL BREAKDOWN **********


clear all

global path_in "H:/OPHI22/data and do files" 	  
global path_out "H:/OPHI22/data and do files"
use "$path_in/SWZ_2014_dataprep.dta", clear
* Adjust path

svyset psu [w=hhweight], strata(stratum) singleunit(scaled)
* Adjust psu, weight, and strata variables as needed

set type double // Specifies precision for decimal points; don't need to adjust

/* For this dofile, you only need to manually adjust the following:
(1) list of indicators in "selecting indicators" section
(2) indicators and weights in "setting indicator weights" section
(3) poverty cutoff(s) in "setting poverty cutoff(s)" section
*/

* -----------------------------------------------------------------------------
* Selecting indicators
* -----------------------------------------------------------------------------
/* Select the indicators that will be used in this measure */

global indic hh_d_water hh_d_toilet hh_d_electric hh_d_assets hh_d_cvacc hh_d_csurv hh_d_cnutri hh_d_idosalt hh_d_school hh_d_schlag
* Adjust list of indicators

* -----------------------------------------------------------------------------
* Uncensored Headcount Ratios: Percentage of the population deprived in each 
* indicator
* -----------------------------------------------------------------------------
/* These ratios are estimated first because they are independent of indicator 
weights and the chosen multidimensional poverty cutoff */
	
svy: mean $indic

* -----------------------------------------------------------------------------
* Setting indicator weights
* -----------------------------------------------------------------------------
/* Change the below according to the desired specification. Remember that the 
sum of weights MUST be equal to 1 or 100% */

foreach var in hh_d_water hh_d_toilet hh_d_electric hh_d_assets hh_d_cvacc hh_d_csurv hh_d_cnutri hh_d_idosalt {	
	gen	w_`var' = 1/12 
	* 1/3 in each dimension, divided for 4 indicators
	lab var w_`var' "Weight `var'"
}

foreach var in hh_d_school hh_d_schlag {	
	gen	w_`var' = 1/6
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
/* Generate the vector of individual weighted deprivation scores, 'c' */

egen	c_vector = rowtotal(g0_w_*)
lab var c_vector "Counting Vector"
	
svy: tab c_vector

* -----------------------------------------------------------------------------
* Identification of the poor 
* -----------------------------------------------------------------------------
/* Identify the poor at different poverty cutoffs (i.e. different k) */

forvalue k = 1(1)100 {
	gen	mdp_`k' = (c_vector >= `k'/100)
	lab var mdp_`k' "Poverty Identification with k=`k'%"
}

* -----------------------------------------------------------------------------
* Censored counting vector
* -----------------------------------------------------------------------------
/* Generate the censored counting vector of individual weighted deprivation 
score, 'c(k)', providing a score of zero if a person is not poor */

forvalue k = 1(1)100 {
	gen	cens_c_vector_`k' = c_vector
	replace cens_c_vector_`k' = 0 if mdp_`k'==0 
}

* -----------------------------------------------------------------------------
* Calculate MPI, H, A for different poverty cutoffs
* -----------------------------------------------------------------------------
/* Calculate the Multidimensional Poverty Index/Adjusted Headcount Ratio (MPI/M0),
the Incidence/Headcount Ratio (H), and the Average Intensity of Poverty among 
the Poor (A) for different poverty cutoffs (k). */

svy: mean cens_c_vector_* // MPI for all possible k cutoffs
svy: mean cens_c_vector_25 cens_c_vector_50 // MPI for specific k cutoffs (one or more)

svy: mean mdp_* // H for all possible k cutoffs
svy: mean mdp_25  mdp_50 // H for specific k cutoffs (one or more)

foreach k in 25 50 { // A for specific k cutoffs (one or more)
	svy, subpop(mdp_`k'): mean cens_c_vector_`k' // A
}	

* -----------------------------------------------------------------------------
* Setting poverty cutoff(s)
* -----------------------------------------------------------------------------
/* Select one or more plausible poverty cutoffs (k) to compute full results */

global sel_k 25 50
* Select desired poverty cutoffs (k)

* -----------------------------------------------------------------------------
* Censored deprivation matrix 
* -----------------------------------------------------------------------------
/* Generate the censored deprivation matrix, replacing deprivations as 0 if the 
person is non-poor */

foreach k of global sel_k {
	foreach var of global indic {
		gen	g0_`k'_`var' = `var'
		replace g0_`k'_`var' = 0 if mdp_`k'==0
	}
}
	
* -----------------------------------------------------------------------------
* Censored Headcount Ratios: Percentage of the population poor and deprived in
* each indicator
* -----------------------------------------------------------------------------
/* Calculate the censored headcount ratios, as the mean of each column of the 
censored deprivation matrix */

foreach k of global sel_k {
	svy: mean g0_`k'_*
}

* -----------------------------------------------------------------------------
* Absolute and Percentage Contributions
* -----------------------------------------------------------------------------
/* Absolute contributions are each indicator's contribution to the MPI level 
(calculated as the censored headcount ratio * weight). Percentage contributions 
are the % of the MPI that each indicator contributes (calculated as the censored 
headcount ratio * weight divided by the MPI). Note that all percentage 
contributions MUST sum to 1 or 100% */

/* Create variables for each censored headcount ratio and k cutoff */
foreach var of global indic {
	foreach k of global sel_k {
		svy: mean g0_`k'_`var'
		gen c_`k'_`var'=_b[g0_`k'_`var']
	}
}

/* Create variables for MPI at each k cutoff */
foreach k of global sel_k {
	svy: mean cens_c_vector_`k'
	gen M_`k'=_b[cens_c_vector_`k']
}
	
/* Contributions (absolute and percentage) */
foreach var of global indic {
	foreach k of global sel_k {
		gen	actr_`k'_`var' = c_`k'_`var'*w_`var'
		lab var actr_`k'_`var'  "Absolute contribution of Indicator `var' to M0 for k-value `k'"
		gen	pctr_`k'_`var' = c_`k'_`var'*w_`var'/M_`k'
		lab var pctr_`k'_`var'  "Percentage contribution of Indicator `var' to M0 for k-value `k'"
	}
}

/* Test and display results */
foreach k of global sel_k {
	egen test_`k'=rowtotal(pctr_`k'*) // Test that % contributions sum to 1/100%
	tab test_`k' if _n==1 // Verify that this adds up to 100%
	sum pctr_`k'* if _n==1 // Note: can change "sum" to "fsum" to better see variable names
	sum actr_`k'* if _n==1 // Note: can change "sum" to "fsum" to better see variable names
}

/* Note: if you want to use fsum but it doesn't run, install using: 
"ssc install fsum" */

* -----------------------------------------------------------------------------
* Intensity Bands
* -----------------------------------------------------------------------------
/* Analyze the distribution of intensities among the poor. Review the censored 
counting vector and then create bands of relevant values as desired */

/* Review censored counting vector */
foreach k of global sel_k {
	svy: tab cens_c_vector_`k'
}

* -----------------------------------------------------------------------------
* Generating Output Dataset
* -----------------------------------------------------------------------------
/* Creating a DTA file with all relevant indicators at the national level as 
variables. The structure of this dataset allows us to combine it with other 
results to be produced subsequently. It can all be run together and does not
need manual adjustment */

	
local estim b se lb ub // We will estimate mean points (b), standard errors (se), and confidence interval lower and upper bounds (lb ub) for all results
local n_ind: list sizeof global(indic) // n_ind contains the number of indicators
	
/* Uncensored headcount ratios */
foreach e of local estim {
	mat `e'=J(1,`n_ind',.) // Initialize row vectors
}

local i=0 // Indicator counter
		
local varn_b = ""
local varn_se = ""
local varn_lb = ""
local varn_ub = ""

foreach var of global indic {  
	local i=`i'+1 // Update indicator counter
	local aux=substr("`var'",6,.) // Extract indicator name
	svy: mean `var' 
	mat E=r(table)
	mat b[1,`i'] = E[1,1]*100 // Estimated coefficient
	local varn_b="`varn_b' "+"u_`aux'_b"
	mat se[1,`i'] = E[2,1]*100 // SE
	local varn_se="`varn_se' "+"u_`aux'_se"
	mat lb[1,`i'] = E[5,1]*100 // CI LB
	local varn_lb="`varn_lb' "+"u_`aux'_lb"
	mat ub[1,`i'] = E[6,1]*100 // CI UB
	local varn_ub="`varn_ub' "+"u_`aux'_ub"
}

mat colnames b=`varn_b'
mat colnames se=`varn_se'
mat colnames lb=`varn_lb'
mat colnames ub=`varn_ub'
mat U=[b,se,lb,ub] // Matrix to be stored and treated subsequently

/* H for selected values */
foreach k of global sel_k {
	foreach e of local estim {
		mat `e'=J(1,1,.) // Re-initialize row vectors
	}
	svy: mean mdp_`k' 
	mat E=r(table)
	mat b[1,1] = E[1,1]*100 // estimated coefficient
	mat se[1,1] = E[2,1]*100 // SE
	mat lb[1,1] = E[5,1]*100 // CI LB
	mat ub[1,1] = E[6,1]*100 // CI UB
	foreach e of local estim { // Name columns for readibility 
		mat colnames `e'="H_`k'_`e'" 
	}
	mat H_`k'=[b,se,lb,ub] // Matrix to be stored and treated subsequently
}
	
/* A for selected values */
foreach k of global sel_k {
	foreach e of local estim {
		mat `e'=J(1,1,.) // Re-initialize row vectors
	}
	svy, subpop(mdp_`k'): mean cens_c_vector_`k' 
	mat E=r(table)
	mat b[1,1] = E[1,1]*100 // estimated coefficient
	mat se[1,1] = E[2,1]*100 // SE
	mat lb[1,1] = E[5,1]*100 // CI LB
	mat ub[1,1] = E[6,1]*100 // CI UB
	foreach e of local estim { // Name columns for readibility 
		mat colnames `e'="A_`k'_`e'" 
	}
	mat A_`k'=[b,se,lb,ub] // Matrix to be stored and treated subsequently
}
	
/* MPI for selected values */
foreach k of global sel_k {
	foreach e of local estim {
		mat `e'=J(1,1,.) // Re-initialize row vectors
	}
	svy: mean cens_c_vector_`k' 
	mat E=r(table)
	mat b[1,1] = E[1,1] // estimated coefficient
	mat se[1,1] = E[2,1] // SE
	mat lb[1,1] = E[5,1] // CI LB
	mat ub[1,1] = E[6,1] // CI UB
	foreach e of local estim { // Name columns for readibility 
		mat colnames `e'="MPI_`k'_`e'" 
	}
	mat M_`k'=[b,se,lb,ub] // Matrix to be stored and treated subsequently
}
	
/* Censored headcount ratio for selected values */
foreach k of global sel_k {
	foreach e of local estim {
		mat `e'=J(1,`n_ind',.) // Initialize row vectors
	}

	local varn_b = ""
	local varn_se = ""
	local varn_lb = ""
	local varn_ub = ""
		
	local i=0 // indicator counter
		
	foreach var of global indic {  
		local i=`i'+1 // update indicator counter
		svy: mean g0_`k'_`var' 
		local aux=substr("`var'",6,.) // Extract indicator name
		mat E=r(table)
		mat b[1,`i'] = E[1,1]*100 // estimated coefficient
		local varn_b="`varn_b' "+"c_`k'_`aux'_b"
		mat se[1,`i'] = E[2,1]*100 // SE
		local varn_se="`varn_se' "+"c_`k'_`aux'_se"
		mat lb[1,`i'] = E[5,1]*100 // CI LB
		local varn_lb="`varn_lb' "+"c_`k'_`aux'_lb"
		mat ub[1,`i'] = E[6,1]*100 // CI UB
		local varn_ub="`varn_ub' "+"c_`k'_`aux'_ub"
	}
	mat colnames b=`varn_b'
	mat colnames se=`varn_se'
	mat colnames lb=`varn_lb'
	mat colnames ub=`varn_ub'
	mat C_`k'=[b,se,lb,ub] // Matrix to be stored and treated subsequently
}
			
/* Contributions (much easier after creating matrix C above) */
foreach k of global sel_k {
	mat ACO_`k'=J(1,`n_ind',.) // Initialize row vectors
	mat RCO_`k'=J(1,`n_ind',.) // Initialize row vectors
	local i=0 // indicator counter
	local varn_ab = "" // Initialize variable name
	local varn_rb = "" // Initialize variable name
	foreach var of global indic {
		local i=`i'+1 // update indicator counter
       	local aux=substr("`var'",6,.) // Extract indicator name
		local a=C_`k'[1,`i']*w_`var'/M_`k'[1,1]
		mat RCO_`k'[1,`i'] = `a'	
		local varn_rb="`varn_rb'"+" pctr_`k'_`aux'"
		local b=C_`k'[1,`i']*w_`var'/100
		mat ACO_`k'[1,`i'] = `b'	
		local varn_ab="`varn_ab'"+" actr_`k'_`aux'"
	}
	mat colnames ACO_`k'=`varn_ab'
	mat colnames RCO_`k'=`varn_rb'
}

/* Merge all indicators and create national-level datasets */
mat S=100
mat colnames S="pop_share"
mat UN=_N
mat colnames UN="sample_size"
mat R=[UN,S]
foreach k of global sel_k {
	mat R=[R,M_`k',H_`k',A_`k',C_`k',RCO_`k',ACO_`k']
}
mat R=[R,U]
	
/* Export as DTA file */
preserve
	clear 
	svmat R, names(col)
	gen loa="National"
	gen subgroup="National"
	order loa subgroup
	keep if _n==1
	save "$path_out/ag_nat", replace

restore
