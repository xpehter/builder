#!/bin/bash
#
# Test task from SKB Kontur:
# https://github.com/kontur-exploitation/testcase-pybash

REPO_REMOTE_ADDRESS='https://github.com/kontur-exploitation/testcase-pybash.git'
#REPO_REMOTE_ADDRESS='https://github.com/xpehter/ideco.git'
WORK_FOLDER=$(pwd)
REPO_LOCAL_DIR='dirik'
REPO_REMOTE_CHECK_INTERVAL=5  # seconds


### Functions ###
## All branches in a remote repository ##
function AllBrRemRepo {
  if [ $# -ne 1 ]; then echo "Error in ${FUNCNAME}: $@" && exit; fi
  local local_REPO_REMOTE_ADDRESS=$1
  git ls-remote -h $local_REPO_REMOTE_ADDRESS | rev | cut -d '/' -f 1 | rev
}
## Set commits in the local repository copy ##
function SetComLocRepo {
  if [ $# -ne 3 ]; then echo "Error in ${FUNCNAME}: $@" && exit; fi
  local local_REPO_REMOTE_ADDRESS=$1
  local local_WORK_FOLDER=$2
  local local_REPO_LOCAL_DIR=$3
  local local_REPO_REMOTE_BRANCH=''
  rm -rf $local_REPO_LOCAL_DIR
  git clone $local_REPO_REMOTE_ADDRESS $local_REPO_LOCAL_DIR
  for local_REPO_REMOTE_BRANCH in $(AllBrRemRepo $local_REPO_REMOTE_ADDRESS)
  do
    cd $local_REPO_LOCAL_DIR && git checkout $local_REPO_REMOTE_BRANCH && cd $local_WORK_FOLDER
  done
}
## Last commit in the remote repository branch ##
function LastComRemBr {
  if [ $# -ne 2 ]; then echo "Error in ${FUNCNAME}: $@" && exit; fi
  local local_REPO_REMOTE_ADDRESS=$1
  local local_BRANCH=$2
  git ls-remote -h $local_REPO_REMOTE_ADDRESS | grep $local_BRANCH | cut -f 1
}
## Last commit in the local repository branch ##
function LastComLocBr {
  if [ $# -ne 3 ]; then echo "Error in ${FUNCNAME}: $@" && exit; fi
  local local_WORK_FOLDER=$1
  local local_REPO_LOCAL_DIR=$2
  local local_BRANCH=$3
  cd $local_REPO_LOCAL_DIR && \
  git for-each-ref --sort=committerdate refs/heads/ | grep $local_BRANCH | cut -d ' ' -f 1 && \
  cd $local_WORK_FOLDER
}


### Action ###
SetComLocRepo $REPO_REMOTE_ADDRESS $WORK_FOLDER $REPO_LOCAL_DIR
while true
do
  for REM_BRANCH in $(AllBrRemRepo $REPO_REMOTE_ADDRESS)
  do
    if [[ "$(LastComRemBr $REPO_REMOTE_ADDRESS $REM_BRANCH)" == "$(LastComLocBr $WORK_FOLDER $REPO_LOCAL_DIR $REM_BRANCH)" ]]; then
      echo "remote $(LastComRemBr $REPO_REMOTE_ADDRESS $REM_BRANCH) = local $(LastComLocBr $WORK_FOLDER $REPO_LOCAL_DIR $REM_BRANCH)"
#      break
    fi
  done
  sleep $REPO_REMOTE_CHECK_INTERVAL
done
