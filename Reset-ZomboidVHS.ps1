#requires -version 2
<#
.SYNOPSIS
  Resets watched VHS/CD lines from a Multiplayer game of Project Zomboid for a
  specified user
.DESCRIPTION
  This script edits recorded_media.bin, which is stored locally for PZ 
  Multiplayer games (LOL), in order to make a player "forget" the watched 
  VHS/CD lines. Useful if the character dies and you want to watch them 
  again, but can of course be misused.
.PARAMETER server_name
  Hostname or IP you specified to connect to the PZ server
.PARAMETER server_port
  Port num that you specified to connnect (default: 16261)
.PARAMETER username
  Whichever username you used to connect, NOT the player name
.INPUTS
  %USERPROFILE\Zomboid\Saves\Multiplayer\...\recorded_media.bin
.OUTPUTS
  Edits the input file and writes a backup to:
  %USERPROFILE\Zomboid\Saves\Multiplayer\...\recorded_media.bin.bak
.NOTES
  Version:        1.0
  Author:         Imanol-Mikel Barba Sabariego
  Creation Date:  2022/04/09
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\Reset-ZomboidVHS.ps1 -server_name xxxx -server_port xxxx -username xxxx
#>

param(
     [Parameter(Mandatory=$true)]
     [string]$server_name,
 
     [Parameter(Mandatory=$true)]
     [int]$server_port,

     [Parameter(Mandatory=$true)]
     [string]$username
 )

$DEFAULT_PZ_SAVE_PATH = $env:USERPROFILE + "\Zomboid\Saves\Multiplayer"

function Backup-File([string]$filename) {
    # Build destination file path
    $src = [io.FileInfo]($filename)
    $dst = [io.FileInfo]($filename + ".bak")

    # Copy the file
    Copy-Item $src.FullName $dst.FullName

    # Make sure file was copied and exists before copying over properties/attributes
    if ($dst.Exists) {
        $dst.CreationTime = $src.CreationTime
        $dst.LastAccessTime = $src.LastAccessTime
        $dst.LastWriteTime = $src.LastWriteTime
        $dst.Attributes = $src.Attributes
        $dst.SetAccessControl($src.GetAccessControl())
    } else {
        throw [System.IO.FileNotFoundException] "$dst not created. Aborting"
    }
}

function Reset-ZomboidVHS([string]$server_name, [int]$server_port, [string]$username) {
    $username_hash = [System.BitConverter]::ToString(
        $md5.ComputeHash(
            [system.Text.Encoding]::UTF8.GetBytes($username)
        )
    ).ToLower() -replace '-', ''

    $target_file = "{0}\{1}_{2}_{3}\recorded_media.bin" -f $DEFAULT_PZ_SAVE_PATH,$server_name,$server_port,$username_hash
    if(Test-Path $target_file) {
        Backup-File -filename $target_file
        $fd = [System.IO.File]::Open($target_file, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
        $buf = New-Object byte[] 4
        # Skip first byte 
        $fd.Seek(4, [System.IO.SeekOrigin]::Begin) | Out-Null
        # Read second byte
        $fd.Read($buf, 0, 4) | Out-Null
        # Reverse, since the number is BE
        [array]::Reverse($buf)
        $num_entries = [System.BitConverter]::ToUInt32($buf,0)
        # Every entry in this offset is an uint16 and the string representation
        # of an uuid (36 bytes).
        $offset = $num_entries * (36 + 2)
        $buf = New-Object byte[] 8
        $fd.Seek($offset, [System.IO.SeekOrigin]::Current) | Out-Null
        $fd.Write($buf, 0, 8)
        $fd.SetLength(8 + $offset + 8)
        $fd.Close()
        Write-Output "Successfully reset VHS!"
    } else {
        Write-Error ("Unable to find target save file {0}. Check input parameters" -f $target_file)
    }
}

Reset-ZomboidVHS -server_name $server_name -server_port $server_port -username $username