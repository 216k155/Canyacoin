// Copyright (c) 2016 The Zcash developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "utiltest.h"

CWalletTx GetValidReceive(ZCJoinSplit& params,
                          const libcanya::SpendingKey& sk, CAmount value,
                          bool randomInputs) {
    CMutableTransaction mtx;
    mtx.nVersion = 2; // Enable JoinSplits
    mtx.vin.resize(2);
    if (randomInputs) {
        mtx.vin[0].prevout.hash = GetRandHash();
        mtx.vin[1].prevout.hash = GetRandHash();
    } else {
        mtx.vin[0].prevout.hash = uint256S("0000000000000000000000000000000000000000000000000000000000000001");
        mtx.vin[1].prevout.hash = uint256S("0000000000000000000000000000000000000000000000000000000000000002");
    }
    mtx.vin[0].prevout.n = 0;
    mtx.vin[1].prevout.n = 0;

    // Generate an ephemeral keypair.
    uint256 joinSplitPubKey;
    unsigned char joinSplitPrivKey[crypto_sign_SECRETKEYBYTES];
    crypto_sign_keypair(joinSplitPubKey.begin(), joinSplitPrivKey);
    mtx.joinSplitPubKey = joinSplitPubKey;

    boost::array<libcanya::JSInput, 2> inputs = {
        libcanya::JSInput(), // dummy input
        libcanya::JSInput() // dummy input
    };

    boost::array<libcanya::JSOutput, 2> outputs = {
        libcanya::JSOutput(sk.address(), value),
        libcanya::JSOutput(sk.address(), value)
    };

    boost::array<libcanya::Note, 2> output_notes;

    // Prepare JoinSplits
    uint256 rt;
    JSDescription jsdesc {params, mtx.joinSplitPubKey, rt,
                          inputs, outputs, 2*value, 0, false};
    mtx.vjoinsplit.push_back(jsdesc);

    // Empty output script.
    CScript scriptCode;
    CTransaction signTx(mtx);
    uint256 dataToBeSigned = SignatureHash(scriptCode, signTx, NOT_AN_INPUT, SIGHASH_ALL);

    // Add the signature
    assert(crypto_sign_detached(&mtx.joinSplitSig[0], NULL,
                                dataToBeSigned.begin(), 32,
                                joinSplitPrivKey
                               ) == 0);

    CTransaction tx {mtx};
    CWalletTx wtx {NULL, tx};
    return wtx;
}

libcanya::Note GetNote(ZCJoinSplit& params,
                       const libcanya::SpendingKey& sk,
                       const CTransaction& tx, size_t js, size_t n) {
    ZCNoteDecryption decryptor {sk.viewing_key()};
    auto hSig = tx.vjoinsplit[js].h_sig(params, tx.joinSplitPubKey);
    auto note_pt = libcanya::NotePlaintext::decrypt(
        decryptor,
        tx.vjoinsplit[js].ciphertexts[n],
        tx.vjoinsplit[js].ephemeralKey,
        hSig,
        (unsigned char) n);
    return note_pt.note(sk.address());
}

CWalletTx GetValidSpend(ZCJoinSplit& params,
                        const libcanya::SpendingKey& sk,
                        const libcanya::Note& note, CAmount value) {
    CMutableTransaction mtx;
    mtx.vout.resize(2);
    mtx.vout[0].nValue = value;
    mtx.vout[1].nValue = 0;

    // Generate an ephemeral keypair.
    uint256 joinSplitPubKey;
    unsigned char joinSplitPrivKey[crypto_sign_SECRETKEYBYTES];
    crypto_sign_keypair(joinSplitPubKey.begin(), joinSplitPrivKey);
    mtx.joinSplitPubKey = joinSplitPubKey;

    // Fake tree for the unused witness
    ZCIncrementalMerkleTree tree;

    libcanya::JSOutput dummyout;
    libcanya::JSInput dummyin;

    {
        if (note.value > value) {
            libcanya::SpendingKey dummykey = libcanya::SpendingKey::random();
            libcanya::PaymentAddress dummyaddr = dummykey.address();
            dummyout = libcanya::JSOutput(dummyaddr, note.value - value);
        } else if (note.value < value) {
            libcanya::SpendingKey dummykey = libcanya::SpendingKey::random();
            libcanya::PaymentAddress dummyaddr = dummykey.address();
            libcanya::Note dummynote(dummyaddr.a_pk, (value - note.value), uint256(), uint256());
            tree.append(dummynote.cm());
            dummyin = libcanya::JSInput(tree.witness(), dummynote, dummykey);
        }
    }

    tree.append(note.cm());

    boost::array<libcanya::JSInput, 2> inputs = {
        libcanya::JSInput(tree.witness(), note, sk),
        dummyin
    };

    boost::array<libcanya::JSOutput, 2> outputs = {
        dummyout, // dummy output
        libcanya::JSOutput() // dummy output
    };

    boost::array<libcanya::Note, 2> output_notes;

    // Prepare JoinSplits
    uint256 rt = tree.root();
    JSDescription jsdesc {params, mtx.joinSplitPubKey, rt,
                          inputs, outputs, 0, value, false};
    mtx.vjoinsplit.push_back(jsdesc);

    // Empty output script.
    CScript scriptCode;
    CTransaction signTx(mtx);
    uint256 dataToBeSigned = SignatureHash(scriptCode, signTx, NOT_AN_INPUT, SIGHASH_ALL);

    // Add the signature
    assert(crypto_sign_detached(&mtx.joinSplitSig[0], NULL,
                                dataToBeSigned.begin(), 32,
                                joinSplitPrivKey
                               ) == 0);
    CTransaction tx {mtx};
    CWalletTx wtx {NULL, tx};
    return wtx;
}
