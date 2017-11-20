// Copyright (c) 2016 The Zcash developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "wallet/wallet.h"
#include "canya/JoinSplit.hpp"
#include "canya/Note.hpp"
#include "canya/NoteEncryption.hpp"

CWalletTx GetValidReceive(ZCJoinSplit& params,
                          const libcanya::SpendingKey& sk, CAmount value,
                          bool randomInputs);
libcanya::Note GetNote(ZCJoinSplit& params,
                       const libcanya::SpendingKey& sk,
                       const CTransaction& tx, size_t js, size_t n);
CWalletTx GetValidSpend(ZCJoinSplit& params,
                        const libcanya::SpendingKey& sk,
                        const libcanya::Note& note, CAmount value);
