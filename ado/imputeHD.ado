* Program -imputeHD- 
* Author: Simo Goshev
* Version: 0.1
*
*
*
*

*** SYNTAX ***
*** anything     = stubs of scales
*** Ivar         = cluster identifier (i.e. person, firm, country id)
*** Timevar      = time/wave identifier
*** BYvars       = variables to split the imputaiton by (e.g. study arm, level of education, etc.)
*** NImputations = number of imputations
*** MCItems      = stubs of scales whose items should be mean centered
*** SCOREtype    = type of score to be computed out of the scale items and then imputed (takes sum or mean)
*** HDoptions    = options to be passed to command -hotdeck-
*** MERGOptions  = options to be passed to -merge- during mering original with imputed data
*** SAVEmidata   = path/file/name of file to save the merged imputed data only
*** KEEPHDimp    = keep imputation files produced by -hotdeck-





********************************************************************************
*** Program
********************************************************************************


capture program drop imputeHD
program define imputeHD
	syntax anything [if] [in], Ivar(varlist) Timevar(varname) /// 
						       [ BYvars(varlist) NImputations(integer 5) ///
							     MCItems(string asis) SCOREtype(string asis) /// 
							     HDoptions(string asis) MERGOptions(string asis) ///
                                 SAVEmidata(string asis) KEEPHDimp ]

	qui{
		*** Collect the levels of timevar
		levelsof `timevar', local(timePoints)
		
		*** Collect all items to impute
		local toImpute ""
		
		*** Process the scales
		foreach stub of local anything {
			unab scale: `stub'*

			*** Do we have to center the items?
			local centerItems =`: list stub in mcitems'
			
			*** If mean centering/score creation is requested
			if `centerItems' {	
				local myItems ""	
				foreach item of local scale {
					tempvar `item'_mc
					gen ``item'_mc' = .
					foreach tp of local timePoints {			
						sum `item' if `timevar' == `tp'   // compute the mean for period
						replace ``item'_mc' = `item' - `r(mean)' if `timevar' == `tp'   // demean the item for period							
					}
					local myItems "`myItems' ``item'_mc'"
				}
			}
			else {
				local myItems "`scale'"
			}
			
			*** If scoretype is requested
			if  "`scoretype'" ~= "" {	
				local commandType "mean"
				
				if "`scoretype'" == "sum" {
					local commandType "total"
					local missing ", missing"
				} 
				
				egen `stub'_`scoretype'Score = row`commandType'(`myItems') `missing'
	
				local toImpute "`toImpute' `stub'_`scoretype'Score"
			}
			else {
				local toImpute "`toImpute' `myItems'"
			}
		}
		
		*** Saving original data
		tempfile myOriginalData
		save `myOriginalData', replace
		
		*** Subsetting data to needed variables
		keep `ivar' `timevar' `toImpute' `byvars'
		
		*** Reshaping the data to long format
		reshape wide `toImpute', i(`ivar') j(`timevar')
		
		*** Collect all variables for imputation in wide
		local toImputeWide ""
		foreach item of local toImpute {
			unab myItems: `item'*
			local toImputeWide "`toImputeWide' `myItems'"
		}
		
		*** Hotdeck imputation
		noi hotdeck `toImputeWide', by(`byvars') imp(`nimputations') keep(`ivar') store `hdoptions'

		*** Merging the imputed datasets with the original data
		noi di _n in y "Merging imputed datasets..."
		
		qui forval i = 1 / `nimputations' {
			
			preserve
			use imp`i', clear
			
			*** Variables to keep
			keep `ivar' `toImputeWide'
			
			*** Collect all variable names
			unab myVars: _all
			
			*** Rename variables
			foreach var of local myVars {
				if "`var'" ~= "`ivar'" {
					ren `var' `var'__`i'
				}
			}
			
			sort `ivar'
			save imp`i', replace
			
			restore
			*** Merge with original data
			merge 1:1 `ivar' using imp`i', nogen
		}

		*** Save the merged data
		tempfile tempSave
		save `tempSave', replace

		*** Remove all imp files if keephdimp ~= ""
		if "`keephdimp'" == "" {
			forval i = 1/`nimputations' {
				erase imp`i'.dta
			}
		}
		else {
			local myLocation: pwd
			no di in y "Original hotdeck imputation files (default name imp*.dta) saved in directory: " _n ///
			" --->  `myLocation'  "
		}
		
		*** Create the -imputed- option
		local imputedOpt ""
		foreach var of local toImputeWide {
			local imputedOpt "`imputedOpt' `var'="
			forval i = 1/`nimputations' {
				local imputedOpt "`imputedOpt' `var'__`i'"
			}
		}
		
		noi di in y "Setting imputed data to mi..."
		
		*** Convert the dataset to mi
		mi import wide, imputed(`imputedOpt') drop 


		noi di in y "Reshaping imputed data back to long format..."
		
		*** Reshape to long
		unab varList: _all
		
		*** Reshape the data to long to facilitate modeling
		mi reshape long `toImpute', i(`ivar') j(`timevar')
		
		if "`savemidata'" ~= "" {
			no di in y "Merged imputation files saved to: " _n ///
			" --->  `savemidata'  "
			save "`savemidata'", replace
		}
		
		noi di in y "Merging imputations with original dataset..."
		*** Merge with original data
		drop `byvars'
		local mergoptions ", `mergoptions'"
		mi merge 1:1 `ivar' `timevar' using `myOriginalData' `mergoptions'
	}
	
	
end
