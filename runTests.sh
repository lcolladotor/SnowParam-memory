#!/bin/sh


## Usage
# sh runTests.sh

## Following script based on
## http://superuser.com/questions/297283/store-the-output-of-date-and-watch-command-to-a-file
cat > .logMemory.sh <<EOF
#!/bin/bash
#$ -cwd
#$ -m e
#$ -N logMemory

touch logs/logMemory.txt
while true
do
    qmem | tee -a logs/logMemory.txt
    sleep 2
done

## Move log files into the logs directory
mv logMemory.* logs/

EOF

echo "Submitting log memory job"
qsub .logMemory.sh
sleep 60

sh SnowParam-memory.sh
sh SnowParam-memory-derfinder.sh
