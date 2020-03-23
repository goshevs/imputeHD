Stata command `imputeHD`
===

*Lead developer and maintainer*: Simo Goshev  
*Group*: BC Research Services


Introduction
---

This new Stata command wraps the user-contributed command `hotdeck` to 
offer functionality for hot deck imputation of scales. `imputeHD`
replaces the dataset in memory with a complete dataset ready for use with 
Stata's `mi` suite of commands.



Installation
---

To load `imputeHD`, include the following line in your do file:

```
qui do "https://raw.githubusercontent.com/goshevs/imputeHD/master/ado/imputeHD.ado"
```


Syntax
---

```
syntax scale_stubs [if] [in], Ivar(varlist) Timevar(varname) /// 
                              [ BYvars(varlist) NImputations(integer 5) ///
                                MCItems(string asis) SCOREtype(string asis) /// 
                                HDoptions(string asis) MERGOptions(string asis) ///
                                SAVEmidata(string asis) KEEPHDimp ]
```

<br>

`imputeHD` takes the following arguments:

**Required**

| argument      | description            |
|---------------|------------------------|
| *scale_stubs* | stubs of scales to be imputed (must be unique) |
| *Ivar*        | unique cluster/panel identifier (i.e. person, firm, country id) |
| *Timevar*     | time/wave/period identifier |

<br>

**Optional arguments:**

| argument       | description            |
|----------------|------------------------|
| *BYvars*       | variables that define the imputation strata (e.g. study arm, level of education, etc.) |
| *NImputations* | number of imputations |
|                | default: `5` |
| *MCItems*      | stubs of scales whose items should be mean centered |
| *SCOREtype*    | type of score to be computed out of the scale items and then imputed (takes `sum` or `mean`) |
| *HDoptions*    | options to be passed to command `hotdeck` |
| *MERGOptions*  | merge options to be passed on to `merge` upon merging the imputed data with the original data; imputed dataset is *master*, original dataset is *using* |
| *SAVEmidata*   | path/file/name of file to save the merged imputed data only |
| *KEEPHDimp*    | keep imputation files produced by `hotdeck` |
 

<br>

**Format of input data**

Input data for `imputeHD` should be in long format. In addition, all extraneous items 
of the scales in `scale_stubs` should be removed from the dataset.

<br>

**Requesting scale scores**

If requesting the use of scale scores, the names of the variables for these scores follow the convention:

`scale_stub` `_` `SCOREtype` `Score`

For example, if creating a mean score for scale with *scale_stub* `er`, the mean score 
variable name will be `er_meanScore`.

<br>

**Subsetting should be implemented with care**

Subsetting using `if` and `in` should be done at the level of respondent. Otherwise, 
observations in the `if` or `in` set will be imputed by `imputeHD`.

<br>

Working with sensitive data?
---

If you are working with sensitive data, please ensure that you point
Stata to a secure directory that it can use as a temporary directory.
Please, see
[this](https://www.stata.com/support/faqs/data-management/statatmp-environment-variable/)
reference for instructions on how to do this.

<br>

Examples
---

```	

** Stubs of scale items to impute
local myScales "er fnc wb ptsd ss"   

** Charasteristics to use as stratifiers in the imputation
local myScrnChr "age_cat_1 education female_n"     

*** Generate a subsetting variable for entire record
sort resp_id timepoint
bys resp_id: gen subset = round(runiform()) if _n == 1
bys resp_id: replace subset = subset[1]

imputeHD `myScales' if subset, i(resp_id) t(timepoint) mci(`myScales') score(mean) ///
                     by(study_arm_1 `myScrnChr') ni(10) hd(seed(12345)) ///
                     save(~/Desktop/myImputedDataOnly.dta)

 
```
