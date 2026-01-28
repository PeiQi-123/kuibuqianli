Write-Host "MyBatis Plus Diagnostic" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Yellow

Write-Host "`n1. Checking Dependencies..." -ForegroundColor Cyan
mvn dependency:tree 2>&1 | Select-String -Pattern "mybatis" | ForEach-Object { Write-Host "   $_" }

Write-Host "`n2. Checking Configuration..." -ForegroundColor Cyan
if (Test-Path "target/classes") {
    Write-Host "   Project is compiled" -ForegroundColor Green
} else {
    Write-Host "   Project NOT compiled" -ForegroundColor Red
}

Write-Host "`n3. Running Debug Mode..." -ForegroundColor Cyan
Write-Host "   Run this command to see detailed error:" -ForegroundColor White
Write-Host "   mvn spring-boot:run -Ddebug 2>&1 | findstr Mybatis" -ForegroundColor Magenta

Write-Host "`n4. Quick Fix Commands:" -ForegroundColor Cyan
Write-Host "   mvn clean" -ForegroundColor White
Write-Host "   mvn dependency:purge-local-repository -DmanualInclude=com.baomidou:mybatis-plus" -ForegroundColor White
Write-Host "   mvn compile" -ForegroundColor White