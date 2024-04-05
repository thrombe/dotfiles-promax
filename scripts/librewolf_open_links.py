import os
import select
import sys
import threading
import time
import subprocess
import pyperclip
import copy
from colorama import Fore, Back, Style

# def open_links_from_stdin():
#     inp = {"input": ""}
#     (pipe_read, pipe_write) = os.pipe()
#     thread = threading.Thread(target=printer_loop, args=(pipe_read, inp))
#     thread.start()
#     time.sleep(1)

#     # Interrupting thread
#     os.write(pipe_write, b'.')

#     thread.join()

#     inp = inp["input"]
#     open_links_in_librewolf(inp)


def open_links_in_librewolf(inp, profile=None):
    links = []
    for line in inp.splitlines():
        # print(line)
        if "](" not in line:
            if line.startswith("http"):
                links.append(line)
        else:
            try:
                i = line.index("](")
                link = line[i + 2 : -1]
                links.append(link)
            except Exception:
                pass

    if len(links) < 1:
        print(
            Style.BRIGHT
            + Fore.RED
            + "\nERROR:\nNo links found in the clipboard."
            + Style.RESET_ALL
        )
        time.sleep(1)
        return
    if profile is None:
        browser = ["librewolf"]
    else:
        browser = ["librewolf", "--profile", f"{profile}"]

    new_window = copy.copy(browser)
    new_window.extend(["--new-window", f"{links[0]}"])
    # subprocess.run([f"{browser} --new-window '{links[0]}'", ], shell=True)
    subprocess.Popen(
        new_window,
        start_new_session=True,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    time.sleep(1)
    for link in links[1:]:
        new_tab = copy.copy(browser)
        new_tab.extend(["--new-tab", f"{link}"])
        # subprocess.run([f"{browser} --new-tab '{link}'", ], shell=True)
        subprocess.run(new_tab)


def open_links_from_clipboard(profile=None):
    clipb_contents = pyperclip.paste()
    print("clipboard contents:\n")
    print(clipb_contents)
    open_links_in_librewolf(clipb_contents, profile)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        profile = sys.argv[1]
        open_links_from_clipboard(profile)
    else:
        open_links_from_clipboard()
