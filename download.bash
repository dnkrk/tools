#!/usr/bin/env bash
# See README.md for instructions and usage notes.


# Initialize
SECONDS=0 

if [ -z "$1" ]
  then
    echo "No url supplied. Example usage: $0 url"
    exit 1
fi
url=$1

length=$(wget $url --spider -o - | grep Length | awk '{print $2}')
chunk_size=10485760  # 10MB
((chunks=length/chunk_size))
((last_chunk=length%chunk_size))

if [ -z $length ];
then
    echo "Invalid URL, remote file dos not exist."
    exit 1
fi

decoded=$(echo -e ${url//%/\\x})
final_filename=${decoded##*/}
echo $final_filename
mkdir tmp_download
pushd tmp_download


# Launch $chunks background wget processes limited in size by ulimit
for (( i=0; i<chunks; i++ ))
do
    filename=$i.part
    ((offset=i*chunk_size))

    blocksize=1024
    ((blocks=chunk_size/blocksize))
    ((block_rem=chunk_size%blocksize))
    if [ $block_rem -ne 0 ];
    then
        echo "Chosen chunk size is not a multiple of ulimit block size $blocksize."
        exit 1;
    fi

    if [[ -f "$filename" && ( $(wc -c < "$filename") == $chunk_size) ]];
    then
        echo "$filename already fully downloaded, skipping."
    else
        (ulimit -f $blocks; wget -O $filename --start-pos=$offset $url)&
    fi

done


# Download last chunk
((last_offset=chunks*chunk_size))
filename="last.part"
if [[ -f "$filename" && ( $(wc -c < "$filename") == $last_chunk) ]];
then
    echo "$filename already fully downloaded, skipping."
else
    rm $filename
    wget -O "$filename" --start-pos=$last_offset $url&
fi

wait


# Concatenate parts
echo "Download finished, concatenating downloaded chunks..."
popd
outfile="temp_outfile"
rm -f $outfile
touch $outfile

for (( i=0; i<chunks; i++ ))
do
    filename=$i.part
    echo "Concatenating part $i/$chunks"
    cat tmp_download/$filename >> $outfile
done
cat "tmp_download/last.part" >> $outfile

echo "Validating file..."

if [[ ( $(wc -c < "$outfile") != $length) ]];
then
    echo "Something went wrong, the created file is of invalid size:"
    echo "$(wc -c < $outfile) vs the expected $length"
    echo "It's possible a number of chunks failed to download, check inside tmp_download and try running the script again."
    rm $outfile
    exit 1
else
    mv $outfile "$final_filename"
    rm -rf tmp_download
    ((mins=SECONDS/60))
    ((secs=SECONDS%60))
    echo "File is valid, download finished in $mins min $secs sec."
fi
exit 0
