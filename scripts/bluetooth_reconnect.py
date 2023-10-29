
# WARNING!!! bad code

import subprocess
from list_connected_blutooth_devices import list_connected_devices, Device

earbuds_name = "WF-XB700"
earbuds_addr = None # mac address

def reconnect_wb700():
    connected = list_connected_devices()
    for d in connected:
        if d.name == earbuds_name:
            earbuds_addr = d.addr
    
    if earbuds_addr is None:
        earbuds_addr = get_earbuds_addr_from_paired()
        if earbuds_addr is None:
            return
        earbuds_addr = d.addr


    # import bluedot
    # a = bluedot.btcomm.BluetoothAdapter()
    # a.powered = False # setter turns bluetooth off
    # a.powered = True
    
    # execute("bluetoothctl power off")
    # execute("bluetoothctl power on")

    # disconnecting is slower than power off, but its more reliable
    execute(f"bluetoothctl disconnect {earbuds_addr}")
    execute(f"bluetoothctl connect {earbuds_addr}")

def execute(command):
    subprocess.check_output(
        [command],
        shell=True,
        stderr=subprocess.STDOUT, # mutes output
        )



def get_earbuds_addr_from_paired():
    out = subprocess.check_output(
        ["bluetoothctl paired-devices"],
        shell=True,
        stderr=subprocess.STDOUT, # mutes output
    )
    out = str(out).strip("'b").split("\\n")
    out = [o.lstrip("Device ") for o in out if o != ""]
    out = [o.split(" ", maxsplit=1) for o in out]
    out = [Device(o[1], o[0]) for o in out]
    for d in out:
        if d.name == earbuds_name:
            return d.addr

if __name__ == "__main__":
    reconnect_wb700()

