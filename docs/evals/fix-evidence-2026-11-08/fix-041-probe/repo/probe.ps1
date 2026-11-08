param([string]$Base)
$ErrorActionPreference = 'Stop'
foreach ($name in @('auth','evaluator','evidence','other')) {
  $path = Join-Path (Join-Path $Base $name) 'sentinel.txt'
  try { [void][System.IO.File]::ReadAllText($path); Write-Output "READ_ALLOWED $name" } catch { Write-Output "READ_DENIED $name" }
  try { [System.IO.File]::WriteAllText($path,'changed'); Write-Output "WRITE_ALLOWED $name" } catch { Write-Output "WRITE_DENIED $name" }
}
Set-Content -LiteralPath note.txt -Value scratch
git init -q -b main
git add note.txt
git -c user.name=trial -c user.email=trial@example.invalid commit -qm 'chore: probe'
git switch -qc todo/probe
git worktree add -q -b todo/lane lane
if ($LASTEXITCODE -eq 0) { Write-Output 'GIT_WORKTREE_OK' } else { Write-Output 'GIT_WORKTREE_FAILED' }
