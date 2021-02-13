SKIPUNZIP=1

wait_count=0
architecture=""
required_version=""
system_gid="1000"
clash_data_dir="/data/clash"
geoip_file_path="${clash_data_dir}/Country.mmdb"
modules_dir="/data/adb/modules"
wget_https_disable="wget --no-check-certificate"
CPFM_mode_dir="${modules_dir}/clash_premium"
clash_releases_link="https://github.com/Dreamacro/clash/releases"
geoip_download_link="https://github.com/Hackl0us/GeoIP2-CN/raw/release/Country.mmdb"

if [ -d "${CPFM_mode_dir}" ] ; then
    touch ${CPFM_mode_dir}/disable && ui_print "- CPFM模块在重启后将会禁用."
fi

case "${ARCH}" in
    arm)
        architecture="armv7"
        ;;
    arm64)
        architecture="armv8"
        ;;
    x86)
        architecture="386"
        ;;
    x64)
        architecture="amd64"
        ;;
esac

mkdir -p ${MODPATH}/system/bin
mkdir -p ${clash_data_dir}

if [ ! -f ${geoip_file_path} ] ; then
    ui_print "- 开始下载Country.mmdb."
    ${wget_https_disable} ${geoip_download_link} -O ${geoip_file_path}
    if [ -f ${geoip_file_path} ] ; then
        ui_print "- Country.mmdb下载完成."
    fi
fi

install_core() {
    until (cd ${MODPATH}/system/bin && gzip -d clash.gz && ui_print "- clash内核安装成功.") ; do
        wait_count=$((${wait_count} + 1))

        if [ ${wait_count} -ge 6 ] ; then
            abort "- ! 已尝试下载5次,但是都失败了,检查网络环境或者连接代理后重新尝试."
        fi

        ui_print "- 开始第${wait_count}次下载clash内核."
        ${wget_https_disable} ${clash_releases_link}/latest -O ${TMPDIR}/version
        required_version=$(cat ${TMPDIR}/version | grep -o "v[0-9]\.[0-9]\.[0-9]" | sort -u)
        ${wget_https_disable} ${clash_releases_link}/download/${required_version}/clash-linux-${architecture}-${required_version}.gz -O ${MODPATH}/system/bin/clash.gz
    done
}

install_core
unzip -o "${ZIPFILE}" -x 'META-INF/*' -d $MODPATH >&2
mv ${MODPATH}/clash.config ${clash_data_dir}

if [ ! -f "${clash_data_dir}/packages.list" ] ; then
    touch ${clash_data_dir}/packages.list
fi

sed -i "s/version=/version=${required_version}/g" ${MODPATH}/module.prop

sleep 1

ui_print "- 开始设置环境权限."
set_perm_recursive ${MODPATH} 0 0 0755 0644
set_perm_recursive ${MODPATH}/scripts 0 ${system_gid} 0755 0755
set_perm_recursive ${clash_data_dir} 0 ${system_gid} 0755 0644
set_perm  ${MODPATH}/system/bin/clash  0  ${system_gid}  6755
set_perm  ${clash_data_dir}/clash.config 0 ${system_gid} 0755
set_perm  ${clash_data_dir}/packages.list 0 ${system_gid} 0644