#
#script daemon and logging support by nohup
#
#TODO: replace shell scripting by LUA?
#
export LANG=C
export PATH=${PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#
export SCRIPTLOGFILE=''
#
export ALLARGS="$@"
#
export SCRIPTPID="$$"
#
export SCRIPTTAG="$0"
#
export SCRIPTSELFT="$0"
#
export SCRIPTMARK="$(echo "$SCRIPTSELFT" | tr '/-' '_')"
#
export DAEMONED
#
if [ -z "$TARGETARCH" ]
then
    #TODO: replace with actually target
    TARGETARCH="aarch64-linux"
	#TARGETARCH=$(cat /proc/xiaoqiang/model)
fi
#
export TARGETARCH
#
#for debug
#export DAEMONSTDIOFILE="/tmp/daemon/stdio/${SCRIPTMARK}.log"
if [ -z "$DAEMONSTDIOFILE" ]
	then
	DAEMONSTDIOFILE='/dev/null'
fi
export DAEMONSTDIOFILE
#
if [ -z "$DAEMONSYSLOGFILE" ]
	then
	DAEMONSYSLOGFILE='syslog'
	#
	#%##DAEMONSYSLOGFILE=$(cat /etc/config/system 2>/dev/null| grep log_file | awk '{print $3}' | tr -d "'")
	#%##if [ -z "$DAEMONSYSLOGFILE" ]
	#%##then
	#%##	DAEMONSYSLOGFILE='/var/log/messages'
	#%##fi
	#%##basexec mkdir -p $(dirname $DAEMONSYSLOGFILE 2>/dev/null)
fi
#
export DAEMONSYSLOGFILE
#
#ash array support, no lock, no cleanup/gc, use carefully
#
export SCRIPTARRAYDIR="/tmp/arrays/${SCRIPTMARK}/"
#
klogger(){
	local msg="$@"
	test -z "$msg" && return 1
	#echo "$msg"
	echo "$msg" >> /dev/kmsg 2>/dev/null
	return 0
}
logexit(){
	local msg="$@"
	klogger "$msg"
	elog "$msg"
	exit 1
}
basexec(){
	local cmdline="$@"
	test -z "$cmdline" && return 1
	$cmdline
	if [ $? -ne 0 ]
		then
		logexit "ERROR: BASEXEC FAILED: $cmdline, PROC EXITED."
	fi
	return 0
}
#
getdefaultrouteip(){
	echo "$(ip route list | grep '^default via ' | grep -v 'tap' | head -n 1| awk '{print $3}')"
}
getdefaultroutedev(){
	echo "$(ip route list | grep '^default via ' | grep -v 'tap' | head -n 1| awk '{print $5}')"
}
getactivegatewayip(){
	echo "$(ip route list | grep '^default via ' | head -n 1| awk '{print $3}')"
}
getactivegatewaydev(){
	echo "$(ip route list | grep '^default via ' | grep -v 'tap' | head -n 1| awk '{print $5}')"
}
getlanip(){
	echo "`ip route list dev br-lan | head -n1|awk '{print $7}'`"
}
getlanipmask(){
	echo "`ip route list dev br-lan | head -n1|awk '{print $1}'`"
}
lanipwait(){
	lanip='no-ip'
	wcnt=0
	timelimit="$1"
	test -z "$timelimit" && timelimit=30
	lanip=`getlanip`
	#conlog "DEBUG: waiting up to $timelimit seconds for lan ip setup."
	while [ $wcnt -lt $timelimit ]
	do
		lanip=`getlanip`
		if [ -n "$lanip" ]
			then
			break
		fi
		sleep 1
		let wcnt=$wcnt+1
	done
	#
	if [ -z "$lanip" ]
		then
		if [ $timelimit -le 0 ]
			then
			return 1
		fi
		dlog "ERROR: probe lan ip failed: $(/sbin/ifconfig br-lan 2>&1)"
		/sbin/ifconfig | grep -q '^br-lan'
		if [ $? -ne 0 ]
			then
			dlog "WARNING: network interface br-lan no exist."
		fi
		dlog "ERROR: lan ip no configured after $timelimit seconds."
		return 1
	fi
	if [ $timelimit -le 0 ]
		then
		return 0
	fi
	dlog "LAN ip config: $lanip"
	return 0
}
iptexec(){
	local exitcode
	local execline
	local capfile
	local execnt
	execline="$@"
	test -z "$execline" && return 0
	basexec mkdir -p /tmp/logexec/
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	exitcode=0
	for execnt in 1 2 3 4 5 6
	do
		$execline > $capfile 2>&1
		exitcode=$?
		if [ $exitcode -ne 0 ]
		then
			cat $capfile 2>/dev/null | grep -iq 'Resource temporarily unavailable'
			if [ $? -ne 0 ]
				then
				break
			else
				sleep 1
			fi
		else
			break
		fi
	done
	if [ $exitcode -ne 0 ]
		then
		dlog "iptexec final: exitcode $exitcode, $execline"
		cat $capfile 2>/dev/null | pipelog dlog
	fi
	rm -f $capfile
	return $exitcode
}
iptsexec(){
	local exitcode
	local execline
	local capfile
	local execnt
	execline="$@"
	test -z "$execline" && return 0
	basexec mkdir -p /tmp/logexec/
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	exitcode=0
	for execnt in 1 2 3 4 5 6
	do
		$execline > $capfile 2>&1
		exitcode=$?
		if [ $exitcode -ne 0 ]
		then
			cat $capfile 2>/dev/null | grep -iq 'Resource temporarily unavailable'
			if [ $? -ne 0 ]
				then
				break
			else
				sleep 1
			fi
		else
			break
		fi
	done
	rm -f $capfile
	return $exitcode
}
iptnewchain(){
	local exitcode
	local execline
	local capfile
	local execnt
	execline="$@"
	test -z "$execline" && return 0
	execline="iptables $execline"
	basexec mkdir -p /tmp/logexec/
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	exitcode=0
	for execnt in 1 2 3 4 5 6
	do
		$execline > $capfile 2>&1
		exitcode=$?
		if [ $exitcode -ne 0 ]
		then
			#
			cat $capfile 2>/dev/null | grep -iq 'Chain already exists'
			test $? -eq 0 && exitcode=0 && break
			cat $capfile 2>/dev/null | grep -iq 'Resource temporarily unavailable'
			if [ $? -ne 0 ]
				then
				break
			else
				sleep 1
			fi
		else
			break
		fi
	done
	if [ $exitcode -ne 0 ]
		then
		dlog "iptnewchain final: exitcode $exitcode, $execline"
		cat $capfile 2>/dev/null | pipelog dlog
	fi
	rm -f $capfile
	return $exitcode
}
iptremoverule(){
	local exitcode
	local execline
	local capfile
	local execnt
	execline="$@"
	test -z "$execline" && return 0
	execline="iptables $execline"
	basexec mkdir -p /tmp/logexec/
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	exitcode=0
	for execnt in 1 2 3 4 5 6 7 8 9 0
	do
		$execline > $capfile 2>&1
		exitcode=$?
		#delete more
		test $exitcode -eq 0 && continue

		cat $capfile 2>/dev/null | grep -iq 'No chain/target/match by that name'
		test $? -eq 0 && exitcode=0 && break

		cat $capfile 2>/dev/null | grep -iq 'Resource temporarily unavailable'
		test $? -ne 0 && break
		#
		#iptables v1.4.10: Couldn't load target `lanuploadtraffic':File not found
		#
		cat $capfile 2>/dev/null | grep -iq 'File not found'
		test $? -ne 0 && exitcode=0 && break

		#other errors
		sleep 1
	done
	if [ $exitcode -ne 0 ]
		then
		dlog "iptremoverule final: exitcode $exitcode, $execline"
		cat $capfile 2>/dev/null | pipelog dlog
	fi
	rm -f $capfile
	return $exitcode
}
#
iptremoveall(){
	iptremoverule $@
	return $?
}
#
killpid(){
	local onepid ksig
	onepid=$1
	ksig=$2
	if [ -z "$onepid" ]
	then
		return 0
	fi
	test -z "$ksig" && ksig=15
	#
	if [ $onepid -le 100 ]
	then
		return 0
	fi
	timelimit=5
	wcnt=0
	while [ : ]
	do
		if [ "$ksig" = '0' ]
			then
			kill -${ksig} $onepid 2>/dev/null
			return $?
		fi
		kill -${ksig} $onepid 2>/dev/null
		test $? -ne 0 && return 0
		let wcnt=$wcnt+1
		test $wcnt -gt $timelimit && break
		sleep 1
	done
	kill -9 $onepid 2>/dev/null
	test $? -eq 0 && return 1
	return 0
	#
}
killpidfile(){
	local pidfile
	pidfile=$1
	if [ -z "$pidfile" ]
	then
		return 0
	fi
	if [ ! -s "$pidfile" ]
	then
		return 0
	fi
	killpid "$(cat $pidfile 2>/dev/null)" "$2"
	return $?
}
#
waitpidfile(){
	local timeout pidfile show
	timeout=$2
	pidfile=$1
	show=$3
	test -z "$pidfile" && dlog "WARNING: waitpidfile, need arg pidfile." && return 0
	test -z "$timeout" && timeout=90
	let timeout=$timeout+1-1 2>/dev/null
	test $? -ne 0 -a "$timeout" != '0' && dlog "WARNING: waitpidfile, invalid arg timeout: $timeout" && return 0
	test ! -s "$pidfile" && return 0
	lckpid=$(cat "$pidfile" 2>/dev/null)
	if [ -n "$show" -a $timeout -gt 0 ]
		then
		dlog ""
		dlog ""
		dlog "WARNING: waiting $timeout seconds for pidfile $pidfile($lckpid) ..."
		dlog ""
		dlog ""
	fi
	wcnt=0
	while [ : ]
	do
		lckpid="`cat "$pidfile" 2>/dev/null`"
		test -z "$lckpid" && return 0
		kill -0 "$lckpid" 2>/dev/null
		if [ $? -ne 0 ]
			then
			return 0
		fi
		let wcnt=$wcnt+1
		test $wcnt -lt $timeout || break
		sleep 1
	done
	if [ $timeout -gt 0 ]
		then
		echo ""
		echo ""
		echo "WARNING: waiting timeout after $timeout seconds for $pidfile($lckpid) ..."
		echo ""
		echo ""
	fi
	return 1
}
waitbootcheck(){
	local timeout
	timeout=$1
	waitpidfile '/tmp/bootcheck.lock' "$timeout"
	return $?
}
isipaddress(){
	echo "$@"|grep -q '^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$'
	return $?
}
isnumber(){
	local chknum
	test "$@" = '0' && return 0
	let chknum=$@+1-1 2>/dev/null
	return $?
}
addroute(){
	#return 0 for ok, will output error msg
	local routeline oneop opok errstr
	routeline="$@"
	test -z "$routeline" && dlog "ERROR: empty arg for addroute." && return 1
	opok=1
	for oneadd in 1 2 3 4 5
	do
		errstr=$(route add $routeline 2>&1)
		if [ -n "$errstr" ]
			then
			echo $errstr | grep -q 'File exists'
			if [ $? -eq 0 ]
				then
				opok=0
			else
				echo "$errstr"
			fi
		fi
		break
	done
	return $opok
}
ipaddradd(){
	local ipmask ipdev exitcode
	ipmask=$1
	ipdev=$2
	exitcode=0
	test -z "$ipdev" && return 1
	ip addr add ${ipmask} dev $ipdev > /tmp/$$.ipaddradd.log 2>&1
	if [ $? -ne 0 ]
		then
		cat /tmp/$$.ipaddradd.log 2>/dev/null | grep -i -q 'File exists'
		exitcode=$?
	fi
	rm -f /tmp/$$.ipaddradd.log
	return $exitcode
}
ipaddrdel(){
	local ipmask ipdev exitcode
	ipmask=$1
	ipdev=$2
	test -z "$ipdev" && return 1
	exitcode=0
	ip addr del ${ipmask} dev $ipdev > /dev/null 2>&1
	return $exitcode
}
delroute(){
	#return 0 for ok, will output error msg
	local routeline oneop opok errstr
	routeline="$@"
	test -z "$routeline" && dlog "ERROR: empty arg for delroute." && return 1
	opok=1
	for oneadd in 1 2 3 4 5
	do
		errstr=$(route del $routeline 2>&1)
		if [ -n "$errstr" ]
			then
			echo $errstr | grep -q 'No such process'
			if [ $? -eq 0 ]
				then
				opok=0
			else
				echo "$errstr"
			fi
			break
		fi
	done
	return $opok
}
#
strcut1() {
	local onestr onepart onecnt outstr
	onestr="$@"
	onecnt=0
	outstr=''
	for onepart in $onestr
	do
		let onecnt=$onecnt+1
		test $onecnt -le 1 && continue
		if [ -z "$outstr" ]
			then
			outstr="$onepart"
		else
			outstr="$outstr $onepart"
		fi
	done
	echo "$outstr"
	return 0
}
#
strcut2() {
	local onestr onepart onecnt outstr
	onestr="$@"
	onecnt=0
	outstr=''
	for onepart in $onestr
	do
		let onecnt=$onecnt+1
		test $onecnt -le 2 && continue
		if [ -z "$outstr" ]
			then
			outstr="$onepart"
		else
			outstr="$outstr $onepart"
		fi
	done
	echo "$outstr"
	return 0
}
#
strcut3() {
	local onestr onepart onecnt outstr
	onestr="$@"
	onecnt=0
	outstr=''
	for onepart in $onestr
	do
		let onecnt=$onecnt+1
		test $onecnt -le 3 && continue
		if [ -z "$outstr" ]
			then
			outstr="$onepart"
		else
			outstr="$outstr $onepart"
		fi
	done
	echo "$outstr"
	return 0
}
#
strcut4() {
	local onestr onepart onecnt outstr
	onestr="$@"
	onecnt=0
	outstr=''
	for onepart in $onestr
	do
		let onecnt=$onecnt+1
		test $onecnt -le 4 && continue
		if [ -z "$outstr" ]
			then
			outstr="$onepart"
		else
			outstr="$outstr $onepart"
		fi
	done
	echo "$outstr"
	return 0
}
#
stringmatchstart(){
	#return 0 for ok
	local cmplist rawstr cmpcnt cmppos rawpos cmplen rawlen onecmp oneraw
	cmplist=$1
	test -z "$cmplist" && return 0
	rawstr=$(tailspacepos 2 $@)
	cmplen=${#cmplist}
	rawlen=${#rawstr}
	if [ $rawlen -lt $cmplen ]
		then
		#dlog "stringmatchstart: $cmplist is no match len $rawstr // $rawlen -lt $cmplen : $@"
		return 1
	fi
	if [ "${rawstr:0:$cmplen}" !=  "$cmplist" ]
		then
		#dlog "stringmatchstart: $cmplist is no match start $rawstr // $rawlen -lt $cmplen : $@"
		return 1
	fi
	#dlog "stringmatchstart: $cmplist is match start $rawstr : $@"
	return 0
}
pipematchstart(){
	local chkstr oneline
	chkstr="$1"
	while read oneline
	do
		stringmatchstart "X$chkstr" "X$oneline"
		test $? -eq 0 && echo "$oneline"
	done
}
#echo val for match
getspacepos(){
	local pos rawargs chkcnt
	pos=$1
	rawargs=$@
	test -z "$pos" && return 1
	let pos=$pos+1 2>/dev/null
	if [ $? -ne 0 ]
	then
		return 1
	fi
	#dlog "DEBUG: getspacepos rawargs: $rawargs, pos=$pos"
	chkcnt=0
	for oneflag in $rawargs
	do
		let chkcnt=$chkcnt+1
		test $chkcnt -eq 1 && continue
		if [ $chkcnt -eq $pos ]
			then
			echo "$oneflag"
			#dlog "DEBUG: getspacepos ret rawargs: $rawargs, pos=$pos => $oneflag"
			return 0
		fi
	done
	return 0
}
#
pipegetspacepos(){
	local chkstr oneline
	chkstr="$1"
	while read oneline
	do
		getspacepos "$chkstr" "$oneline"
	done
}
#echo val for match
tailspacepos(){
	#return string after pos
	local pos rawargs chkcnt tailstr
	pos=$1
	rawargs=$@
	test -z "$pos" && return 1
	let pos=$pos+1-1 2>/dev/null
	if [ $? -ne 0 ]
	then
		return 1
	fi
	#dlog "DEBUG: tailspacepos rawargs: $rawargs, pos=$pos"
	chkcnt=0
	for oneflag in $rawargs
	do
		let chkcnt=$chkcnt+1
		test $chkcnt -eq 1 && continue
		if [ $chkcnt -le $pos ]
			then
			continue
		fi
		if [ -z "$tailstr" ]
		then
			tailstr="$oneflag"
		else
			tailstr="$tailstr $oneflag"
		fi
		#dlog "DEBUG: tailspacepos rawargs: $rawargs, pos=$pos => $oneflag, tailstr=$tailstr"
	done
	echo "$tailstr"
	return 0
}
##
#stringtrim()
#	| sed 's/^ *//g'
#}
##
#This will remove all spaces ...
#echo " test test test " | tr -d ' '
#
#This will remove trailing spaces...
#
#echo " test test test " | sed 's/ *$//g'
#which results in
#
# test test test
#This will remove leading spaces...
#
#echo " test test test " | sed 's/^ *//g'
#which results in
#
#test test test
#This will remove both trailing and leading spaces
#
#echo " test test test " | sed -e 's/^ *//g' -e 's/ *$//g'
#which results in
#
#test test test
#
charlistinclude(){
	#return 0 for ok
	local cmplist rawstr cmpcnt cmppos rawpos cmplen rawlen onecmp oneraw
	cmplist=$1
	test -z "$cmplist" && return 0
	rawstr=$@
	cmplen=${#cmplist}
	rawlen=${#rawstr}
	cmpcnt=0
	cmppos=0
	rawpos=0
	while [ $cmppos -lt $cmplen ]
	do
		onecmp=${cmplist:$cmppos:1}
		let rawpos=$cmplen+1
		while [ $rawpos -lt $rawlen ]
		do
			oneraw=${rawstr:$rawpos:1}
			#dlog "charlistinclude: '$onecmp' vs '$oneraw' // '$rawstr'"
			if [ "$onecmp" = "$oneraw" ]
				then
				let cmpcnt=$cmpcnt+1
				break
			fi
			let rawpos=$rawpos+1
		done
		let cmppos=$cmppos+1
	done
	if [ $cmpcnt -lt $cmplen ]
		then
		#dlog "charlistinclude: '$cmplist' is $cmpcnt / $cmplen nomatch '$rawstr' // '$@'"
		return 1
	else
		#dlog "charlistinclude: '$cmplist' is $cmpcnt / $cmplen match '$rawstr' // '$@'"
		return 0
	fi
}
charlistlimit(){
	#return 0 for ok
	local cmplist rawstr cmpcnt cmppos rawpos cmplen rawlen onecmp oneraw
	cmplist=$1
	test -z "$cmplist" && return 0
	rawstr=$(tailspacepos 2 $@)
	cmplen=${#cmplist}
	rawlen=${#rawstr}
	cmpcnt=0
	rawpos=0
	while [ $rawpos -lt $rawlen ]
	do
		oneraw=${rawstr:$rawpos:1}
		cmppos=0
		while [ $cmppos -lt $cmplen ]
		do
			onecmp=${cmplist:$cmppos:1}
			if [ "$onecmp" != "$oneraw" ]
				then
				dlog "charlistlimit: $cmplist is nolimit $rawstr // $onecmp != $oneraw : $@"
				return 1
			fi
			let cmppos=$cmppos+1
		done
		let rawpos=$rawpos+1
	done
	dlog "charlistlimit: $cmplist is limit $rawstr : $@"
	return 0
}
charlistdel(){
	#return 0 for ok
	local cmplist rawstr cmpcnt cmppos rawpos cmplen rawlen onecmp oneraw outstr
	cmplist=$1
	test -z "$cmplist" && return 0
	rawstr=$@
	cmplen=${#cmplist}
	rawlen=${#rawstr}
	cmpcnt=0
	rawpos=0
	let rawpos=$cmplen+1
	outstr=''
	while [ $rawpos -lt $rawlen ]
	do
		oneraw=${rawstr:$rawpos:1}
		cmppos=0
		isinclude=0
		while [ $cmppos -lt $cmplen ]
		do
			onecmp=${cmplist:$cmppos:1}
			if [ "$onecmp" = "$oneraw" ]
				then
				#dlog "charlistdel: skipped $onecmp vs $oneraw"
				isinclude=1
				break
			fi
			let cmppos=$cmppos+1
		done
		let rawpos=$rawpos+1
		test $isinclude -ne 0 && continue
		if [ -z "$outstr" ]
			then
			outstr=$oneraw
		else
			outstr=${outstr}${oneraw}
		fi
	done
	#dlog "charlistdel: $cmplist del from $rawstr => $outstr // $@"
	echo "$outstr"
	return 0
}
#TODO: replace grep
#tr -d '[a-zA-Z0-9-_.]'
validAlphaNum(){
	#check input, return 0 for ok
	local invalidstr
	invalidstr=$(echo "$@" | tr -d '[a-zA-Z0-9-_.]')
	if [ -z "$invalidstr" ]
		then
		#dlog "validAlphaNum: $@ -> true [0-9A-Za-z:-]"
		return 0
	else
		#dlog "validAlphaNum: $@ -> false [0-9A-Za-z:-]"
		return 1
	fi
}
validAlphaNum3(){
	#return 0 for ok
	local checkstr checklen onechar validstr validlen onevalid isincluded
	checkstr="$@"
	test -z "$checkstr" && return 1
	validstr='01234567890abcdefghijklnmopqrstuvwxyzABCDEFGHIJKLNMOPQRSTUVWXYZ:-_.'
	#
	checklen=${#checkstr}
	while [ : ]
	do
		let checklen=$checklen-1
		test $checklen -ge 0 || break
		onechar=${checkstr:$checklen:1}
		validlen=${#validstr}
		isincluded=0
		while [ : ]
		do
			let validlen=$validlen-1
			test $validlen -ge 0 || break
			onevalid=${validstr:$validlen:1}
			if [ "$onechar" = "$onevalid" ]
				then
				isincluded=1
				#echo "DEBUG: '$onechar' included in $validstr"
				break
			fi
		done
		if [ $isincluded -eq 0 ]
			then
			#echo "DEBUG: '$onechar' NOT included in $validstr"
			return 1
		fi
	done
	#echo "DEBUG: '$checkstr' all included in $validstr"
	return 0
}
validAlphaNum2(){
	#check input, return 0 for ok
	#TODO: remove grep
	echo "$@" | grep -q '^[0-9A-Za-z:-_\.]\+$'
	if [ $? -eq 0 ]
		then
		#dlog "validAlphaNum: $@ -> true [0-9A-Za-z:-]"
		return 0
	else
		#dlog "validAlphaNum: $@ -> false [0-9A-Za-z:-]"
		return 1
	fi
}
#set or update
arrfastset(){
	#$1 arrname, $2 key $3-... value
	local arrname arrkey arrvalue arrdir
	arrname="$1"
	arrkey="$2"
	test -z "$arrkey" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	arrvalue=$(strcut2 "$@")
	test -z "$arrvalue" && return 1
	arrdir="${SCRIPTARRAYDIR}/${arrname}/"
	#dlog "ARRAY DEBUG: set, dir: $arrdir, name: $arrname, key:$arrkey, vaule: $arrvalue"
	basexec mkdir -p $arrdir && echo "$arrvalue" > "$arrdir$arrkey"  2>/dev/null
	test -$? -ne 0 && logexit "ERROR: arrfastset save to file $arrdir$arrkey failed."
	return 0
}
arrset(){
	#$1 arrname, $2 key $3-... value
	local arrname arrkey arrvalue arrdir
	arrname="$1"
	arrkey="$2"
	test -z "$arrkey" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	validAlphaNum $arrname || return 1
	validAlphaNum $arrkey || return 1
	arrfastset $@
	return $?
}
#del
arrfastdel(){
	#$1 arrname, $2 key 
	local arrname arrkey arrvalue arrdir
	arrname="$1"
	arrkey="$2"
	test -z "$arrkey" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	arrdir="${SCRIPTARRAYDIR}/${arrname}/"
	#dlog "ARRAY DEBUG: del, dir: $arrdir, name: $arrname, key:$arrkey, vaule: $arrvalue"
	rm -f "$arrdir$arrkey"
	return $?
}
#del
arrdel(){
	#$1 arrname, $2 key 
	local arrname arrkey arrvalue arrdir
	arrname="$1"
	arrkey="$2"
	test -z "$arrkey" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	validAlphaNum $arrname || return 1
	validAlphaNum $arrkey || return 1
	arrfastdel $@
	return $?
}
#del all
arrdelall(){
	#$1 arrname, $2 key
	local arrname arrkey arrvalue arrdir
	arrname="$1"
	test -z "$arrname" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	validAlphaNum $arrname || return 1
	arrdir="${SCRIPTARRAYDIR}/${arrname}/"
	rm -rf "$arrdir"
	return $?
}
#key list all
arrkeylist(){
	#$1 arrname, $2 key
	local arrname arrkey arrvalue arrdir allkeys
	arrname="$1"
	test -z "$arrname" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	validAlphaNum $arrname || return 1
	arrdir="${SCRIPTARRAYDIR}/${arrname}/"
	allkeys=''
	#if [ "$arrname" = 'mactrafficdata' ]
	#	then
	#	dlog "DEBUG: arr name: $arrname"
	#	dlog "DEBUG: arr  dir: $arrdir"
	#	dlog "DEBUG: arr  cmd: ls -A $arrdir 2>&1"
	#	ls -A $arrdir 2>&1 | pipelog dlog
	#fi
	for arrkey in $(ls -A $arrdir 2>/dev/null)
	do
		test -d "$arrdir$arrkey" && continue
		if [ -z "$allkeys" ]
			then
			allkeys="$arrkey"
		else
			allkeys="$allkeys $arrkey"
		fi
	done
	#if [ "$arrname" = 'mactrafficdata' ]
	#	then
	#	dlog "DEBUG: key list: $allkeys"
	#fi
	echo "$allkeys"
	return 0
}
arrkeys(){
	arrkeylist $@
}
arrfastgetfile(){
	local onekey arrname
	arrname="$1"
	onekey="$2"
	test -z "$onekey" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	arrdir="${SCRIPTARRAYDIR}/${arrname}/"
	#dlog "ARRAY DEBUG: arrfastgetfile, dir: $arrdir, name: $arrname, key:$arrkey, vaule: $arrvalue"
	echo "$arrdir$onekey"
}
arrdump(){
	local dumpkeys onekey arrname
	arrname="$1"
	test -z "$arrname" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	dumpkeys=$(arrkeys $@)
	dlog "ARRAY DUMP:"
	dlog "ARRAY NAME: $arrname"
	dlog "ARRAY KEYS: $dumpkeys"
	for onekey in $dumpkeys
	do
		dlog "$onekey $(arrfastgetfile $arrname $onekey) => $(arrfastget $arrname $onekey)"
	done
	dlog "ARRAY DUMP: ---"
}
arrkeydump(){
	local onekey arrname
	arrname="$1"
	onekey="$2"
	test -z "$onekey" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	dlog "ARRAY KEYS DUMP:"
	dlog "ARRAY NAME: $arrname"
	dlog "ARRAY KEYS: $onekey"
	dlog "ARRAY  VAL: $(arrfastget $arrname $onekey)"
	dlog "ARRAY KEYS DUMP: --- $(arrfastgetfile $arrname $onekey)"
}
#get
arrfastget(){
	#$1 arrname, $2 key
	local arrname arrkey arrvalue arrdir
	arrname="$1"
	arrkey="$2"
	test -z "$arrname" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	arrdir="${SCRIPTARRAYDIR}/${arrname}/"
	test ! -f "$arrdir$arrkey" && return 1
	read arrvalue < $arrdir$arrkey 2>/dev/null
	#dlog "ARRAY DEBUG: get, dir: $arrdir, name: $arrname, key:$arrkey, vaule: $arrvalue"
	echo "$arrvalue"
	return 0
}
#
#get
arrget(){
	#$1 arrname, $2 key
	local arrname arrkey arrvalue arrdir
	arrname="$1"
	arrkey="$2"
	test -z "$arrname" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	validAlphaNum $arrname || return 1
	validAlphaNum $arrkey || return 1
	arrfastget $@
	return $?
}
#
#check exist
arrcheck(){
	#return 0 for exist
	#$1 arrname, $2 key
	local arrname arrkey arrvalue arrdir
	arrname="$1"
	arrkey="$2"
	test -z "$arrname" && return 1
	test -z "$SCRIPTARRAYDIR" && return 1
	#validAlphaNum $arrname || return 1
	#validAlphaNum $arrkey || return 1
	arrdir="${SCRIPTARRAYDIR}/${arrname}/"
	test ! -f "$arrdir$arrkey" && return 1
	return 0
}
#
flog(){
	msg="$@"
	test -z "$msg" && return 0
	DATE="`date`"
	test -n "$SCRIPTLOGFILE" && echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> $SCRIPTLOGFILE 2>/dev/null
	return 0
}
#
dlog(){
	local msg
	msg="$@"
	test -z "$msg" && return 0
	DATE="`date`"
	if [ -z "$DAEMONSYSLOGFILE" -o "$DAEMONSYSLOGFILE" = 'syslog' ]
		then
		msg=$(echo "$msg" | sed -e 's#^-#_#')
		/usr/bin/logger -t "${SCRIPTTAG}[${SCRIPTPID}]" "$msg"
	else
		echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> $DAEMONSYSLOGFILE 2>/dev/null
	fi
	test -n "$SCRIPTLOGFILE" && echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> $SCRIPTLOGFILE 2>/dev/null
	return 0
}
#
elog(){
	msg="$@"
	test -z "$msg" && return 0
	DATE="`date`"
	if [ -z "$DAEMONSYSLOGFILE" -o "$DAEMONSYSLOGFILE" = 'syslog' ]
		then
		msg=$(echo "$msg" | sed -e 's#^-#_#')
		/usr/bin/logger -t "${SCRIPTTAG}[${SCRIPTPID}]" "$msg"
	else
		echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> $DAEMONSYSLOGFILE 2>/dev/null
	fi
	test -n "$SCRIPTLOGFILE" && echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> $SCRIPTLOGFILE 2>/dev/null
	echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> /proc/$$/fd/2 2>/dev/null
	return 0
}
#
conlog(){
	msg="$@"
	test -z "$msg" && return 0
	DATE="`date`"
	if [ -z "$DAEMONSYSLOGFILE" -o "$DAEMONSYSLOGFILE" = 'syslog' ]
		then
		msg=$(echo "$msg" | sed -e 's#^-#_#')
		/usr/bin/logger -t "${SCRIPTTAG}[${SCRIPTPID}]" "$msg"
	else
		echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> $DAEMONSYSLOGFILE 2>/dev/null
	fi
	echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> /dev/console 2>/dev/null
	test -n "$SCRIPTLOGFILE" && echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> $SCRIPTLOGFILE 2>/dev/null
	return 0
}
#
conelog(){
	msg="$@"
	test -z "$msg" && return 0
	DATE="`date`"
	if [ -z "$DAEMONSYSLOGFILE" -o "$DAEMONSYSLOGFILE" = 'syslog' ]
		then
		msg=$(echo "$msg" | sed -e 's#^-#_#')
		/usr/bin/logger -t "${SCRIPTTAG}[${SCRIPTPID}]" "$msg"
	else
		echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> $DAEMONSYSLOGFILE 2>/dev/null
	fi
	echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> /dev/console 2>/dev/null
	test -n "$SCRIPTLOGFILE" && echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> $SCRIPTLOGFILE 2>/dev/null
	echo "$DATE ${SCRIPTTAG}[${SCRIPTPID}]: $msg" >> /proc/$$/fd/2 2>/dev/null
	return 0
}
#TODO: fix line length limit
pipelog(){
	logfun="$@"
	if [ -z "$logfun" ]
		then
		dlog "ERROR: pipelog fun arg no defined."
		return 1
	fi
	type -t $logfun >/dev/null 2>&1
	if [ $? -ne 0 ]
		then
		dlog "ERROR: pipelog fun $logfun no defined."
		return 1
	fi
	while read onelogline
	do
		$logfun "$onelogline"
	done
}
#TODO: fix line length limit
lpipelog(){
	logfun="$@"
	if [ -z "$logfun" ]
		then
		dlog "ERROR: pipelog fun arg no defined."
		return 1
	fi
	type -t $logfun >/dev/null 2>&1
	if [ $? -ne 0 ]
		then
		dlog "ERROR: pipelog fun $logfun no defined."
		return 1
	fi
	while [ : ]
	do
		while read onelogline
		do
			$logfun "$onelogline"
		done
		sleep 3
	done
}
slog(){
	#usage: slog uuid dlog "msg"
	local logmark logfun logmsg logstat
	logmark="$1"
	logfun="$2"
	logmsg="$@"
	if [ -z "$logfun" ]
		then
		dlog "ERROR: slog fun arg no defined."
		return 1
	fi
	if [ "$logfun" = 'release' ]
		then
		arrfastset slogmark $logmark 0
		return 0
	fi
	type -t $logfun >/dev/null 2>&1
	if [ $? -ne 0 ]
		then
		dlog "ERROR: pipelog fun $logfun no defined."
		return 1
	fi
	logstat=$(arrfastget slogmark $logmark)
	#dlog "slog arrfastget slogmark $logmark = $logstat"
	if [ "$logstat" = '1' ]
		then
		#already mark
		return 0
	fi
	arrfastset slogmark $logmark 1
	logmsg=$(echo "$logmsg" | sed -e "s/^$logmark //"|sed -e "s/^$logfun //")
	$logfun "$logmsg"
	return 0
}
#echo val for match
getoptval(){
	pos=$1
	#logger "ALLARGS: $ALLARGS, pos=$pos"
	test -z "$pos" && return 1
	let pos=$pos+1-1 2>/dev/null
	if [ $? -ne 0 ]
	then
		return 0
	fi
	chkcnt=0
	for oneflag in $ALLARGS
	do
		echo "$oneflag" | grep -q '^-'
		if [ $? -eq 0 ]
		then
			continue
		fi
		let chkcnt=$chkcnt+1
		if [ $chkcnt -eq $pos ]
		then
			echo "$oneflag"
			#logger "ALLARGS: $ALLARGS, pos=$pos, oneflag=$oneflag"
			return 1
		fi
	done
	return 0
}

strippath() {
	stmsg="$@"
	newstr="${stmsg}${stmsg}"
	while [ : ]
	do
		newstr=`echo "${stmsg}" | sed -e 's/\/\//\//g'`
		if [ "${newstr}" != "${stmsg}" -a -n "${newstr}" ]
		then
			stmsg="${newstr}"
		else
			break;
		fi
	done
	echo "${newstr}"
}

slaprtrim() {
	onexcu=`strippath $@`
	onexcu=`echo ${onexcu} |  sed -e 's/\/$//'`
	echo $onexcu
}

slapltrim() {
	onexcu=`strippath $@`
	onexcu=`echo ${onexcu} |  sed -e 's/\/$//'`
	echo $onexcu
}
#
argmatch(){
	#1 for match
	local chk
	chk="$@"
	test -z "$chk" && echo 0 && return 0
	for onechk in $chk
	do
	   for onearg in $ALLARGS
	   do
	   	if [ "$onechk" = "$onearg" ]
	   		then
	   		echo 1
	   		return 1
	   	fi
	   done
	done
	echo 0
	return 0
}
#
setlogfile(){
	newlogfile="$1"
	test -z "$newlogfile" && return 0
	echo "" > $newlogfile 2>/dev/null
	if [ $? -ne 0 ]
		then
		conlog "ERROR: can not write to logfile $newlogfile"
		return 0
	fi
	SCRIPTLOGFILE="$newlogfile"
}
#
linecat(){
	local catfiles onefile oneline
	catfiles="$@"
	for onefile in $catfiles
	do
		if [ ! -f "$onefile" ]
			then
			#dlog "WARNING: linecat, file no found: $onefile"
			continue
		fi
		while read oneline
		do
			echo "$oneline"
		done < $onefile
	done
}
dlogexec(){
	local exitcode
	local execline
	local capfile
	execline="$@"
	test -z "$execline" && return 0
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	basexec mkdir -p /tmp/logexec/
	$execline > $capfile 2>&1
	exitcode=$?
	dlog "logexec: exitcode $exitcode, $execline"
	cat $capfile 2>/dev/null | pipelog dlog
	rm -f $capfile
	return $exitcode
}
#
dlogselftexec(){
	local exitcode
	local execline
	local capfile
	execline="$SCRIPTSELFT"
	test -z "$execline" && return 0
	execline="$execline selftexec"
	test "$(argmatch selftexec)" = '1' && return 0
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	basexec mkdir -p /tmp/logexec/
	$execline > $capfile 2>&1
	exitcode=$?
	dlog "logexec: exitcode $exitcode, $execline"
	cat $capfile 2>/dev/null | pipelog dlog
	rm -f $capfile
	exit $exitcode
}
#
echoexec(){
	local exitcode
	local execline
	local capfile
	execline="$@"
	test -z "$execline" && return 0
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	basexec mkdir -p /tmp/logexec/
	$execline > $capfile 2>&1
	exitcode=$?
	if [ $exitcode -ne 0 ]
		then
		dlog "logexec: exitcode $exitcode, $execline"
	fi
	cat $capfile
	rm -f $capfile
	return $exitcode
}
#
echoelogexec(){
	local exitcode
	local execline
	local capfile
	execline="$@"
	test -z "$execline" && return 0
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	basexec mkdir -p /tmp/logexec/
	$execline > $capfile 2>&1
	exitcode=$?
	cat $capfile 2>/dev/null | pipelog elog
	if [ $exitcode -ne 0 ]
		then
		elog "logexec: exitcode $exitcode, $execline"
	fi
	rm -f $capfile
	return $exitcode
}
echoconlogexec(){
	local exitcode
	local execline
	local capfile
	execline="$@"
	test -z "$execline" && return 0
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	basexec mkdir -p /tmp/logexec/
	$execline > $capfile 2>&1
	exitcode=$?
	cat $capfile 2>/dev/null | tee | pipelog conlog
	if [ $exitcode -ne 0 ]
		then
		conlog "logexec: exitcode $exitcode, $execline"
	fi
	rm -f $capfile
	return $exitcode
}
#
echodlogexec(){
	local exitcode
	local execline
	local capfile
	execline="$@"
	test -z "$execline" && return 0
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	basexec mkdir -p /tmp/logexec/
	$execline > $capfile 2>&1
	exitcode=$?
	cat $capfile 2>/dev/null | tee | pipelog dlog
	if [ $exitcode -ne 0 ]
		then
		dlog "logexec: exitcode $exitcode, $execline"
	fi
	rm -f $capfile
	return $exitcode
}
#
logexec(){
	local exitcode
	local execline
	local capfile
	execline="$@"
	test -z "$execline" && return 0
	basexec mkdir -p /tmp/logexec/
	capfile="/tmp/logexec/log.$$.$(date -u +%s)"
	$execline > $capfile 2>&1
	exitcode=$?
	if [ $exitcode -ne 0 ]
	then
		dlog "logexec: exitcode $exitcode, $execline"
		cat $capfile 2>/dev/null | pipelog dlog
	fi
	rm -f $capfile
	return $exitcode
}
#
setexitmark(){
	#
	setpid="$1"
	if [ -z "$setpid" ]
		then
		setpid=$SCRIPTPID
	fi
	#
	if [ -z "$SCRIPTLOCK" ]
	then
		SCRIPTLOCK=$SCRIPTMARK
	fi
	validAlphaNum "${SCRIPTLOCK}"
	if [ $? -ne 0 ]
		then
		conlog "ERROR: invalid SCRIPTLOCK(${SCRIPTLOCK}) for daemon setexitmark."
		exit 1
	fi
	arrset run exit_${SCRIPTLOCK} "$setpid"
	#dlog "set proc $$ lock, exit $?, $SCRIPTSELFT // $setpid => ${SCRIPTARRAYDIR}/run/lock"
	#dlog "set proc $$ lock ret: $(arrget run lock)"
	if [ $? -ne 0 ]
		then
		conlog "ERROR: create daemon exitmark($setpid) failed."
		exit 1
	fi
	#
}
#
getexitmark(){
	#
	if [ -z "$SCRIPTLOCK" ]
	then
		SCRIPTLOCK=$SCRIPTMARK
	fi
	validAlphaNum "${SCRIPTLOCK}"
	if [ $? -ne 0 ]
		then
		conlog "ERROR: invalid SCRIPTLOCK(${SCRIPTLOCK}) for daemon getexitmark."
		exit 1
	fi
	echo "$(arrfastget run exit_${SCRIPTLOCK})"
	return 0
}
#
delexitmark(){
	#
	if [ -z "$SCRIPTLOCK" ]
	then
		SCRIPTLOCK=$SCRIPTMARK
	fi
	validAlphaNum "${SCRIPTLOCK}"
	if [ $? -ne 0 ]
		then
		conlog "ERROR: invalid SCRIPTLOCK(${SCRIPTLOCK}) for daemon delexitmark."
		exit 1
	fi
	arrfastdel run exit_${SCRIPTLOCK}
	return $?
}
#
getlockedprocpid(){
	if [ -z "$SCRIPTLOCK" ]
	then
		SCRIPTLOCK=$SCRIPTMARK
	fi
	validAlphaNum "${SCRIPTLOCK}"
	if [ $? -ne 0 ]
		then
		conlog "ERROR: invalid SCRIPTLOCK(${SCRIPTLOCK}) for daemon lock."
		exit 1
	fi
	lockedpid="$(arrget run lock_${SCRIPTLOCK})"
	test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: getlockedprocpid: arrget run lock_${SCRIPTLOCK} => $lockedpid"
	echo "$lockedpid"
	return 0
}
releaselockedprocpid(){
	if [ -z "$SCRIPTLOCK" ]
	then
		SCRIPTLOCK=$SCRIPTMARK
	fi
	validAlphaNum "${SCRIPTLOCK}"
	if [ $? -ne 0 ]
		then
		conlog "ERROR: invalid SCRIPTLOCK(${SCRIPTLOCK}) for daemon unlock."
		exit 1
	fi
	setexitmark
	lockedpid="$(arrget run lock_${SCRIPTLOCK})"
	#test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: releaselockedprocpid: arrget run lock_${SCRIPTLOCK} => $lockedpid"
	dlog "DEBUG: releaselockedprocpid: arrget run lock_${SCRIPTLOCK} => $lockedpid"
	arrdel run "lock_${SCRIPTLOCK}"
	return $?
}
setproclock(){
	#
	setpid="$1"
	if [ -z "$setpid" ]
		then
		setpid=$SCRIPTPID
	fi
	test -z "$setpid" && return 0
	let setpid=$setpid+1-1 2>/dev/null
	test $? -ne 0 && return 1
	#
	if [ -z "$SCRIPTLOCK" ]
	then
		SCRIPTLOCK=$SCRIPTMARK
	fi
	validAlphaNum "${SCRIPTLOCK}"
	if [ $? -ne 0 ]
		then
		conlog "ERROR: invalid SCRIPTLOCK(${SCRIPTLOCK}) for daemon lock."
		exit 1
	fi
	arrset run lock_${SCRIPTLOCK} "$setpid"
	#dlog "set proc $$ lock, exit $?, $SCRIPTSELFT // $setpid => ${SCRIPTARRAYDIR}/run/lock"
	#dlog "set proc $$ lock ret: $(arrget run lock)"
	if [ $? -ne 0 ]
		then
		elog "ERROR: create daemon lock failed: arrset run lock_${SCRIPTLOCK} $setpid"
		exit 1
	else
		test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: setproclocked: arrset run lock_${SCRIPTLOCK} => $setpid"
	fi
	#
}
checkproclock(){
	local waitlck
	local replaceproc
	#
	#check lock, return 0 for no locked, 1 for locked
	#
	test -z "$SCRIPTPID" && SCRIPTPID=$$
	test -z "$SCRIPTSELFT" && SCRIPTSELFT=$0
	#
	waitlck="$1"
	replaceproc="$2"
	test -z "$waitlck" && waitlck=1
	let waitlck=$waitlck+1-1 2>/dev/null
	if [ $? -ne 0 ]
		then
		waitlck=1
	fi
	test $waitlck -le 0 && waitlck=0
	#
	wcnt=0
	#SCRIPTLOCK will effect in getlockedprocpid
	lckpid=$(getlockedprocpid)
	if [ "$lckpid" = "$SCRIPTPID" ]
		then
		#it's me
		test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: checkproclock, no locked, myself: $SCRIPTPID"
		return 0
	fi
	if [ -z "$lckpid" ]
		then
		test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: checkproclock, no locked, lockpid no exist."
		return 0
	fi
	kill -0 "$lckpid" 2>/dev/null
	if [ $? -ne 0 ]
		then
		#no running
		test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: checkproclock, no locked, $lckpid no running."
		return 0
	fi
	if [ "$replaceproc" = 'replaceproc' ]
		then
		dlog "WARNING: try to replace old proc ${lckpid}"
		killpid $lckpid
	fi
	if [ $waitlck -gt 1 ]
		then
		dlog "INFO: proclock waiting $lckpid, timeout $waitlck"
	fi
	running=0
	while [ : ]
	do
		running=0
		lckpid=$(getlockedprocpid)
		if [ -n "$lckpid" ]
			then
			kill -0 "$lckpid" 2>/dev/null
			if [ $? -ne 0 ]
				then
				#no running
				break
			else
				running=1
			fi
		else
			break
		fi
		let wcnt=$wcnt+1
		test $wcnt -ge $waitlck && break
		sleep 1
	done
	#
	if [ $waitlck -gt 1 ]
		then
		if [ $running -ne 0 ]
			then
			dlog "WARNING: pid lock waiting $lckpid timeout after $wcnt seconds."
		else
			dlog "INFO: pid lock waiting $lckpid finish after $wcnt seconds."
		fi
	else
		test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: checkproclock, no locked, max wait $waitlck seconds, esp $wcnt seconds, pid $lckpid"
	fi
	#test -n "$lckpid" && dlog "DEBUG: checkproclock, $waitlck seconds, waiting for $lckpid running=$running, after $wcnt seconds."
	return $running
}
#
procgodaemon(){
	#no lock set/check
	if [ `echo "$SCRIPTSELFT"|grep -c '^/'` -eq 0 ]
		then
		elog "ERROR: script must start by absolute path."
		exit 1
	fi
	#
	#check lock
	#
	checkproclock 1
	if [ $? -ne 0 ]
		then
		test "$1" = 'fixme' && dlog "FIXME: already running, pid $(getlockedprocpid))" && exit 1
		exit 0
	#else
	#	elog "INFO: no running"
	fi
	#
	delexitmark
	#
	DAEMONED=''
	if [ `argmatch blocking daemon status checkconf` -eq 0 -a -x "$SCRIPTSELFT" ]
		then
		#
		if [ -z "$SCRIPTNICE" ]
		then
			SCRIPTNICE=10
		fi
		let SCRIPTNICE=$SCRIPTNICE+1-1 2>/dev/null
		if [ $? -ne 0 ]
			then
			SCRIPTNICE=10
		fi
		setproclock
		basexec mkdir -p /tmp/daemon/stdio/
		touch $DAEMONSTDIOFILE
		if [ $? -ne 0 ]
			then
			elog "ERROR: create STDIO file failed: touch $DAEMONSTDIOFILE $(tuch $DAEMONSTDIOFILE 2>&1)"
			exit 1
		fi
		#fifofile="/tmp/daemon/${SCRIPTMARK}.fifo"
		#rm -f $fifofile
		#mkfifo $fifofile
		#if [ $? -ne 0 ]
		#	then
		#	elog "ERROR: create FIFO pipe failed: mkfifo $fifofile $(mkfifo $fifofile 2>&1)"
		#	exit 1
		#fi
		#nohup cat $fifofile 2>&1 < /dev/null | pipelog dlog &
		#pipepid=$!

		#dlog "DEBUG: pipelog pid: $pipepid"
		#disable msg: nohup: ignoring input by cat /dev/zero
		#nice -n $SCRIPTNICE nohup $SCRIPTSELFT $ALLARGS daemon >> $fifofile 2>&1 < /dev/zero &
		SCRIPTTITLE=$(echo "$SCRIPTTITLE"|tr '/\- ' '_')
		nice -n $SCRIPTNICE nohup $SCRIPTSELFT $ALLARGS daemon "$SCRIPTTITLE" >> $DAEMONSTDIOFILE 2>&1 < /dev/zero &
		runcode=$?
		daemonedpid=$!
		#
		if [ $runcode -ne 0 ]
			then
			elog "ERROR: execute // $SCRIPTSELFT $ALLARGS daemon // failed:"
			elog "ERROR: got invalid exitcode: $runcode"
			exit 1
		fi
		if [ -z "$daemonedpid" ]; then
			elog "ERROR: execute // $SCRIPTSELFT $ALLARGS daemon // failed:"
			elog "ERROR: got invalid pid: $daemonedpid"
			exit 1
		fi
		test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: setproclock for daemon: $daemonedpid"
		setproclock "$daemonedpid"
		test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: running background: $daemonedpid"
		exit 0
	else
		#already daemon
		# trap daemon only
		trap daemonexit SIGTERM SIGINT
		DAEMONED='yes'
		export PROC_LOCK_DEBUG='FALSE'
	fi
	setproclock "$SCRIPTPID"
	#
}
export SCRIPTWARNED=0
waitcleanup(){
	test $SCRIPTWARNED -eq 0 && elog "INFO: waiting for cleanup ..."
	let SCRIPTWARNED=$SCRIPTWARNED+1
	sleep 1
	test $SCRIPTWARNED -ge 10 && exit 0
}
daemonexit(){
	delexitmark
	trap waitcleanup SIGTERM SIGINT
	SCRIPTWARNED=0
	dlog "INFO: exiting ..."
	type -t daemonstop >/dev/null 2>&1
	if [ $? -eq 0 ]
		then
		dlog "INFO: cleanup befor exit ..."
		daemonstop 2>&1 | pipelog dlog
	fi
	dlog "INFO: exited."
	exit 0
}
daemonexited(){
	local exitcode=$1
	test -z "$exitcode" && exitcode=0
	#like daemonexit
	type -t daemonpostexit >/dev/null 2>&1
	if [ $? -eq 0 ]
		then
		dlog "INFO: post exit ..."
		daemonpostexit 2>&1 | pipelog dlog
	fi
	exit $exitcode
}
proc_ctl(){
	if [ "$1" = 'restart' -o "$1" = 'reload' ]
		then
		trap - SIGTERM SIGINT SIGQUIT
		narg=`echo $@ | sed -e 's/restart//g'|sed -e 's/reload//g'|sed -e 's/  / /g'`
		$0 stop $narg >/dev/null 2>&1
		sleep 1
		$0 start $narg 2>&1
		exit $?
	fi
	#
	if [ "$1" = 'status' ]
		then
		#return 0 for running
		trap - SIGTERM SIGINT SIGQUIT
		lckpid=$(getlockedprocpid)
		if [ -n "$lckpid" ]
			then
			kill -0 "$lckpid" 2>/dev/null
			if [ $? -eq 0 ]
				then
				# running
				test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: check proc lock status, running, pid: $lckpid"
				test "$2" != 'mute' && elog "INFO: running, pid: $lckpid"
				exit 0
			else
				test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: check proc lock status, no running, pid: $lckpid"
			fi
		else
			test "${PROC_LOCK_DEBUG}" = 'TRUE' && dlog "DEBUG: check proc lock status, no lockpid"
		fi
		test "$2" != 'mute' && elog "INFO: no running."
		exit 1
	fi
	if [ "$1" = 'stop' -o "$1" = 'kill' ]
		then
		#
		ctlop="$1"
		#
		killsig=15
		#
		trap - SIGTERM SIGINT SIGQUIT
		lckpid=$(getlockedprocpid)
		if [ -n "$lckpid" ]
			then
			kill -0 "$lckpid" 2>/dev/null
			if [ $? -ne 0 ]
				then
				#no running
				daemonexited 0
			fi
			#
			setexitmark
			#
			#conlog "WARNING: PROC_CALLER=$PROC_CALLER"
			#
			#/etc/init.d/rcS K shutdown
			#
			#/etc/init.d/rcS S boot
			#
			kill -$killsig "$lckpid" 2>/dev/null
			if [ $? -ne 0 ]
				then
				elog "ERROR: stop pid $lckpid failed."
				exit 1
			else
				if [ "$PROC_CALLER" = "/etc/init.d/rcS K shutdown" ]
					then
					# export PROC_CALLER='/etc/init.d/rcS K shutdown'
					dlog "WARNING: fast $ctlop for system shutdown($PROC_CALLER)."
					releaselockedprocpid
					dlog "WARNING: kill all sleep for system shutdown($PROC_CALLER)."
					killall sleep
					daemonexited 0
				fi
				wcnt=0
				waitlimit=120
				while [ : ]
				do
					lckpid=$(getlockedprocpid)
					test -z "$lckpid" && break
					if [ "$ctlop" = 'kill' ]
						then
						kill -9 "$lckpid" 2>/dev/null
					else
						sleep 1
					fi
					kill -0 "$lckpid" 2>/dev/null || break
					let wcnt=$wcnt+1
					test $wcnt -ge $waitlimit && break
				done
				kill -0 "$lckpid" 2>/dev/null
				if [ $? -ne 0 ]
					then
					elog "INFO: $ctlop pid $lckpid ok."
				else
					elog "ERROR: waiting for pid $lckpid exit timeout after $waitlimit seconds, KILLED."
					kill -9 "$lckpid" 2>/dev/null
				fi
			fi
		fi
		daemonexited 0
	fi
}
procdaemon(){
	#check lock
	#daemon
	proc_ctl $ALLARGS
	#set lock
	if [ "$DAEMONBYPASS" != 'yes' ]
		then
		#
		procgodaemon $ALLARGS
		#
	#else
	#	dlog "daemon: bypass $SCRIPTSELFT $ALLARGS"
	fi
}

runintimeusage(){
	echo "USAGE: runintimeusage <timeout> <command>"
}
runintime(){

	timeout=$1
	cmdline=$@
	test -z "$timeout" && return 0

	let timeout=$timeout+1-1 2>/dev/null
	test $? -ne 0 && runintimeusage && echo "ERROR: timeout($timeout) should be 1 - 120" && return 1
	test $timeout -gt 120 -o $timeout -le 0 && runintimeusage && echo "ERROR: timeout($timeout) should be 1 - 120" && return 1
	cmdline=$(echo $cmdline | sed -e "s/$timeout //")
	if [ -z "$cmdline" ]
	then
		runintimeusage
		echo "ERROR: command arg not found."
		return 1
	fi
	#echo "DEBUG: running /$cmdline/$timeout ..."

	nowts=$(date +%s)
	doid=`echo "$nowts/$cmdline/$timeout"|md5sum|awk '{print $1}'`
	dofile="/tmp/`basename $0`.$$.$doid.tmp"

	touch $dofile
	$cmdline > $dofile 2>&1 &
	runcode=$?
	lookpid=$!

	wcnt=0
	addlist=''
	while [ $wcnt -le $timeout ]
	do
		kill -0 $lookpid 2>/dev/null
		if [ $? -ne 0 ]
		then
			#it exited
			break
		fi
		let wcnt=$wcnt+1
		sleep 1
	done

	kill $lookpid 2>/dev/null
	linecat $dofile
	rm -f $dofile
	return $runcode
#
}
find_mtd_part() {
		local PART="$(grep "\"$1\"" /proc/mtd | awk -F: '{print $1}')"
		local PREFIX=/dev/mtdblock

		PART="${PART##mtd}"
		[ -d /dev/mtdblock ] && PREFIX=/dev/mtdblock/
		echo "${PART:+$PREFIX$PART}"
}
#
getmtdbyname() {
	find_mtd_part $@
}
#
overlaymountdir(){
	local showmnt
	local ovldir
	showmnt="$1"
	#
	#check ' /tmp/overlay-disabled' first
	#
	ovldir=`df | grep ' /tmp/overlay-disabled$'|awk '{print $6}'`
	if [ -z "$ovldir" ]
	then
		ovldir=`df | grep ' /overlay$'|awk '{print $6}'`
	fi
	if [ -z "$ovldir" ]
		then
		#
		if [ -n "$showmnt" ]
			then
			conlog "ERROR: overlay no mounted."
			conlog "---"
			conlog "INFO: current mount table:"
			conlog "---"
			#
			df | while read oneline
			do
				conlog "$oneline"
			done
			#
		fi
		#
		return 1
	fi
	if [ -n "$showmnt" ]
		then
		conlog "INFO: overlay mounted: $ovldir"
		df 2>&1 | while read oneline
		do
			conlog "$oneline"
		done
	fi
	echo "$ovldir"
	return 0
}
getoverlaydir(){
	local showmnt
	showmnt="$1"
	local ovldir
	#
	#check ' /tmp/overlay-disabled' first
	#
	ovldir=$(overlaymountdir $@)
	if [ -n "$ovldir" ]
		then
		echo "$ovldir"
		return 0
	fi
	#
	#waiting for overlay mount
	#
	conlog "---"
	conlog "INFO: waiting for overlay mounted, up to 60 seconds."
	conlog "---"
	#
	ovldir=''
	wcnt=0
	while [ $wcnt -le 60 ]
	do
		ovldir=$(overlaymountdir)
		if [ -n "$ovldir" ]
			then
			break
		fi
		let wcnt=$wcnt+1
		sleep 1
	done
	#
	if [ -z "$ovldir" ]
		then
		conlog "ERROR: waiting for overlay mounted failed after 60 seconds."
		return 1
	fi
	if [ -n "$showmnt" ]
		then
		conlog "INFO: overlay mounted: ${ovldir}"
		df | while read oneline
		do
			conlog "$oneline"
		done
	fi
	echo "$ovldir"
	return 0
}
#
ipalivecheck(){
	local chkip mute pingret arpret
	chkip="$1"
	mute="$2"
	#
	test -z "$chkip" && return 1
	#
	#check ip with ping and arp
	#
	/usr/bin/arp -d $chkip 2>/dev/null
	for fcnt in 1 2 3 4 5 6 7 8 9 10
	do
		pingret=`ping -c 1 -w 1 $chkip | grep ': seq='|grep -c ' time='`
		arpret=`/usr/bin/arp -n | grep -v '00:00:00:00:00:00'|grep -v 'incomplete'|grep "^$chkip"`
		if [ $pingret -gt 0 -o -n "$arpret" ]
			then
			break
		fi
	done
	if [ $pingret -le 0 -a -z "$arpret" ]
			then
			test "$mute" = '0' && dlog "WARNING: $chkip unreachable."
			return 1
	#else
	#	dlog "DEBUG: $chkip alive: $arpret"
	fi
	return 0
}
iplocalcheck(){
	#return 0 for ok,
	local chkip mute arpret mark
	chkip="$1"
	mute="$2"
	mark="$3"
	test -z "$mark"&&mark='local'
	#
	test -z "$chkip" && return 1
	#
	#check ip with ping and arp
	#
	####niclist="`ifconfig | grep 'Link encap:' | awk '{print $1}'`"
	#####
	####for onenic in $niclist
	####do
	####	#check p-to-p
	####	ifconfig $onenic 2>/dev/null | grep -i 'inet'|awk -F':' '{print $3}'|awk '{print $1}'|grep -q "$chkip"
	####	if [ $? -eq 0 ]
	####		then
	####		#p-to-p link: inet addr:10.0.109.10  P-t-P:10.0.109.254  Mask:255.255.255.255
	####		return 0
	####	fi
	####done
	#

	#p-to-p link: inet addr:10.0.109.10  P-t-P:10.0.109.254  Mask:255.255.255.255
	ifconfig | grep -q "P-t-P:$chkip "
	if [ $? -eq 0 ]
		then
		return 0
	fi

	#my local ip is false
	ifconfig | grep -q "inet addr:$chkip "
	if [ $? -eq 0 ]
		then
		return 1
	fi

	#
	#check ether
	/usr/bin/arp -d $chkip 2>/dev/null
	for fcnt in 1 2 3 4
	do
		ping -c 1 -w 1 $chkip >/dev/null 2>&1
		arpret=`/usr/bin/arp -n | grep -v '00:00:00:00:00:00'|grep -v 'incomplete'|grep "^$chkip"`
		if [ -n "$arpret" ]
			then
			break
		fi
	done
	if [ -z "$arpret" ]
			then
			test "$mute" = '0' && dlog "WARNING: $chkip unreachable in ${mark}."
			return 1
	#else
	#	dlog "DEBUG: $chkip reachable in ${mark}: $arpret"
	fi
	return 0
}

iplocalethercheck(){
	iplocalcheck $1 $2 'local ethernet'
	return $?
}
#
ipconfictcheck(){
	local chklist chknics onenic nicmac chkip cmpnic dupmac isconfict lannet wannet
	isconfict=0
	chklist="$@"
	test -z "$chklist" && chklist='eth0.2 br-lan'
	for onenic in $chklist
	do
		nicmac=$(ifconfig eth0.2|grep 'HWaddr '|awk '{print $5}')
		chkip=$(/sbin/ifconfig $onenic 2>/dev/null | grep 'inet addr:' | awk -F'inet addr:' '{print $2}'| awk '{print $1}')
		chknics="$onenic"
		for cmpnic in $chknics
		do
			dupmac=$(/usr/bin/arping -D -f -b -c 1 -w 1 -s 0.0.0.0 -I $cmpnic $chkip 2>&1 | grep 'reply from ' | tr -d '[]' | awk -F"$chkip " '{print $2}'|awk '{print $1}')
			if [ -n "$dupmac" ]
			then
				test "$(arrfastget ipconfict ${nicmac}-${onenic}-${chkip}-${cmpnic})" != "1" && dlog "WARNING: IP of ${onenic}/${nicmac} $chkip confict with mac $dupmac at $cmpnic"
				arrfastset ipconfict ${nicmac}-${onenic}-${chkip}-${cmpnic} 1
				let isconfict=$isconfict+1
			else
				test "$(arrfastget ipconfict ${nicmac}-${onenic}-${chkip}-${cmpnic})" = "1" && dlog "INFO: IP confict of ${onenic}/${nicmac} $chkip at ${cmpnic} is gone."
				arrfastset ipconfict ${nicmac}-${onenic}-${chkip}-${cmpnic} 0
			fi
		done
	done
	wannet=$(ip route list dev eth0.2 2>/dev/null| awk '/scope/{print$1}'|head -n1|pipegetspacepos 1)
	test -z "$wannet" && return $isconfict
	lannet=$(ip route list dev br-lan 2>/dev/null| awk '/scope/{print$1}'|head -n1|pipegetspacepos 1)
	if [ "$lannet" = "$wannet" ]
		then
		let isconfict=$isconfict+1
		test "$(arrfastget ipconfict laneqwan)" != "1" && dlog "WARNING: wan network $wannet confict with lan network $lannet"
		arrfastset ipconfict laneqwan 1
	else
		test "$(arrfastget ipconfict laneqwan)" = "1" && dlog "INFO: wan network $wannet confict with lan network $lannet is gone."
		arrfastset ipconfict laneqwan 0
	fi
	return $isconfict
}
ipconfictcheck2(){
	local chklist onenic nicmac chkip cmpnic dupmac isconfict lannet wannet
	isconfict=0
	chklist="$@"
	test -z "$chklist" && chklist='eth0.2 br-lan'
	for onenic in $chklist
	do
		nicmac=$(ifconfig eth0.2|grep 'HWaddr '|awk '{print $5}')
		chkip=$(/sbin/ifconfig $onenic 2>/dev/null | grep 'inet addr:' | awk -F'inet addr:' '{print $2}'| awk '{print $1}')
		for cmpnic in $chklist
		do
			dupmac=$(/usr/bin/arping -D -f -b -c 1 -w 1 -s 0.0.0.0 -I $cmpnic $chkip 2>&1 | grep 'reply from ' | tr -d '[]' | awk -F"$chkip " '{print $2}'|awk '{print $1}')
			if [ -n "$dupmac" ]
			then
				test "$(arrfastget ipconfict ${nicmac}-${onenic}-${chkip}-${cmpnic})" != "1" && dlog "WARNING: IP of ${onenic}/${nicmac} $chkip confict with mac $dupmac at $cmpnic"
				arrfastset ipconfict ${nicmac}-${onenic}-${chkip}-${cmpnic} 1
				let isconfict=$isconfict+1
			else
				test "$(arrfastget ipconfict ${nicmac}-${onenic}-${chkip}-${cmpnic})" = "1" && dlog "INFO: IP confict of ${onenic}/${nicmac} $chkip at ${cmpnic} is gone."
				arrfastset ipconfict ${nicmac}-${onenic}-${chkip}-${cmpnic} 0
			fi
		done
	done
	wannet=$(ip route list dev eth0.2 2>/dev/null| head -n1|pipegetspacepos 1)
	test -z "$wannet" && return $isconfict
	lannet=$(ip route list dev br-lan | head -n1|pipegetspacepos 1)
	if [ "$lannet" = "$wannet" ]
		then
		let isconfict=$isconfict+1
		test "$(arrfastget ipconfict laneqwan)" != "1" && dlog "WARNING: wan network $wannet confict with lan network $lannet"
		arrfastset ipconfict laneqwan 1
	else
		test "$(arrfastget ipconfict laneqwan)" = "1" && dlog "INFO: wan network $wannet confict with lan network $lannet is gone."
		arrfastset ipconfict laneqwan 0
	fi
	return $isconfict
}
#
#2013-11-27 21:18:29.000000000
#+%Y-%m-%d-%H:%M:%S
#
timestamp2date(){
	local onets="$1"
	test -z "$onets" && return 1
	echo "$(date -u -D '%s' -d "$onets" +%Y.%m.%d-%H:%M:%S)"
	return $?
}
rrd2timestamp(){
	local onets="$@"
	local cnvts
	test -z "$onets" && return 1
	onets="$(echo $onets | tr ' ' '-')"
	cnvts="$(date -u +'%s' -d "$onets" -D '%Y-%m-%d-%H:%M:%S')"
	test -z "$cnvts" && return 1
	echo "$cnvts"
	return 0
}
setclock2timestamp(){
	local onets="$1"
	test -z "$onets" && return 1
	tsstr="$(timestamp2date $onets)"
	test -z "$tsstr" && return 1
	date -s "$tsstr"
	return $?
}
#
basexec mkdir -p /tmp/daemon/ && basexec mkdir -p $SCRIPTARRAYDIR
if [ $? -ne 0 ]
	then
	conlog "ERROR: lib.scripthelper.sh create directory /tmp/daemon/ and $SCRIPTARRAYDIR failed: $(basexec mkdir -p /tmp/daemon/ 2>&1) $(basexec mkdir -p $SCRIPTARRAYDIR 2>&1)"
	exit 1
fi
#
#trap daemonexit SIGTERM SIGINT SIGFPE SIGSTP
#trap daemonexit SIGTERM SIGINT
#
trap - SIGTERM SIGINT SIGFPE SIGQUIT
#
##
