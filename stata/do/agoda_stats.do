// init
cd "/Users/ml/Projects/PycharmProjects/agoda"

set more off
clear 
capture log close
// for descriptive stats, need to re-import basic data
use "combined_data_original.dta"
// check data 
describe
tab hotel_id
by hotel_id, sort: gen nvals_hotel_id = _n == 1 
tab accommadation_type_name
count if nvals_hotel_id
tab booking_date
tab checkin_date
tab date_diff
tab city_id star_rating
// 16808 has higher proportion of hostels
// 8584 and 17193 higher proportion of resorts 
// 9395 higher proportion of hotels and serviced apartments
tab accommadation_type_name
encode accommadation_type_name, generate(accom_int)
encode chain_hotel, generate(chain_int)

tab city_id accommadation_type_name
// city stuff
tab city_id
twoway scatter log_ADR_USD checkin_date if city_id == 5085, msize(tiny) || lfit log_ADR_USD checkin_date
twoway scatter log_ADR_USD checkin_date if city_id == 8584, msize(tiny) || lfit log_ADR_USD checkin_date
*up: 
twoway scatter log_ADR_USD checkin_date if city_id == 9395, msize(tiny) || lfit log_ADR_USD checkin_date
* slight up:
twoway scatter log_ADR_USD checkin_date if city_id == 16808, msize(tiny) || lfit log_ADR_USD checkin_date
* up:
twoway scatter log_ADR_USD checkin_date if city_id == 17193, msize(tiny) || lfit log_ADR_USD checkin_date

tab city_id chain_hotel
histogram booking_date, width(1)
histogram checkin_date, width(1)
histogram date_diff, width(1)
twoway (histogram booking_date, color(ltblue) width(1)) (histogram checkin_date, fcolor(none) lcolor(black) width(1))
gen log_ADR_USD = log(ADR_USD)
// set up key vars
gen date_diff = checkin_date - booking_date
tab date_diff

gen stay_length = checkout_date - checkin_date
tab stay_length

scatter log_ADR_USD date_diff, msize(tiny) || lfit log_ADR_USD date_diff
scatter log_ADR_USD star_rating, msize(tiny) || lfit log_ADR_USD star_rating //done
scatter log_ADR_USD stay_length, msize(tiny) || lfit log_ADR_USD stay_length //done
scatter log_ADR_USD booking_date, msize(tiny) || lfit log_ADR_USD booking_date //done
scatter log_ADR_USD checkin_date, msize(tiny) || lfit log_ADR_USD checkin_date
scatter log_ADR_USD date_diff, msize(tiny) || lfit log_ADR_USD date_diff
graph bar (mean) ADR_USD, over( city_id, sort(1) ) //done
graph bar (mean) ADR_USD, over( accommadation_type_name, sort(1) ) //done



// unhelpful:
scatter ADR_USD date_diff, msize(tiny)

gen log_ADR_USD = log(ADR_USD)

tab star_rating
twoway scatter log_ADR_USD date_diff if star_rating == 1, msize(tiny)
twoway lfit log_ADR_USD date_diff if star_rating == 3, msize(tiny)
scatter log_ADR_USD date_diff if star_rating == 1, msize(tiny) || lfit log_ADR_USD date_diff
scatter log_ADR_USD date_diff if star_rating == 2, msize(tiny) || lfit log_ADR_USD date_diff
scatter log_ADR_USD date_diff if star_rating == 3, msize(tiny) || lfit log_ADR_USD date_diff
scatter log_ADR_USD date_diff if star_rating == 4, msize(tiny) || lfit log_ADR_USD date_diff


scatter ADR_USD checkin_date, msize(tiny)
scatter ADR_USD booking_date, msize(tiny)

// best regresssion (but unintuitive result re: date_diff): 
reg ADR_USD date_diff star_rating i.city_id i.accom_int i.chain_int checkin_date stay_length

// frontier (this result is the same as regression)
frontier ADR_USD date_diff star_rating i.city_id i.accom_int i.chain_int checkin_date stay_length

// time series prep
tab hotel_id, sort
by hotel_id, sort: drop if _N < 100

// INCLUDING PREDICTIONS

* decision tree regression:
clear
use "preds_output.dta"
describe
gen decision_tree_prediction =  dt_preds
gen actual_rate = ADR_USD
twoway scatter actual_rate decision_tree_prediction, msize(tiny) || lfit actual_rate actual_rate
drop if actual_rate > 2500
histogram decision_tree_prediction, width(30) color(ltblue)
histogram actual_rate, width(30) color(ltblue)
* RNN:
clear
use "nets_output.dta"
use "nets_output_2.dta" // under-fitted
use "nn_long.dta"
describe
gen actual_rate = ADR_USD
gen log_net_preds = log(net_preds)
gen neural_net_prediction = net_preds
twoway scatter ADR_USD net_preds, msize(tiny) || lfit ADR_USD ADR_USD
twoway scatter actual_rate neural_net_prediction, msize(tiny) || lfit actual_rate neural_net_prediction
histogram neural_net_prediction, width(10) color(ltblue)
histogram actual_rate, width(10) color(ltblue)

drop RNN_prediction
gen RNN_prediction = net_preds *  1.5
gen actual_value = ADR_USD
twoway scatter actual_value RNN_prediction, msize(tiny) || lfit actual_value actual_value
histogram RNN_prediction, width(10) color(ltblue) xscale(range(0 1000))
histogram actual_value, width(10) color(ltblue) xscale(range(0 2000))
drop if actual_value > 2000

// INCLUDING WEIGHTS
by hotel_id booking_date, sort: gen weight = _N
tab weight


// CREATING AV PRICE VAR
egen avg_price = mean(ADR_USD), by(hotel_id booking_date)	
tab avg_price

// CREATING AVERAGE DATE DIFF
egen avg_date_diff = mean(date_diff), by(hotel_id booking_date)	

// CREATING AVERAGE STAY LENGTH
egen avg_stay = mean(stay_length), by(hotel_id booking_date)	
tab avg_date_diff

// DROPPING DUPLICATE DATES
sort hotel_id booking_date
quietly by hotel_id booking_date:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup > 1
describe
*********************
* ANALYSIS
*********************

// BAYES STUFF 
clear
use "case_study_data_weighted_cleaned.dta"
describe
bayes: mixed avg_price avg_stay c.avg_date_diff#c.weight star_rating i.city_id i.accom_int i.chain_int //[fweights=weights]
bayesgraph diagnostics {avg_price:_cons}, histopts(normal)
bayesstats ess
bayesstats summary
bayesstats ic 
bayespredict {_ysim}, saving(ysimdata)

clear
use "case_study_data.dta"
bayes: mixed log_ADR_USD stay_length c.booking_date#c.checkin_date star_rating i.city_id i.accom_int i.chain_int || hotel_id:
bayesgraph diagnostics {ADR_USD:_cons}, histopts(normal) // indicates bad convergence
* run after either above model
bayes, saving(ri_mcmc)
estimates store ri
*************************
*************************
*************************
clear
use "case_study_data.dta"
tab city_id
// finding av. price change by booking_date across cities
// CREATING AV PRICE VAR
egen avg_price_city = mean(ADR_USD), by(city_id checkin_date)	
tab avg_price_city

// DROPPING DUPLICATE DATES
sort city_id checkin_date
quietly by city_id checkin_date:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup > 1
describe
xtset city_id checkin_date
graph twoway (scatter avg_price_city checkin_date), by(city_id) ytitle("Average Price at Booking Date by City") || lfit ADR_USD checkin_date


**************************
**************************
**************************

// CREATING AVERAGE DATE DIFF
egen avg_date_diff_city = mean(date_diff), by(city_id booking_date)	

// CREATING AVERAGE STAY LENGTH
egen avg_stay_city = mean(stay_length), by(city_id booking_date)	
tab avg_stay_city

// LONGITUDINAL
clear
use "case_study_data_weighted_cleaned.dta"
xtset hotel_id booking_date
xtdescribe
tsfill, full

xtreg log_ADR_USD stay_length c.booking_date#c.checkin_date star_rating i.city_id i.accom_int i.chain_int


// REGRESSION / OTHER

// best regresssion (but unintuitive result re: date_diff): 
reg ADR_USD star_rating i.city_id i.accom_int i.chain_int c.checkin_date##c.booking_date stay_length
outreg2 ADR_USD star_rating i.city_id i.accom_int i.chain_int date_diff stay_length using "outreg.docx"
// frontier (this result is the same as regression)
frontier ADR_USD date_diff star_rating i.city_id i.accom_int i.chain_int checkin_date stay_length

// CITY BY CITY
tab city_id
reg ADR_USD star_rating i.accom_int i.chain_int booking_date stay_length date_diff if city_id == 5085
reg ADR_USD star_rating i.accom_int i.chain_int booking_date stay_length date_diff if city_id == 8584
reg ADR_USD star_rating i.accom_int i.chain_int booking_date stay_length date_diff if city_id == 9395
reg ADR_USD star_rating i.accom_int i.chain_int booking_date stay_length date_diff if city_id == 16808
reg ADR_USD star_rating i.accom_int i.chain_int booking_date stay_length date_diff if city_id == 17193
















