# regex
numRE='^[0-9]+$'

# sockets
mapCppSocket="/tmp/cppMap-socket"

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

idSize=6;

function hashh
{
    local output=$(echo $1 | md5sum | sed 's/\([0-9a-f]*\).*/\1/')
    # echo " first " $output "\n"
    output=$(echo $output | sed 's/.*\([0-9a-f]\{13\}\)$/\1/')
    # echo " second " $output "\n"
    output=$(printf "%d" 0x$output)
    output=$(echo $output | sed "s/\([0-9]\{$idSize\}\).*/\1/")
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
    # output="$output$(hashh $1)|${#1}$1"
    output="$output$(hashh "$1")|$(dataLength "$1")$1"
    echo "$output"
}

# echo $(add 'Vil Mlakar')
# echo $(add 123456789)
# exit 1

function hashSeed
{
    # echo "seed before $seed"
    seed=$(echo $seed | md5sum | sed 's/\([0-9a-f]*\).*/\1/')
    # echo "seed after $seed"
}

function getRandomIndex
{
    local seedInDec=$(echo $seed | sed 's/.*\([0-9a-f]\{13\}\)$/\1/')
    seedInDec=$(printf "%d" 0x$seedInDec)
    local arraySize=${#masterNameArray[@]}
    local index=$((seedInDec%arraySize))
    echo $index
}

function getElementAtIndex()
{
    local element=${masterNameArray[$1]}
    local onePast=$(($1+1))
    # masterNameArray=( "${masterNameArray[@]:0:$1}" "${masterNameArray[@]:$onePast}" )
    masterNameArray=( "${masterNameArray[@]:0:$1}" "${masterNameArray[@]:$onePast}" )
    eval $2='$element'
}

function sendd
{
    echo "sending " "$1"
    local output=$(echo "$1" | socat - UNIX-CLIENT:/tmp/cppMap-socket)
    echo $output
}

function addRandom
{
    hashSeed
    local index=$(getRandomIndex)
    getElementAtIndex $index name
    local output=$(add "$name")
    output=$(sendd "$output")
    echo $output
}

checkInputFile $inputFile
seed=$(checkSeed $seed)
validationFrequency=$(checkValidationFrequency $validationFrequency)
initalSize=$(checkInitalSize $initalSize)

echo "seed " $seed
echo "validation Frequency " $validationFrequency
echo "initalSize " $initalSize 

mapfile -t masterNameArray < $inputFile


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

# TODO check if initalSize is !> masterNameArray size
arraySize=${#masterNameArray[@]}
for ((i=0;i<initalSize;++i))
do
    addRandom
    echo "done adding"
done
