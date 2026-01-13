# #!/bin/bash

echo " iteration $1 -----------------------------------------------------------------------------------------"

echo "loading pdb into amber file format"  # -------------------------------------------------------

PDBFILE=output.pdb envsubst < MD_simulation/scripts/load_pdb.in | tleap -f - >leap.out

echo "starting MD simulation" # --------------------------------------------------------------------

cd MD_simulation
bash scripts/all_relax.scr
cd .. 

echo "create cleaned pdb from amber files" # -------------------------------------------------------

$AMBERHOME/bin/cpptraj -i MD_simulation/scripts/netCDF_to_pdb.in>cpptraj.out

echo "analyze input pdb for individual helices in origami structure" # -----------------------------

python Helix_separator/find_bound_double_strands.py

echo "calculating average helical parameters from trajectory" # ------------------------------------

rm -f Offset_energy_calculator/MD_Results/MD_averaged_parameters_of_helix_*.dat
i=0
while read -r line; do
   line_arr=($line)
   range_i=${line_arr[0]} ind=$i envsubst < MD_simulation/scripts/extract_Data.in > tmp_cpptraj.in 
   $AMBERHOME/bin/cpptraj -i tmp_cpptraj.in >cpptraj.out
   sed -i "1i$line" Offset_energy_calculator/MD_Results/MD_averaged_parameters_of_helix_$i.dat
   ((i++))
done < Helix_separator/cpptraj_base_pairing.txt
rm tmp_cpptraj.in

echo "comparing simulation data to equilibrium coordinates" # --------------------------------------------------

python Offset_energy_calculator/calculate.py

rm -rf MD_simulation/long_sim_data/*
mv MD_simulation/trajectorys MD_simulation/long_sim_data/
mv MD_simulation/info MD_simulation/long_sim_data/
mv MD_simulation/out MD_simulation/long_sim_data/
mv MD_simulation/restart_files MD_simulation/long_sim_data/
mkdir MD_simulation/trajectorys
mkdir MD_simulation/out
mkdir MD_simulation/info
mkdir MD_simulation/restart_files


# echo "starting vmd visualization of result"

# #vmd -e display_energys.tcl