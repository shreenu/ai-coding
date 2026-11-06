# Installs every skill from this repo into a project, or globally (Windows PowerShell).
# Usage:
#   .\scripts\install.ps1 C:\path\to\project   # project install
#   .\scripts\install.ps1 -Global              # global install for all agents
param(
  [string]$ProjectDir,
  [switch]$Global
)
$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $PSScriptRoot
$SkillsDir = Join-Path $RepoDir "skills"

# Copies one skill folder into a target skills directory.
function Copy-Skill([string]$SkillPath, [string]$TargetDir) {
  $name = Split-Path $SkillPath -Leaf
  $dest = Join-Path $TargetDir $name
  New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
  if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
  Copy-Item -Recurse $SkillPath $dest
  Write-Host "  -> $dest"
}

# Adds a one-line pointer to AGENTS.md so agents without skill support still follow the skill.
function Add-AgentsMdPointer([string]$Dir, [string]$SkillName) {
  $file = Join-Path $Dir "AGENTS.md"
  $pointer = "- For building apps or coding challenges, follow ``.agents/skills/$SkillName/SKILL.md``."
  if (-not (Test-Path $file)) { New-Item -ItemType File -Path $file | Out-Null }
  if (-not (Select-String -Path $file -SimpleMatch $pointer -Quiet)) {
    Add-Content -Path $file -Value "`n$pointer"
    Write-Host "  -> pointer added to $file"
  }
}

$skills = Get-ChildItem -Directory $SkillsDir

if ($Global) {
  $globalDirs = @(".claude", ".codex", ".cursor", ".copilot", ".gemini") |
    ForEach-Object { Join-Path (Join-Path $HOME $_) "skills" }
  foreach ($skill in $skills) {
    Write-Host "Installing $($skill.Name) globally"
    foreach ($dir in $globalDirs) { Copy-Skill $skill.FullName $dir }
  }
  exit 0
}

if (-not $ProjectDir) { throw "Give a project path or -Global" }
foreach ($skill in $skills) {
  Write-Host "Installing $($skill.Name) into $ProjectDir"
  Copy-Skill $skill.FullName (Join-Path $ProjectDir ".agents\skills")
  Copy-Skill $skill.FullName (Join-Path $ProjectDir ".claude\skills")
  Add-AgentsMdPointer $ProjectDir $skill.Name
}
Write-Host "Done."
