#!/bin/bash
#====================================================
#Отправка сообщений  по номеру телефона на WhatsApp
#Сделано специально для BPQ Packet Node
#
#Обратная связь:
#Packet email: RN1M@RN1M.SPB.RUS.EU
#Winlink email: RN1M<at>winlink.org
#
#RN1M, Sergey 73!
#====================================================
#check на валлидность позывного, код Реда PE1RRR

function writeMessage {
	echo -n "Please enter your callsign: "
	read callId
	callClean=${callId//[$'\t\r\n']} && callId=${callId%%*( )}
	call=${callClean^^}
	callWithoutSSID=`echo ${call} | cut -d"-" -f1`
	len=`expr length "$callWithoutSSID"`
	CallsignRegex="[a-zA-Z0-9]{1,3}[0123456789][a-zA-Z0-9]{0,3}[a-zA-Z]"
	if [[ $callWithoutSSID =~ $CallsignRegex ]] && (( $len >= 1 && $len <= 8 ))
	then return 0
	else
	echo "Error: Invalid Callsign..."
	writeMessage
	fi
}

#генерируем пароль для сервера APRS-IS
function generateAPRSIS {
        h=1
	tmp_code=29666
	 while (( $h < $len )); do
		sym=$(echo $callWithoutSSID | cut -b $h)
		ords=$(printf "%d" "'$sym")
		s=$(( $ords * 256 ))
		tmp_code="$(( tmp_code ^ s ))"
		b=$(( h + 1 ))
		sym=$(echo $callWithoutSSID | cut -b $b)
		ords=$(printf "%d" "'$sym")
		tmp_code="$(( tmp_code ^ ords ))"
		h=$(( h + 2 ))
	done
		code=$(( $tmp_code & 32767 ))
}

#Sending messages from APRS-IS to WhatsApp
#APRS-IS server
function  BPQtoWhatsApp {
server=poland.aprs2.net
port=14580
#Send data to the server
#APRS to WhatsApp Radio Gateway by KC1QCQ
echo -n "Please enter phone number (with +): "
read number
echo -n "Please enter text your message: "
read text

data="${call//[$'\t\r\n']}>APBPQ1,TCPIP*::WTSAPP   :@${number//[$'\t\r\n']} ${text}"
login="user ${callWithoutSSID//[$'\t\r\n']} pass $code"
	printf '%s\n' "user $callWithoutSSID pass $code" "${data}" | ncat -C "$server" "$port" > /home/rn1m/bash_rn1m/tmp.file
	status=$(grep -c -w "verified" /home/rn1m/bash_rn1m/tmp.file)
	if [ $status -eq 1 ]; then
		echo "The message sent successfully!"
	else
		echo "The message was not sent, try again."
	fi

}
function exitAnswer {
	echo -n "Do you still want to send a message? (y\n) "
	read answer
	answer=`echo $answer | tr '[:upper]' '[^lower]'`
	answerClean=${answer//[$'\t\r\n']} && answer=${answer%%*( )}
	case "$answerClean" in
	"Y" | "y" )
	writeMessage
	generateAPRSIS
	BPQtoWhatsApp
	exitAnswer
	;;
	"N" | "n" )
	echo "Goodbay, 73!"
	exit 0
	;;
	*)
	exitAnswer
	;;
esac
}
#
echo "Sending messages from BPQ to WhatsApp"
	writeMessage
	generateAPRSIS
	BPQtoWhatsApp
	exitAnswer
