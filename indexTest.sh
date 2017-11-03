# regex
numRE='^[0-9]+$'

# sockets
mapCppSocket="/tmp/cppMap-socket"

# size of integer used to idenfitfy each name
idSize=6;

inputFile=$1
seed=$2
validationFrequency=$3
initalSize=$4

function checkInputFile
{
    if ! [ -e $1 ]; then
        echo "InputFile " $1 " not found"
        exit 3
    fi
}

function checkInitalSize 
{
    local initialSize=100
    if [ -z "$1" ]; then
        # echo "seed not empty, generating seed: " $seed
        echo $initialSize
        return
    fi

    if ! [[ $1 =~ $numRE ]] ; then
        # echo "seed not a number, generating seed: " $seed
        echo $initialSize
        return
    fi

    echo $1
}

function checkValidationFrequency 
{
    local validationFreq=5
    if [ -z "$1" ]; then
        # echo "seed not empty, generating seed: " $seed
        echo $validationFreq " one "
        return
    fi

    if ! [[ $1 =~ $numRE ]] ; then
        # echo "seed not a number, generating seed: " $seed
        echo $validationFreq
        return
    fi

    echo $1
}

function checkSeed 
{
    if [ -z "$1" ]; then
        local seed=$(date +%s)
        # echo "seed not empty, generating seed: " $seed
        echo $seed
        return
    fi

    if ! [[ $1 =~ $numRE ]] ; then
        local seed=$(date +%s)
        # echo "seed not a number, generating seed: " $seed
        echo $seed
        return
    fi

    echo $1
}

################### check all input parameters ################### 
checkInputFile $inputFile
seed=$(checkSeed $seed)
validationFrequency=$(checkValidationFrequency $validationFrequency)
initalSize=$(checkInitalSize $initalSize)

function hashh
{
    local output=$(echo $1 | md5sum | sed 's/\([0-9a-f]*\).*/\1/')
    # echo " first " $output "\n"
    output=$(echo $output | sed 's/.*\([0-9a-f]\{13\}\)$/\1/')
    # echo " second " $output "\n"
    output=$(printf "%d" 0x$output)
    # output=$(echo $output | sed "s/\([0-9]\{$idSize\}\).*/\1/")
    output=$(echo $output | sed "s/.*\([0-9]\{$idSize\}\)$/\1/")
    echo $output
}

function dataLength
{
    local length=${#1}
    if [ ${#length} -eq 1 ]; then
        echo $length" "
        return
    fi

    echo $length
}

function add
{
    local output="add   |"
    output="$output$(hashh "$1")|$(dataLength "$1")$1"
    echo "$output"
}

function delete
{
    local output="delete|"
    output="$output$(hashh "$1")|$(dataLength "$1")$1"
    echo "$output"
}

function hashSeed
{
    # echo "seed before $seed"
    seed=$(echo $seed | md5sum | sed 's/\([0-9a-f]*\).*/\1/')
    # echo "seed after $seed"
}

function getRandomIndexInMasterArray
{
    local seedInDec=$(echo $seed | sed 's/.*\([0-9a-f]\{13\}\)$/\1/')
    seedInDec=$(printf "%d" 0x$seedInDec)
    local arraySize=${#masterNameArray[@]}
    local index=$((seedInDec%arraySize))
    echo $index
}

function getRandomIndexInAddedArray
{
    local seedInDec=$(echo $seed | sed 's/.*\([0-9a-f]\{13\}\)$/\1/')
    seedInDec=$(printf "%d" 0x$seedInDec)
    local arraySize=${#added[@]}
    local index=$((seedInDec%arraySize))
    echo $index
}

function getElementAtIndexInMasterArray()
{
    local element=${masterNameArray[$1]}
    local onePast=$(($1+1))
    masterNameArray=( "${masterNameArray[@]:0:$1}" "${masterNameArray[@]:$onePast}" )
    eval $2='$element'
}

function getElementAtIndexInAddedArray()
{
    local element=${added[$1]}
    local onePast=$(($1+1))
    added=( "${added[@]:0:$1}" "${added[@]:$onePast}" )
    eval $2='$element'
}

function sendd
{
    echo "sending " "$1"
    local output=$(echo "$1" | socat - UNIX-CLIENT:/tmp/cppMap-socket)
    echo $output
}

function checkInital
{
    local Hash=$(hashh "$1")
    local test=${initalNames[$Hash]}
    if ! [ -z "$test" ]; then
        if [ "$test" != "$1" ]; then
            echo "Something has gone serously wrong.." $test " " $1
            exit 4
        fi
        unset initalNames["$Hash"]
    fi
}

function addRandom
{
    local index=$(getRandomIndexInMasterArray)
    getElementAtIndexInMasterArray $index name
    local output=$(add "$name")
    output=$(sendd "$output")
    added+=("$name")
    eval $1='$name'
}

function deleteRandom
{
    local index=$(getRandomIndexInAddedArray)
    echo "inded: " $index
    # echo "added Array size before: " ${#added}
    getElementAtIndexInAddedArray $index name
    # echo "added Array size after: " ${#added}
    local output=$(delete "$name")
    output=$(sendd "$output")
    checkInital "$name"
    eval $1='$name'
}

function getAction
{
    local action=$(echo $seed | sed 's/.*\([0-9a-f]\{1\}\)$/\1/')
    action=$(echo $action | awk '{print toupper($0)}')
    action=$( echo "obase=2; ibase=16; $action" | bc )
    action=$(echo $action | sed 's/.*\([0-1]\{2\}\)$/\1/')

    if [ "$action" == "0" ] || [ "$action" == "00" ]; then
        echo "add"
        return
    fi

    if [ "$action" == "1" ] || [ "$action" == "01" ]; then
        echo "search_existing"
        return
    fi

    if [ "$action" == "10" ]; then
        echo "search_non-existing"
        return
    fi

    if [ "$action" == "11" ]; then
        echo "delete"
        return
    fi

    echo $action
}

echo "seed " $seed
echo "validation Frequency " $validationFrequency
echo "initalSize " $initalSize 

mapfile -t masterNameArray < $inputFile

if [ $initalSize -gt ${#masterNameArray[@]} ]; then
    echo "inital size ($initalSize) is more than number of Names supplied (${#masterNameArray[@]})"
    exit 5
fi

# output=$(add "2342342")
# echo "output"  "$output"
# echo $(sendd "$output")
# exit 1

# # check for duplicate names
# for i in "${masterNameArray[@]}"
# do
# match=0
#     for j in "${masterNameArray[@]}"
#     do
#         if [ "$i" == "$j" ]; then
#             match=$[$match+1]
#         fi
#         if [ $match -gt 1 ]; then
#             echo "duplicate name: " $i
#             exit 5
#         fi
#     done
# done 

# check for duplicate names and hash collisions
# for i in "${masterNameArray[@]}"
# do
#     match=0
#     nameHash=$(hashh "$i")
#     # echo "nameHash "$nameHash

#     for j in "${masterNameArray[@]}"
#     do
#         lineHash=$(hashh "$j")

#         # check if name in outter loop and inner loop 
#         # are only equivalent once
#         if [ "$i" == "$j" ]; then
#             match=$[$match+1]

#             # if names are equivalent more than once,
#             # we have a name duplicate
#             if [ $match -gt 1 ]; then
#                 echo "Error! duplicate name: " $i $j
#                 exit 5
#             fi
#             # echo "found equivelent: $i $j"
#             continue
#         fi

#         if [ "$nameHash" == "$lineHash" ]; then
#             echo "Error! hash collision!: " $i "("$nameHash") and $j ("$lineHash")"
#             exit 6
#         fi
#     done
# done 

############## initalization ############## 
# 1) start all processes
# maptree
# /home/aa/rust/mapImplementation/mapTree &
# cppLLRBTree
# /home/aa/rust/cppB-tree/cppLLRBTree &
# rust implementaiotn 
# /home/aa/rust/b-tree/target/debug/btree &

arraySize=${#masterNameArray[@]}

declare -A initalNames
added=()

for ((i=0;i<initalSize;++i))
do
    addRandom $name
    echo "done adding " $name
    initalNames[$(hashh $name)]=$name
    echo "Name in initalNames[$(hashh $name)] = "${initalNames[$(hashh $name)]}
    # added+=('$name')
    # echo "Added[0] " ${added[0]}
done

echo " masterNameArray size " ${#masterNameArray[@]}
echo " initalNames size " ${#initalNames[@]}

count=0
while [ ${#masterNameArray[@]} -ne 0 ] && [ ${#initalNames[@]} -ne 0 ]
do
    hashSeed
    action=$(getAction)

    if [ "$action" == "add" ]; then
        echo "inside add"
        # addRandom
    fi

    if [ "$action" == "search_existing" ]; then
        echo "inside search_existing"
        # addRandom
    fi

    if [ "$action" == "search_non-existing" ]; then
        echo "inside search_non-existing"
        # addRandom
    fi

    if [ "$action" == "delete" ]; then
        echo "inside delete"
        # addRandom
    fi

    $count=$[$count+1]
    if [ $count -eq $validationFrequency ]; then
        count=0
        # compare()
    fi
done
