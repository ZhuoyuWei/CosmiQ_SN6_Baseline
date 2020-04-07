#!/bin/bash



EXP_ID=$1
solaris_branch=master

#output dir setting
WDATA_DIR=/data/zhuoyu/spacenet6/wdata
OUTPUT_DIR=$WDATA_DIR/$EXP_ID
mkdir $OUTPUT_DIR

#envirement
sudo apt-get update
sudo apt-get install -y --no-install-recommends bc bzip2 ca-certificates curl emacs git less libgdal-dev libssl-dev libffi-dev libncurses-dev libgl1 jq nfs-common parallel python-dev python-pip python-wheel python-setuptools tree unzip zip vim wget xterm build-essential

cd /
EXP_ROOT_DIR=/zhuoyu_exp
sudo mkdir $EXP_ROOT_DIR
sudo chmod 777 $EXP_ROOT_DIR
cd $EXP_ROOT_DIR
pwd
ls



#code
sudo pip install "rtree>=0.8,<0.9"
cd ${EXP_ROOT_DIR}
mkdir rtree_code
cd rtree_code
git clone https://github.com/Toblerity/rtree.git
cd rtree
sudo pip install .

CODE_DIR=${EXP_ROOT_DIR}/code
mkdir ${CODE_DIR}
cd ${CODE_DIR}
git clone https://github.com/cosmiq/solaris.git
sudo pip install geopandas
cd solaris
git checkout ${solaris_branch}
sudo pip install git+git://github.com/toblerity/shapely.git
sudo pip install .

#running code
cd ${EXP_ROOT_DIR}
mkdir running_code
cd running_code
git clone https://github.com/ZhuoyuWei/CosmiQ_SN6_Baseline.git
cd CosmiQ_SN6_Baseline




traindatapath=/data/zhuoyu/spacenet6/unzip_dir/AOI_11_Rotterdam
testdatapath=/data/zhuoyu/spacenet6/unzip_dir/test/test_public/AOI_11_Rotterdam

traindataargs="\
--sardir $traindatapath/SAR-Intensity \
--opticaldir $traindatapath/PS-RGB \
--labeldir $traindatapath/geojson_buildings \
--rotationfile $traindatapath/SummaryData/SAR_orientations.txt \
"

dstdir=/root

settings="\
--rotationfilelocal $dstdir/SAR_orientations.txt \
--maskdir $dstdir/masks \
--sarprocdir $dstdir/sartrain \
--opticalprocdir $dstdir/optical \
--traincsv $dstdir/train.csv \
--validcsv $dstdir/valid.csv \
--opticaltraincsv $dstdir/opticaltrain.csv \
--opticalvalidcsv $dstdir/opticalvalid.csv \
--testcsv $dstdir/test.csv \
--yamlpath $dstdir/sar.yaml \
--opticalyamlpath $dstdir/optical.yaml \
--modeldir $dstdir/weights \
--testprocdir $dstdir/sartest \
--testoutdir $dstdir/inference_continuous \
--testbinarydir $dstdir/inference_binary \
--testvectordir $dstdir/inference_vectors \
--rotate \
--transferoptical \
--mintrainsize 20 \
--mintestsize 80 \
"


python baseline.py --pretrain --train $traindataargs $settings



outputpath=$OUTPUT_DIR
testdataargs="\
--testdir $testdatapath/SAR-Intensity \
--outputcsv $outputpath \
"


python baseline.py --pretest --test $testdataargs $settings
