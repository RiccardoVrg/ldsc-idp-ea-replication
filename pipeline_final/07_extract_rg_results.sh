#!/bin/bash
cd ~/ldsc_project/out/rg

echo "IDP,rg,rg_se,rg_z,rg_p,h2_idp,h2_idp_se,h2_ea,h2_ea_se" > rg_IDP_EA_results.csv

for log in logs/*_EA.log; do
    idp=$(basename $log _EA.log)
    if [[ $idp == *"TEST"* ]] || [[ $idp == *"CHECK"* ]]; then continue; fi
    
    rg_line=$(grep "munge/big40_final" $log | tail -1)
    if [ ! -z "$rg_line" ]; then
        rg=$(echo $rg_line | awk '{print $3}')
        se=$(echo $rg_line | awk '{print $4}')
        z=$(echo $rg_line | awk '{print $5}')
        p=$(echo $rg_line | awk '{print $6}')
        h2_idp=$(echo $rg_line | awk '{print $7}')
        h2_idp_se=$(echo $rg_line | awk '{print $8}')
        
        if [ "$rg" != "NA" ]; then
            echo "$idp,$rg,$se,$z,$p,$h2_idp,$h2_idp_se,0.0983,0.0047" >> rg_IDP_EA_results.csv
        fi
    fi
done

echo "Extracted $(tail -n +2 rg_IDP_EA_results.csv | wc -l) results"
cp rg_IDP_EA_results.csv ~/ldsc_project/rg_ALL_FINAL.csv
echo "Output: rg_IDP_EA_results.csv"
