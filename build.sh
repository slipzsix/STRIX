#!/bin/bash
#
# ANDROID scripts building linux kernel k4.14
#

if [ ! -d "clang" ]; then
    mkdir clang && curl  https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/clang-r547379.tar.gz -RLO && tar -C clang/ -xf clang-*.tar.gz
else
	echo "Local clang dir found, will not download clang and using that instead"
fi
 
if [ ! -d "KernelSU" ]; then
curl -LSs "https://raw.githubusercontent.com/ShirkNeko/SukiSU-Ultra/main/kernel/setup.sh" | bash -s susfs-dev
else
	echo "Local KernelSU dir found, will not download KernelSU and using that instead"
fi
                      
echo -e "$blue***********************************************"
echo -e "      SELECTED BUILD TYPE                          "
echo -e "***********************************************$nocol"
echo "1. miui"
echo "2. aosp"
read -p "Enter the number of your choice: " build_choice
# Modify dtsi file if MIUI build is selected
if [ "$build_choice" = "1" ]; then
    sed -i 's/qcom,mdss-pan-physical-width-dimension = <69>;$/qcom,mdss-pan-physical-width-dimension = <695>;/' arch/arm64/boot/dts/qcom/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    sed -i 's/qcom,mdss-pan-physical-height-dimension = <154>;$/qcom,mdss-pan-physical-height-dimension = <1546>;/' arch/arm64/boot/dts/qcom/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    DISPLAY="MIUI"
elif [ "$build_choice" = "2" ]; then
    sed -i 's/qcom,mdss-pan-physical-width-dimension = <695>;$/qcom,mdss-pan-physical-width-dimension = <69>;/' arch/arm64/boot/dts/qcom/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    sed -i 's/qcom,mdss-pan-physical-height-dimension = <1546>;$/qcom,mdss-pan-physical-height-dimension = <154>;/' arch/arm64/boot/dts/qcom/dsi-panel-k6-38-0c-0a-fhd-dsc-video.dtsi
    DISPLAY="AOSP"
    else
    echo "Invalid choice. Exiting..."
    exit 1
fi

echo -e "$blue***********************************************"
echo "          BUILDING KERNEL $DISPLAY                  "
echo -e "***********************************************$nocol"
export PATH="${PWD}/clang/bin/:${PATH}"
export ARCH=arm64
export KBUILD_BUILD_USER=nobody
export KBUILD_BUILD_HOST=android-build
export KBUILD_COMPILER_STRING="${PWD}/clang"
make O=out vendor/sweet_defconfig
make -j$(nproc --all) O=out \
                              ARCH=arm64 \
                              LLVM=1 \
                              LLVM_IAS=1 \
                              AR=llvm-ar \
                              NM=llvm-nm \
                              LD=ld.lld \
                              OBJCOPY=llvm-objcopy \
                              OBJDUMP=llvm-objdump \
                              STRIP=llvm-strip \
                              CC=clang \
                              CROSS_COMPILE=aarch64-linux-gnu- \
                              CROSS_COMPILE_ARM32=arm-linux-gnueabi 2>&1 | tee -a build.log

if [ ! -f "out/arch/arm64/boot/Image.gz" ]; then
    echo -e "\nKernel compiled successfully! Zipping up...\n"
    if [ ! -d "AnyKernel3" ]; then
    git clone --depth=1 https://github.com/basamaryan/AnyKernel3 -b master AnyKernel3
    else
	echo "Local Anykernel3 dir found, will not download Anykernel3 and using that instead"
    fi
    cp out/arch/arm64/boot/Image.gz AnyKernel3/Image.gz
    cp out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img
    cp out/arch/arm64/boot/dtb.img AnyKernel3/dtb.img
    cd AnyKernel3
    zip -r9 "../STRIX-${DISPLAY}-Personal-$(date '+%Y%m%d-%H%M').zip" * -x .git
    cd ..
    rm -rf AnyKernel3/Image.gz
    rm -rf AnyKernel3/dtbo.img
    rm -rf AnyKernel3/dtb.img
	echo -e "\nCompilation failed!"
	exit 1
fi
echo -e "$blue***********************************************"
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo -e "***********************************************$nocol"
