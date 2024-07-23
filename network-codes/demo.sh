#!/bin/bash

source .env

docker="sudo -E docker"
docker_compose="${docker} compose"

network_usage_in_before=(0 0 0 0 0)
network_usage_out_before=(0 0 0 0 0)
network_usage_in_after=(0 0 0 0 0)
network_usage_out_after=(0 0 0 0 0)
network_usage_in_diff=(0 0 0 0 0)
network_usage_out_diff=(0 0 0 0 0)

upload_path="myfile"
download_path="download"

clean_up() {
  echo -e "\n> Terminating any existing cluster ..."
  ./cmd.sh term
  echo -e "> Remove the data directory."
  sudo rm -r ${NEXOEDGE_DATA_DIR}
  # also remove the test file
  rm ${upload_path} ${download_path}
}

show_status() {
  ./cmd.sh report
}

start_cluster() {
  clean_up
  echo -e "\n> Starting a new cluster ..."
  ./cmd.sh start
  sleep 4
  echo "> Start a new cluster."
  show_status
}

gen_file() {
  dd if=/dev/urandom of=${upload_path} bs=1M count=100
}

upload_file() {
  smbclient -U nexoedge%nexoedge //127.0.0.1/nexoedge -c "put ${upload_path}"
}

download_file() {

  echo -e "\n> Remove any downloaded file"
  rm ${download_path}

  echo -e "\n> Downloading the file ..."
  smbclient -U nexoedge%nexoedge //127.0.0.1/nexoedge -c "get ${upload_path} ${download_path}"

  echo -e "\n> Checking the downloaded file ..."
  diff -s myfile ${download_path}
}

show_file_list() {
  echo -e "\n> Show all uploaded files"
  smbclient -U nexoedge%nexoedge //127.0.0.1/nexoedge -c "ls"
}

fail_a_site() {
  # stop the first storage site
  echo -e "\n> Removing a storage site ..."
  ${docker} stop ${PROJECT_NAME}-site-1-1

  # wait for one site to switch to the DISCONNECTED state
  while [ 1 -eq 1 ]; do
    count=$(./cmd.sh report | grep DISCONNECTED | wc -l)
    if [ $((count)) -eq 1 ]; then
      break
    fi
    sleep 1
  done
  echo "> Removed a storage site."
  show_status
}

wait_for_repair() {
  echo -e "\n> Waiting for data repair ."
  while [ 1 -eq 1 ]; do
    sleep 3
    # there should be no empty containers after a repair
    if [ -z "$(./cmd.sh report | grep ' 0/')" ]; then
      break;
    fi
    echo -n "..."
  done 
  echo ""
}

record_network_usage_before() {
  # mark the rx
  for i in $(seq 1 4); do
    network_usage_in_before[$((i-1))]=$(docker exec ${PROJECT_NAME}-site-$i-1 netstat -s | grep InOctets | awk '{print $2}' 2>/dev/null)
  done
  # mark the tx
  for i in $(seq 1 4); do
    network_usage_out_before[$((i-1))]=$(docker exec ${PROJECT_NAME}-site-$i-1 netstat -s | grep OutOctets | awk '{print $2}' 2>/dev/null)
  done
}

record_network_usage_after() {
  # mark the rx
  for i in $(seq 2 4); do
    network_usage_in_after[$((i-1))]=$(docker exec ${PROJECT_NAME}-site-$i-1 netstat -s | grep InOctets | awk '{print $2}' 2>/dev/null)
  done
  # mark the tx
  for i in $(seq 2 4); do
    network_usage_out_after[$((i-1))]=$(docker exec ${PROJECT_NAME}-site-$i-1 netstat -s | grep OutOctets | awk '{print $2}' 2>/dev/null)
  done
}

show_network_usage_diff() {
  for i in $(seq 0 4); do
    network_usage_in_diff[$i]=$((${network_usage_in_after[$i]} - ${network_usage_in_before[$i]}))
  done
  for i in $(seq 0 4); do
    network_usage_out_diff[$i]=$((${network_usage_out_after[$i]} - ${network_usage_out_before[$i]}))
  done

  total_tx=0
  total_rx=0
  for i in $(seq 0 4); do
    b=$((${network_usage_out_before[$i]}))
    a=$((${network_usage_out_after[$i]}))
    tx=$((${network_usage_out_diff[$i]} / 1024 / 1024))
    if [ $tx -le 0 ]; then continue; fi
    echo ">> Site $((i+1)) [TX] $tx MB (before: $b; after $a)"
    total_tx=$((total_tx+tx))
    total_rx=$((total_rx+rx))
  done
  echo ">> Total: [TX] $total_tx MB"
}

stop_two_sites() {
  echo -e "\n> Removing two storage sites ..."
  ${docker} stop ${PROJECT_NAME}-site-2-1
  ${docker} stop ${PROJECT_NAME}-site-3-1
  sleep 5

  ${docker} restart ${PROJECT_NAME}-site-4-1
  ${docker} restart ${PROJECT_NAME}-site-5-1
  sleep 1

  # wait for two extra sites to switch to the DISCONNECTED state
  while [ 1 -eq 1 ]; do
    count=$(./cmd.sh report | grep DISCONNECTED | wc -l)
    if [ $((count)) -eq 3 ]; then
      break
    fi
    sleep 1
  done
  echo ""
  echo -e "\n> Removed two storage sites"
  show_status
}


start_cluster
gen_file
upload_file
show_file_list
download_file
record_network_usage_before
fail_a_site
wait_for_repair
record_network_usage_after
show_network_usage_diff
stop_two_sites
download_file
clean_up
