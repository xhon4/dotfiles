#!/usr/bin/env python3
# r4chi-dotfiles · by occhi

import subprocess
import time

from pypresence import Presence

CLIENT_ID = "1263505205522337883"
UPDATE_INTERVAL = 15


def get_metadata() -> tuple[str | None, str | None]:
    try:
        title = subprocess.check_output(
            ["playerctl", "metadata", "xesam:title"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
        artist = subprocess.check_output(
            ["playerctl", "metadata", "xesam:artist"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
        return title, artist
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None, None


def main() -> None:
    rpc = Presence(CLIENT_ID)
    rpc.connect()
    try:
        while True:
            title, artist = get_metadata()
            if title and artist:
                rpc.update(
                    details=title,
                    state=artist,
                    large_image="music",
                    large_text="Audacious",
                )
            else:
                rpc.clear()
            time.sleep(UPDATE_INTERVAL)
    except KeyboardInterrupt:
        pass
    finally:
        rpc.close()


if __name__ == "__main__":
    main()
