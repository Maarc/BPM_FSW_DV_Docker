# DOCKER-VERSION 0.3.4
FROM psteiner/heise_bpm

MAINTAINER wrichter <wrichter@redhat.com>
MAINTAINER psteiner <psteiner@redhat.com>

USER root

RUN yum -y install libcanberra-gtk2 PackageKit-gtk-module java-1.7.0-openjdk-devel firefox
RUN mkdir /tmp/.X11-unix
RUN mkdir /tmp/workspace

USER jbosseap
   
ADD software/jbdevstudio-product-universal-7.1.1.GA-v20140314-2145-B688.jar $HOME/tmp/
ADD config/InstallConfigRecord.xml $HOME/tmp/

RUN java -jar $HOME/tmp/jbdevstudio-product-universal-7.1.1.GA-v20140314-2145-B688.jar $HOME/tmp/InstallConfigRecord.xml 

USER root
RUN rm -rf $HOME/tmp/*

USER jbosseap
# next line needed to circumvent a bug
RUN echo -e "-Dorg.eclipse.swt.internal.gtk.cairoGraphics=false" >> $HOME/jbdevstudio/studio/jbdevstudio.ini

EXPOSE 22 3306 5432 8080 9990 27017 9999

CMD $HOME/jbdevstudio/jbdevstudio-unity

# Build command -> docker build --rm -t wrichter/jbds .
# run command -> docker run -i -t -e DISPLAY=unix$DISPLAY -e TERM=$TERM -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/snd:/dev/snd --lxc-conf='lxc.cgroup.devices.allow = c 116:* rwm' psteiner/bpm_jdbs
