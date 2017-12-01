#!/bin/tcsh
set base_path=`echo $0 |rev|cut -d/ -f2-|rev`
set base_path=$base_path"/"
cd base_path
set base_path=`pwd`
set base_path=$base_path"/"
echo $base_path 
set wo_path=$base_path
cd $base_path
foreach main_name_full ( $argv )
cd
set main_name=`echo $main_name_full|sed s/".mnova"//g`
echo "For : " $main_name
set mnova_in = $base_path$main_name".mnova"
echo $mnova_in
set path_working_directory=$base_path"/"
set mnova_sc=$path_working_directory"assignmentReport"
##set path_mnova_scripts="/Applications/MestReNova.app/Contents/Resources/scripts/"
set path_mnova_scripts=$base_path
##cp -rp $mnova_sc".qs" $path_mnova_scripts
echo "running Mnova script for generation of the nmredata.sdf file..."
#open --new -g -a mestrenova --args '"'$mnova_in'"' -sd $path_mnova_scripts"assignmentReport.qs"
echo open --new -g -a mestrenova --args $mnova_in -sd $path_mnova_scripts"assignmentReport.qs"
open --new -g -a mestrenova --args $mnova_in -sd $path_mnova_scripts"assignmentReport.qs"
cd
echo "waiting for the end of the processing of $main_name ..."
while ( ! -f mnova_process_done.txt )
sleep 1
echo -n "."
end
rm mnova_process_done.txt
echo "done with : " $main_name
sleep 1
foreach cc ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18)
if (-f compound$cc.nmredata.sdf) then
cat compound$cc.nmredata.sdf |grep -v DEBUG|grep -v UNIX_CREATE>"$wo_path/$main_name"_$cc.nmredata.sdf
cat compound$cc.nmredata.sdf |grep -v DEBUG>$wo_path/compound$cc.nmredata.sdf
endif
end
cd $wo_path
echo "prepare script"
echo "#"'!'"/bin/tcsh" > to_be_run_in_unix.csh
cat compound*.sdf| grep UNIX_CREATE|sed s+UNIX_WO_PATH+$wo_path+g|sed s/CSH_NAME_CSH/$main_name/g|cut -c14- >> to_be_run_in_unix.csh
echo >> to_be_run_in_unix.csh
chmod +x to_be_run_in_unix.csh
cp to_be_run_in_unix.csh was_run_in_unix_$main_name.csh
./to_be_run_in_unix.csh
rm ./to_be_run_in_unix.csh
rm compound*nmredata.sdf
rm was_run_in_unix*
cd
rm compound*.sdf
end
echo "Process: "
echo $0
echo "Terminated"
