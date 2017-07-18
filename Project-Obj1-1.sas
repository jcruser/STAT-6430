filename master 'C:\SASProject\Master.csv';
filename newform 'C:\SASProject\NewForms.csv';
filename assign 'C:\SASProject\Assignments.csv';
filename correct 'C:\SASProject\Corrections.csv';
filename projclas  'C:\SASProject\ProjClass.csv';

/*import Master data*/
data master_n;

infile master firstobs=2 dsd; /*get rid of the first row in the orginal data */
retain Consultant ProjNum Date Hours Stage Complete; /*Keep the column order*/
length Date $10;
input Consultant $ ProjNum Date mmddyy10. Hours Stage Complete;/*Change internal representation  of dates to sort on the basis of dates*/
run;

/*import NewForm data */
data newform_n;
infile newform firstobs=2 dsd;
retain ProjNum Date Hours Stage Complete;
length Date $10;
input ProjNum Date mmddyy10. Hours Stage Complete;
run;

/*import Assignment data */
data assign_n;
infile assign firstobs=2 dsd;
input Consultant $ ProjNum;
run;

/*import Correction */
data correct_n;
infile correct firstobs=2 dsd;
length Date $10;
input ProjNum Date mmddyy10. $ Hours Stage;
run;

/*import Project Class */
data Proj_class;
infile projclas firstobs=2 dsd;
input type $ ProjNum;
run;

/*stack newform_n and master_n */
data stack_MN;
set master_n newform_n;
run;

/*After stacking, the additional ProjNum from newform will not have corresponding consultant name. The following codes serve as a
a way to fill in the missing consultant name */

data stack_fill;
set stack_MN;
retain X; /*keep the last non-missing value in memory*/
if not missing (Consultant) Then X = Consultant; /*fills the new variable with non-missing value */
Consultant = X;
run;

/* merge stack_fill with assign_n */

/** sort assign_n **/
proc sort data=assign_n;
by ProjNum;
run;

/** sort stack_fill **/
proc sort data=stack_fill;
by ProjNum;
run;

/** merge **/
data merge_a;
merge assign_n stack_fill;
by ProjNum;
run;

/* update merge_a with correct_n */

/**sort correct_n **/
proc sort data= correct_n;
by ProjNum Date;
run;

/**sort merge_a **/
proc sort data= merge_a;
by ProjNum Date;
run;

data new_master;
update merge_a(in = in1) correct_n(in = in2); /*Update merge_a using correct_n by referring to both ProjNum and Date*/
by ProjNum Date;
if in2 then Corrections = 'Yes'; /*Add columns for corrrections*/
run;

/*sort master*/
proc sort data= new_master;
by ProjNum;
run;

/*sort project class*/
proc sort data= Proj_Class;
by ProjNum;
run;

/*Add column for type*/
data new_master (keep= Consultant ProjNum Type Date Hours Stage Complete Corrections);
merge new_master Proj_Class;
by ProjNum;
run;

proc sort data= new_master;
by ProjNum Date;
run;


/*End of Objective 1, assuming merge is correct*/

/*Objective 2: List of ongoing projects as on 11/4/2010*/
data ongoing ( keep = ProjNum);
set new_master;
by ProjNum Date;
if complete = 0 and last.ProjNum = 1 then output;
run;

/*Objective 3: */
