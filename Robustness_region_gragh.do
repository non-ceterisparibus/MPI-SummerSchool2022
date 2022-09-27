
clear all
global path_in "H:/OPHI22/data and do files" 	  
global path_out "H:/OPHI22/data and do files"
* Adjust path

cd $path
use "$path_in/estimation.dta", clear


* Keep related variables (MPI) M0
keep region cens_c_vector_*

* Generate censored headcount ratio for each region
forvalue k = 1(1)100  {
	bysort region: egen region_avg_m0_`k' = mean(cens_c_vector_`k')
}

* Keep info at region-level
keep region region_avg_m0_*
duplicates drop region region_avg_m0_*, force

* Reshape data
reshape long region_avg_m0_, i(region) j(k)  
duplicates drop region_avg_m0_, force

clonevar M0 = region_avg_m0_

twoway line M0 k if region==1 || line M0 k if region==2 || line M0 k if region==3 || line M0 k if region==4,legend(order(1 "Hhohho" 2 "Manzini" 3 "Shiselweni"  4  "Lubombo"))



 * BY AREA
use "$path_in/estimation.dta", clear

* Keep related variables (MPI) M0
keep area cens_c_vector_*

* Generate poverty rates for each region
forvalue k = 1(1)100  {
	bysort area: egen area_avg_m0_`k' = mean(cens_c_vector_`k')
}

* Keep info at region-level
keep area area_avg_m0_*
duplicates drop area area_avg_m0_*, force

* Reshape data
reshape long area_avg_m0_, i(area) j(k)  
duplicates drop area area_avg_m0_, force

clonevar M0 = area_avg_m0_

twoway line M0 k if area==1 || line M0 k if area==2 ,legend(order(1 "Urban" 2 "Rural" ))


*---------------------------------------------------------------------------
* POVERTY RATE
*---------------------------------------------------------------------------

 * BY REGION
use "$path_in/estimation.dta", clear

* Keep related variables (MPI) M0
keep region mdp_*

* Generate poverty rates for each region
forvalue k = 1(1)100  {
	bysort region: egen region_H_`k' = mean(mdp_`k')
}

* Keep info at region-level
keep region region_H_*
duplicates drop region region_H_*, force

* Reshape data
reshape long region_H_, i(region) j(k)  
duplicates drop region region_H_, force

clonevar H = region_H_

twoway line H k if region==1 || line H k if region==2 || line H k if region==3 || line H k if region==4,legend(order(1 "Hhohho" 2 "Manzini" 3 "Shiselweni"  4  "Lubombo"))


 * BY AREA
use "$path_in/estimation.dta", clear

* Keep related variables (MPI) M0
keep area mdp_*

* Generate poverty rates for each region
forvalue k = 1(1)100  {
	bysort area: egen area_H_`k' = mean(mdp_`k')
}

* Keep info at region-level
keep area area_H_*
duplicates drop area area_H_*, force

* Reshape data
reshape long area_H_, i(area) j(k)  
duplicates drop area area_H_, force

clonevar H = area_H_

twoway line H k if area==1 || line H k if area==2 ,legend(order(1 "Urban" 2 "Rural" ))



 * BY gender
use "$path_in/estimation.dta", clear

* Keep related variables (MPI) M0
keep  sex mdp_*

* Generate poverty rates for each region
forvalue k = 1(1)100  {
	bysort  sex: egen  sex_H_`k' = mean(mdp_`k')
}

* Keep info at region-level
keep  sex  sex_H_*
duplicates drop  sex  sex_H_*, force

* Reshape data
reshape long  sex_H_, i( sex) j(k)  
duplicates drop  sex  sex_H_, force

clonevar H =  sex_H_

twoway line H k if  sex==1 || line H k if  sex==2 ,legend(order(1 "Male" 2 "Female" ))
