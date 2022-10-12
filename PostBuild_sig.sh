#!/bin/bash

page_size=2048

path_padding_fw=tmp/out_with_pad.bin
path_padding_fw_vs_hash=tmp/out_with_hash.bin
path_padding_fw_vs_hash_sig=tmp/out_with_hash_sig.bin
path_padding_fw_vs_hash_sig_key_pub=out_with_hash_sig_key_pub.bin
path_hash=tmp/hash.bin
path_sig_der=tmp/sig.der
path_sig_hex=tmp/sig.hex
path_sig_bin=tmp/sig.bin
path_key_public=ecc_pub.key
path_key_pub_hex=tmp/key_pub.hex
path_key_pub_bin=tmp/key_pub.bin


Help()
{
   # Display Help
   echo "Script for:"
	echo "	- padding firmware by page size, calculate hash, add hash to the end of padding firmware"
	echo "	- extract public key from private, sign hash, convert sign to bin format, add sign to the end of padding firmware"
	echo "	- convert public key to bin and byte array, add public bin key to the end of padding firmware"
   echo
   echo "Syntax: $0 <path to privat key> <path to firmware> [-nodeltmp]"
	echo "		-nodeltmp - flag to no delete tmp directory with in-between calculations"
   echo "Author: Shyshkin Kostiantyn (shyshkin.kostiantyn@gmail.com)"
   echo
}

if [ $# != 2 ] && [ $# != 3 ] || [ $1 == '--help' ]
then
	Help
	exit 0
fi
rm -rf tmp
mkdir tmp

echo "binary file to be handled: " $(realpath G0_AppAuth.bin) 
printf "\n"

echo "########## Calculate padding size ############"
file_size=$(du -b $2 | awk '{print $1}')
padding_need=$(($file_size % 2048))
if [ $padding_need != 0 ]
then
	pad_size=$(($(($(($file_size / $page_size)) + 1)) * $page_size))
else
	pad_size=$file_size
fi

srec_cat $2 -binary -fill 0x00 0x0000 $pad_size -o $path_padding_fw -binary

echo "file size : $file_size bytes"
echo "page size : $page_size"
echo "file size after padding : $pad_size"
printf "\n"

echo "########## Generate hash ############"
openssl dgst -sha256 -binary $path_padding_fw > $path_hash
echo "FW HASH" 
hexdump $path_hash
printf "\n"

echo "########## Generate ecc public key from private key ############"
openssl pkey -in $1 -pubout -out $path_key_public

echo "################# Convert public key to binary #################"
openssl ec -pubin -in $path_key_public -noout -text | grep ":"| grep "    "| sed 's/    //g'| sed 's/:/:/g' | awk -F: '{print $1 $2 $3 $4 $5 $6 $7 $8 $9 $10 $11 $12 $13 $14 $15}' | tr -d '\n' | cut -b 3- > $path_key_pub_hex
xxd -r -p $path_key_pub_hex $path_key_pub_bin

echo "Public key binary:"
hexdump $path_key_pub_bin
printf "\n"
echo "Public key hex array for ecc_pub_key.h:"
cat $path_key_pub_hex | sed 's/../, 0x&/g' | cut -b 3-
printf "\n"

echo "########## Sign hash biary ############"
openssl dgst -sha256 -sign $1 -out $path_sig_der $path_padding_fw

echo "########## Verify signature ############"
openssl pkeyutl -verify -pubin -inkey $path_key_public -sigfile $path_sig_der -in $path_hash

echo "########## Convert signature from asn1 to raw binary ############"
openssl asn1parse -in $path_sig_der -inform DER | awk '{print $7}' | cut -d ":" -f 2 | xargs -L1 echo | tr -d '\n' >> $path_sig_hex
xxd -r -p $path_sig_hex $path_sig_bin
echo "FW signature:"
hexdump $path_sig_bin
printf "\n"

echo "########## Generate bin + padding + hash ############"
cat $path_padding_fw $path_hash > $path_padding_fw_vs_hash
echo "########## Generate bin + padding + hash + sig ############"
cat $path_padding_fw_vs_hash $path_sig_bin > $path_padding_fw_vs_hash_sig
echo "########## Generate bin + padding + hash + sig + pubkey ############"
cat $path_padding_fw_vs_hash_sig $path_key_pub_bin > $path_padding_fw_vs_hash_sig_key_pub
printf "\n"
echo "Binary with Signature to be flashed: " $(realpath $path_padding_fw_vs_hash_sig_key_pub)

if [ $# != 3 ] || [ $3 != "-nodeltmp" ]
then
	rm -rf tmp
fi

