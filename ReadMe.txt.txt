---------------------------------------------------------------------------------
*Brainalyzer - V 0.01A								
*	Alpha build									
*
*Complete Functions:
*	None
*
*In Progress Functions:
*	1) Preprocessing
*		1.a - Load EEG and downsample to 2k (Dylan)
*		1.b - Load position and interpolate up to 2k (Dylan)
*		1.c - Spike Sorting (Iago)
*	2) Velocity & Acceleration
*		Notes: Up to this point, this has been done in preprocessing
*			but now I am wondering if it should be done in own 
*			function for convenience and memory's sake (?)
*
*
----------------------------------------------------------------------------------

*Instructions
	To run Brainalyzer
		1) AS OF NOW, change constant values at beginning of Brainalyzer_Start.m 
			-inDir: Directory of raw TDT formatted blocks
			-outDir: Directory of workspace for Brainalyzer results
			-ratNum: Identification number of rat 
				(do not need to include anything else even if using noted syntax)
			-Analysis: Value representing which analysis / function you wish to run
		2) Run Brainalyzer_Start and follow the interface's instructions (all hail skynet)

	To install new functions:
		1) Add functions and necessary libraries to matlab path lists
		2) Add function number and comments on what this command runs in constants
			section of Brainalayzer_Start.m in main Brainalyzer directory
		3) Using same value index from step two, add function number and name in same 
			format and syntax to 'tasks' string in beginning of Brain_FetchBlocksToAnalyze.m
			(Example, function 5 being ripple finder would make tasks{5} = '\05 - Ripple Analyzer\')
		4) Add elseif statement for index value of function to if loop at bottom of Brainalyzer_Start.m
			(Example, elseif analysis == 5 run Brain_RippleFinder())