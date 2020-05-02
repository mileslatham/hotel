// init
cd "/Users/ml/Projects/PycharmProjects/agoda"
set more off
clear 
capture log close
log using "testing_log", replace
sysuse "auto.dta"

* BASIC EXPLORATORY STUFF * 
browse // opens data editor
describe // describes each var storage, diaply, label
summarize // observations + summary stats for each var
codebook  // type range, unique vals, missing, summary stats, percentiles
codebook make
codebook rep78 // helpful for checking var quality
browse if missing(rep78)
list make if missing(rep78)

* SUMMARY STATS * 
summarize price
summarize price, detail // includes percentiles, weight sums, var+skew+kurtosis
list make if price > 13000
list price if price > 13000

tab foreign
tab rep78
tab rep78 foreign, row

// instead of:
summarize mpg if foreign == 0
summarize mpg if foreign == 1
// do: 
by foreign, sort: summarize mpg
tab foreign, summarize(mpg)

// other helpful format:
table foreign, contents(mean mpg mean weight mean rep78)

// simple hypothesis test
ttest mpg, by(foreign)


corr mpg weight
by foreign, sort: corr mpg weight
correlate mpg weight length turn displacement

* GRAPHING *
twoway (scatter mpg weight)
twoway (scatter mpg weight), by(foreign, total) // nonlinear

* REGRESSION *
gen weightsq = weight ^ 2
summarize weightsq, detail

reg mpg weight weightsq foreign // is it correct to include both weight vars?
// postestimation:
drop mpghat
predict mpghat

twoway (scatter mpg weight) (line mpghat weight, sort), by(foreign)

// silly physics stuff
generate gp100m = 100 / mpg
label variable gp100m "Gallons per 100 miles"
twoway (scatter gp100m weight), by(foreign, total)
regress gp100m weight foreign






