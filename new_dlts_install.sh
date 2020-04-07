#!/bin/sh

CUDNN_VERSION="7.3.0.29"
#LABEL com.nvidia.cudnn.version="${CUDNN_VERSION}"
solaris_branch=master


# prep apt-get and cudnn
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends apt-utils libcudnn7=${CUDNN_VERSION}-1+cuda9.0  libcudnn7-dev=$CUDNN_VERSION-1+cuda9.0
sudo apt-mark hold libcudnn7
sudo rm -rf /var/lib/apt/lists/*

# install requirements
sudo apt-get update -y

sudo apt-get install -y --no-install-recommends \
    bc \
    bzip2 \
    ca-certificates \
    curl \
    emacs \
    git \
    less \
    libgdal-dev \
    libssl-dev \
    libffi-dev \
    libncurses-dev \
    libgl1 \
    jq \
    nfs-common \
    parallel \
    python-dev \
    python-pip \
    python-wheel \
    python-setuptools \
    tree \
    unzip \
    vim \
    wget \
    xterm \
    build-essential
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

#SHELL ["/bin/bash", "-c"]
export PATH=/opt/conda/bin:$PATH


# install anaconda
wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.5.4-Linux-x86_64.sh -O ~/miniconda.sh

sh miniconda.sh -b -p /opt/conda
rm ~/miniconda.sh
/opt/conda/bin/conda clean -tipsy
ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc
echo "conda activate base" >> ~/.bashrc

# prepend pytorch and conda-forge before default channel
conda update -n base -c defaults conda
conda config --prepend channels conda-forge
conda config --prepend channels pytorch

mkdir code cd code
git clone https://github.com/cosmiq/solaris.git && \
cd solaris
git checkout ${solaris_branch}
conda env create -f environment-gpu.yml
export PATH=/opt/conda/envs/solaris/bin:$PATH

source activate solaris
sudo pip install git+git://github.com/toblerity/shapely.git
cd solaris
sudo pip install .

cd /zhuoyu_exp/code/CosmiQ_SN6_Baseline

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
