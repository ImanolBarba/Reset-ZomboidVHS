# Reset-ZomboidVHS
Resets VHS watched on a Multiplayer server for a specified username 

Why use this?
--
Currently, there is an issue that prevents a playing charater from earning XP on tapes seen by previous characters in the same Multiplayer Server, while logging in with the same username. See:

https://theindiestone.com/forums/index.php?/topic/49635-build-4166-mp-vhs-tapes-do-not-give-xp-if-already-watched-by-previous-players/

This is expected to be fixed at some point, in the meantime, feel free to use this script.

NOTE: Because the devs decided that local storage is a great idea for Multiplayer save data to be stored, this means that someone can exploit this to rewatch VHS all the time in a MP game and earn infinite XP. Use responsibly!

How to use this?
--
On a powershell console:

```
PS C:\Users\imanol> .\Reset-ZomboidVHS.ps1 -server_name xxxx -server_port xxxx -username xxxx
```

Alternatively, just double click the script and it'll ask for the parameters interactively.

See:
```
.PARAMETER server_name
  Hostname or IP you specified to connect to the PZ server
.PARAMETER server_port
  Port num that you specified to connnect (default: 16261)
.PARAMETER username
  Whichever username you used to connect, NOT the player name
```

Oh no, something went HORRIBLY wrong!
--
Don't worry, this script backs up the `recorded_media.bin` file in the same directory that it edits it, so just replace the file back and everything's gucci

The file is in `%USERPROFILE%\Zomboid\Saves\Multiplayer\${server_name}_${server_port}_$(md5{username})/recorded_media.bin`

It'll also be shown in the script output

Cheers
