#!/bin/bash
set -u


DATADIR=./benchmark-datadir
SHA256CMD="$(command -v sha256sum || echo shasum)"
SHA256ARGS="$(command -v sha256sum >/dev/null || echo '-a 256')"

function canya_rpc {
    ./src/canya-cli -datadir="$DATADIR" -rpcuser=user -rpcpassword=password -rpcport=5983 "$@"
}

function canya_rpc_slow {
    # Timeout of 1 hour
    canya_rpc -rpcclienttimeout=3600 "$@"
}

function canya_rpc_veryslow {
    # Timeout of 2.5 hours
    canya_rpc -rpcclienttimeout=9000 "$@"
}

function canya_rpc_wait_for_start {
    canya_rpc -rpcwait getinfo > /dev/null
}

function canyad_generate {
    canya_rpc generate 101 > /dev/null
}

function canyad_start {
    case "$1" in
        sendtoaddress|loadwallet)
            case "$2" in
                200k-recv)
                    use_200k_benchmark 0
                    ;;
                200k-send)
                    use_200k_benchmark 1
                    ;;
                *)
                    echo "Bad arguments to canyad_start."
                    exit 1
            esac
            ;;
        *)
            rm -rf "$DATADIR"
            mkdir -p "$DATADIR/regtest"
            touch "$DATADIR/canyacoin.conf"
    esac
    ./src/canyad -regtest -datadir="$DATADIR" -rpcuser=user -rpcpassword=password -rpcport=5983 -showmetrics=0 &
    ZCASHD_PID=$!
    canya_rpc_wait_for_start
}

function canyad_stop {
    canya_rpc stop > /dev/null
    wait $ZCASHD_PID
}

function canyad_massif_start {
    case "$1" in
        sendtoaddress|loadwallet)
            case "$2" in
                200k-recv)
                    use_200k_benchmark 0
                    ;;
                200k-send)
                    use_200k_benchmark 1
                    ;;
                *)
                    echo "Bad arguments to canyad_massif_start."
                    exit 1
            esac
            ;;
        *)
            rm -rf "$DATADIR"
            mkdir -p "$DATADIR/regtest"
            touch "$DATADIR/canyacoin.conf"
    esac
    rm -f massif.out
    valgrind --tool=massif --time-unit=ms --massif-out-file=massif.out ./src/canyad -regtest -datadir="$DATADIR" -rpcuser=user -rpcpassword=password -rpcport=5983 -showmetrics=0 &
    ZCASHD_PID=$!
    canya_rpc_wait_for_start
}

function canyad_massif_stop {
    canya_rpc stop > /dev/null
    wait $ZCASHD_PID
    ms_print massif.out
}

function canyad_valgrind_start {
    rm -rf "$DATADIR"
    mkdir -p "$DATADIR/regtest"
    touch "$DATADIR/canyacoin.conf"
    rm -f valgrind.out
    valgrind --leak-check=yes -v --error-limit=no --log-file="valgrind.out" ./src/canyad -regtest -datadir="$DATADIR" -rpcuser=user -rpcpassword=password -rpcport=5983 -showmetrics=0 &
    ZCASHD_PID=$!
    canya_rpc_wait_for_start
}

function canyad_valgrind_stop {
    canya_rpc stop > /dev/null
    wait $ZCASHD_PID
    cat valgrind.out
}

function extract_benchmark_data {
    if [ -f "block-107134.tar.xz" ]; then
        # Check the hash of the archive:
        "$SHA256CMD" $SHA256ARGS -c <<EOF
4bd5ad1149714394e8895fa536725ed5d6c32c99812b962bfa73f03b5ffad4bb  block-107134.tar.xz
EOF
        ARCHIVE_RESULT=$?
    else
        echo "block-107134.tar.xz not found."
        ARCHIVE_RESULT=1
    fi
    if [ $ARCHIVE_RESULT -ne 0 ]; then
        canyad_stop
        echo
        echo "Please generate it using qa/canya/create_benchmark_archive.py"
        echo "and place it in the base directory of the repository."
        echo "Usage details are inside the Python script."
        exit 1
    fi
    xzcat block-107134.tar.xz | tar x -C "$DATADIR/regtest"
}

# Precomputation
case "$1" in
    *)
        case "$2" in
            verifyjoinsplit)
                canyad_start "${@:2}"
                RAWJOINSPLIT=$(canya_rpc zcsamplejoinsplit)
                canyad_stop
        esac
esac

case "$1" in
    time)
        canyad_start "${@:2}"
        case "$2" in
            sleep)
                canya_rpc zcbenchmark sleep 10
                ;;
            parameterloading)
                canya_rpc zcbenchmark parameterloading 10
                ;;
            createjoinsplit)
                canya_rpc zcbenchmark createjoinsplit 10 "${@:3}"
                ;;
            verifyjoinsplit)
                canya_rpc zcbenchmark verifyjoinsplit 1000 "\"$RAWJOINSPLIT\""
                ;;
            solveequihash)
                canya_rpc_slow zcbenchmark solveequihash 50 "${@:3}"
                ;;
            verifyequihash)
                canya_rpc zcbenchmark verifyequihash 1000
                ;;
            validatelargetx)
                canya_rpc zcbenchmark validatelargetx 5
                ;;
            trydecryptnotes)
                canya_rpc zcbenchmark trydecryptnotes 1000 "${@:3}"
                ;;
            incnotewitnesses)
                canya_rpc zcbenchmark incnotewitnesses 100 "${@:3}"
                ;;
            connectblockslow)
                extract_benchmark_data
                canya_rpc zcbenchmark connectblockslow 10
                ;;
            sendtoaddress)
                canya_rpc zcbenchmark sendtoaddress 10 "${@:4}"
                ;;
            loadwallet)
                canya_rpc zcbenchmark loadwallet 10
                ;;
            *)
                canyad_stop
                echo "Bad arguments to time."
                exit 1
        esac
        canyad_stop
        ;;
    memory)
        canyad_massif_start "${@:2}"
        case "$2" in
            sleep)
                canya_rpc zcbenchmark sleep 1
                ;;
            parameterloading)
                canya_rpc zcbenchmark parameterloading 1
                ;;
            createjoinsplit)
                canya_rpc_slow zcbenchmark createjoinsplit 1 "${@:3}"
                ;;
            verifyjoinsplit)
                canya_rpc zcbenchmark verifyjoinsplit 1 "\"$RAWJOINSPLIT\""
                ;;
            solveequihash)
                canya_rpc_slow zcbenchmark solveequihash 1 "${@:3}"
                ;;
            verifyequihash)
                canya_rpc zcbenchmark verifyequihash 1
                ;;
            trydecryptnotes)
                canya_rpc zcbenchmark trydecryptnotes 1 "${@:3}"
                ;;
            incnotewitnesses)
                canya_rpc zcbenchmark incnotewitnesses 1 "${@:3}"
                ;;
            connectblockslow)
                extract_benchmark_data
                canya_rpc zcbenchmark connectblockslow 1
                ;;
            sendtoaddress)
                canya_rpc zcbenchmark sendtoaddress 1 "${@:4}"
                ;;
            loadwallet)
                # The initial load is sufficient for measurement
                ;;
            *)
                canyad_massif_stop
                echo "Bad arguments to memory."
                exit 1
        esac
        canyad_massif_stop
        rm -f massif.out
        ;;
    valgrind)
        canyad_valgrind_start
        case "$2" in
            sleep)
                canya_rpc zcbenchmark sleep 1
                ;;
            parameterloading)
                canya_rpc zcbenchmark parameterloading 1
                ;;
            createjoinsplit)
                canya_rpc_veryslow zcbenchmark createjoinsplit 1 "${@:3}"
                ;;
            verifyjoinsplit)
                canya_rpc zcbenchmark verifyjoinsplit 1 "\"$RAWJOINSPLIT\""
                ;;
            solveequihash)
                canya_rpc_veryslow zcbenchmark solveequihash 1 "${@:3}"
                ;;
            verifyequihash)
                canya_rpc zcbenchmark verifyequihash 1
                ;;
            trydecryptnotes)
                canya_rpc zcbenchmark trydecryptnotes 1 "${@:3}"
                ;;
            incnotewitnesses)
                canya_rpc zcbenchmark incnotewitnesses 1 "${@:3}"
                ;;
            connectblockslow)
                extract_benchmark_data
                canya_rpc zcbenchmark connectblockslow 1
                ;;
            *)
                canyad_valgrind_stop
                echo "Bad arguments to valgrind."
                exit 1
        esac
        canyad_valgrind_stop
        rm -f valgrind.out
        ;;
    valgrind-tests)
        case "$2" in
            gtest)
                rm -f valgrind.out
                valgrind --leak-check=yes -v --error-limit=no --log-file="valgrind.out" ./src/canya-gtest
                cat valgrind.out
                rm -f valgrind.out
                ;;
            test_bitcoin)
                rm -f valgrind.out
                valgrind --leak-check=yes -v --error-limit=no --log-file="valgrind.out" ./src/test/test_bitcoin
                cat valgrind.out
                rm -f valgrind.out
                ;;
            *)
                echo "Bad arguments to valgrind-tests."
                exit 1
        esac
        ;;
    *)
        echo "Invalid benchmark type."
        exit 1
esac

# Cleanup
rm -rf "$DATADIR"
