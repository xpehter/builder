#!/bin/bash
#
# Test task from SKB Kontur:
# https://github.com/kontur-exploitation/testcase-pybash

#REPO_REMOTE_ADDRESS='https://github.com/kontur-exploitation/testcase-pybash.git'
REPO_REMOTE_ADDRESS='https://github.com/xpehter/kont_test.git'
#REPO_REMOTE_ADDRESS='https://github.com/xpehter/ideco.git'
REPO_LOCAL_DIR='dirik'
REPO_REMOTE_CHECK_INTERVAL=5  # seconds
PATH_LOG='./xuilder.log'
APP_VERSION=1.0  # Ideally, the version should be taken from the repository
IMAGE_NAME='node-web-app'


### Functions ###
## All branches in a remote repository ##
function AllBrRemRepo {
  if [ $# -ne 1 ]; then echo "Error in ${FUNCNAME}: $*" && exit; fi
  local local_REPO_REMOTE_ADDRESS=$1
  git ls-remote -h "$local_REPO_REMOTE_ADDRESS" | rev | cut -d '/' -f 1 | rev
}
## Set commits in the local repository copy ##
function SetComLocRepo {
  if [ $# -ne 2 ]; then echo "Error in ${FUNCNAME}: $*" && exit; fi
  local local_REPO_REMOTE_ADDRESS=$1
  local local_REPO_LOCAL_DIR=$2
  local local_REPO_REMOTE_BRANCH=''
  rm -rf "$local_REPO_LOCAL_DIR"
  git clone "$local_REPO_REMOTE_ADDRESS" "$local_REPO_LOCAL_DIR"
  for local_REPO_REMOTE_BRANCH in $(AllBrRemRepo "$local_REPO_REMOTE_ADDRESS")
  do
    git -C "$local_REPO_LOCAL_DIR" checkout "$local_REPO_REMOTE_BRANCH" # For 'git -C <directory>' requires Git v1.8.5 and later
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
  if [ $# -ne 2 ]; then echo "Error in ${FUNCNAME}: $@" && exit; fi
  local local_REPO_LOCAL_DIR=$1
  local local_BRANCH=$2
  git -C $local_REPO_LOCAL_DIR for-each-ref --sort=committerdate refs/heads/ | grep $local_BRANCH | cut -d ' ' -f 1
}
## Set build number ##
function SetBldNum {
  if [ $# -gt 1 ]; then echo "Error in ${FUNCNAME}: $*" && exit; fi
  local local_PATH_LOG=$PATH_LOG
  if test -f "$local_PATH_LOG" ; then
    BUILD_NUMBER="$(tail -n 1 $local_PATH_LOG | cut -d ' ' -f 6 | cut -d ':' -f 1)"
    if [ -z "$BUILD_NUMBER" ]; then echo "Error in ${FUNCNAME}: BUILD_NUMBER is NULL" && exit 1; fi
    if [ $# -gt 0 ]; then (( BUILD_NUMBER=BUILD_NUMBER+${1} )); fi
  else
    BUILD_NUMBER=1
  fi
}
## Writing a log ##
function WriteLog {
  if [ $# -ne 1 ]; then echo "Error in ${FUNCNAME}: $*" && exit; fi
  local local_BUILD_NUMBER=$BUILD_NUMBER
  local local_APP_VERSION=$APP_VERSION
  local local_MESSAGE=$1
  local local_PATH_LOG=$PATH_LOG
  if [ -z "$BUILD_NUMBER" ]; then echo "Error in ${FUNCNAME}: BUILD_NUMBER is NULL" && exit 1; fi
  echo "$(date +'%F %T') ver $local_APP_VERSION build ${local_BUILD_NUMBER}: $local_MESSAGE" >> "$local_PATH_LOG"
}
## Image building ##
function ImgBld {
  local local_REPO_LOCAL_DIR=$REPO_LOCAL_DIR
  local local_APP_VERSION=$APP_VERSION
  local local_branch=$(git -C $local_REPO_LOCAL_DIR branch | grep '*' | cut -d ' ' -f 2)
  docker build \
    -t "${IMAGE_NAME}:${local_branch}-${local_APP_VERSION}.${BUILD_NUMBER}" \
    --build-arg arg_REPO_LOCAL_DIR=${local_REPO_LOCAL_DIR} \
    --label "branch=$local_branch" \
    --label "сommit=$(git -C $local_REPO_LOCAL_DIR log --pretty=format:"%H" | head -n 1)" \
    --label "maintainer=$(git -C $local_REPO_LOCAL_DIR log --pretty=format:"%an" | head -n 1)" .
}
## Run container ##
function RunCont {
  local local_branch=$(git -C $REPO_LOCAL_DIR branch | grep '*' | cut -d ' ' -f 2)
  local local_OLD_CONT=$(docker ps -a --format {{.Names}} | grep ${IMAGE_NAME}_${local_branch})
  if [ ! -z "$local_OLD_CONT" ]; then
    docker stop "$local_OLD_CONT" && \
    docker rm "$local_OLD_CONT"
  fi
  docker run \
    -p 127.0.0.1:80:80 \
    --name "${IMAGE_NAME}_${local_branch}-${APP_VERSION}.${BUILD_NUMBER}" \
    -d "${IMAGE_NAME}:${local_branch}-${APP_VERSION}.${BUILD_NUMBER}"
}

### Action ###
SetComLocRepo $REPO_REMOTE_ADDRESS $REPO_LOCAL_DIR
for REM_BRANCH_FR in $(AllBrRemRepo $REPO_REMOTE_ADDRESS)
do
  git -C $REPO_LOCAL_DIR checkout $REM_BRANCH_FR
  SetBldNum 1
  WriteLog 'Start image building'
  ImgBld
  WriteLog 'Build image completed'
  RunCont
  WriteLog 'Container started'
done
while true
do
  for REM_BRANCH in $(AllBrRemRepo $REPO_REMOTE_ADDRESS)
  do
    if [[ "$(LastComRemBr $REPO_REMOTE_ADDRESS $REM_BRANCH)" != "$(LastComLocBr $REPO_LOCAL_DIR $REM_BRANCH)" ]]; then
      echo "remote $(LastComRemBr $REPO_REMOTE_ADDRESS $REM_BRANCH) = local $(LastComLocBr $REPO_LOCAL_DIR $REM_BRANCH)"
      SetComLocRepo $REPO_REMOTE_ADDRESS $REPO_LOCAL_DIR
      git -C $REPO_LOCAL_DIR checkout $REM_BRANCH
      SetBldNum 1
      WriteLog 'Start image building'
      ImgBld
      WriteLog 'Build image completed'
      RunCont
      WriteLog 'Container started'
#      break
      WriteLog 'In while'
    fi
  done
  sleep $REPO_REMOTE_CHECK_INTERVAL
done
