#!/bin/sh
# FFmpegAVS2 build script (MODIFIED FOR LOCAL ZIP FILES)

touch build.log
echo "BUILD TIME: $(date +%Y-%m-%d)" > build.log

if test -t 1 && which tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
    if test -n "$ncolors" && test $ncolors -ge 8; then
        msg_color=$(tput setaf 3)$(tput bold)
        error_color=$(tput setaf 1)$(tput bold)
        reset_color=$(tput sgr0)
    fi
    ncols=$(tput cols)
fi

checkfail()
{
    echo "$error_color""ERROR: $@ failed.$reset_color"
    exit 1
}

printLog()
{
    echo ">>> $@" >> $build_dir/build.log
    $@ >> $build_dir/build.log 2>&1
}

# NEW FUNCTION: To extract ZIP files
extractZipSource()
{
    local zip_file=$1         # e.g., FFmpegAVS2-n3.4_avs2.zip
    local expected_dir=$2     # e.g., FFmpegAVS2
    local extracted_dir=$3    # e.g., FFmpegAVS2-n3.4_avs2

    echo ">>>>"
    echo " -------------------------------------------------------------------------- "
    echo " Unpacking: $zip_file "
    echo " -------------------------------------------------------------------------- "

    if [ ! -f "$zip_file" ]; then
        checkfail "ZIP file $zip_file not found. Please download it first."
    fi

    if [ -d "$expected_dir" ]; then
        echo "Directory $expected_dir already exists. Skipping extraction."
    else
        echo "Extracting $zip_file..."
        unzip -q $zip_file || checkfail "unzip $zip_file failed"
        echo "Renaming $extracted_dir to $expected_dir..."
        mv "$extracted_dir" "$expected_dir" || checkfail "mv $extracted_dir failed"
    fi
    echo "success..."
}


# current dir
build_dir=`pwd`

# Clean up old directories to ensure a fresh build
echo "$msg_color[Cleaning up old directories...]$reset_color"
rm -rf FFmpegAVS2 xavs2 davs2 avs2_lib
echo "Cleanup complete."

# Unpack sources from local ZIP files
extractZipSource "FFmpegAVS2-n3.4_avs2.zip" "FFmpegAVS2" "FFmpegAVS2-n3.4_avs2"
extractZipSource "xavs2-master.zip" "xavs2" "xavs2-master"
extractZipSource "davs2-master.zip" "davs2" "davs2-master"


###############################
# build xavs2 encoder
###############################
echo "$msg_color[Start building xAVS2 encoder]$reset_color"
cd xavs2/build/linux  # xAVS2 directory
printLog ./configure --prefix=$build_dir/avs2_lib \
            --enable-pic \
            --enable-shared \
            --disable-asm
printLog make -j8 || checkfail "make failed"
printLog make install
cd -

###############################
# build davs2 decoder
###############################
echo "$msg_color[Start building dAVS2 decoder]$reset_color"
cd davs2/build/linux  # dAVS2 directory
printLog ./configure --prefix=$build_dir/avs2_lib \
            --enable-pic \
            --enable-shared \
            --disable-asm
printLog make -j8 || checkfail "make failed"
printLog make install
cd -

###############################
# build ffmpeg decoder
###############################
echo "$msg_color[Start building FFmpegAVS2]$reset_color"
cd FFmpegAVS2

# REMOVED: git checkout is no longer needed as we are using the correct source from the ZIP

export PKG_CONFIG_PATH=$build_dir/avs2_lib/lib/pkgconfig
printLog ./configure \
  --prefix=$build_dir/avs2_lib \
  --enable-gpl \
  --enable-libxavs2 \
  --enable-libdavs2 \
  --enable-shared \
  --enable-static \
  --disable-asm   # Disable assembly to prevent compilation errors on modern systems

printLog make -j8 || checkfail "make failed"
printLog make install
cd -

echo ""
echo "$msg_color""Everything done!$reset_color"
echo "The compiled libraries and executables are in the 'avs2_lib' directory."
