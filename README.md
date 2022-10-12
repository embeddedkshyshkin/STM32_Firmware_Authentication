# STM32_Firmware_Authentication
Bash script for STM32 firmware Authentication preparation 

## Usage
* Generate ecc private key with NIST p256 curve
* Compile binary stm32 firmware
* Run script with parameters:
  `./PostBuild_sig.sh <path to private key> <path to firmware binary> [-nodeltmp]`
* Upload ready binary firmware to controller

## Description: 
* Padding firmware to 2048 size page `openssl ecparam -name prime256v1 -genkey -out ecc.key`
* Genarate hash of padding firmware
* Add hash to the end of padding firmware
* Make signature of hash by private key
* Convert signature to binary format
* Generate public key from private key
* Verify public key with signature
* Add signature to the end of firmware with hash
* Convert public key to binary format
* Add binary public key to the end of firmare
* Convert public key to hex array

## Enviroment:
- openssl
- srec_cat

## Attention:
* To finish, you need activate WRP protection of region where hash + signature + public key located
* Make RDP to level at least 1

## Author Shyshkin Kostiantyn (shyshkin.kostiantyn@gmail.com)
