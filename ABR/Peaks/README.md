# ABRanalysis
OBJECTIVE:
Auditory brainstem response (ABR) analysis code (MATLAB, R2022b) for artifact removal, threshold estimation, and peak/trough picking (P1/N1 - P5/N5).

Author: Jim Bundy (2021)
Updated: Fernando Aguilera de Alba (24 January 2024)

INSTRUCTIONS:

1) Make or choose a folder on your computer. This folder will contain the 
ABR code once you clone it from GitHub

2) Clone the repository onto your designated folder. Open the terminal at the designated directory and type the following command:
     git clone https://github.com/fernandoaguilera10/ABR-Analysis.git

4) Once the code is cloned, you should see a folder named "ABRanalysis" within the folder you chose initially.

6) The only file you will need to open is "abr_setup.m". Within this script, you will need to specify your project, data, and output directories (Mac or Windows)

8) Depending on whether you are using Mac or Windows, use either the top or bottom portion of the script (ismac == 1 section for Mac).
   
10) Replace the following variables to meet your specific needs: ChinID (QXXX), ChinCondition (pre- OR post-exposure), ChinFile (date of data collection), PROJdir (the project directory), abr_data_dir (the directory containing data in default format:  data/subject/ABR/pre OR post/timepoint --> e.g. data/Q123/ABR/pre/baseline_2)

11) Save and run the script. After a few seconds, the ABR GUI should launch.

NOTE: Compiling time may increase if running scripts/data online instead of locally (i.e., Synology, GitHub). Check MATALB's status bar.