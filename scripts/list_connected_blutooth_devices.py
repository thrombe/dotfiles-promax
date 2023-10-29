import pydbus

bus = pydbus.SystemBus()

adapter = bus.get('org.bluez', '/org/bluez/hci0')
mngr = bus.get('org.bluez', '/')
quiet = True

class Device:
    def __init__(self, name, addr):
        self.name = name
        self.addr = addr

def list_connected_devices():
    connected_devices = []
    mngd_objs = mngr.GetManagedObjects()
    for path in mngd_objs:
        con_state = mngd_objs[path].get('org.bluez.Device1', {}).get('Connected', False)
        if con_state:
            addr = mngd_objs[path].get('org.bluez.Device1', {}).get('Address')
            name = mngd_objs[path].get('org.bluez.Device1', {}).get('Name')
            if not quiet:
                print(f'Device {name} [{addr}] is connected')
            connected_devices.append(Device(name, addr))
    return connected_devices

if __name__ == '__main__':
    quiet = False
    list_connected_devices()
