#!/usr/bin/env python3

import argparse
import hashlib
import logging
import os
import shutil
import struct
import sys
import traceback

# Constants

# Seems to be consistent between Linux and macOS
DEFAULT_PZ_SAVE_PATH = f"{os.environ.get('HOME')}/Zomboid/Saves/Multiplayer"

# Globals
logger = None


def backupFile(filename: str) -> bool:
    try:
        shutil.copy2(filename, f"{filename}.bak")
        return True
    except Exception as e:
        # yes, yes catching all is a bad idea, but literally SO MANY things can
        # go wrong, you could have no permission, no disk space, read-only, etc
        # As long as we fail in any case and notify the user gracefully it 
        # should be fine
        logger.error(f"Failed to write backup: {str(e)}")
        logger.error(f"Stacktrace:\n{traceback.format_exc()}")
    return False


def resetZomboidVHS(server_name: str, server_port: int, username: str) -> bool:
    usernameHash = hashlib.md5(username.encode('utf-8')).hexdigest()
    targetFile = f"{DEFAULT_PZ_SAVE_PATH}/{server_name}_{server_port}_{usernameHash}/recorded_media.bin"

    if os.path.exists(targetFile):
        print(f"Editing {targetFile}...")
        if not backupFile(targetFile):
            print("Backup not created. Aborting...")
            return False
        print(f"Backed up to {targetFile}.bak")
        
        with open(targetFile, "rb+") as fd:
            # Skip first uint32 (No idea what it is, seems to be always 1)
            fd.seek(4)
            # Read second uint32 with BE ordering
            numEntries = struct.unpack(">I",fd.read(4))[0]
            # Every entry in this offset is an uint16 and the string representation
            # of an uuid (36 bytes).
            offset = numEntries * (2 + 36)
            fd.seek(offset, 1)
            fd.write(b'\x00' * 8)
            fd.truncate(8 + offset + 8)
            print("Successfully reset VHS!")
        return True
    else:
        print(f"Unable to find target save file {targetFile}. Check input parameters")
    return False


def main() -> int:
    global logger
    logging.basicConfig(format='%(levelname)s - %(asctime)s [%(filename)s:%(lineno)d %(funcName)s()] %(message)s', level=logging.INFO)
    logger = logging.getLogger(__name__)

    if sys.version_info.major < 3 or (sys.version_info.major == 3 and sys.version_info.minor < 7):
        logger.error("This bot requires at least Python 3.7 to run")
        exit(1)
    
    parser = argparse.ArgumentParser(description="Reset Zomboid VHS tapes")
    parser.add_argument("--server-name", type=str, required=True, help="Hostname or IP you specified to connect to the PZ server")
    parser.add_argument("--server-port", type=int, required=True, default=16261, help="Port num that you specified to connnect (default: 16261)")
    parser.add_argument("--username", type=str, required=True, help="Hostname or IP you specified to connect to the PZ server")
    args = parser.parse_args()

    if resetZomboidVHS(args.server_name, args.server_port, args.username):
        return 0
    return 1
    

if __name__ == "__main__":
    exit(main())