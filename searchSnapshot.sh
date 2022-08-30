git clone https://github.com/flutter/flutter.git
cd flutter
mkdir android-arm64-release
(curl -s 'https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json' | jq -r '.releases[]|if (select(.channel=="stable")) then .hash else empty end'  && curl -s 'https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json' | jq -r '.releases[]|if (select(.channel=="beta")) then .hash else empty end' && curl -s 'https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json' | jq -r '.releases[]|if (select(.channel=="dev")) then .hash else empty end' ) | awk '!x[$0]++' | cut -d ' ' -f1 | while read h; do (echo $(git cat-file -p $h:bin/internal/engine.version)  >> enginehash.tmp); done && awk -i inplace '!a[$0]++' enginehash.tmp
git log --branches=* --format=%H | while read c; do (echo $(git cat-file -p $c:bin/internal/engine.version)  >> enginehash.tmp); done && awk -i inplace '!a[$0]++' enginehash.tmp
while IFS= read -r line; do

out=$(wget -N https://storage.googleapis.com/flutter_infra_release/flutter/$line/android-arm64-release/linux-x64.zip 2>&1)

if [[ $out == *"Not Found"* ]]; then
    echo "No new file; not unzipping; Error $line"
    echo "Engine Not Found:  $line" >> ListEngine.info
else
    mkdir ./android-arm64-release/$line
    unzip linux-x64.zip -d ./android-arm64-release/$line
    rm -rf linux-x64.zip
    EngineHash=$(strings ./android-arm64-release/$line/gen_snapshot -n 32 | grep -e "^[0-9a-f]\{32\}" 2>&1)
    echo $EngineHash >> ./android-arm64-release/$line/EngineHash
    if [[ $oldEnginer == *"$EngineHash"* ]]; then
    echo "FoundEngineHash: $line"
    continue
    fi
    dartsdk=$(./android-arm64-release/$line/gen_snapshot --version 2>&1)
    echo $dartsdk >> ListEngine.info
    echo "Engine: $line" >> ListEngine.info
    echo "EngineHashSnapshot: " >> ListEngine.info
    echo $EngineHash >> ListEngine.info
    echo "Success $line"
fi

done < enginehash.tmp
