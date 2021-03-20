# jamfStatus
Download: [jamfStatus](https://github.com/jamfprofessionalservices/jamfStatus/releases/download/current/jamfStatus.zip)

Keep an eye on the status of Jamf Cloud with jamfStatus.  The app will place an icon in the menu bar to reflect the current cloud status.

<img src="./jamfStatus/images/menubar.png" alt="menu bar" width="200" />
<p>
An alert window will be displayed as the cloud status changes.  You can configure how the alert window display refreshes, either at every status check or only when the status changes.

For minor Jamf Cloud issues something similar to the following be displayed.

<img src="./jamfStatus/images/alert.png" alt="alert" width="700" />

For major Jamf Cloud issues something similar to the following be displayed.

<img src="./jamfStatus/images/major.png" alt="alert" width="700" />

Access Preferences from the menu bar icon.  Here you'll be able to set the following:<br>
- Polling interval.<br>
- Whether the alert window is displayed at every polling interval or only when the status changes.<br>
- How the menubar icon is displayed.  Minimizing will place a thin transparent icon in the menubar.<br>
- Use of a LaunchAgent, to automatically start the app when logging in.*<br>
- Information for your specific Jamf Cloud instance. The account used only needs to be able to authenticate, no need to assign permissions. If your cloud server does not utilize the HTTPS port 443 be sure to include the port you use in the URL.<br>

<img src="./jamfStatus/images/prefs.png" alt="notifications" width="600" /><br>

There are two different menu bar icon styles to choose from.  One uses colors to indicate the status and the other uses slashes.<br><br>
            <div style="margin-left: 55px;">
               <table>
                  <tr>
                    <th>Status</th>
                    <td>minor</td>
                    <td>major</td>
                    <td>minor</td>
                    <td>major</td>
                  </tr>
                  <tr>
                    <th>Icon</th>
                    <td><img src="./jamfStatus/images/minor1.png" id="Image2" alt=""></th>
                     <td><img src="./jamfStatus/images/major1.png" id="Image2" alt=""></th>
                        <td><img src="./jamfStatus/images/minor2.png" id="Image2" alt=""></th>
                           <td><img src="./jamfStatus/images/major2.png" id="Image2" alt=""></th>
                  </tr>
                </table></div><br>

Notifications, if any, will appear after the next polling cycle once the information has been entered.

<img src="./jamfStatus/images/notifications.png" alt="Preferences" width="600" />

Status changes are logged to ~/Library/Logs/jamfStatus/jamfStatus.log.  Once the log exceeds 5MB it will be zipped and a new log will be created.  A maximum of 10 zipped log files are retained.  Sample log data:

```
Thu Sep 17 20:24:30 Jamf Cloud Critical Issue Alert
Thu Sep 17 20:24:30 Please be aware there is a major issue that may affect your Jamf Cloud instance.
Thu Sep 17 20:24:30    eu-central-1: JCDS: Major Outage
Thu Sep 17 20:24:30    Jamf Cloud Distribution Service (JCDS): Major Outage

Thu Sep 17 20:25:30 Jamf Cloud Minor Issue Alert
Thu Sep 17 20:25:30 Please be aware there is a minor issue that may affect your Jamf Cloud instance.
Thu Sep 17 20:25:30    Compute Services - US: Degraded Performance
Thu Sep 17 20:25:30    Database Services - US: Degraded Performance

Thu Sep 17 20:27:30 Notice
Thu Sep 17 20:27:30 Jamf Cloud: All systems go.
```
