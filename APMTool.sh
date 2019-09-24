#!/bin/bash
#Function
finish(){
killall APM1
killall APM2
killall APM3
killall APM4
killall APM5
killall APM6
killall ifstat
sed -i 's/K/000/g' System_Metrics.csv
}
APM_Starter(){
	ip=$1
	./APM1 $1 | ./APM2 $1 | ./APM3 $1 | ./APM4 $1 | ./APM5 $1 | ./APM6 $1&
	echo "Started APM"
}
ProcessLevel(){
	time=$1
	interval=1
	while [ $interval -le 6 ]
	do
		cpu=$(ps -aux | egrep APM"$interval" | awk 'NR==1{print $3}')
		memory=$(ps -aux | egrep ./APM"$interval" | awk 'NR==1{print $4}')
		line="$time,$cpu,$memory"
		echo $line >> APM"$interval"_metrics.csv
		((interval++))	
	done

}
SystemLevel(){
	time=$1
	kbWrite=$(iostat | grep -a sda | awk '{print $4}')
	netUsage=$(ifstat | grep ens33 | awk '{print $7 "," $9}')
	availDisk=$(df -m | grep centos-root | awk '{print $4}')
	line=$(awk -v netUsage=$netUsage -v kbWrite=$kbWrite -v time=$time -v availDisk=$availDisk 'BEGIN{print time ","netUsage"," kbWrite "," availDisk}')
	echo $line >> System_Metrics.csv
}
#Main
echo "Time,RX Data Rate,TX Data Rate,Disk Writes,Disk Capacity" > System_Metrics.csv
int=1
while [ $int -le 6 ]
do
		echo "Time,APM$int CPU,APM$int Memory" > APM"$int"_metrics.csv
		((int++))
done
APM_Starter 10.150.100.11
ifstat -d 1
while [ $SECONDS -le 900 ]
do
	sleep 5
	SystemLevel $SECONDS
	ProcessLevel $SECONDS
	echo "Took Metrics at $SECONDS"
done 
trap finish exit
