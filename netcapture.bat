@echo off
rem Start pktmon capture (full packets) to a specific file
pktmon start --etw --pkt-size 0 -f C:\pktmon.etl
Pause
rem (run until you want to stop)
rem Stop and convert:
pktmon stop
pktmon pcapng C:\pktmon.etl -o C:\capture.pcapng
