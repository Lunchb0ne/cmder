function Configure-Git($GIT_INSTALL_ROOT){
  $env:Path += $(";" + $GIT_INSTALL_ROOT + "\cmd")

  # Add "$GIT_INSTALL_ROOT\usr\bin" to the path if exists and not done already
  $GIT_INSTALL_ROOT_ESC=$GIT_INSTALL_ROOT.replace('\','\\')
  if ((test-path "$GIT_INSTALL_ROOT\usr\bin") -and -not ($env:path -match "$GIT_INSTALL_ROOT_ESC\\usr\\bin")) {
      $env:path = "$env:path;$GIT_INSTALL_ROOT\usr\bin"
  }

  # Add "$GIT_INSTALL_ROOT\mingw[32|64]\bin" to the path if exists and not done already
  if ((test-path "$GIT_INSTALL_ROOT\mingw32\bin") -and -not ($env:path -match "$GIT_INSTALL_ROOT_ESC\\mingw32\\bin")) {
      $env:path = "$env:path;$GIT_INSTALL_ROOT\mingw32\bin"
  } elseif ((test-path "$GIT_INSTALL_ROOT\mingw64\bin") -and -not ($env:path -match "$GIT_INSTALL_ROOT_ESC\\mingw64\\bin")) {
      $env:path = "$env:path;$GIT_INSTALL_ROOT\mingw64\bin"
  }
}

function Import-Git(){

    $GitModule = Get-Module -Name Posh-Git -ListAvailable
    if($GitModule | select version | where version -le ([version]"0.6.1.20160330")){
        Import-Module Posh-Git > $null
    }
    if($GitModule | select version | where version -ge ([version]"1.0.0")){
        Import-Module Posh-Git > $null
        $GitPromptSettings.AnsiConsole = $false
    }
    if(-not ($GitModule) ) {
        Write-Warning "Missing git support, install posh-git with 'Install-Module posh-git' and restart cmder."
    }
    # Make sure we only run once by alawys returning true
    return $true
}

function checkGit($Path) {  
    if (Test-Path -Path (Join-Path $Path '.git') ) {
      if($env:gitLoaded -eq 'false') {
        $env:gitLoaded = Import-Git
      }

      if (getGitStatusSetting -eq $true) {
        Write-VcsStatus
      } else {
        $headContent = Get-Content (Join-Path $Path '.git/HEAD')
        if ($headContent -like "ref: refs/heads/*") {
            $branchName = $headContent.Substring(16)
        } else {
            $branchName = "HEAD detached at $($headContent.Substring(0, 7))"
        }
        Write-Host " [$branchName]" -NoNewline -ForegroundColor White
      }

      return
    }
    $SplitPath = split-path $path
    if ($SplitPath) {
        checkGit($SplitPath)
    }
}

function getGitStatusSetting() {
    $gitStatus = (git --no-pager config -l) | out-string

    ForEach ($line in $($gitStatus -split "`r`n")) {
        if ($line -match 'cmder.status=false' -or $line -match 'cmder.psstatus=false') {
            return $false
        }
    }

    return $true
}
