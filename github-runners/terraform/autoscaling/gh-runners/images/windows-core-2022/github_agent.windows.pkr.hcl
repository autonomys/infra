packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "runner_version" {
  description = "The version (no v prefix) of the runner software to install https://github.com/actions/runner/releases. The latest release will be fetched from GitHub if not provided."
  default     = null
}

variable "region" {
  description = "The region to build the image in"
  type        = string
  default     = "us-west-2"
}

variable "security_group_id" {
  description = "The ID of the security group Packer will associate with the builder to enable access"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "If using VPC, the ID of the subnet, such as subnet-12345def, where Packer will launch the EC2 instance. This field is required if you are using an non-default VPC"
  type        = string
  default     = null
}

variable "root_volume_size_gb" {
  type    = number
  default = 100
}

variable "ebs_delete_on_termination" {
  description = "Indicates whether the EBS volume is deleted on instance termination."
  type        = bool
  default     = true
}

variable "associate_public_ip_address" {
  description = "If using a non-default VPC, there is no public IP address assigned to the EC2 instance. If you specified a public subnet, you probably want to set this to true. Otherwise the EC2 instance won't have access to the internet"
  type        = string
  default     = null
}

variable "custom_shell_commands" {
  description = "Additional commands to run on the EC2 instance, to customize the instance, like installing packages"
  type        = list(string)
  default     = []
}

variable "temporary_security_group_source_public_ip" {
  description = "When enabled, use public IP of the host (obtained from https://checkip.amazonaws.com) as CIDR block to be authorized access to the instance, when packer is creating a temporary security group. Note: If you specify `security_group_id` then this input is ignored."
  type        = bool
  default     = false
}

data "http" github_runner_release_json {
  url = "https://api.github.com/repos/actions/runner/releases/latest"
  request_headers = {
    Accept = "application/vnd.github+json"
    X-GitHub-Api-Version : "2022-11-28"
  }
}

locals {
  runner_version = coalesce(var.runner_version, trimprefix(jsondecode(data.http.github_runner_release_json.body).tag_name, "v"))
}

source "amazon-ebs" "githubrunner" {
  ami_name                                  = "github-runner-windows-core-2022-${formatdate("YYYYMMDDhhmm", timestamp())}"
  communicator                              = "winrm"
  instance_type                             = "m4.xlarge"
  region                                    = var.region
  security_group_id                         = var.security_group_id
  subnet_id                                 = var.subnet_id
  associate_public_ip_address               = var.associate_public_ip_address
  temporary_security_group_source_public_ip = var.temporary_security_group_source_public_ip

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-ECS_Optimized-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  tags = {
    OS_Version    = "windows-core-2022"
    Release       = "Latest"
    Base_AMI_Name = "{{ .SourceAMIName }}"
  }
  user_data_file = "./bootstrap_win.ps1"
  winrm_insecure = true
  winrm_port     = 5986
  winrm_use_ssl  = true
  winrm_username = "Administrator"

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = "${var.root_volume_size_gb}"
    delete_on_termination = "${var.ebs_delete_on_termination}"
  }
}

build {
  name = "githubactions-runner"
  sources = [
    "source.amazon-ebs.githubrunner"
  ]

  provisioner "file" {
    source = "../installer.ps1"
    destination = "/tmp/installer.ps1"
  }

  provisioner "powershell" {
    inline = [
      "powershell -ExecutionPolicy Bypass -File /tmp/installer.ps1",
      "$ErrorActionPreference = \"Continue\"",
      "$VerbosePreference = \"Continue\"",
      "Start-Transcript -Path \"C:\\UserData.log\" -Append",

      "# Install Chocolatey",
      "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12",
      "$env:chocolateyUseWindowsCompression = 'true'",
      "Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression",

      "# Add Chocolatey to powershell profile",
      "$ChocoProfileValue = @'",
      "$ChocolateyProfile = \"$env:ChocolateyInstall\\helpers\\chocolateyProfile.psm1\"",
      "if (Test-Path($ChocolateyProfile)) {",
      "  Import-Module \"$ChocolateyProfile\"",
      "}",

      "refreshenv",
      "'@",
      "# Write it to the $profile location",
      "Set-Content -Path \"$PsHome\\Microsoft.PowerShell_profile.ps1\" -Value $ChocoProfileValue -Force",
      "# Source it",
      ". \"$PsHome\\Microsoft.PowerShell_profile.ps1\"",

      "refreshenv",

      "Write-Host \"Installing cloudwatch agent...\"",
      "Invoke-WebRequest -Uri https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi -OutFile C:\\amazon-cloudwatch-agent.msi",
      "$cloudwatchParams = '/i', 'C:\\amazon-cloudwatch-agent.msi', '/qn', '/L*v', 'C:\\CloudwatchInstall.log'",
      "Start-Process \"msiexec.exe\" $cloudwatchParams -Wait -NoNewWindow",
      "Remove-Item C:\\amazon-cloudwatch-agent.msi",

      "# Install dependent tools",
      "Write-Host \"Installing additional development tools\"",
      "choco install git awscli -y",
      "refreshenv",

      "## Install rust and cargo",
      "# Ensure Chocolatey is installed",
      "if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {",
      "    Write-Host \"Installing Chocolatey...\"",
      "    Set-ExecutionPolicy Bypass -Scope Process -Force",
      "    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))",
      "}",

      "# Set environment variables for Rust",
      "$env:RUSTUP_HOME = \"C:\\Users\\Default\\.rustup\"",
      "$env:CARGO_HOME = \"C:\\Users\\Default\\.cargo\"",

      "# Ensure the directories exist",
      "New-Item -ItemType Directory -Path $env:RUSTUP_HOME, $env:CARGO_HOME -Force | Out-Null",

      "# Install Rust with Chocolatey",
      "choco install rust -y --params=\"'/AddToPath:1'\"",

      "# Add Rust binaries to the path for the current session",
      "$env:Path += \";$env:CARGO_HOME\\bin\"",

      "# Refresh environment to ensure Rust is available in the PATH",
      "refreshenv",

      "# Validate Rust installation",
      "rustc --version",
      "cargo --version",

      "# Install common tools with cargo",
      "rustup component add rustfmt --toolchain nightly",
      "rustup component add clippy --toolchain nightly",
      "rustup component add rust-src --toolchain nightly",
      "cargo install cargo-cache",
      "cargo install cargo-sweep",

      "# Cleanup Cargo crates cache",
      "Remove-Item \"$env:CARGO_HOME\\registry\\*\" -Recurse -Force",
      "Write-Host \"Rust and common toolsets have been successfully installed.\"",

      "# Install the latest stable version of llvm and clang compilers",
      "choco install llvm -y",

      "# Add LLVM to the system PATH",
      "$llvmPath = \"C:\\Program Files\\LLVM\\bin\"",
      "[Environment]::SetEnvironmentVariable(\"Path\", $env:Path + \";$llvmPath\", [System.EnvironmentVariableTarget]::Machine)",

      "# Refresh the current session's PATH",
      "$env:Path = [System.Environment]::GetEnvironmentVariable(\"Path\",\"Machine\")",

      "# Verify LLVM installation",
      "clang --version",
      "llvm-config --version",

      "Write-Host \"LLVM and Clang have been successfully installed and added to the PATH.\"",

      "# Disable Windows Defender",
      "Write-Host \"Disable Windows Defender...\"",
      "$avPreference = @(",
      "    @{DisableArchiveScanning = $true}",
      "    @{DisableAutoExclusions = $true}",
      "    @{DisableBehaviorMonitoring = $true}",
      "    @{DisableBlockAtFirstSeen = $true}",
      "    @{DisableCatchupFullScan = $true}",
      "    @{DisableCatchupQuickScan = $true}",
      "    @{DisableIntrusionPreventionSystem = $true}",
      "    @{DisableIOAVProtection = $true}",
      "    @{DisablePrivacyMode = $true}",
      "    @{DisableScanningNetworkFiles = $true}",
      "    @{DisableScriptScanning = $true}",
      "    @{MAPSReporting = 0}",
      "    @{PUAProtection = 0}",
      "    @{SignatureDisableUpdateOnStartupWithoutEngine = $true}",
      "    @{SubmitSamplesConsent = 2}",
      "    @{ScanAvgCPULoadFactor = 5; ExclusionPath = @(\"D:\\\", \"C:\\\")}",
      "    @{DisableRealtimeMonitoring = $true}",
      "    @{ScanScheduleDay = 8}",
      ")",

      "$avPreference += @(",
      "    @{EnableControlledFolderAccess = \"Disable\"}",
      "    @{EnableNetworkProtection = \"Disabled\"}",
      ")",

      "$avPreference | Foreach-Object {",
      "    $avParams = $_",
      "    Set-MpPreference @avParams",
      "}",

      "# https://github.com/actions/runner-images/issues/4277",
      "# https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/microsoft-defender-antivirus-compatibility?view=o365-worldwide",
      "$atpRegPath = 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows Advanced Threat Protection'",
      "if (Test-Path $atpRegPath) {",
      "    Write-Host \"Set Microsoft Defender Antivirus to passive mode\"",
      "    Set-ItemProperty -Path $atpRegPath -Name 'ForceDefenderPassiveMode' -Value '1' -Type 'DWORD'",
      "}",

      "# Install zstd",
      "Write-Host \"Install zstd\"",
      "Invoke-WebRequest -Uri \"https://raw.githubusercontent.com/horta/zstd.install/main/install.ps1\" -OutFile \"install_zstd.ps1\"",
      ".\\install_zstd.ps1",
      "Remove-Item \"install_zstd.ps1\"",

      "# Add zstd to the PATH",
      "$zstdPath = \"C:\\Program Files\\zstd\"",
      "[Environment]::SetEnvironmentVariable(\"Path\", $env:Path + \";$zstdPath\", [System.EnvironmentVariableTarget]::Machine)",
      "$env:Path = [System.Environment]::GetEnvironmentVariable(\"Path\",\"Machine\")",

      "# Install Visual Studio Code 2022 and extensions",
      "Write-Host \"Install Visual Studio Code 2022\"",
      "choco install visualstudio2022community -y",

      "# Add Visual Studio Code to the PATH",
      "$vscodePath = \"C:\\Program Files\\Microsoft VS Code\\bin\"",
      "[Environment]::SetEnvironmentVariable(\"Path\", $env:Path + \";$vscodePath\", [System.EnvironmentVariableTarget]::Machine)",
      "$env:Path = [System.Environment]::GetEnvironmentVariable(\"Path\",\"Machine\")",

      "# Install the Visual Studio Extensions from toolset.json",
      "Write-Host \"Install Visual Studio Extensions\"",
      "$toolset = Get-ToolsetContent",
      "$vsixPackagesList = $toolset.visualStudio.vsix",
      "if (-not $vsixPackagesList) {",
      "    Write-Host \"No extensions to install\"",
      "    exit 0",
      "}",

      "$vsixPackagesList | ForEach-Object {",
      "    # Retrieve cdn endpoint to avoid HTTP error 429",
      "    # https://github.com/actions/runner-images/issues/3074",
      "    $vsixPackage = Get-VsixInfoFromMarketplace $_",
      "    Write-Host \"Installing $vsixPackage\"",
      "    if ($vsixPackage.FileName.EndsWith(\".vsix\")) {",
      "        Install-VSIXFromUrl $vsixPackage.DownloadUri",
      "    } else {",
      "        Install-Binary `",
      "            -Url $vsixPackage.DownloadUri `",
      "            -InstallArgs @('/install', '/quiet', '/norestart')",
      "    }",
      "}",

      "# Setup PowerShellGet",
      "Write-Host \"Setup PowerShellGet\"",
      "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force",

      "# Specifies the installation policy",
      "Set-PSRepository -InstallationPolicy Trusted -Name PSGallery",

      "# Warmup PSModuleAnalysisCachePath (speedup first PowerShell invocation by 20s)",
      "Write-Host 'Warmup PSModuleAnalysisCachePath (speedup first PowerShell invocation by 20s)'",
      "$PSModuleAnalysisCachePath = 'C:\\PSModuleAnalysisCachePath\\ModuleAnalysisCache'",
      "[Environment]::SetEnvironmentVariable('PSModuleAnalysisCachePath', $PSModuleAnalysisCachePath, \"Machine\")",
      "$env:PSModuleAnalysisCachePath = $PSModuleAnalysisCachePath",
      "New-Item -Path $PSModuleAnalysisCachePath -ItemType 'File' -Force | Out-Null",

      "# User (current user, image generation only)",
      "if (-not (Test-Path $profile)) {",
      "    New-Item $profile -ItemType File -Force",
      "}",

      "@\"",
      "if (-not (Get-Module -ListAvailable -Name PowerHTML)) {",
      "    Install-Module PowerHTML -Scope CurrentUser",
      "}",
      "if (-not (Get-Module -Name PowerHTML)) {",
      "    Import-Module PowerHTML",
      "}",
      "\"@ | Add-Content -Path $profile -Force",

      "# Install AzureSignTool",
      "Write-Host \"Install AzureSignTool\"",
      "dotnet tool install --global AzureSignTool",
      "dotnet tool update --global AzureSignTool",

      "# Add .dotnet tools to the PATH",
      "$dotnetToolsPath = \"$env:USERPROFILE\\.dotnet\\tools\"",
      "[Environment]::SetEnvironmentVariable(\"Path\", $env:Path + \";$dotnetToolsPath\", [System.EnvironmentVariableTarget]::Machine)",
      "$env:Path = [System.Environment]::GetEnvironmentVariable(\"Path\",\"Machine\")",

      "dotnet dev-certs https --trust",
      "refreshenv"
    ]
  }

  provisioner "file" {
    content = templatefile("../start-runner.ps1", {
      start_runner = templatefile("../../../modules/runners/templates/start-runner.ps1", {})
    })
    destination = "C:\\start-runner.ps1"
  }

  provisioner "powershell" {
    inline = concat([
      templatefile("./windows-provisioner.ps1", {
        action_runner_url = "https://github.com/actions/runner/releases/download/v${local.runner_version}/actions-runner-win-x64-${local.runner_version}.zip"
      })
    ], var.custom_shell_commands)
  }
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
