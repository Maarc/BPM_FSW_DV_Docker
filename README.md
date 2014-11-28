# Docker Images

This is a set of Docker images which together form a Red Hat BPM-Suite and Red Hat Fuse ServiceWorks demo environment.
I personally use this setup whenever I have to present these topics to some audience.

# About the images

The demo requires two Docker-Images (Heise_BPM_Image and Heise_FSW_Image). As you can probably guess Heise_BPM_Image hosts the Red Hat JBoss BPM-Suite and Heise_FSW_Image hosts Red Hat JBoss Fuse ServiceWorks. All required images are built automatically. During the built process the base images (EAP_Image, BPM_Image, and FSW_Image) are built as well. These are plain base Images which can be re-used for your custom demos as well.

## Control Script

The `demo.sh` control script provides several actions from *building* the images to *running*, and *removing* the images. The following section describes how to use the `demo.sh script.

### demo.sh usage

The `demo.sh` script accepts the following parameters:

- **build** - the build parameter triggers an image build and accepts the following parameters  
  - **bpm** - build the base image for Red Hat JBoss BPM Suite
  - **eap** - build the base image for Red Hat JBoss EAP
  - **fsw** - build the base image for Red Hat JBoss Fuse Service Works
  - **dv** - build the base image for Red Hat JBoss BPM Suite
  - **heise\_bpm** - build the heise_bpm image which in turn requires the bpm image (see above), which in turn requires the eap image. 
  - **heise\_fsw** - build the heise_fsw image which in turn requires the fsw image (see above)
  - **heise\_dv** - build the heise_dv image which in turn requires the dv image (see above ) 
  - **all** - build all required images in one go
- **stop** - the stop parameter tries to stop running images and accepts the following parameters  
  - **heise\_bpm** - tries to only stop running heise_bpm images 
  - **heise\_fsw** - tries to only stop running heise_fsw images
  - **heise\_dv** - tries to only stop running heise_dv images
  - **all** - tries to stop all images (default)
- **start** - Creates and runs the fsw and bpms containers and names it accordingly. If an existing fsw container is present, but not running it is started. By default the containers are started in detached mode. If you want to see what is going on you need to add an additional _attached_ parameter.
  - **attached** - Starts the bpms container attached and removes it after you terminate the jboss process.
- **remove** - removes images from the docker registry. Needed for rebuilding parts of the demo environment.
  - **bpm** - remove the bpm image and all intermediary images
  - **eap** - remove the eap image and all intermediary images
  - **fsw** - remove the fsw image and all intermediary images
  - **dv** - remove the fsw image and all intermediary images
  - **heise\_bpm** - remove the heise_bpm image and all intermediary images 
  - **heise\_fsw** - remove the heise_fsw image and all intermediary images
  - **heise\_dv** - remove the heise_dv image and all intermediary images
- **status** - runs `docker ps`. Can be used to see what instances are running and how the ports are mapped.


## Heise BPM image
This image is made out of 3 layers

   1. Red Hat JBoss EAP ( image-name psteiner/eap )
   2. Red Hat JBoss BPM Suite ( image-name psteiner/bpm )
   3. WebService consumer deployed into layer 2 ( image-name psteiner/heise_bpm )

Heise Fuse Service Works image
-----------------------------
This image is made out of 2 layers

   1. Red Hat JBoss Fuse ServiceWorks ( image-name psteiner/fsw )
   2. WebService provider deployed into layer 1 ( image-name psteiner/heise_fsw )

Heise Data Virtualization image
-----------------------------
This image is made out of 2 layers

   1. Red Hat JBoss Data Virtualization ( image-name psteiner/datavirt )
   2. Data Virtualization product with custom virtual database(s) ( image-name psteiner/heise_datavirt )

Postgres image
--------------
This image is not yet used for the demo, but in preparation for so!

It will be used for the Business Activity Monitoring of the demo and
probably later also for showcasing data virtualization.

Creating the images
===================
After successfully cloning this image with `git clone https://github.com/PatrickSteiner/BPM_FSW_Docker.git` you will have one directory per image.

Please download the following Red Hat JBoss products:
* [Red Hat JBoss EAP](http://www.jboss.org/download-manager/file/jboss-eap-6.1.0.GA.zip)
* [Red Hat JBoss BPM-Suite](https://access.redhat.com/jbossnetwork/restricted/softwareDownload.html?softwareId=30853&product=bpm.suite)
* [Red Hat JBoss FSW](http://www.jboss.org/download-manager/file/jboss-fsw-6.0.0.GA.zip)
* [Red Hat JBoss Data Virtualization](https://access.redhat.com/jbossnetwork/restricted/listSoftware.html?product=data.services.platform&downloadType=distributions)


Please copy the downloaded products as follows:
* jboss-eap-6.1.0.GA.zip into the folder `EAP_Image` root folder
* jboss-bpms-6.0.3.GA-redhat-1-deployable-eap6.x.zip into the folder `BPM_Image` root folder
* jboss-fsw-installer-6.0.0.GA-redhat-4.jar into the `FSW_Image` root folder
* jboss-dv-installer-6.0.0.GA-redhat-4.jar into the `DV_Image/software` folder

After the files are downloaded, run `demo.sh build all` 

If you prefer to see all this in a video, here we go:
[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/9aKRDL1sWuM/0.jpg)](https://www.youtube.com/watch?v=9aKRDL1sWuM)

Starting the images
===================

As the two images depend on each other, via a Link, we need to run them in the right order. For this purpose you can simply run `demo.sh start` which will run the demo in detached mode on fixed ports (49160) or you can run `demo.sh start attached` which will run the fsw image in detached mode and the bpms image in attached mode and remove the image after the jboss process is terminated. 

Running the demo
==================

A first video on how to start and run the environment is here:

[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/aB8e0gcXkUw/0.jpg)](https://www.youtube.com/watch?v=aB8e0gcXkUw)


Known issues
============

Starting an image
-----------------
 `2014/06/19 20:40:34 unable to remount sys readonly: unable to mount sys as readonly max retries reached`

 This error can be cirumvented by editing `/etc/sysconfig/docker` and replacing 
 ```
 other_args="--exec-driver=lxc"
 ```
 with
 ```
 other_args="--exec-driver=lxc --selinux-enabled"
 ```

Have fun and feel free to comment, come up with ideas for improvement, etc.

Patrick and Buddy

psteiner at redhat.com
buddy at redhat.com

