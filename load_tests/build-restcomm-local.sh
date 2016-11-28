#!/bin/bash

if [ $# -lt 3 ]; then
    echo "No arguments provided. Usage: "
    echo "build-restcomm-local.sh BRANCH_NAME BUILD_WORKSPACE MAJOR_VERSION_NUMBER"
    exit 1
fi

CURRENT_DIR=`pwd`
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`

RESTCOMM_BRANCH=$1
BUILD_WORKSPACE=$2
MAJOR_VERSION_NUMBER=$3

export MAVEN_OPTS="-Xmx1024m -XX:MaxPermSize=256m"
export RUN_TESTSUITE=false
export BUILD_NUMBER=$RESTCOMM_BRANCH-load-test
echo "MAJOR VERSION NUMBER: $MAJOR_VERSION_NUMBER"
echo "RESTCOMM BRANCH: $RESTCOMM_BRANCH"
echo "RUN TESTSUITE: $RUN_TESTSUITE"
#export ANT_HOME=/opt/ant/apache-ant-1.8.3

rm -rf $BUILD_WORKSPACE
mkdir -p $BUILD_WORKSPACE

cp -ar ../* $BUILD_WORKSPACE
cd $BUILD_WORKSPACE

rm Mobicents-Restcomm*.zip
rm dependencies -rf

export DEPENDENCIES_HOME=$BUILD_WORKSPACE/dependencies
mkdir -p $DEPENDENCIES_HOME
export RESTCOMM_HOME=$BUILD_WORKSPACE
export BUILD_RELEASE=$BUILD_WORKSPACE/release
cd $RESTCOMM_HOME
# git checkout -b restcomm-release-$MAJOR_VERSION_NUMBER.$BUILD_NUMBER
# git rev-parse HEAD > git-info-restcomm.txt
echo $MAJOR_VERSION_NUMBER.$BUILD_NUMBER >> mss-version.txt

echo "Workign directory: " `pwd`
mvn versions:set -DnewVersion=$MAJOR_VERSION_NUMBER.$BUILD_NUMBER
#git commit -a -m "New release candidate $MAJOR_VERSION_NUMBER.$BUILD_NUMBER"

cd $BUILD_RELEASE
FILE=$RESTCOMM_HOME/restcomm/configuration/mss-sip-stack.properties
sed -e "s|MAJOR_VERSION_NUMBER.BUILD_NUMBER|$MAJOR_VERSION_NUMBER.$BUILD_NUMBER|g" $FILE > $FILE.bak
mv $FILE.bak $FILE
ant release -f $RESTCOMM_HOME/release/build.xml -Drestcomm.release.version=$MAJOR_VERSION_NUMBER.$BUILD_NUMBER -Drestcomm.branch.name=restcomm-release-$MAJOR_VERSION_NUMBER.$BUILD_NUMBER -Dcheckout.restcomm.dir=$RESTCOMM_HOME -Dworkspace.restcomm.dir=$RESTCOMM_HOME/restcomm -Dcheckout.dir=$DEPENDENCIES_HOME
mv $BUILD_RELEASE/Restcomm-*.zip $BUILD_WORKSPACE/Restcomm-JBoss-AS7.zip

cd $RESTCOMM_HOME/restcomm
#commenting the deploy command as it eats up storage on artifactory
#mvn deploy -Dmaven.test.skip=true

if [ "$RUN_TESTSUITE" = "true" ]
then
mvn -fn test -Dmaven.test.failure.ignore=true
else
echo "Will not run test suite because variable is $RUN_TESTSUITE"
fi

echo "$MAJOR_VERSION_NUMBER.$BUILD_NUMBER" > $BUILD_WORKSPACE/restcomm-version.txt
ls -la $BUILD_WORKSPACE/*.zip
md5sum $BUILD_WORKSPACE/*.zip
sha1sum $BUILD_WORKSPACE/*.zip