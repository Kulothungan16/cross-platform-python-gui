#!/bin/bash
set -x
################################################################################
# File:    mac/buildDmg.sh
# Purpose: Builds a self-contained dmg for a simple Hello World
#          GUI app using kivy. See also:
#
#          * https://kivy.org/doc/stable/installation/installation-osx.html
#          * https://kivy.org/doc/stable/guide/packaging-osx.html
#          * https://github.com/kivy/buildozer/issues/494#issuecomment-390262889
#
# Authors: Michael Altfield <michael@buskill.in>
# Created: 2020-06-21
# Updated: 2020-06-21
# Version: 0.1
################################################################################

############
# SETTINGS #
############

PYTHON_PATH='/usr/bin/python3'
APP_NAME='helloWorld'

PYTHON_VERSION="`${PYTHON_PATH} --version | cut -d' ' -f2`"
PYTHON_EXEC_VERSION="`echo ${PYTHON_VERSION} | cut -d. -f1-2`"

###################
# INSTALL DEPENDS #
###################

# install os-level depends
brew install wget
brew cask install platypus

uname -a
sw_vers
which python2
python2 --version
which python3
python3 --version
echo $PATH
pwd
ls -lah

# first update our PATH so installed depends can be executed
PATH=${PATH}:/Users/runner/Library/Python/${PYTHON_EXEC_VERSION}/bin

# everything here is python3, except these bits. python2 is used in
# package_app.py, which is used by buildozer and has a few depends
sudo /usr/bin/python2 -m ensurepip
/usr/bin/python2 -m pip install --upgrade --user docopt sh

# setup a virtualenv to isolate our app's python depends
sudo ${PYTHON_PATH} -m ensurepip
${PYTHON_PATH} -m pip install --upgrade --user pip setuptools
#${PYTHON_PATH} -m pip install --upgrade --user virtualenv
#${PYTHON_PATH} -m virtualenv /tmp/kivy_venv

# install kivy and all other python dependencies with pip into our virtual env
#source /tmp/kivy_venv/bin/activate; python -m pip install -r requirements.txt

# install buildozer
${PYTHON_PATH} -m pip install --upgrade git+http://github.com/kivy/buildozer

# install a bunch of other shit so buildozer doesn't fail with python3
# see: https://github.com/kivy/buildozer/issues/494#issuecomment-390262889

## Install platypus
if [[ $(which platypus > /dev/null; echo $?) != "0" ]]; then
    pushd ~/Downloads
    wget https://www.sveinbjorn.org/files/software/platypus/platypus5.2.zip
    unzip platypus5.2.zip
    rm platypus5.2.zip
    
    sudo cp Platypus-5.2/Platypus.app/Contents/Resources/platypus_clt /usr/local/bin/
    sudo mv /usr/local/bin/platypus_clt /usr/local/bin/platypus
    
    sudo mkdir -p /usr/local/share/platypus
    sudo cp Platypus-5.2/Platypus.app/Contents/Resources/ScriptExec /usr/local/share/platypus
    sudo chmod +x /usr/local/share/platypus/ScriptExec
    sudo cp -R Platypus-5.2/Platypus.app/Contents/Resources/MainMenu.nib /usr/local/share/platypus
    
    rm -Rf Platypus-5.2
    popd
else
    echo "Platypus is already installed..."
fi

## Install GStreamer
if [[ ! -d /Library/Frameworks/GStreamer.framework ]]; then
    pushd ~/Downloads
    
    # You need both, gstreamer runtime binaries and libs and the development package including the headers.
    
    wget https://gstreamer.freedesktop.org/data/pkg/osx/1.14.0/gstreamer-1.0-devel-1.14.0-x86_64.pkg
    sudo /usr/sbin/installer -pkg gstreamer-1.0-devel-1.14.0-x86_64.pkg -target /
    rm gstreamer-1.0-devel-1.14.0-x86_64.pkg
    
    wget https://gstreamer.freedesktop.org/data/pkg/osx/1.14.0/gstreamer-1.0-1.14.0-x86_64.pkg
    sudo /usr/sbin/installer -pkg gstreamer-1.0-1.14.0-x86_64.pkg -target /
    rm gstreamer-1.0-1.14.0-x86_64.pkg
    
    popd
else
    echo "GStreamer is already installed..."
fi

## Install SDL2 stuff
if [[ ! -d /Library/Frameworks/SDL2.framework ]]; then
    pushd ~/Downloads
    wget https://www.libsdl.org/release/SDL2-2.0.4.dmg
    hdiutil attach SDL2-2.0.4.dmg && sudo cp -R /Volumes/SDL2/SDL2.framework /Library/Frameworks
    hdiutil detach /Volumes/SDL2
    rm SDL2-2.0.4.dmg
    popd
else
    echo "SDL2 is already installed..."
fi

if [[ ! -d /Library/Frameworks/SDL2_image.framework ]]; then
    pushd ~/Downloads
    wget https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.1.dmg
    hdiutil attach SDL2_image-2.0.1.dmg && sudo cp -R /Volumes/SDL2_image/SDL2_image.framework /Library/Frameworks
    hdiutil detach /Volumes/SDL2_image
    rm SDL2_image-2.0.1.dmg
    popd
else
    echo "SDL2_image is already installed..."
fi

if [[ ! -d /Library/Frameworks/SDL2_ttf.framework ]]; then
    pushd ~/Downloads
    wget https://www.libsdl.org/projects/SDL_ttf/release/SDL2_ttf-2.0.14.dmg
    hdiutil attach SDL2_ttf-2.0.14.dmg && sudo cp -R /Volumes/SDL2_ttf/SDL2_ttf.framework /Library/Frameworks
    hdiutil detach /Volumes/SDL2_ttf
    rm SDL2_ttf-2.0.14.dmg
    popd
else
    echo "SDL2_ttf is already installed..."
fi

if [[ ! -d /Library/Frameworks/SDL2_mixer.framework ]]; then
    pushd ~/Downloads
    wget https://www.libsdl.org/projects/SDL_mixer/release/SDL2_mixer-2.0.1.dmg
    hdiutil attach SDL2_mixer-2.0.1.dmg && sudo cp -R /Volumes/SDL2_mixer/SDL2_mixer.framework /Library/Frameworks
    hdiutil detach /Volumes/SDL2_mixer
    rm SDL2_mixer-2.0.1.dmg
    popd
else
    echo "SDL2_mixer is already installed..."
fi

#####################
# PREPARE BUILDOZER #
#####################

# create and enter our new dir for buildozer
mkdir buildozer
pushd buildozer

# create buildozer.spec file
cat > buildozer.spec << EOF
[app]
title = Hello World
package.name = ${APP_NAME}
package.domain = org.test
source.dir = ../src/
source.include_exts = py,png,jpg,kv,atlas
version = 0.1
requirements = kivy
orientation = portrait
osx.python_version = 3
osx.kivy_version = 1.9.1
fullscreen = 0
[buildozer]
log_level = 2
warn_on_root = 1
EOF

# Change buildozer to use a python3.7 virtual environment instead of python2.7
pushd /usr/local/lib/$PYTHON_EXEC_VERSION/site-packages/buildozer
sed -i '' 's;virtualenv --python=python2.7;virtualenv --python=python3.7;g' __init__.py
popd

# Change the osx target to use python3 to run the package_app.py script.
pushd /usr/local/lib/$PYTHON_EXEC_VERSION/site-packages/buildozer/targets
sed -i '' "s;'python', 'package_app.py';'python3', 'package_app.py';g" osx.py
popd

# First run fails but is necessary to create the directory .buildozer
buildozer osx debug
if [[ "$?" != 0 ]]; then
    echo "[INFO] First run of buildozer failed as expected."
fi

# Go into the kivy sdk directory to create the file Kivy.app
pushd .buildozer/osx/platform/kivy-sdk-packager-master/osx
rm -Rf Kivy3.dmg
sed -i '' "s;3.5.0;$PYTHON_VERSION;g" create-osx-bundle.sh
sed -i '' "s;python3.5;$PYTHON_EXEC_VERSION;g" create-osx-bundle.sh
sed -i '' "s;rm {};rm -f {};g" create-osx-bundle.sh
./create-osx-bundle.sh python3
# Repair symlink
pushd Kivy.app/Contents/Resources/venv/bin/
rm ./python3
ln -s ../../../Frameworks/python/$PYTHON_VERSION/bin/python3 .
popd

# Go into kivy sdk directory and fix the script package_app.py to use the specified python version.
pushd .buildozer/osx/platform/kivy-sdk-packager-master/osx
sed -i '' "s;3.5.0;$PYTHON_VERSION;g" package_app.py
# Make it python3 compatible by removing decode(...) calls.
sed -i '' "s;\.decode('utf-8');;g" package_app.py
popd

#############
# BUILD APP #
#############

# buildozer should now be able to build our .app file
buildozer osx debug

############
# THIN APP #
############

# remove unnecessary libs, such as the 141M GStreamer framework
rm -rf "${APP_NAME}.app/Contents/Frameworks/GStreamer.framework"

#############
# BUILD DMG #
#############

# create a .dmg file from the .app file
./create-osx-dmg.sh "${APP_NAME}.app"

# create the dist dir for our result to be uploaded as an artifact
mkdir dist
cp "${APP_NAME}.dmg" dist/

#######################
# OUTPUT VERSION INFO #
#######################

uname -a
sw_vers
which python2
python2 --version
which python3
python3 --version
pwd
echo $PATH
ls -lah /Users/runner/Library/Python/3.7/bin
ls -lah
ls -lah dist

##################
# CLEANUP & EXIT #
##################

# exit cleanly
exit 0