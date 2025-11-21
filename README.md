<h1>The U.S. Retirement System: Fast Facts</h1>

This repository includes the data and necessary code to support EIG's analysis on the state of retirement plan participation, access, and employer matching. You can find the analysis on our website here [here](https://eig.org/whos-left-out-of-americas-retirement-savings-system).

All links are current at the time of publication.

Contact Benjamin Glasner (benjamin@eig.org) or Sarah Eckhardt (sarah@eig.org) with any questions.

***

<h2>Methodology for identifying access, participation, and matching.</h2>

1. <h3>Survey of Consumer Finances </h3>

Codebook: [link](https://www.federalreserve.gov/econres/files/codebk2022.txt)

For the definition of participation: [link](https://www.federalreserve.gov/econres/files/bulletin.macro.txt)

Universe: subset of employed individuals, ages 18-65

Access: 
	
 	X11032>0	OR
 
	X11132>0	OR

 	X11332>0	OR

 	X11432>0	OR
 
	X11032==-1	OR
	
 	X11132==-1	OR
 
	X11332==-1	OR
 
	X11432==-1	OR
 
	X5316==1 & X6461==1	OR
	
 	X5324==1 & X6466==1	OR
	
 	X5332==1 & X6471==1	OR
	
 	X5416==1 & X6476==1	OR
	
 	X4136 == 1

Participates:  
	
 	X11032>0	OR
	
 	X11132>0	OR
	
 	X11332>0	OR
	
 	X11432>0	OR
	
 	X11032==-1	OR
	
 	X11132==-1	OR
	
 	X11332==-1	OR
	
 	X11432==-1	OR
	
 	X5316==1 & X6461==1	OR
	
 	X5324==1 & X6466==1	OR
	
 	X5332==1 & X6471==1	OR
	
 	X5416==1 & X6476==1

Employer Contributes:
	
 	X11047==1	OR
	
 	X11147==1	OR

X11032 - What is the balance of your pension account now? [1st job]

X11132 - What is the balance of your pension account now? [2nd job]

X11332 - What is the balance of your spouse’s pension account now? [1st job]

X11432 - What is the balance of your spouse’s pension account now? [2nd job]

X5316 -  Is this a payment or account from a (current job,) past job, a disability or military benefit, former spouse's pension, or something else? [1st benefit]

X6461 -  Is this pension currently an account plan, such as a 401(k), where you could take the whole balance as one payment if you wanted to? [1st benefit]

X5324 -  Is this a payment or account from a (current job,) past job, a disability or military benefit, former spouse's pension, or something else? [2nd benefit]

X6466 -  Is this pension currently an account plan, such as a 401(k), where you could take the whole balance as one payment if you wanted to? [2nd benefit]

X5332 - Is this a payment or account from a (current job,) past job, a disability or military benefit, former spouse's pension, or something else? [3rd benefit]

X6471 -  Is this pension currently an account plan, such as a 401(k), where you could take the whole balance as one payment if you wanted to? [3rd benefit]

X5416 - Is this a payment or account from a (current job,) past job, a disability or military benefit, former spouse's pension, or something else? [4th benefit]

X6476 -  Is this pension currently an account plan, such as a 401(k), where you could take the whole balance as one payment if you wanted to? [4th benefit]

X11047 - Does your employer/the business make contributions to this plan? [1st job]

X11147 -  Does your employer/the business make contributions to this plan? [2nd job]

***

2. <h3>NCS</h3>
(Provided in public release file summary for private employment, based on all workers)

***

3. <h3>CPS ASEC</h3>

Codebook:  [link](https://cps.ipums.org/cps-action/variables/PENSION#codes_section)

Universe: Subset of employed individuals (self employed, part or full time), ages 18-65

Access: PENSION == 2 | PENSION == 3

Participates: PENSION == 3

***

4. <h3>SIPP</h3>

Codebook: [link](https://www.census.gov/data-tools/demo/uccb/sippdict)

Universe: subset of non-government employed individuals, ages 18-65

Access: 
      
      EMJOB_401 == 1 ~ "Yes",
      
      EMJOB_IRA == 1 ~ "Yes",
      
      EMJOB_PEN == 1 ~ "Yes",
      
      EMJOB_401 == 2 ~ "No",
      
      EMJOB_IRA == 2 ~ "No",
      
      EMJOB_PEN == 2 ~ "No",
      
      EOWN_THR401  == 2 ~ "No",
      
      EOWN_IRAKEO  == 2 ~ "No",
      
      EOWN_PENSION == 2 ~ "No"

Participates: 

	ESCNTYN_401 == 1

Employer Contributes: 
	
 	EECNTYN_401 ==1
  

EMJOB_PEN - Any defined-benefit or cash balance plan(s) provided through main employer or business during the reference period.

EMJOB_401 - Any 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through main employer or business during the reference period.

EMJOB_IRA - Any IRA or Keogh account(s) provided through main employer or business during the reference period.

EOWN_PENSION - Participated in a defined-benefit pension or cash balance plan during the reference period.

EOWN_THR401 - Owned any 401k, 403b, 503b, or Thrift Savings Plan accounts during the reference period.

EOWN_IRAKEO - Owned any IRA or Keogh accounts during the reference period.

ESCNTYN_401 - During the reference period, respondent contributed to the 401k, 403b, 503b, or Thrift Savings Plan account(s) provided through their main employer or business.

EECNTYN_401 - Main employer or business contributed to respondent's 401k, 403b, 503b, or Thrift Savings Plan account(s) during the reference period.


***

<h2>Other Notes</h2>

All numbers reported for labor force size are estimated using the Current Population Survey.
