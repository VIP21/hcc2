#!/bin/bash
#
#  build-deb-libamdgcn.sh   Uing debhelper and alien, build the libamdgcn noarch debian and rpm packages.
#                      This script needs packages: debuitils,devscripts,cli-common-dev,alien
#                      A complete build of libamdgcn in /opt/rocm/libamdgcn_$HCC2_VERSION_STRING
#                      is required before running this script.
#                      You must also have sudo access to build the debs.
#                      You will be prompted for your password for sudo.

#
pkgname=libamdgcn
version="0.4"
mod="0"
dirname="libamdgcn_$version-$mod"
sourcedir="/opt/rocm/$dirname"
installdir="/opt/rocm/$dirname"

DEBFULLNAME="Greg Rodgers"
DEBEMAIL="Gregory.Rodgers@amd.com"
export DEBFULLNAME DEBEMAIL

echo "opt/rocm/$dirname opt/rocm/libamdgcn" > debian/$pkgname.links
echo "opt/rocm/$dirname" > debian/$pkgname.install
echo "usr/share/doc/$dirname" >> debian/$pkgname.install

tmpdir=/tmp/$USER/build-deb
builddir=$tmpdir/$pkgname
if [ -d $builddir ] ; then 
   echo "Cleanup: rm -rf $builddir"
   sudo rm -rf $builddir
fi
echo
debdir=$PWD/debian-libamdgcn
froot=$builddir/$pkgname-${version}
mkdir -p $froot$installdir
mkdir -p $froot/usr/share/doc/$dirname

echo 
echo "PREPARING fake root directory $froot... "
rsync -a $sourcedir"/" --exclude "\.git" $froot$installdir
cp $debdir/copyright $froot/usr/share/doc/$dirname/.
cp $debdir/LICENSE.TXT $froot/usr/share/doc/$dirname/.
# changes the name from debian-libamdgcn to debian
rsync -a $debdir/ $froot/debian/

echo 
echo "BUILDING TARBALL $builddir/${pkgname}_${version}.orig.tar.gz "
echo "FROM THE FAKEROOT $froot ... "
cd $builddir
tar -czf $builddir/${pkgname}_${version}.orig.tar.gz ${pkgname}-${version}

echo 
echo "RUNNING dch to manage the changelog "
cd  $froot
echo dch -v ${version}-${mod} -e --package $pkgname
dch -v ${version}-${mod} --package $pkgname
# put the updated changelog back
cp -p $froot/debian/changelog $debdir/.

debuildargs="-us -uc -rsudo --lintian-opts -X files,changelog-file,fields"
echo 
echo "RUNNING debuild $debuildargs "
debuild $debuildargs 
# put the updated changelog back
cp -p $froot/debian/${pkgname}.debhelper.log $debdir/.

mkdir -p $tmpdir/debs
debfile="$tmpdir/debs/${pkgname}_$version-${mod}_all.deb" 
if [ -f "$debfile" ] ; then 
  rm -f $debfile
fi
mv $builddir/${pkgname}_$version-${mod}_all.deb $debfile
mkdir -p $tmpdir/rpms
cd $tmpdir/rpms
echo sudo alien -k --scripts --to-rpm $debfile
sudo alien -k --scripts --to-rpm $debfile
echo 
echo "DONE Debian package is in $debfile"
echo "     rpm package is in $tmpdir/rpms/${pkgname}_$version-${mod}.noarch.rpm"
echo 
