# Mnova_export_script
This script, based on existing Mnova script, was developped by Damien Jeannerat
It works on the mac version of Mnova 11

### Installation:
Download and unzip the repository.

Open a shell in the folder.

Make the .csh file executable.

chmod +x ./mnova2NMReDATA.csh

### Use:

Add one or more .mnova file in the current folder and type:

./mnova2NMReDATA.csh *mnova

This will create NMR records for all mnova files present in the folder when the Bruker files are fond where they were when the mnova file was created.

## Versions
Version 1.1 [introduced a backslash before the end-of-line character](http://nmredata.org/wiki/NMReDATA_tag_format#.3CNMREDATA_VERSION.3E) inside tags.
