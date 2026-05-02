SELECT * FROM loan_data 
LIMIT 10;

#1 — Loan approval rate Education + Married

SELECT 
    Education,
    Married,
    COUNT(*) AS total_applications,
    SUM(CASE WHEN Loan_Status = 'Y' THEN 1 ELSE 0 END) AS approved,
    ROUND(SUM(CASE WHEN Loan_Status = 'Y' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS approval_rate
FROM loan_data
GROUP BY Education, Married
ORDER BY approval_rate DESC;

#2 AVG(LOAN AMOUNT + PROPERTY AREA)

WITH area_stats AS 
(SELECT 
	Property_Area,
	ROUND(AVG(LoanAmount), 0) AS avg_loan,
	ROUND(AVG(ApplicantIncome), 0) AS avg_income,
	COUNT(*) AS total
FROM loan_data
    WHERE LoanAmount IS NOT NULL
    GROUP BY Property_Area)
SELECT *,
    ROUND(avg_loan * 100.0 / avg_income, 2) AS loan_to_income_ratio
FROM area_stats
ORDER BY avg_loan DESC;

#3 — Risk segmentation (credit history + loan amount)

WITH loan_segments AS 
(SELECT *,
	CASE
		WHEN Credit_History = 0 THEN 'High Risk'
		WHEN Credit_History = 1 AND LoanAmount > 200 THEN 'Medium Risk'
		ELSE 'Low Risk'
        END AS risk_level
FROM loan_data
WHERE LoanAmount IS NOT NULL),
segment_stats AS
(SELECT 
risk_level,
	COUNT(*) AS total,
	ROUND(AVG(LoanAmount), 0) AS avg_loan,
	ROUND(AVG(ApplicantIncome), 0) AS avg_income,
	SUM(CASE WHEN Loan_Status = 'Y' THEN 1 ELSE 0 END) AS approved
FROM loan_segments
GROUP BY risk_level)
SELECT *,
    ROUND(approved * 100.0 / total, 2) AS approval_rate
FROM segment_stats
ORDER BY approval_rate DESC;

#4 Gap between the "rich" and avg people

WITH income_ordered AS
(SELECT 
	Loan_ID, Education, Property_Area, 
    ApplicantIncome,LoanAmount, Loan_Status,
	
LAG(ApplicantIncome) OVER 
(PARTITION BY Education 
	ORDER BY ApplicantIncome DESC)
	AS prev_income,
ApplicantIncome - LAG(ApplicantIncome) OVER 
	(PARTITION BY Education 
	ORDER BY ApplicantIncome DESC) AS income_gap
    FROM loan_data
    WHERE LoanAmount IS NOT NULL)
SELECT *
FROM income_ordered
WHERE income_gap IS NOT NULL
ORDER BY income_gap;