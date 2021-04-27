# iUFCExport-LuaScript
Script for DCS (https://www.digitalcombatsimulator.com/) to export plane UFCs (or other panels)

## How to install
- Check if you already have a `Scripts` folder inside your DCS Saved Games folder. The usual path is `<your_home>\Saved Games\DCS\Scripts`.
  - If you don't, then create this `Scripts` folder.
- Go to that `Scripts` folder and check if you already have a file name `Export.lua`.
  - If you don't, download the `Exports.lua` file provided from the [latest release](https://github.com/wluc9875/iUFCExport-LuaScript/releases/latest) and copy it to your `Scripts` folder.
  - If you do, add the content of the `Exports.lua` file provided in this project to the end of the existing `Exports.lua`.
- Finally, download the `iUFCExport.lua` file from the [latest release](https://github.com/wluc9875/iUFCExport-LuaScript/releases/latest) and copy it to your `Scripts` folder

## Configure Windows 10 Firewall
The following configuration is required to let your PC accept the incoming commands from your iPad and to let the content of your UFC displays to reach your iPad.

Run application `Windows PowerShell` **as an Administrator**.
1) execute the following command to open the inbound channel
````
New-NetFirewallRule -DisplayName "iUFCExport inbound" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 7676
````
2) execute the following command to open the outbound channel
````
New-NetFirewallRule -DisplayName "iUFCExport outbound" -Direction Outbound -Action Allow -Protocol UDP -LocalPort 7677
````
If you prefer to configure these rules with the `Windows Defender Firewall with Advanced Security` application, please follow this [link](./config-firewall.md). Note that configuring the outbound rule goes through similar steps, except that you have to use port 7677 instead of 7676.

## Troubleshooting

### DCS doesn't update the displays on the iPad

Sometimes, your local network router may not accept local multicast and you wouldn't see anything displayed in the UFCs on your iPad (like the ODU/OSB texts).

In that case, you will have to try another outbound IP address. You would have to replace the `224.0.0.1` address in this line of the iUFCExport.lua script.

```
iUFCExport.HOST = "224.0.0.1" -- local network multicast IP address
```

There are 2 options. They require you to get your iPad IP address. You can get your iPad IP address by going to `Settings > Wi-Fi`. Then select your wifi network in the list.  The address you're looking for is in the line `IP address`.

#### Option 1

Use your iPad IP address, replacing the last of the 4 numbers by 255. This will allow for a local broadcast.

For example, if your address is something like `192.168.1.33`, use `192.168.1.255`.

If it works for you, fine, you won't need to change it again.

#### Option 2
Use your iPad IP address.

Unfortunately, if only this option works for you, then you won't be able to drive several iPads from DCS.

### Ports 7676 and 7677 are already taken by other applications

In rare cases, you may have to adjust the base port used to communicate with your iPad. By default it's 7676.

To do that, check this line in the `iUFCExport.lua` file:

 ```
 iUFCExport.OUTBOUND_PORT = 7676 -- change this port if already taken. If you do that, don't forget to adjust the iPad application ports too.
 ```

and replace `7676` by the port of your choice (as long as it's between 1024 and 65534).

Don't forget to:
* adjust the base port on your iPad application, as explained here: https://github.com/wluc9875/iUFCExport-iPad#configuring-other-ports
* adapt your Windows 10 Firewall rules to use your new ports (base port and base port + 1)