Stata command `imputeHD`
===

*Lead developer and maintainer*: Simo Goshev  
*Group*: BC Research Services


Introduction
---

This new Stata command wraps the user-contributed command `hotdeck` to 
offer functionality for hot deck imputation of scales. `imputeHD`
outputs a formatted dataset ready for use with Stata's `mi` estimation
commands.



Installation
---

To load `imputeHD`, include the following line in your do file:

```
do "https://raw.githubusercontent.com/goshevs/imputeHD/master/ado/imputeHD.ado"
```


Syntax
---

```
syntax scale_stubs [if] [in], Ivar(varlist) Timevar(varname) /// 
                              [ BYvars(varlist) NImputations(integer 5) ///
                                MCItems(string asis) SCOREtype(string asis) /// 
                                HDoptions(string asis) MERGOptions(string asis) ///
                                SAVEmidata(string asis) ]
```

<br>

`imputeHD` takes the following arguments:

**Required**

| argument      | description            |
|---------------|------------------------|
| *scale_stubs* | stubs of scales to be imputed |
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

<br>

**Format of input data**

Input data for `imputeHD` should be in long format. 

<br>

**Requesting scale scores**

If requesting the use of scale scores, the names of the variables for these scores follow the convention:

`scale_stub` `_` `SCOREtype` `Score`

For example, if creating a mean score for scale with *scale_stub* `er`, the mean score 
variable name will be `er_meanScore`.

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
local myScales "er fnc wb ptsd ss"                  // stubs of scale items to impute
local myScrnChr "age_cat_1 education female_n"      // screener charasteristics to use in the imputation

imputeHD `myScales' , i(resp_id) t(timepoint) mci(`myScales') score(sum) by(study_arm_1 `myScrnChr') hd(seed(12345))

 
```
