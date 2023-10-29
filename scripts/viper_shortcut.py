import list_connected_blutooth_devices
import bluetooth_reconnect
import subprocess
import enum
import os
import sys
import time

reconnect_bluetooth = sys.argv[-1] == "-r"

class AudioDevices(enum.Enum):
    ACTIVE = enum.auto()
    SPEAKERS = enum.auto()
    MDR_XB55AB = enum.auto()
    WF_XB700 = enum.auto()
    CCA_CRA = enum.auto()

maybe_custom_viper_path = "/home/issac/0Git/Viper4Linux/viper"
if not os.path.exists(maybe_custom_viper_path):
    maybe_custom_viper_path = "viper"
    # subprocess.check_output(["notify-send", "-t", "1000", "custom viper not found"])


configs_path="/home/issac/.config/viper4linux/"

configs = {
    AudioDevices.ACTIVE: "audio.conf",
    AudioDevices.SPEAKERS: "presets/laptop-speakers.conf",
    AudioDevices.MDR_XB55AB: "presets/mdr-xb55ab-salisilic.conf",
    AudioDevices.WF_XB700: "presets/wf-xb-700-smol-bass-boost.conf",
    AudioDevices.CCA_CRA: "presets/cra-smol-bass-boost.conf",
}

def check_if_wf_xb700_connected():
    blutooth_devices = list_connected_blutooth_devices.list_connected_devices()
    found_wf_xb700 = False
    if "WF-XB700" in [d.name for d in blutooth_devices]:
        found_wf_xb700 = True
        # print("wf_xb700 connected")
    return found_wf_xb700

def check_if_wired_headphone_connected():
    # cat /proc/asound/card0/codec\#0 | less
    # commands = "grep -A 4 'Node 0x21' /proc/asound/card0/codec#0 |  grep 'Amp-Out vals:  \[0x00 0x00\]'"
    output = subprocess.check_output(["grep", "-A", "4", "Node 0x21", "/proc/asound/card0/codec#0"])
    output = [p.strip(" ") for p in str(output).replace("\\n", ", ").split(", ") if "Amp-Out vals:  " in p][0]

    found_mdr_xb55ap = False
    if output == "Amp-Out vals:  [0x00 0x00]":
        found_mdr_xb55ap = True
        # print("mdr_xb55ap connected")
    return found_mdr_xb55ap

def choose_correct_device():
    required_audio_device = AudioDevices.SPEAKERS
    if check_if_wired_headphone_connected():
        required_audio_device = AudioDevices.CCA_CRA
    if check_if_wf_xb700_connected():
        required_audio_device = AudioDevices.WF_XB700
        if reconnect_bluetooth:
            subprocess.check_output(["notify-send", "-t", "1000", "reconnecting bluetooth device"])
            bluetooth_reconnect.reconnect_wb700()
            # time.sleep(1)
    return required_audio_device

def set_config_file():
    required_audio_device = choose_correct_device()
    active_config_path = configs_path + configs[AudioDevices.ACTIVE]
    required_config_path = configs_path + configs[required_audio_device]
    subprocess.check_output(["cp", required_config_path, active_config_path])
    subprocess.check_output(["notify-send", "-t", "1000", f"{required_audio_device}".split(".")[1]])

def restart_viper():
    # restart viper and set correct volume
    sound_level = subprocess.check_output(["amixer", "sget", "Master"])
    sound_level = [p.strip(" ") for p in str(sound_level).split("\\n") if "Front Left: " in p][0].split()[-2].strip("[]")
    subprocess.check_output([maybe_custom_viper_path, "restart"])
    subprocess.check_output(["amixer", "set", "Master", sound_level])

if __name__ == "__main__":
    set_config_file()

    # viper restarts on blutooth reconnections already cuz of blutooth_detect.py script
    if not reconnect_bluetooth:
        restart_viper()
        