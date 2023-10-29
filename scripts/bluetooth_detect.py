

# https://gist.github.com/altbrace/52ae1783b31257021520673fadb95b6e

from pydbus import SystemBus
from gi.repository import GLib  # don't mind the import error if you get one, it should work
import subprocess
import time

import viper_shortcut

ADDRESS = '74:45:CE:D7:E7:99'.replace(":", "_")  # your Bluetooth device's MAC separated by underscores
last_time = 0.0

def event_callback(sender=None, iface=None, signal=None, object=None, arg0=None):
    global last_time
    dev_api = dev['org.bluez.Device1']
    if dev_api.Connected:
        if time.time() - last_time > 5:
            last_time = time.time()
        else:
            print("detected connect. but returning")
            return
        print(f"Device {ADDRESS} connected")
        viper_shortcut.set_config_file()
        time.sleep(3)
        viper_shortcut.restart_viper()
    else:
        print(f"Device {ADDRESS} disconnected.")


bus = SystemBus()
dev = bus.get('org.bluez', f'/org/bluez/hci0/dev_{ADDRESS}')  # get the device by dbus path

listener = bus.subscribe(iface='org.freedesktop.DBus.Properties', signal='PropertiesChanged',
                         object=f'/org/bluez/hci0/dev_{ADDRESS}',
                         arg0='org.bluez.Device1', signal_fired=event_callback)

loop = GLib.MainLoop()
loop.run()
