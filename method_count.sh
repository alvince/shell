#! /bin/bash

sdk_dir=$ANDROID_HOME
if [ -z $sdk_dir ]; then
    sdk_dir=$ANDROID_SDK
fi
if [ -z $sdk_dir ]; then
    echo 'No android sdk configured'
    exit 1
fi

file=$1
f_name=${file##*/}
f_suffix=${f_name##*.}
if [ -z $f_suffix ]; then
    echo 'Invalid file type'
    exit 2
fi

opt_type=0
echo "Targe file: [ ${f_name%.*} ] [ $f_suffix ]"
case $f_suffix in
    dex)
        opt_type=1
        ;;
    apk)
        opt_type=2
        ;;
    jar)
        opt_type=3
        ;;
    ?)
        echo 'Non support file type'
        exit 1
        ;;
esac

function __dump_methods_count_from_dex() {
    dex_target=$1
    count=`cat $dex_target | head -c 92 | tail -c 4 | hexdump -e '1/4 "%d\n"'`
    echo "Methods count: " $count
}

temp=`ls $sdk_dir/build-tools | sort -V`
build_tools=`echo $temp | awk '{print $NF}'`
echo 'Use android build tools' $build_tools
build_tools_dir=$sdk_dir/build-tools/$build_tools

echo 'Dump methods from' ${file##*/}
case $opt_type in
    1)
        __dump_methods_count_from_dex $file
        ;;
    2)
        $build_tools_dir/dexdump -f $file | grep method_ids_size
        ;;
    3)
        if [ ! -d $HOME/.tmp ]; then
            mkdir -p $HOME/.tmp
        fi
        dump_tmp="$HOME/.tmp/${f_name%.*}.dex"
        $build_tools_dir/dx --dex --verbose --no-strict \
            --output=$dump_tmp $file > ~/.tmp/dx_dump_temp.log
        __dump_methods_count_from_dex $dump_tmp
        ;;
    ?)
        echo 'Non support file type'
        exit 1
        ;;
esac

exit 0
