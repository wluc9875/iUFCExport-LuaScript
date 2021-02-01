# iUFCExport-LuaScript
Script for DCS (https://www.digitalcombatsimulator.com/) to export plane UFCs (or other panels)

## How to install
- Check if you already have a `Scripts` folder inside your DCS Saved Games folder. The usual path is `<your_home>\Saved Games\DCS\Scripts`.
  - If you don't, then create this `Scripts` folder.
- Go to that `Scripts` folder and check if you already have a file name `Export.lua`.
  - If you don't, copy the `Exports.lua` file provided in this project to your `Scripts` folder.
  - If you do, add the content of the `Exports.lua` file provided in this project to the end of the existing `Exports.lua`.
- Finally, copy the `iUFCExport.lua` file to your `Scripts` folder

## Configure Windows 10 Firewall
The following configuration is required to let your PC accept the incoming commands from your iPad.

### Step 1: Open "Firewall and network protection" settings
You can find it in your Windows settings.
![STEP1](./doc-resources/step1.PNG)

### Step 2: Click on "Advanced settings"
![STEP2](./doc-resources/step2.PNG)
This will open the application: "Windows Defender Firewall with Advanced Security"

### Step 3: Select "Inbound rules"
![STEP3](./doc-resources/step3.PNG)

### Step 4: Click on "New Rule..."
![STEP4](./doc-resources/step4.PNG)
This will open an inbound rule creation wizard.

### Step 5: Select type of rule "Port"
![STEP5](./doc-resources/step5.PNG)
Then click "Next"

### Step 6: Select protocol and ports
For the protocol, choose "UDP".
For the ports, select "Specific local ports" and enter value 7677.
![STEP6](./doc-resources/step6.PNG)
Then click "Next"

### Step 7: Select action: "Allow the connection"
![STEP7](./doc-resources/step7.PNG)
Then click "Next"

### Step 8: Leave profile selection by default
![STEP8](./doc-resources/step8.PNG)
Then click "Next"

### Step 9: Give the rule a name and description
You can enter the suggested texts below or just use the texts you'd like.
![STEP9](./doc-resources/step9.PNG)

That's it!

