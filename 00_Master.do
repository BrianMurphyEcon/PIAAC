********************************************************************************
*********************** MASTER DO-FILE FOR PIAAC PROJECT ***********************
********************************************************************************

*** Set Main Directory ***

*** MAIN FOR BRIAN ***
global main "C:\Users\bmmur\UH-ECON Dropbox\Brian Murphy\Chinhui Work\PIAAC"


*** Define subdirectories ***
global code		      "$main\Code"
global bklmp          "$main\BKLMP Code"
global data           "$main\Data"
	global temp		  "$data\Temp"	
global crosswalks     "$main\crosswalks"
global maps           "$main\IPUMSI_world_release2024"
global output         "$main\Output"
	global fig2		  "$output\Figure2"
	global fig3		  "$output\Figure3"
	global fig4		  "$output\Figure4"
	global fig5		  "$output\Figure5"
	global tab1		  "$output\Table1"
	global tab3		  "$output\Table3"

*** Run .do Files ***
do "$code\01_Create Dataset"
do "$code\10_Analysis.do"
do "$code\11_Sorting.do"
do "$code\12_Replicating.do"
do "$code\13_Mismatch.do"
