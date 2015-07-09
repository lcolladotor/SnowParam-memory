#!/bin/sh


## Usage
# sh SnowParam-memory.sh

CORES=10

for rversion in 3.1.x 3.2 3.2.x
do
    echo "Creating scripts for R version ${rversion}"
    for param in snow multicore
    do
    echo "Creating script for bpparam ${param}"
    SHORT="${param}-${rversion}"
    sname="bp-R${rversion}-${param}"
    cat > .${sname}.sh <<EOF
#!/bin/bash
#$ -cwd
#$ -m e
#$ -l mem_free=1G,h_vmem=3G,h_fsize=5G
#$ -N ${SHORT}
#$ -pe local ${CORES}

echo '**** Job starts ****'
date

# Make logs directory
mkdir -p logs

## Run test
module load R/${rversion}
Rscript SnowParam-memory.R -p "${param}" -m ${CORES}

## Move log files into the logs directory
mv ${SHORT}.* logs/

echo '**** Job ends ****'
date
EOF
    call="qsub .${sname}.sh"
    $call
    done
done


