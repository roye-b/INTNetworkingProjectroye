#!/bin/bash
# run the server locally
cd tls_webserver
python3 app.py $1 &
cd ..

# let the server up and running
sleep 5

if [[ $1 = "eve" ]]
then

  bash tlsHandshake.sh 127.0.0.1
  EXIT_CODE=$?
  kill -9 $! &> /dev/null

  if [[ "$EXIT_CODE" -ne "5" ]]
  then
    echo -e "\n\nExpected exit code 5 and 'Server Certificate is invalid.' to be printed to stdout since client has responded with Eve's certificate."
    exit 1
  fi

  echo -e "\n\n✅ Well Done! you've passed Eve certificate tests"

elif [[ $1 = "bad-msg" ]]
then

  bash tlsHandshake.sh 127.0.0.1
  EXIT_CODE=$?
  kill -9 $! &> /dev/null

  if [[ "$EXIT_CODE" -ne "6" ]]
  then
    echo -e "\n\nExpected exit code 6 because the server encrypted the wrong client test message."
    exit 1
  fi

  echo -e "\n\n✅ Well Done! you've passed bad client message encryption tests"

else
  set -e

  bash tlsHandshake.sh 127.0.0.1
  curl 127.0.0.1:8080/flush &> /dev/null
  kill -9 $! &> /dev/null

  L=$(jq length tls_webserver/secrets.json)

  if [ "$L" != 1 ]; then
      echo -e "\n\nExpected the server to get Client Hello message only once, but called $L"
      exit 1
  fi

  # TODO test case for unavailable server, for uuid 71444da2-4e2d-4a32-8442-393eaaf593f4

  echo -e "\n\n✅ Well Done! you've passed the full handshake test\n\n\n"

fi

