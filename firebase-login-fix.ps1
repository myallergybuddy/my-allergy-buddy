Set-Location c:\allergy\allergy_app2\allergy_app
$env:NODE_OPTIONS = '--require ./no-keepalive.cjs'

Write-Host "Node workaround enabled for Firebase login (Node 24.17 bug)." -ForegroundColor Cyan
Write-Host "When asked, type Y to open the browser." -ForegroundColor Yellow
Write-Host ""

firebase login --reauth
Write-Host ""
firebase login:list

if ($LASTEXITCODE -eq 0) {
  Write-Host ""
  Write-Host "If logged in, run these next:" -ForegroundColor Green
  Write-Host "firebase use my-allergy-buddy"
  Write-Host "firebase deploy --only hosting"
}

Write-Host ""
Write-Host "Press Enter to close..."
Read-Host | Out-Null
