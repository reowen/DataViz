
-- query for updateTreatments.R
SELECT country_desc, region_desc, district_desc, disease, workbook_year, indicator, value_num 
FROM reporting_values_country
WHERE most_recent_submission_f = 1 
AND indicator IN ('ppl_targeted_all_num', 'ppl_targeted_usaid_num', 'sac_target_usaid_num', 'r1_ppl_targeted_all_num', 'r1_ppl_targeted_usaid_num', 
'r2_ppl_targeted_all_num', 'r2_ppl_targeted_usaid_num', 'r1_sac_target_usaid_num', 'r2_sac_target_usaid_num', 'ppl_treated_all_num', 
'ppl_treated_usaid_num', 'sac_treated_all_num', 'sac_treated_usaid_num', 'r1_ppl_treated_all_num', 'r1_ppl_treated_usaid_num', 
'r2_ppl_treated_all_num', 'r2_ppl_treated_usaid_num', 'r1_sac_treated_all_num', 'r1_sac_treated_usaid_num', 'r2_sac_treated_all_num', 
'r2_sac_treated_usaid_num', 'population_at_risk', 'sac_population_requiring_mda') 
AND reporting_period <> 'work_planning' AND disease <> 'at_least_one_ntd';

SELECT country, disease, workbook_year, 
MAX(persons_targeted_all) AS persons_targeted_all, 
MAX(persons_targeted_usaid) AS persons_targeted_usaid, 
MAX(sac_targeted_usaid) AS sac_targeted_usaid, 
MAX(persons_targeted_all_r1) AS persons_targeted_all_r1, 
MAX(persons_targeted_usaid_r1) AS persons_targeted_usaid_r1, 
MAX(persons_targeted_all_r2) AS persons_targeted_all_r2, 
MAX(persons_targeted_usaid_r2) AS persons_targeted_usaid_r2, 
MAX(sac_targeted_usaid_r1) AS sac_targeted_usaid_r1, 
MAX(sac_targeted_usaid_r2) AS sac_targeted_usaid_r2, 
MAX(persons_treated_all) AS persons_treated_all, 
MAX(persons_treated_usaid) AS persons_treated_usaid, 
MAX(sac_treated_all) AS sac_treated_all, 
MAX(sac_treated_usaid) AS sac_treated_usaid, 
MAX(persons_treated_all_r1) AS persons_treated_all_r1, 
MAX(persons_treated_usaid_r1) AS persons_treated_usaid_r1, 
MAX(persons_treated_all_r2) AS persons_treated_all_r2, 
MAX(persons_treated_usaid_r2) AS persons_treated_usaid_r2, 
MAX(sac_treated_all_r1) AS sac_treated_all_r1, 
MAX(sac_treated_usaid_r1) AS sac_treated_usaid_r1, 
MAX(sac_treated_all_r2) AS sac_treated_all_r2, 
MAX(sac_treated_usaid_r2) AS sac_treated_usaid_r2, 
MAX(persons_at_risk) AS persons_at_risk, 
MAX(sac_at_risk) AS sac_at_risk

FROM 
(SELECT
country_desc AS 'country', disease, workbook_year,
CASE WHEN indicator = 'ppl_targeted_all_num' THEN value_num END AS persons_targeted_all,
CASE WHEN indicator = 'ppl_targeted_usaid_num' THEN value_num END AS persons_targeted_usaid, 
CASE WHEN indicator = 'sac_target_usaid_num' THEN value_num END AS sac_targeted_usaid,
CASE WHEN indicator = 'r1_ppl_targeted_all_num' THEN value_num END AS persons_targeted_all_r1, 
CASE WHEN indicator = 'r1_ppl_targeted_usaid_num' THEN value_num END AS persons_targeted_usaid_r1,
CASE WHEN indicator = 'r2_ppl_targeted_all_num' THEN value_num END AS persons_targeted_all_r2, 
CASE WHEN indicator = 'r2_ppl_targeted_usaid_num' THEN value_num END AS persons_targeted_usaid_r2, 
CASE WHEN indicator = 'r1_sac_target_usaid_num' THEN value_num END AS sac_targeted_usaid_r1, 
CASE WHEN indicator = 'r2_sac_target_usaid_num' THEN value_num END AS sac_targeted_usaid_r2, 
CASE WHEN indicator = 'ppl_treated_all_num' THEN value_num END AS persons_treated_all, 
CASE WHEN indicator = 'ppl_treated_usaid_num' THEN value_num END AS persons_treated_usaid,
CASE WHEN indicator = 'sac_treated_all_num' THEN value_num END AS sac_treated_all, 
CASE WHEN indicator = 'sac_treated_usaid_num' THEN value_num END AS sac_treated_usaid, 
CASE WHEN indicator = 'r1_ppl_treated_all_num' THEN value_num END AS persons_treated_all_r1,
CASE WHEN indicator = 'r1_ppl_treated_usaid_num' THEN value_num END AS persons_treated_usaid_r1,
CASE WHEN indicator = 'r2_ppl_treated_all_num' THEN value_num END AS persons_treated_all_r2, 
CASE WHEN indicator = 'r2_ppl_treated_usaid_num' THEN value_num END AS persons_treated_usaid_r2,
CASE WHEN indicator = 'r1_sac_treated_all_num' THEN value_num END AS sac_treated_all_r1,
CASE WHEN indicator = 'r1_sac_treated_usaid_num' THEN value_num END AS sac_treated_usaid_r1,
CASE WHEN indicator = 'r2_sac_treated_all_num' THEN value_num END AS sac_treated_all_r2, 
CASE WHEN indicator = 'r2_sac_treated_usaid_num' THEN value_num END AS sac_treated_usaid_r2, 
CASE WHEN indicator = 'population_at_risk' THEN value_num END AS persons_at_risk, 
CASE WHEN indicator = 'sac_population_requiring_mda' THEN value_num END AS sac_at_risk

FROM reporting_values_country
WHERE most_recent_submission_f = 1 
AND indicator IN ('ppl_targeted_all_num', 'ppl_targeted_usaid_num', 'sac_target_usaid_num', 'r1_ppl_targeted_all_num', 'r1_ppl_targeted_usaid_num', 
'r2_ppl_targeted_all_num', 'r2_ppl_targeted_usaid_num', 'r1_sac_target_usaid_num', 'r2_sac_target_usaid_num', 'ppl_treated_all_num', 
'ppl_treated_usaid_num', 'sac_treated_all_num', 'sac_treated_usaid_num', 'r1_ppl_treated_all_num', 'r1_ppl_treated_usaid_num', 
'r2_ppl_treated_all_num', 'r2_ppl_treated_usaid_num', 'r1_sac_treated_all_num', 'r1_sac_treated_usaid_num', 'r2_sac_treated_all_num', 
'r2_sac_treated_usaid_num', 'population_at_risk', 'sac_population_requiring_mda') 
AND reporting_period <> 'work_planning' AND disease <> 'at_least_one_ntd')x
GROUP BY country, disease, workbook_year;