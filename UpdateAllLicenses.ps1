#License
$licenseFile = "C:\Users\wbrakowski8911\Desktop\Aktuelles\German Developer BC V17.flf"

#Fill array with container names
Write-Host("Filling arrays with container names...")
$inactiveContainerNames = docker ps --filter "status=exited" --format "{{.Names}}"
$containerNames = docker ps -a --format "{{.Names}}"

#Start inactive containers
Write-Host("Starting inactive containers...")
for ($i=0; $i -lt $inactiveContainerNames.length; $i++){
    Start-BcContainer -containerName $inactiveContainerNames[$i]              
}

#Update licenses for all containers
#Iterate through container names
#Check if container is healthy
#If container is starting, wait 2 seconds and try again (max no. of tries = 60, about 2 minutes)
#If container is unhealthy, store it to show it later
#If container is healthy, import the license and restart container
Write-Host("Importing licenses...")
$unhealthyContainers = @()
$maxNoOfTries = 60
for ($i=0; $i -lt $containerNames.length; $i++){            
    $noOfTries = 0 
    $containerProcessed = $false    
    do {
        Write-Host("Checking container health for " + $containerNames[$i] + "...")       
        $filterName = "name=" + $containerNames[$i]
        $containerHealth = docker ps -a --filter $filterName --format "{{.Status}}"
        Write-Host("Container health: " + $containerHealth)
        #Get status again and again until it is not starting anymore, (max no. of tries = 60, about 2 minutes)            
        if ($containerHealth -match "starting") {                
            $noOfTries += 1
            Write-Host("Container " + $containerNames[$i] + " starting. Waiting 2 seconds...No of tries: " + $noOfTries)
            Start-Sleep -s 2
        }
        #Store unhealthy container
        elseif ($containerHealth -match "unhealthy"){              
            Write-Host("Container " + $containerNames[$i] + " was unhealthy. Skipping import of license for this container.")              
            
            $unhealthyContainers += $containerNames[$i]
            $containerProcessed = $true
        }
        #Import license and restart container
        else {            
            Import-BcContainerLicense -containerName $containerNames[$i] -licenseFile $licenseFile -restart
            $containerProcessed = $true             
        }        
    }
    until ($noOfTries -eq $maxNoOfTries -or $containerProcessed)  
}

#Stop containers that were inactive
Write-Host("Stopping containers...")
for ($i=0; $i -lt $inactiveContainerNames.length; $i++){
    Stop-BcContainer -containerName $inactiveContainerNames[$i]    
}

#List unhealthy containers
if ($unhealthyContainers.length -gt 0) {
    Write-Host("The licence was not imported in the following containers because they were unhealthy:")
    Write-Host($unhealthyContainers)
}
