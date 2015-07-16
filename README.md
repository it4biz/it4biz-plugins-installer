# it4biz-plugins-installer
IT4biz Plugins Installer

it4biz-plugins-installer.sh is a shell script to install the IT4biz plugins into a pentaho installation.

You also can install using the Pentaho Marketplace in your BI Portal.

Currently supports Saiku Chart Plus.

Requirements: Linux, macintosh or windows with cygwin, wget, unzip

Usage: it4biz-plugins-installer.sh -s solutionPath [-w pentahoWebapPath] [-b branch] [-y]

Please backup your solution, we're not resposible by any harm this does to your server.

This readme text and the it4biz-plugins-installer.sh was adapted from the original version avaible at https://github.com/pmalves/ctools-installer by Pedro Alves.

Example:

```
git clone https://github.com/it4biz/it4biz-plugins-installer.git
sudo ./it4biz-plugins-installer.sh -s /Applications/Pentaho/BIServer/biserver-ce-5.4/biserver-ce/pentaho-solutions/ -w /Applications/Pentaho/BIServer/biserver-ce-5.4/biserver-ce/tomcat/webapps/pentaho -b dev --no-update -c saikuchartplus
```



