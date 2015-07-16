#!/bin/bash

INSTALLER=`basename "$0"`
VER='1.0'

echo
echo IT4biz Plugins Installer
echo
echo it4biz-plugins-installer version $VER
echo
echo "Author: Caio Moreno de Souza (IT4biz)"
echo "Modify from the original ctools-installer.sh (https://github.com/pmalves/ctools-installer)"
echo Copyright IT4biz 2007-2015
echo
echo
echo Changelog:
echo
echo v1.0 - First release
echo
echo
echo "Disclaimer: we can't be responsible for any damage done to your system, which hopefully will not happen"
echo Note: it4biz-plugins-installer will upgrade the plugins under system directory.
echo "      Any changes you have made there will have to be backed up and manually copied after running the script"
echo


usage (){

	echo
	echo "Usage: it4biz-plugins-installer.sh -s solutionPath [-w pentahoWebapPath] [-b branch]"
	echo
	echo "-s    Solution path (eg: /biserver/pentaho-solutions)"
	echo "-w    Pentaho webapp server path (required for cgg on versions before 4.5. eg: /biserver-ce/tomcat/webapps/pentaho)"
	echo "-b    Branch from where to get ctools, stable for release, dev for trunk. Default is stable"
	echo "-c    Comma-separated list of CTools to install (Supported module-names: marketplace,cdf,cda,cde,cgg,cfr,sparkl,cdc,cdv,saiku,saikuadhoc,saikuchartplus)"
	echo "-y    Assume yes to all prompts"
	echo "--no-update Skip update of the ctools-installer.sh"
	echo "-n    Add newline to end of prompts (for integration with CBF)"
	echo "-r    Directory for storing offline files"
	echo "-h    This help screen"
	echo
	exit 1
}

cleanup (){
	#clean all things at the folder .tmp in the folder you execute the scripts
        rm -rf .tmp
}


# Parse options

[ $# -gt 1 ] || usage


SOLUTION_DIR='PATH'				# Variable name
WEBAPP_PATH='PATH'				# Show all matches (y/n)?
HAS_WEBAPP_PATH=0
BRANCH='stable'
ECHO_FLAG='-n'
MODULES=''
ASSUME_YES=false
NO_UPDATE=false
OFFLINE_REPOSITORY=''
BASERVER_VERSION=''

ORIGINAL_CMDS=$@

while [ $# -gt 0 ]
do
    case "$1" in
	--)	shift; break;;
	-s)	SOLUTION_DIR="$2"; shift;;
	-w)	WEBAPP_PATH="$2"; shift;;
	-b) BRANCH="$2"; shift;;
	-c) MODULES="$2"; shift;;
	-y)	ASSUME_YES=true;;
	--no-update) NO_UPDATE=true;;
	-n)	ECHO_FLAG='';;
	-r) OFFLINE_REPOSITORY="$2"; shift;;
	--)	break;;
	-*|-h)	usage ;;
    esac
    shift
done

[ "$SOLUTION_DIR" = 'PATH' ] && usage

if [ "$WEBAPP_PATH" != 'PATH' ]
then
HAS_WEBAPP_PATH=1
fi


if  [ $BRANCH != 'stable' ] && [ $BRANCH != 'dev' ]
then
	echo ERROR: Branch must either be stable or dev
	exit 1
fi

if [[ ! -d "$SOLUTION_DIR" ]]
then
	echo ERROR: Supplied solution path is not a directory
	exit 1
fi

if [[ ! -d "$SOLUTION_DIR/system" ]]
then
	echo "ERROR: Supplied solution path doesn't look like a valid pentaho solutions directory.  Missing system sub-directory."
	exit 1
fi

if [[ $HAS_WEBAPP_PATH -eq 1 ]]
then
	if [[ ! -d $WEBAPP_PATH/WEB-INF/lib ]]
	then

		echo "ERROR: Supplied webapp path doesn't look like a valid web application - missing WEB-INF/lib"
		exit 1
	fi

fi

if [[ -d "$SOLUTION_DIR/system/jackrabbit" ]]
then
	BASERVER_VERSION='5x'
else
	BASERVER_VERSION='4x'
fi

if [ "$OFFLINE_REPOSITORY" != "" ]
then
	mkdir -p "$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH"
	if [ $? != 0 ]; then
		echo "ERROR: Failed to create offline stage directory: $OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH"
		exit 1
	fi
fi

for reqcmd in zip unzip wget
do
  if [[ -z "$(which $reqcmd)" ]]
  then
    echo "ERROR: Missing required '$reqcmd' command."
    exit 1
  fi
done

# enable extended regexp matching
shopt -s extglob

if [ $BRANCH = 'dev' ]
then
	URL1=''
    FILESUFIX='-TRUNK-SNAPSHOT'
else
	URL1='-release'
    FILESUFIX='-+([0-9.])' # +([0-9.]) is an extended regexp. meaning match
                           # at least one of these items: [0-9.]
fi


# Define download functions

download_file () {
	WGET_CTOOL="$1"
	WGET_URL="$2"
	WGET_FILE="$3"
	WGET_TARGET_DIR="$4"
	mkdir -p "$WGET_TARGET_DIR"
	OFFLINE_FILE="$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH/$WGET_CTOOL/$WGET_FILE"
	if [ ! -z "$OFFLINE_REPOSITORY" -a -e "$OFFLINE_FILE" -a -s "$OFFLINE_FILE" ]; then
		echo $ECHO_FLAG "Found $WGET_CTOOL in offline repository. "
		cp "$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH/$WGET_CTOOL/$WGET_FILE" "$WGET_TARGET_DIR"
	else
		echo $ECHO_FLAG "Downloading $WGET_CTOOL..."
		wget -q --no-check-certificate "$WGET_URL" -O "$WGET_TARGET_DIR/$WGET_FILE"
		if [ ! -s "$WGET_TARGET_DIR/$WGET_FILE" ]; then
			rm "$WGET_TARGET_DIR/$WGET_FILE"
			echo "Downloaded file $WGET_FILE is empty - it could be broken download url"
			exit 1
		fi
		if [ ! -z "$OFFLINE_REPOSITORY" ]; then
			echo $ECHO_FLAG " Storing $WGET_CTOOL in offline repository... "
			mkdir -p "$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH/$WGET_CTOOL" ;
			cp "$WGET_TARGET_DIR/$WGET_FILE" "$OFFLINE_REPOSITORY/$BASERVER_VERSION/$BRANCH/$WGET_CTOOL/$WGET_FILE"
		fi
	fi
}



downloadSaiku (){
	# SAIKU
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		if [ $BRANCH = 'dev' ]
		then
			URL='http://ci.analytical-labs.com/job/saiku-bi-platform-plugin/lastSuccessfulBuild/artifact/saiku-bi-platform-plugin/target/*zip*/target.zip'
			download_file "SAIKU" "$URL" "target.zip" ".tmp/saiku"
			rm -f .tmp/dist/marketplace.xml
			unzip -o .tmp/saiku/target.zip -d .tmp > /dev/null
			chmod -R u+rwx .tmp
			mv .tmp/target/saiku-* .tmp
		else
			URL='http://meteorite.bi/downloads/saiku-plugin-2.5.zip'
			download_file "SAIKU" "$URL" "saiku-plugin.zip" ".tmp"
		fi
	else
		if [ $BRANCH = 'dev' ]
		then
            echo 'SAIKU [trunk] not available for download. downloading stable'
        fi
        URL='http://meteorite.bi/downloads/saiku-plugin-p5-3.1.8.zip'
		download_file "SAIKU" "$URL" "saiku-plugin.zip" ".tmp"
	fi
	echo "Done"
}



downloadSaikuChartPlus (){

echo "Donwload Saiku Chart Plus"

	# SaikuChartPlus by IT4biz
	if [[ "$BASERVER_VERSION" = "4x" ]]; then
		if [ $BRANCH = 'dev' ]
		then
			URL='http://sourceforge.net/projects/saikuchartplus/files/SaikuChartPlus3/saiku-chart-plus-vSaiku3-plugin-pentaho.zip/download'
			#URL='https://github.com/it4biz/SaikuChartPlus/archive/vSaiku3-ChartPlusStable.zip'
			download_file "SAIKU_CHART_PLUS" "$URL" "vSaiku3-ChartPlusStable.zip" ".tmp"
		else
			URL='http://sourceforge.net/projects/saikuchartplus/files/SaikuChartPlus3/saiku-chart-plus-vSaiku3-plugin-pentaho.zip/download'
			#URL='https://github.com/it4biz/SaikuChartPlus/archive/vSaiku3-ChartPlusStable.zip'
			download_file "SAIKU_CHART_PLUS" "$URL" "vSaiku3-ChartPlusStable.zip" ".tmp"
		fi
	else
		if [ $BRANCH = 'dev' ]
		then
            echo 'SAIKU [trunk] not available for download. downloading stable'
        fi

	URL='http://sourceforge.net/projects/saikuchartplus/files/SaikuChartPlus3/saiku-chart-plus-vSaiku3-plugin-pentaho.zip/download'
	#URL='https://github.com/it4biz/SaikuChartPlus/archive/vSaiku3-ChartPlusStable.zip'
			download_file "SAIKU_CHART_PLUS" "$URL" "vSaiku3-ChartPlusStable.zip" ".tmp"
	fi
	echo "Done"
}


# Define install functions

installSaiku (){
	rm -rf $SOLUTION_DIR/system/saiku
	unzip -o .tmp/saiku-plugin*zip -d "$SOLUTION_DIR/system/" > /dev/null

	LIB_DIR=$WEBAPP_PATH/WEB-INF/lib
	SAIKU_DIR=$SOLUTION_DIR/system/saiku/lib

	# http://stackoverflow.com/questions/18721314/cube-in-analysis-view-not-showing-in-saiku-analytics
	# it still works for 5.3
	mv -v $SAIKU_DIR/saiku-olap-util*.jar $LIB_DIR
	rm -v $SAIKU_DIR/mondrian*.jar $SAIKU_DIR/olap4j*.jar $SAIKU_DIR/eigenbase*.jar
}


installSaikuChartPlus (){
	rm -rf $SOLUTION_DIR/system/saiku-chart-plus
	unzip -o .tmp/vSaiku3-ChartPlusStable*zip -d "$SOLUTION_DIR/system/" > /dev/null
	#unzip -o .tmp/vSaiku3-ChartPlusStable*zip -d "$SOLUTION_DIR/system/"
}


# read options for stuff to download/install

INSTALL_SAIKU=0
INSTALL_SAIKU_CHART_PLUS=0


if  [ $BASERVER_VERSION = '5x' ]; then
    if [ "$MODULES" != "" ] ||  $ASSUME_YES; then
	    INSTALL_SAIKU=1
    else
	    echo
    	echo $ECHO_FLAG "Install Saiku? This will delete everything in $SOLUTION_DIR/system/saiku. you sure? (y/N) "
	    read -e answer < /dev/tty

    	case $answer in
	      [Yy]* ) INSTALL_SAIKU=1;;
    	  * ) ;;
	    esac
    fi
fi

#SAIKU_CHART_PLUS
if  [ $BASERVER_VERSION = '5x' ]; then
    if [ "$MODULES" != "" ] ||  $ASSUME_YES; then
	    INSTALL_SAIKU_CHART_PLUS=1
    else
	    echo
    	echo $ECHO_FLAG "Install Saiku Chart Plus? This will delete everything in $SOLUTION_DIR/system/saiku-chart-plus. you sure? (y/N) "
	    read -e answer < /dev/tty

    	case $answer in
	      [Yy]* ) INSTALL_SAIKU_CHART_PLUS=1;;
    	  * ) ;;
	    esac
    fi
fi


nothingToDo (){
	echo Nothing to do. Exiting
	cleanup
	exit 1
}

if [ "$MODULES" != "" ]; then
  INSTALL_SAIKU=0
  INSTALL_SAIKU_CHART_PLUS=0
  MODULES_ARR=$(echo $MODULES | tr "," "\n")
  for MODULE in $MODULES_ARR
  do
    case $MODULE in
      saiku) INSTALL_SAIKU=1;;
      saikuchartplus) INSTALL_SAIKU_CHART_PLUS=1;;
        * ) ;;
    esac
  done
fi


[ $INSTALL_SAIKU -ne 0 ] || [ $INSTALL_SAIKU_CHART_PLUS -ne 0 ] ||  nothingToDo


# downloading files

echo
echo Downloading files
echo


[ $BASERVER_VERSION = '4x' ] || [ $INSTALL_SAIKU -eq 0 ] || downloadSaiku
[ $BASERVER_VERSION = '4x' ] || [ $INSTALL_SAIKU_CHART_PLUS -eq 0 ] || downloadSaikuChartPlus


# installing files

echo
echo Installing files
echo

[ $BASERVER_VERSION = '4x' ] || [ $INSTALL_SAIKU -eq 0 ] || installSaiku
[ $BASERVER_VERSION = '4x' ] || [ $INSTALL_SAIKU_CHART_PLUS -eq 0 ] || installSaikuChartPlus



cleanup

echo
echo Done!
echo

exit 0
