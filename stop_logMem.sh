while true
do
    qstat > testQstat.txt
    numJobs=$(grep -v logMemory testQstat.txt | wc -l)
    if [ "$numJobs" -gt "2" ]
    then
        echo "Continue ${numJobs}"
    else
        echo "Adios"
        qdel 6516136
        break
    fi
    sleep 10
done