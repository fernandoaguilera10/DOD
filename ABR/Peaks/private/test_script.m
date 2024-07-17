data_dir = 'Y:\Users\Hannah\ARO_2018_MEMR_TTS\Data\Q363\ABR\post\2weeksPostTTS\MH-2019_03_26-Q363_2weekspostTTS_ABRs_2 - Copy (4)\';
save_dir = 'Y:\Users\Hannah\ARO_2018_MEMR_TTS\Data\Q363\ABR\post\2weeksPostTTS\MH-2019_03_26-Q363_2weekspostTTS_ABRs_2 - Copy (5)\';
mat_dir = 'Y:\Users\Hannah\ARO_2018_MEMR_TTS\Analysis\ABR\';

run('Y:\Users\Hannah\ARO_2018_MEMR_TTS\Data\Q363\ABR\post\2weeksPostTTS\MH-2019_03_26-Q363_2weekspostTTS_ABRs_2 - Copy (4)\a0003_ABR_click.m')
x_araw = ans;
yyy = ans;
raw_name = 'araw.m';
new_name = 'ac.m';

yyy.AD_Data.AD_Avg_V = yyy.AD_Data.AD_Avg_V + 1;

cd(data_dir);

fid = fopen(raw_name, 'wt+');
fprintf(fid,'function x = %s\n', raw_name);

cd(mat_dir);
mat2text(x_araw,fid);
fclose('all');

cd(data_dir);

fid = fopen(new_name, 'wt+');
fprintf(fid,'function x = %s\n', new_name);

cd(mat_dir);
mat2text(yyy,fid);
fclose('all');

cd(data_dir);

fid = fopen(new_name, 'wt+');
fprintf(fid,'function x = %s\n', new_name);
cd(mat_dir);
mat2text(x_araw,fid);
fclose('all');
cd(data_dir);
