#!/bin/bash
cd ~/ldsc_project/out/h2

echo "IDP,h2,h2_se,lambda_gc,intercept" > h2_results.csv

for log in logs/*.log; do
    idp=$(basename $log .log)
    h2=$(grep "Total Observed scale h2:" $log | awk '{print $5}')
    se=$(grep "Total Observed scale h2:" $log | awk '{print $6}' | tr -d '()')
    lambda=$(grep "Lambda GC:" $log | awk '{print $3}')
    intercept=$(grep "Intercept:" $log | awk '{print $2}')
    
    if [ ! -z "$h2" ]; then
        echo "$idp,$h2,$se,$lambda,$intercept" >> h2_results.csv
    fi
done

echo "Extracted $(wc -l < h2_results.csv) results to h2_results.csv"
