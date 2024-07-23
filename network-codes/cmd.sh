#!/bin/bash

docker="sudo -E docker"
docker_compose="${docker} compose"

env_file=".env"
source ${env_file}

proxy_compose_file="proxy.yaml"
agents_compose_file="storage-sites.yaml"
cluster_compose_file="nexoedge-cifs-cluster.yaml"
project="${PROJECT_NAME}"

cifs_user="nexoedge"
cifs_pass="nexoedge"
portal_user="admin"
portal_pass="admin"


create_directories() {
  for d in $(grep source ${proxy_compose_file} ${agents_compose_file} ${cluster_compose_file} | sed 's/.* source: \(.*\)/\1/g'); do
    d=$(eval echo ${d})
    if [ -f ${d} ]; then continue; fi
    sudo mkdir -p ${d}
    sudo chmod 777 ${d}
  done
}

stop_all() {
  echo "> Stop all containers ..."
  ${docker_compose} --env-file ${env_file} -p ${project} -f ${cluster_compose_file} down
  ${docker} network rm ${NEXOEDGE_NETWORK}
  echo "> Stopped all containers."
}

start_all() {
  echo "> Starting all containers..."
  ${docker} network create ${NEXOEDGE_NETWORK}
  ${docker_compose} --env-file ${env_file} -p ${project} -f ${cluster_compose_file} up -d
  echo "> Started all containers."
}

usage() {
  echo "./cmd.sh <command>"
  echo "   command:"
  echo "     - 'show': Show the containers of this project."
  echo "     - 'start': Shut down and start the whole cluster."
  echo "     - 'term': Shut down the whole cluster."
  echo "     - 'report': Show the cluster status."
  echo "     - 'checkdb': Show the keys in the metadata and statistics stores."
  echo "     - 'test': Run the test script that generates, uploads, and downloads random-byte files."
}

if [ "$1" == "show" ]; then
  ${docker} ps | grep -e ${project} 

elif [ "$1" == "start" ]; then
  create_directories

  # stop everything
  stop_all
  # start again
  start_all
  # post-start setup
  ## cifs
  ${docker} cp smb.conf ${project}-cifs-1:/usr/local/samba/etc/ >/dev/null
  ${docker} exec ${project}-cifs-1 /bin/bash -c "useradd -M ${cifs_user} && usermod -L ${cifs_user}; echo -e \"${cifs_pass}\n${cifs_pass}\" | /usr/local/samba/bin/pdbedit -a ${cifs_user} -t" >/dev/null
  ## portal login
  ${docker} exec ${project}-statsdb-1 /bin/sh -c "redis-cli HMSET ${portal_user} username ${portal_user} password ${portal_pass}" >/dev/null

elif [ "$1" == "term" ]; then
  # stop everything
  stop_all

elif [ "$1" == "report" ]; then
  ${docker} exec ${project}-reporter-1 ncloud-reporter /usr/lib/ncloud/current/

elif [ "$1" == "checkdb" ]; then
  ${docker} exec ${project}-metastore-1 redis-cli KEYS \*
  ${docker} exec ${project}-statsdb-1 redis-cli KEYS \*

elif [ "$1" == "test" ]; then
  ./upload-download-test.sh

else
  usage
fi
