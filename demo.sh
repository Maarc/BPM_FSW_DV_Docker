#!/usr/bin/env bash
#
# Created by Juergen Hoffmann <buddy@redhat.com>
# extended by Patrick Steiner <psteiner@redhat.com>
#

# This script builds all required docker images.

set -e
NAME=$(basename $0)
declare -A DOCKER_IMAGE

DOCKER_IMAGE["EAP:IMAGE_NAME"]="psteiner/eap"
DOCKER_IMAGE["EAP:ZIP"]="jboss-eap-6.1.1.zip"
DOCKER_IMAGE["EAP:URL"]="http://www.jboss.org/download-manager/file/jboss-eap-6.1.1.zip"

DOCKER_IMAGE["BPM:IMAGE_NAME"]="psteiner/bpm"
DOCKER_IMAGE["BPM:ZIP"]="jboss-bpms-6.0.3.GA-redhat-1-deployable-eap6.x.zip"
DOCKER_IMAGE["BPM:URL"]="https://access.redhat.com/jbossnetwork/restricted/softwareDownload.html?softwareId=30853&product=bpm.suite"

DOCKER_IMAGE["FSW:IMAGE_NAME"]="psteiner/fsw"
DOCKER_IMAGE["FSW:ZIP"]="jboss-fsw-installer-6.0.0.GA-redhat-4.jar"
DOCKER_IMAGE["FSW:URL"]="http://www.jboss.org/download-manager/file/jboss-fsw-6.0.0.GA.zip"

DOCKER_IMAGE["DV:IMAGE_NAME"]="psteiner/datavirt"
DOCKER_IMAGE["DV:ZIP"]="software/jboss-dv-installer-6.0.0.GA-redhat-4.jar"
DOCKER_IMAGE["DV:URL"]="http://www.jboss.org/download-manager/file/jboss-dv-installer-6.0.0.GA-redhat-4.jar"

DOCKER_IMAGE["POSTGRES:IMAGE_NAME"]="psteiner/postgres"

DOCKER_IMAGE["HEISE_BPM:IMAGE_NAME"]="psteiner/heise_bpm"
DOCKER_IMAGE["HEISE_BPM:ZIP"]="postgresql-8.4-703.jdbc4.jar"
DOCKER_IMAGE["HEISE_BPM:URL"]="http://jdbc.postgresql.org/download/postgresql-8.4-703.jdbc4.jar"

DOCKER_IMAGE["HEISE_FSW:IMAGE_NAME"]="psteiner/heise_fsw"

DOCKER_IMAGE["HEISE_DV:IMAGE_NAME"]="psteiner/heise_datavirt"

DOCKER_IMAGE["JBDS:IMAGE_NAME"]="psteiner/jbds"
DOCKER_IMAGE["JBDS:ZIP"]="software/jbdevstudio-product-universal-7.1.1.GA-v20140314-2145-B688.jar"
DOCKER_IMAGE["JBDS:HTTP_PORT"]="49200"
DOCKER_IMAGE["JBDS:ADMIN_PORT"]="49210"

function sanity_check {
  IMAGE=$1

  # Sanity checks before running the build
  if [ ! -f ${IMAGE}_Image/${DOCKER_IMAGE["${IMAGE}:ZIP"]} ]; then
    echo "ERROR: ${IMAGE}_Image/${DOCKER_IMAGE["${IMAGE}:ZIP"]} not found"
    echo "Please put download ${IMAGE} from ${DOCKER_IMAGE["${IMAGE}:URL"]} and place it into ${IMAGE}_Image"
    exit 1
  fi
}

function remove_image {
  IMAGE=$1

  echo "Removing $IMAGE"

  # grab the image id hash
  IMAGE_ID=$(docker images | grep -w $IMAGE | awk '{ print $3; }')

  # Only try removing the images if there is a pre-built image
  if [ ! -z "$IMAGE_ID" ]; then

  echo "found $IMAGE_ID"

    if [ $(docker ps -a | grep $IMAGE_ID | awk '{ print $1; }' | wc -l) -gt 0 ]; then
      # remove all running and stopped containers based of the image
      docker rm -f $(docker ps -a | grep $IMAGE_ID | awk '{ print $1; }')
    fi

    if [ $(docker ps -a | grep $IMAGE | awk '{ print $1; }' | wc -l) -gt 0 ]; then
      # In case we still have the named reference
      docker rm -f $(docker ps -a | grep $IMAGE | awk '{ print $1; }')
    fi

    # finally remove the image
    docker rmi $IMAGE_ID
  fi
}


function remove_all_images {
  remove_image ${DOCKER_IMAGE["EAP:IMAGE_NAME"]}
  remove_image ${DOCKER_IMAGE["BPM:IMAGE_NAME"]}
  remove_image ${DOCKER_IMAGE["FSW:IMAGE_NAME"]}
  remove_image ${DOCKER_IMAGE["DV:IMAGE_NAME"]}
  remove_image ${DOCKER_IMAGE["POSTGRES:IMAGE_NAME"]}
  remove_image ${DOCKER_IMAGE["HEISE_BPM:IMAGE_NAME"]}
  remove_image ${DOCKER_IMAGE["HEISE_FSW:IMAGE_NAME"]}
  remove_image ${DOCKER_IMAGE["HEISE_DV:IMAGE_NAME"]}
  remove_image ${DOCKER_IMAGE["JBDS:IMAGE_NAME"]}

}

function build_image {
  IMAGE=$1
  pushd ./${IMAGE}_Image >/dev/null
  echo "Building ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]}"

  if [ "$IMAGE" == "HEISE_BPM" ]; then
	echo "Calling maven to create dashboard importer"
        pushd dashboard-importer > /dev/null
	mvn clean package > /dev/null
	popd
  fi

  docker build -q --rm -t ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} .
  popd > /dev/null

}

function connect_image {
  IMAGE=$1
  CONTAINER_ID=$(docker ps | grep ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} | cut -c1-13 )
  PID=$(docker inspect --format '{{ .State.Pid }}' $CONTAINER_ID)
  
  echo "Connecting ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} with CONTAINER_ID <$CONTAINER_ID> and PID <$PID>"

  sudo nsenter -m -u -n -i -p -t $PID
}

function commit_image {
  IMAGE=$1
  CONTAINER_ID=$(docker ps | grep ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} | cut -c1-13 )
  PID=$(docker inspect --format '{{ .State.Pid }}' $CONTAINER_ID)
  
  echo "Commit ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} with CONTAINER_ID <$CONTAINER_ID>"

  docker commit $CONTAINER_ID ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]}  
}

function get_ip {
  IMAGE=$1
  CONTAINER_ID=$(docker ps | grep ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} | cut -c1-13 )
  IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $CONTAINER_ID)
  
  echo "IP adress of ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} is <$IP>"
}

function stop_image {
  IMAGE=$1
  if [ $(docker ps | grep ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} | wc -l) -gt 0 ]; then
    echo "Stopping all Images matching ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]}"
    docker stop $(docker ps | grep ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} | awk '{ print $1; }')

    if [ ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} == ${DOCKER_IMAGE["HEISE_FSW:IMAGE_NAME"]} ]; then
	echo "Removing ${DOCKER_IMAGE["HEISE_FSW:IMAGE_NAME"]}"
	docker rm $(docker ps -a | grep ${DOCKER_IMAGE["${IMAGE}:IMAGE_NAME"]} | awk '{ print $1; }')
    fi 

  fi
}

sanity_check "EAP"
sanity_check "BPM"
sanity_check "FSW"
sanity_check "DV"
sanity_check "HEISE_BPM"
sanity_check "JBDS"

case "$1" in
remove)
  case "$2" in
    bpm)
      echo "Removing BPM Image(s)"
      remove_image ${DOCKER_IMAGE["BPM:IMAGE_NAME"]}
      ;;
    fsw)
      echo "Removing FSW Image(s)"
      remove_image ${DOCKER_IMAGE["FSW:IMAGE_NAME"]}
      ;;
    eap)
      echo "Removing EAP Image(s)"
      remove_image ${DOCKER_IMAGE["EAP:IMAGE_NAME"]}
      ;;
    dv)
      echo "Removing DV Image(s)"
      remove_image ${DOCKER_IMAGE["DV:IMAGE_NAME"]}
      ;;
    postgres)
      echo "Removing Postgres Image(s)"
      remove_image ${DOCKER_IMAGE["POSTGRES:IMAGE_NAME"]}
      ;;
    heise_bpm)
      echo "Removing Heise_BPM Image(s)"
      remove_image ${DOCKER_IMAGE["HEISE_BPM:IMAGE_NAME"]}
      ;;
    heise_fsw)
      echo "Removing Heise_FSW Image(s)"
      remove_image ${DOCKER_IMAGE["HEISE_FSW:IMAGE_NAME"]}
      ;;
    heise_dv)
      echo "Removing Heise_DV Image(s)"
      remove_image ${DOCKER_IMAGE["HEISE_DV:IMAGE_NAME"]}
      ;;
    jbds)
      echo "Removing Heise_DV Image(s)"
      remove_image ${DOCKER_IMAGE["JBDS:IMAGE_NAME"]}
      ;;
    all)
      echo "Removing All Images"
      remove_all_images
      ;;
    *)
      echo "usage: ${NAME} remove (bpm|fsw|eap|dv|postgres|heise_bpm|heise_fsw|heise_dv|all)"
      exit 1
    esac
    ;;
start)
  # If there is no fsw image running
  if [ ! $( docker ps | grep fsw | wc -l ) -gt 0 ]; then 
    # If there isn't a stopped image
    if [ ! $( docker ps -a | grep fsw | wc -l ) -gt 0 ]; then
      # Create a new FSW Container
      echo "Starting ${DOCKER_IMAGE["HEISE_FSW:IMAGE_NAME"]}"
      docker run -P -h fsw --name fsw -d ${DOCKER_IMAGE["HEISE_FSW:IMAGE_NAME"]}
    else
      # Start the existing container
      echo "Re-Starting ${DOCKER_IMAGE["HEISE_FSW:IMAGE_NAME"]}"
      docker start fsw
    fi
  else
    echo "${DOCKER_IMAGE["HEISE_FSW:IMAGE_NAME"]} already running"
  fi

  # If there is no postgres image running
  if [ ! $( docker ps | grep postgres | wc -l ) -gt 0 ]; then 
    # If there isn't a stopped image
    if [ ! $( docker ps -a | grep postgres | wc -l ) -gt 0 ]; then
      # Create a new FSW Container
      echo "Starting ${DOCKER_IMAGE["POSTGRES:IMAGE_NAME"]}"
      docker run -P -h postgres --name postgres -d ${DOCKER_IMAGE["POSTGRES:IMAGE_NAME"]}
    else
      # Start the existing container
      docker start postgres
      echo "Re-Starting ${DOCKER_IMAGE["POSTGRES:IMAGE_NAME"]}"
    fi
  else
    echo "${DOCKER_IMAGE["POSTGRES:IMAGE_NAME"]} already running"
  fi

  case "$2" in
    jbds)
      echo "Starting ${DOCKER_IMAGE["JBDS:IMAGE_NAME"]}"
      WORKSPACE=`pwd`
      WORKSPACE=$WORKSPACE"/workspace/Docker_Heise_DV"
      echo "Mapping workspace to <"$WORKSPACE"> to /tmp/workspace"

      docker run -i -t -p ${DOCKER_IMAGE["JBDS:HTTP_PORT"]}:8080 -p ${DOCKER_IMAGE["JBDS:ADMIN_PORT"]}:9990 -e DISPLAY=unix$DISPLAY -e TERM=$TERM -v $WORKSPACE:/tmp/workspace -v /tmp/.X11-unix:/tmp/.X11-unix --lxc-conf='lxc.cgroup.devices.allow = c 116:* rwm'  -h datavirt --link postgres:postgres ${DOCKER_IMAGE["JBDS:IMAGE_NAME"]} /home/jboss/jbdevstudio/jbdevstudio-unity
     ;;
    all)
	  echo "Starting ${DOCKER_IMAGE["HEISE_DV:IMAGE_NAME"]}"
      WORKSPACE=`pwd`
      WORKSPACE=$WORKSPACE"/workspace/Docker_Heise_DV"
      docker run -p 49180:8080 -p 49190:9990 --name datavirt -h datavirt --link postgres:postgres -v $WORKSPACE:/tmp/workspace -d ${DOCKER_IMAGE["HEISE_DV:IMAGE_NAME"]}

      echo "Starting ${DOCKER_IMAGE["HEISE_BPM:IMAGE_NAME"]}"
      docker run -p 49160:8080 -p 49170:9990 --link fsw:fsw --link postgres:postgres --link datavirt:datavirt -d ${DOCKER_IMAGE["HEISE_BPM:IMAGE_NAME"]}
      echo "${DOCKER_IMAGE["HEISE_DV:IMAGE_NAME"]}"
	  ;;
    *)
      echo "usage: ${NAME} start (all|jbds)"
      exit 1
    esac
    ;;

connect)
  case "$2" in
    heise_bpm)
      echo "Connecting into running Heise_BPM container"
      connect_image "HEISE_BPM"
      ;;
    heise_fsw)
      echo "Connecting into running Heise_FSW container"
      connect_image "HEISE_FSW"
      ;;
    heise_dv)
      echo "Connecting into running Heise_DV container"
      connect_image "HEISE_DV"
      ;;
    postgres)
      echo "Connecting into running postgresql container"
      connect_image "POSTGRES"
      ;;
    jbds)
      echo "Connecting into running postgresql container"
      connect_image "JBDS"
      ;;
    *)
      echo "usage: ${NAME} connect (heise_bpm|heise_fsw|heise_dv|postgres|jbds)"
      exit 1
  esac
  ;;
commit)
  case "$2" in
    heise_bpm)
      commit_image "HEISE_BPM"
      ;;
    heise_fsw)
      commit_image "HEISE_FSW"
      ;;
    heise_dv)
      commit_image "HEISE_DV"
      ;;
    jbds)
      commit_image "JBDS"
      ;;
    *)
      echo "usage: ${NAME} commit (heise_bpm|heise_fsw|heise_dv|jbds)"
      exit 1
  esac
  ;;

ip)
  case "$2" in
    heise_bpm)
      get_ip "HEISE_BPM"
      ;;
    heise_fsw)
      get_ip "HEISE_FSW"
      ;;
    heise_dv)
      get_ip "HEISE_DV"
      ;;
    postgres)
      get_ip "POSTGRES"
      ;;
    jbds)
      get_ip "JBDS"
      ;;
    *)
      echo "usage: ${NAME} ip (heise_bpm|heise_fsw|heise_dv|postgres)"
      exit 1
  esac
  ;;
build)
  case "$2" in
    bpm)
      build_image "BPM"
      ;;
    fsw)
      build_image "FSW"
      ;;
    eap)
      build_image "EAP"
      ;;
    dv)
      build_image "DV"
      ;;
    postgres)
      build_image "POSTGRES"
      ;;
    heise_bpm)
      build_image "HEISE_BPM"
      ;;
    heise_fsw)
      build_image "HEISE_FSW"
      ;;
    heise_dv)
      build_image "HEISE_DV"
      ;;
    jbds)
      build_image "JBDS"
      ;;
    all)
      build_image "EAP"
      build_image "BPM"
      build_image "FSW"
      build_image "DV"
      build_image "POSTGRES"
      build_image "HEISE_BPM"
      build_image "HEISE_FSW"
      build_image "HEISE_DV"
      build_image "JBDS"
      ;;
    *)
      echo "usage: ${NAME} build (bpm|fsw|eap|dv|postgres|heise_bpm|heise_fsw|heise_dv|jbds|all)"
      exit 1
    esac
    ;;
stop)
  case "$2" in
    heise_bpm)
      stop_image "HEISE_BPM"
      ;;
    heise_fsw)
      stop_image "HEISE_FSW"
      ;;
    heise_dv)
      stop_image "HEISE_DV"
      ;;
    all)
      stop_image "HEISE_BPM"
      stop_image "HEISE_FSW"
      stop_image "HEISE_DV"
      stop_image "POSTGRES"
      ./cleanup.sh
      ;;
    *)
      stop_image "HEISE_BPM"
      stop_image "HEISE_FSW"
      stop_image "HEISE_DV"
      stop_image "POSTGRES"
      ./cleanup.sh
    esac
    ;;
status)
    docker ps
    ;;
help)
    echo "usage: ${NAME} (remove|start|build|status|connect)"
    ;;
*)
    echo "usage: ${NAME} (remove|start|build|status|connect)"
    exit 1
esac

