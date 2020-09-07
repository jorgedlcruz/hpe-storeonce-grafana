#!/bin/bash
##  .SYNOPSIS
##  Grafana Dashboard for HPE StoreOnce G4 - Using RestAPI to InfluxDB Script
## 
##  .DESCRIPTION
##  This Script will query the HPE StoreOnce RESTful API and send the data directly to InfluxDB, which can be used to present it to Grafana. 
##  The Script and the Grafana Dashboard it is provided as it is, and bear in mind you can not open support Tickets regarding this project. It is a Community Project
##	
##  .Notes
##  NAME:  hpe_storeonce_grafana.sh
##  ORIGINAL NAME: hpe_storeonce_grafana.sh
##  LASTEDIT: 05/09/2020
##  VERSION: 1.0
##  KEYWORDS: storeonce, InfluxDB, Grafana
   
##  .Link
##  https://jorgedelacruz.es/
##  https://jorgedelacruz.uk/

##
# Configurations
##
# Endpoint URL for InfluxDB
InfluxDBURL="http://YOURINFLUXSERVER" #Your InfluxDB Server, http://FQDN or https://FQDN if using SSL
InfluxDBPort="8086" #Default Port
InfluxDB="telegraf" #Default Database
InfluxDBUser="INFLUXUSER" #User for Database
InfluxDBPassword='INFLUXPASS' #Password for Database

# Endpoint URL for login action
storeonceUsername="HPEUSERNAME" #Your username, if using domain based account, please add it like user@domain.com (if you use domain\account it is not going to work!)
storeoncePassword='HPEPASS'
storeonceRestServer="https://STOREONCEFQDNORIP"
storeonceRestPort="443" #Default Port
storeonceSessionBearer=$(curl -X POST "$storeonceRestServer:$storeonceRestPort/pml/login/authenticatewithobject" -H "Content-Type:application/json" -H "Accept:application/json" -d '{"username":"'$storeonceUsername'","password":"'$storeoncePassword'","grant_type":"password"}' -k --silent | jq --raw-output ".access_token")


#HPE StoreOnce Appliance Information
HPEUrl="$storeonceRestServer:$storeonceRestPort/api/v1/management-services/federation/members"
HPEDashboardUrl=$(curl -X GET --header "Accept:application/json" --header "Authorization:Bearer $storeonceSessionBearer" "$HPEUrl" 2>&1 -k --silent)

  HPEHostname=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[0].hostname" | awk '{gsub(/ /,"\\ ");print}')
  HPEUUID=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[0].uuid")
  HPEProductName=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[0].productName" | awk '{gsub(/ /,"\\ ");print}')
  HPESerialNumber=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[0].serialNumber")

#HPE StoreOnce Dashboard Information
HPEUrl="$storeonceRestServer:$storeonceRestPort/api/v1/data-services/dashboard/overview"
HPEDashboardUrl=$(curl -X GET --header "Accept:application/json" --header "Authorization:Bearer $storeonceSessionBearer" "$HPEUrl" 2>&1 -k --silent)

  HPEVersion=$(echo "$HPEDashboardUrl" | jq --raw-output ".highestSoftwareVersion")
  HPELocalDiskBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallLocalDiskBytes")
  HPELocalUserBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallLocalUserBytes")
  HPELocalFreeBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallLocalFreeBytes")
  HPELocalCapacityBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallLocalCapacityBytes")
  HPECloudDiskBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallCloudDiskBytes")
  HPECloudUserBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallCloudUserBytes")
  HPECloudFreeBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallCloudFreeBytes")
  HPECloudCapacityBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallCloudCapacityBytes")
  HPETotalCatalystStores=$(echo "$HPEDashboardUrl" | jq --raw-output ".catStoresSummary.statusSummary.total")
  HPETotalCloudBankStores=$(echo "$HPEDashboardUrl" | jq --raw-output ".cloudBankStoresSummary.statusSummary.total")
  HPETotalNASShares=$(echo "$HPEDashboardUrl" | jq --raw-output ".nasSharesSummary.statusSummary.total")
  HPETotalVTLLibraries=$(echo "$HPEDashboardUrl" | jq --raw-output ".vtlLibrariesSummary.statusSummary.total")
  HPETotalNASSharesReplica=$(echo "$HPEDashboardUrl" | jq --raw-output ".nasRepMappingSummary.statusSummary.total")
  HPETotalVTLLibrariesReplica=$(echo "$HPEDashboardUrl" | jq --raw-output ".vtlRepMappingSummary.statusSummary.total")  
  HPETotalDedupeRatio=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallDedupeRatio")
  HPETotalCapacitySavedBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallCapacitySavedBytes")
  HPETotalCapacitySavedPercentage=$(echo "$HPEDashboardUrl" | jq --raw-output ".overallCapacitySavedPercent")  
 
  ##Un-comment the following echo for debugging
  #echo "hpe_storeonce_dashboard,hpehostname=$HPEHostname,hpeproduct=$HPEProductName,hpeserialnumber=$HPESerialNumber,hpeversion=$HPEVersion hpelocaldisk=$HPELocalDiskBytes,hpelocaluser=$HPELocalUserBytes,hpelocalfree=$HPELocalFreeBytes,hpelocalcapacity=$HPELocalCapacityBytes,hpeclouddisk=$HPECloudDiskBytes,hpeclouduser=$HPECloudUserBytes,hpecloudfree=$HPECloudFreeBytes,hpecloudcapacity=$HPECloudCapacityBytes,hpecatalyst=$HPETotalCatalystStores,hpecloudbank=$HPETotalCloudBankStores,hpenasshares=$HPETotalNASShares,hpevtl=$HPETotalVTLLibraries,hpenasreplica=$HPETotalNASSharesReplica,hpevtlreplica=$HPETotalVTLLibrariesReplica,hpededuperatio=$HPETotalDedupeRatio,hpecapacitysaved=$HPETotalCapacitySavedBytes,hpecapacitysavedpercent=$HPETotalCapacitySavedPercentage"  
  
  ##Comment the Curl while debugging
  echo "Writing hpe_storeonce_dashboard to InfluxDB"
  curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "hpe_storeonce_dashboard,hpehostname=$HPEHostname,hpeproduct=$HPEProductName,hpeserialnumber=$HPESerialNumber,hpeversion=$HPEVersion hpelocaldisk=$HPELocalDiskBytes,hpelocaluser=$HPELocalUserBytes,hpelocalfree=$HPELocalFreeBytes,hpelocalcapacity=$HPELocalCapacityBytes,hpeclouddisk=$HPECloudDiskBytes,hpeclouduser=$HPECloudUserBytes,hpecloudfree=$HPECloudFreeBytes,hpecloudcapacity=$HPECloudCapacityBytes,hpecatalyst=$HPETotalCatalystStores,hpecloudbank=$HPETotalCloudBankStores,hpenasshares=$HPETotalNASShares,hpevtl=$HPETotalVTLLibraries,hpenasreplica=$HPETotalNASSharesReplica,hpevtlreplica=$HPETotalVTLLibrariesReplica,hpededuperatio=$HPETotalDedupeRatio,hpecapacitysaved=$HPETotalCapacitySavedBytes,hpecapacitysavedpercent=$HPETotalCapacitySavedPercentage"
  
#HPE StoreOnce Appliance Metrics
#CPU
TimeEnd=$(date -u --date="-1 minutes" +%FT%TZ)
TimeStart=$(date -u --date="-61 minutes" +%FT%TZ)
HPEUrl="$storeonceRestServer:$storeonceRestPort/api/v1/management-services/hardware/parametrics-cpu?startDate=$TimeStart&endDate=$TimeEnd&samples=60"
HPEDashboardUrl=$(curl -X GET --header "Accept:application/json" --header "Authorization:Bearer $storeonceSessionBearer" "$HPEUrl" 2>&1 -k --silent)

declare -i arraycpu=0

for id in $(echo "$HPEDashboardUrl" | jq -r '.members[].timestamp'); do
    HPETimestamp=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraycpu].timestamp")
    HPEpercentageCpuUsage=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraycpu].percentageCpuUsage")
    HPEpercentageUser=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraycpu].percentageUser")
    HPEpercentageNice=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraycpu].percentageNice")
    HPEpercentageSys=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraycpu].percentageSys")
    HPETimeUnix=$(date -d "$HPETimestamp" +"%s")

    ##Un-comment the following echo for debugging
    #echo "hpe_storeonce_parametrics,hpehostname=$HPEHostname hpecpuusage=$HPEpercentageCpuUsage,hpecpuuser=$HPEpercentageUser,hpecpunice=$HPEpercentageNice,hpecpusys=$HPEpercentageSys $HPETimeUnix"

    ##Comment the Curl while debugging
    echo "Writing hpe_storeonce_parametrics CPU to InfluxDB"
    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "hpe_storeonce_parametrics,hpehostname=$HPEHostname hpecpuusage=$HPEpercentageCpuUsage,hpecpuuser=$HPEpercentageUser,hpecpunice=$HPEpercentageNice,hpecpusys=$HPEpercentageSys $HPETimeUnix"

    arraycpu=$arraycpu+1
done

#RAM
HPEUrl="$storeonceRestServer:$storeonceRestPort/api/v1/management-services/hardware/parametrics-memory?startDate=$TimeStart&endDate=$TimeEnd&samples=60"
HPEDashboardUrl=$(curl -X GET --header "Accept:application/json" --header "Authorization:Bearer $storeonceSessionBearer" "$HPEUrl" 2>&1 -k --silent)

declare -i arrayram=0

for id in $(echo "$HPEDashboardUrl" | jq -r '.members[].timestamp'); do
    HPETimestamp=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arrayram].timestamp")
    HPEphysicalMemoryBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arrayram].physicalMemoryBytes")
    HPEavailableMemoryBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arrayram].availableMemoryBytes")
    HPEpercentageMemoryUsage=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arrayram].percentageMemoryUsage")
    HPETimeUnix=$(date -d "$HPETimestamp" +"%s")

    ##Un-comment the following echo for debugging
    #echo "hpe_storeonce_parametrics,hpehostname=$HPEHostname hperamphysical=$HPEphysicalMemoryBytes,hperamavailable=$HPEavailableMemoryBytes,hperampercentage=$HPEpercentageMemoryUsage $HPETimeUnix"

    ##Comment the Curl while debugging
    echo "Writing hpe_storeonce_parametrics RAM to InfluxDB"
    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "hpe_storeonce_parametrics,hpehostname=$HPEHostname hperamphysical=$HPEphysicalMemoryBytes,hperamavailable=$HPEavailableMemoryBytes,hperampercentage=$HPEpercentageMemoryUsage $HPETimeUnix"

    arrayram=$arrayram+1   
done

#DISK
HPEUrl="$storeonceRestServer:$storeonceRestPort/api/v1/management-services/hardware/parametrics-disk?startDate=$TimeStart&endDate=$TimeEnd&samples=60"
HPEDashboardUrl=$(curl -X GET --header "Accept:application/json" --header "Authorization:Bearer $storeonceSessionBearer" "$HPEUrl" 2>&1 -k --silent)

declare -i arraydisk=0

for id in $(echo "$HPEDashboardUrl" | jq -r '.members[].timestamp'); do
    HPETimestamp=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].timestamp")
    HPEOSpercentageDiskUsage=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].percentageDiskUsage")
    HPEOSreadThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].readThroughput")
    HPEOSwriteThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].writeThroughput")
    HPEOSreadsPerSecond=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].readsPerSecond")
    HPEOSwritesPerSecond=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].writesPerSecond")
    HPEDATApercentageDiskUsage=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].percentageDiskUsage")
    HPEDATAreadThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].readThroughput")
    HPEDATAwriteThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].writeThroughput")
    HPEDATAreadsPerSecond=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].readsPerSecond")
    HPEDATAwritesPerSecond=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraydisk].disks[0].writesPerSecond")
    
    HPETimeUnix=$(date -d "$HPETimestamp" +"%s")

    ##Un-comment the following echo for debugging
    #echo "hpe_storeonce_parametrics,hpehostname=$HPEHostname hpeospercentagedisk=$HPEOSpercentageDiskUsage,hpeosreadthroughput=$HPEOSreadThroughput,hpeoswritethroughput=$HPEOSwriteThroughput,hpeosreads=$HPEOSreadsPerSecond,hpeoswrites=$HPEOSwritesPerSecond,hpedatareadthroughput=$HPEDATAreadThroughput,hpedatawritethroughput=$HPEDATAwriteThroughput,hpedatareads=$HPEDATAreadsPerSecond,hpedatawrites=$HPEDATAwritesPerSecond $HPETimeUnix"

    ##Comment the Curl while debugging
    echo "Writing hpe_storeonce_parametrics DISK to InfluxDB"
    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "hpe_storeonce_parametrics,hpehostname=$HPEHostname hpeospercentagedisk=$HPEOSpercentageDiskUsage,hpeosreadthroughput=$HPEOSreadThroughput,hpeoswritethroughput=$HPEOSwriteThroughput,hpeosreads=$HPEOSreadsPerSecond,hpeoswrites=$HPEOSwritesPerSecond,hpedatareadthroughput=$HPEDATAreadThroughput,hpedatawritethroughput=$HPEDATAwriteThroughput,hpedatareads=$HPEDATAreadsPerSecond,hpedatawrites=$HPEDATAwritesPerSecond $HPETimeUnix"

    arraydisk=$arraydisk+1   
done

#NETWORKING
HPEUrl="$storeonceRestServer:$storeonceRestPort/api/v1/management-services/hardware/parametrics-ethernet?startDate=$TimeStart&endDate=$TimeEnd&samples=60"
HPEDashboardUrl=$(curl -X GET --header "Accept:application/json" --header "Authorization:Bearer $storeonceSessionBearer" "$HPEUrl" 2>&1 -k --silent)

declare -i arraynetworking=0

for id in $(echo "$HPEDashboardUrl" | jq -r '.members[].timestamp'); do
    HPETimestamp=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraynetworking].timestamp")
    HPEETHPortName=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraynetworking].ethernetPorts[].portName")
    HPEETHreceiveRate=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraynetworking].ethernetPorts[].receiveRate")
    HPEETHtransmitRate=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraynetworking].ethernetPorts[].transmitRate")
  
    
    HPETimeUnix=$(date -d "$HPETimestamp" +"%s")

    ##Un-comment the following echo for debugging
    #echo "hpe_storeonce_parametrics,hpehostname=$HPEHostname,hpeethportname=$HPEETHPortName hpeethreceive=$HPEETHreceiveRate,hpeethtransmit=$HPEETHtransmitRate $HPETimeUnix"

    ##Comment the Curl while debugging
    echo "Writing hpe_storeonce_parametrics ETH to InfluxDB"
    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "hpe_storeonce_parametrics,hpehostname=$HPEHostname,hpeethportname=$HPEETHPortName hpeethreceive=$HPEETHreceiveRate,hpeethtransmit=$HPEETHtransmitRate $HPETimeUnix"

    arraynetworking=$arraynetworking+1   
done

#CATALYST/NAS/VTL
HPEUrl="$storeonceRestServer:$storeonceRestPort/api/v1/data-services/cat/parametrics-throughput?startDate=$TimeStart&endDate=$TimeEnd&samples=60"
HPEDashboardUrl=$(curl -X GET --header "Accept:application/json" --header "Authorization:Bearer $storeonceSessionBearer" "$HPEUrl" 2>&1 -k --silent)

declare -i arraybackup=0

for id in $(echo "$HPEDashboardUrl" | jq -r '.members[].timestamp'); do
    HPETimestamp=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].timestamp")
    HPEaverageInboundCopyjobSessions=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].averageInboundCopyjobSessions")
    HPEaverageOutboundCopyjobSessions=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].averageOutboundCopyjobSessions")
    HPEinboundCopyjobNetworkThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].inboundCopyjobNetworkThroughput")
    HPEinboundCopyjobLogicalThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].inboundCopyjobLogicalThroughput")
    HPEoutboundCopyjobNetworkThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].outboundCopyjobNetworkThroughput")
    HPEoutboundCopyjobLogicalThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].outboundCopyjobLogicalThroughput")
    HPEinboundDatajobNetworkThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].inboundDatajobNetworkThroughput")
    HPEinboundDatajobLogicalThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].inboundDatajobLogicalThroughput")
    HPEaverageInboundCopyjobSessions=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].averageInboundCopyjobSessions")
    HPEaverageDataJobSessions=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].averageDataJobSessions")
    HPEoutboundDatajobNetworkThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].outboundDatajobNetworkThroughput")
    HPEoutboundDatajobLogicalThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].outboundDatajobLogicalThroughput")
    HPEoutboundCloudNetworkThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].outboundCloudNetworkThroughput")
    HPEinboundCloudNetworkThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].inboundCloudNetworkThroughput")
    HPEoutboundCopyjobLogicalThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].outboundCopyjobLogicalThroughput")
    HPEinboundDatajobNetworkThroughput=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraybackup].inboundDatajobNetworkThroughput")
    HPETimeUnix=$(date -d "$HPETimestamp" +"%s")

    ##Un-comment the following echo for debugging
    #echo "hpe_storeonce_parametrics,hpehostname=$HPEHostname hpeincopyjobsessions=$HPEaverageInboundCopyjobSessions,hpeoutcopyjobsessions=$HPEaverageOutboundCopyjobSessions,hpeincopynet=$HPEinboundCopyjobNetworkThroughput,hpeincopylog=$HPEinboundCopyjobLogicalThroughput,hpeoutcopynet=$HPEoutboundCopyjobNetworkThroughput,hpeoutcopylog=$HPEoutboundCopyjobLogicalThroughput,hpeindatajobnet=$HPEinboundDatajobNetworkThroughput,hpeindatalog=$HPEinboundDatajobLogicalThroughput,hpeavgsessions=$HPEaverageInboundCopyjobSessions,hpeoutdatanet=$HPEoutboundDatajobNetworkThroughput,hpeoutdatalog=$HPEoutboundDatajobLogicalThroughput,hpeoutcloudnet=$HPEoutboundCloudNetworkThroughput,hpeincloudnet=$HPEinboundCloudNetworkThroughput,hpeoutcopyjoblog=$HPEoutboundCopyjobLogicalThroughput,hpeindatajobnet=$HPEinboundDatajobNetworkThroughput $HPETimeUnix"

    ##Comment the Curl while debugging
    echo "Writing hpe_storeonce_parametrics Operations to InfluxDB"
    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "hpe_storeonce_parametrics,hpehostname=$HPEHostname hpeincopyjobsessions=$HPEaverageInboundCopyjobSessions,hpeoutcopyjobsessions=$HPEaverageOutboundCopyjobSessions,hpeincopynet=$HPEinboundCopyjobNetworkThroughput,hpeincopylog=$HPEinboundCopyjobLogicalThroughput,hpeoutcopynet=$HPEoutboundCopyjobNetworkThroughput,hpeoutcopylog=$HPEoutboundCopyjobLogicalThroughput,hpeindatajobnet=$HPEinboundDatajobNetworkThroughput,hpeindatalog=$HPEinboundDatajobLogicalThroughput,hpeavgsessions=$HPEaverageInboundCopyjobSessions,hpeoutdatanet=$HPEoutboundDatajobNetworkThroughput,hpeoutdatalog=$HPEoutboundDatajobLogicalThroughput,hpeoutcloudnet=$HPEoutboundCloudNetworkThroughput,hpeincloudnet=$HPEinboundCloudNetworkThroughput,hpeoutcopyjoblog=$HPEoutboundCopyjobLogicalThroughput,hpeindatajobnet=$HPEinboundDatajobNetworkThroughput $HPETimeUnix"

    arraybackup=$arraybackup+1   
done

#HPE StoreOnce Catalyst Volumes Overview
HPEUrl="$storeonceRestServer:$storeonceRestPort/api/v1/data-services/cat/stores"
HPEDashboardUrl=$(curl -X GET --header "Accept:application/json" --header "Authorization:Bearer $storeonceSessionBearer" "$HPEUrl" 2>&1 -k --silent)

declare -i arraystores=0

for id in $(echo "$HPEDashboardUrl" | jq -r '.members[].name'); do
    HPECatalystId=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraystores].id")
    HPECatalystName=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraystores].name" | awk '{gsub(/ /,"\\ ");print}')
    HPECatalystuserBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraystores].userBytes")
    HPECatalystdiskBytes=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraystores].diskBytes")
    HPECatalystdedupeRatio=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraystores].dedupeRatio")
    HPECatalystnumItems=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraystores].numItems")
    HPECatalystnumDataJobs=$(echo "$HPEDashboardUrl" | jq --raw-output ".members[$arraystores].numDataJobs")

    ##Un-comment the following echo for debugging
    #echo "hpe_storeonce_catalyst,hpehostname=$HPEHostname,hpecatalystname=$HPECatalystName,hpecatalystdescription=$HPECatalystDescription hpecatalystuserBytes=$HPECatalystuserBytes,hpecatalystdiskBytes=$HPECatalystdiskBytes,hpecatalystdedupe=$HPECatalystdedupeRatio,hpecatalystnumItems=$HPECatalystnumItems,hpecatalystnumDataJobs=$HPECatalystnumDataJobs"

    ##Comment the Curl while debugging
    echo "Writing hpe_storeonce_catalyst to InfluxDB"
    curl -i -XPOST "$InfluxDBURL:$InfluxDBPort/write?precision=s&db=$InfluxDB" -u "$InfluxDBUser:$InfluxDBPassword" --data-binary "hpe_storeonce_catalyst,hpehostname=$HPEHostname,hpecatalystname=$HPECatalystName hpecatalystuserBytes=$HPECatalystuserBytes,hpecatalystdiskBytes=$HPECatalystdiskBytes,hpecatalystdedupe=$HPECatalystdedupeRatio,hpecatalystnumItems=$HPECatalystnumItems,hpecatalystnumDataJobs=$HPECatalystnumDataJobs"

    arraystores=$arraystores+1   
done