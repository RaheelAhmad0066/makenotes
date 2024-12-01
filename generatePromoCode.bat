@echo off
echo Checking authenticated accounts...
call gcloud auth list

set /p customCode="Enter custom code (or Q to quit): "
if /I "%customCode%"=="Q" exit /b

set /p maxRedemptions="Enter max redemptions (or Q to quit): "
if /I "%maxRedemptions%"=="Q" exit /b

set /p usageLimit="Enter usage limit (or Q to quit): "
if /I "%usageLimit%"=="Q" exit /b

set /p mediaUsageLimit="Enter media usage limit (in KB) (or Q to quit): "
if /I "%mediaUsageLimit%"=="Q" exit /b

set /p expiryDuration="Enter expiry duration (in seconds) (or Q to quit): "
if /I "%expiryDuration%"=="Q" exit /b

call gcloud functions call generatePromoCode --region=asia-east2 --gen2 --data "{ \"data\": { \"code\": \"%customCode%\", \"maxRedemptions\": \"%maxRedemptions%\", \"usageLimit\": \"%usageLimit%\", \"mediaUsageLimit\": \"%mediaUsageLimit%\", \"expiry\": \"%expiryDuration%\" } }"

pause
```