# Ethereum Yellow Paper Notes

![Yellow Paper](assets/yellow_paper.jpeg)

## Math Symbols
 - `∃`: there exists
 - `∀`: for all
 - `∧`: and
 - `∨`: or
 - `N_{H}`: 1,150,000 aka block number at which the protocol was upgraded from homestead to frontier.
 - `T`: a transaction eg `T = { n: nonce, p: gasPrice, g: gasLimit, t: to, v: value, i: initBytecode, d: data }`
 - `S()`: returns the sender of a transaction eg `S(T) = T.from`
 - `Λ`: (lambda) account creation function
 - `KEC`: Keccak SHA-3 hash function
 - `RLP`: Recursive Length Prefix encoding

## High-level glossary
 - `σ`: ethereum world state
 - `B`: block
 - `μ`: EVM state
 - `A`: accumulated transaction sub-state
 - `I`: execution environment
 - `o`: output of `H(μ,I)` ie null if we're good to go or a set of data if execution should halt
 - `Υ(σ,T) => σ'`: the transaction-level state transition function
 - `Π(σ,B) => σ'`: the block-level state transition function, processes all transactions then finalizes with Ω
 - `Ω(B,σ) => σ`: block-finalisation state transition function
 - `O(σ,μ,A,I)`: one iteration of the execution cycle
 - `H(μ,I) => o`: outputs null while execution should continue or a series if execution should halt.

- `RLP`: Recursive Length Prefix (serialization and encoding scheme used in Ethereum to encode structured data such as transactions, blocks, and account state)
  - Integer
    - `RLP`(big endian representation of integer)
  - Byte array
    - If one byte with value < 128, return this one value
    - If size < 56 bytes, return sequence [128 + size, bytes]
    - If size >= 56 bytes, return [183 + size of encoded length, big-endian integer length, bytes]
  - List
    - if total size < 56 bytes, [192 + total size, serialized items]
    - If size >= 56 bytes, return [247 + size of encoded length, big-endian integer length, serialized items]

- `Merkle Patricia Tree`
  - Allow efficient (logarithmic) insert/delete operations
  - Hex-prefix encoding
    - Encodes sequence of hex nibbles + a flag to a sequence of bytes
    - High nibble of the first byte contains two flags
      - the lowest bit encodes the oddness of sequence length
      - the second-lowest encodes the input flag
    - If number of nibbles is even low nibble of first byte is zero, data starts with second byte
    - If number of nibbles is odd data starts with low nibble of first byte 
  - Maps from 256-bit hashes to arbitrary-length binary data
  - If node's RLP encoding is < 32 bytes it is stored directly, otherwise it stores hash-pointer to byte array
  - Three kinds of nodes
    - Leaf
      - RLP(HP-encoded(remaining nibbles of key), true), value)
    - Extension
      - RLP(HP-encoded(2 (?) next nibbles of key), false), pointer to next node)
    - Branch
      - RLP(child0, ..., child15, value or () if no value for this prefix)

    <img src="assets/trie.png"  width="60%" height="80%">

- `Signing transactions`
  - Private key - random positive integer 32 bytes long, big-endian in the range [1, sec256k1n - 1]
  - Public key - byte array of size 64 formed from the concatenation of two positive   integers each < 2**256
  - ECDSASIGN(e, private key) = (v, r, s)
  - Message to sign is the Keccak hash of the transaction fields
  - Validation
    - 0 < r < secp256k1n
    - 0  < s < secp2561kn before Homestead
    - 0 < s < sep256k1n / 2 after Homestead
    - v - either the 'recovery id' (27 or 28, specifies sign of the curve point) or 'chain id doubled plus 35 or 36'


## Ethereum World-State: σ

```
σ = [ account1={...}, account2={...},
  account3= {

    n: nonce aka number of transactions sent by account3
    b: balance ie number of wei account3 controls
    s: storage root, hash of the merkle-patricia tree that contains this accounts long-term data store
    c: code, hash of the EVM bytecode that controls this account. If this equals the hash of an empty string, this is a non-contract account.

  }, ...
]
```

- World State
  - Essentially the mapping between addresses and account states
  - Address
    - 160 bit (20 bytes)
    - Rightmost 160 bits of Keccak hash of ECDSA public key
  - Clients store the state in Merkle Patricia tree
  - State DB - backend DB, essentially key-value storage of bytearrays to bytearrays
  - State root hashes are stored in the blockchain
  - Account state
    - nonce
      - for regular account number of transactions sent from this address
      - for contract number of contract creations
      - 256 bit
    - balance
      - 256 bit
    - storageRoot
      - 256-bit hash of the root node of storage trie
      - Storage trie is a maping between 256-bit integers and 256-bit integers
        - encoded as mapping of Keccak 256-bit hash of key to RLP of value
    - codeHash
      - 256-bit Keccak hash of code
      - State database contains the full code for this hash
      - for simple non-contract account 256-bit Keccak hash of empty string
  - Empty account - no code, zero nonce, zero balance // since spurious dragon
  - Dead account - non-existent or empty // since spurious dragon

## Transaction: $T$

- Transaction
  - Any transaction type is either message call or contract creation (defined by to field)  
  - All transaction types specify a number of common fields:
  - type: EIP-2718 transaction type $T_x$
  - Legacy transaction // term defined in Berlin EIP-2718, before all transactions are legacy
    - nonce $T_n$
      - number of transactions sent by the sender, 256 bit integer
    - gasPrice $T_p$
      - number of wei paid for each unit of gas, 256 bit integer
      - selected by transaction creator
      - the higher the price the more likely transaction will be selected by the miner
    - gasLimit $T_g$
      - maximum amount of gas that can be used in this transaction, 256 bit integer
    - to $T_t$
      - address of recipient for call, 160 bit binary
      - empty for contract creation (RLP of empty byte series)
    - value $T_v$
      - to be transferred to recipient or newly created account, 256 bit integer
    - v, r, s $T_r$ $T_s$
      - elliptic curve values corresponding to the signature
      - 5 bit, 256 bit, 256 bit integers
      - determine the sender
    - init $T_i$
      - Only for contract creation
      - unlimited size byte array with EVM-code for the new account initialization
      - init code returns body of the contract (saved as it's code)
      - init code itself is discarded after first run
    - data $T_d$
      - Only for message call
      - unlimited size byte array, specifying the input data for the message call
  - Transaction Type 1 // since Berlin
    - chainId $T_c$
    - nonce $T_n$
      - number of transactions sent by the sender, 256 bit integer
    - gasPrice $T_p$
      - number of wei paid for each unit of gas, 256 bit integer
      - selected by transaction creator
      - the higher the price the more likely transaction will be selected by the miner
    - gasLimit $T_g$
      - maximum amount of gas that can be used in this transaction, 256 bit integer
    - to $T_t$
      - address of recipient for call, 160 bit binary
      - empty for contract creation (RLP of empty byte series)
    - value $T_v$
      - to be transferred to recipient or newly created account, 256 bit integer
    - data $T_d$
      - Only for message call
      - unlimited size byte array, specifying the input data for the message call
    - accessList $T_A$
      - List of (address, list of storage key) pairs
      - keys: $E ≡ (E_a, E_s)$
      - Can be empty
      - List of storage keys for any address can be empty
      - Non-unique addresses and keys are allowed, but charged multiple times
      - https://eips.ethereum.org/EIPS/eip-2930
    - signatureYParity $T_y$, signatureR, signatureS
      - elliptic curve values corresponding to the signature
      - determine the sender
  - Transaction Type 2 // since London
    - chainId $T_c$
    - nonce $T_n$
      - number of transactions sent by the sender, 256 bit integer
    - max_priority_fee_per_gas
      - maximum fee per gas sender is willing to give to miners to incentivize them to include their transaction
    - max_fee_per_gas
      - maximum fee per gas sender is willing to pay total, which covers both the priority fee and the block’s network fee per gas (aka: base fee) 
    - gasLimit
      - maximum amount of gas that can be used in this transaction, 256 bit integer
    - destination
      - address of recipient for call, 160 bit binary
      - empty for contract creation (RLP of empty byte series)
    - amount
      - value to be transferred to recipient or newly created account, 256 bit integer
    - data
      - Only for message call
      - unlimited size byte array, specifying the input data for the message call
    - access_list
      - List of (address, list of storage key) pairs
      - Can be empty
      - List of storage keys for any address can be empty
      - Non-unique addresses and keys are allowed, but charged multiple times
      - https://eips.ethereum.org/EIPS/eip-2930
    - signature_y_parity, signature_r, signature_s
      - elliptic curve values corresponding to the signature
      - determine the sender
    - The transaction will always pay the base fee per gas of the block it was included in, and they will pay max_priority_fee_per_gas set in the transaction, as long as the combined amount of the two fees doesn’t exceed the transaction’s max_fee_per_gas.
    - https://eips.ethereum.org/EIPS/eip-1559

## Block: $B$
![Block](https://miro.medium.com/v2/resize:fit:1400/0*0jUnJkLPAPhIA2Bg)


```
B = Block = {
  H: Header = {
    p: parentHash,
    o: ommersHash,
    c: beneficiary,
    r: stateRoot,
    t: transactionsRoot,
    e: receiptsRoot,
    b: logsBloomFilter,
    d: difficulty,
    i: number,
    l: gasLimit,
    g: gasUsed,
    s: timestamp,
    x: extraData,
    m: mixHash,
    n: nonce,
  },
  T: Transactions = [
    tx1, tx2...
  ],
  U: Uncle block headers = [
    header1, header2..
  ],
  R: Transaction Receipts = [
    receipt_1 = {
      σ: root hash of the ETH state after transaction 1 finishes executing,
      u: cumulative gas used immediately after this tx completes,
      b: bloom filter,
      l: set of logs created while executing this tx
    }
  ]
}
```

- Block
  - Structure
    - $B ≡ (B_H, B_T, B_U)$
    - Header
      - parentHash
        - 256-bit Keccak hash of parent block header
      - ommersHash
        - 256-bit Keccak hash of ommers list of this block
      - beneficiary
        - miner address (or set by miner)
      - stateRoot
        - 256-bit Keccak hash of the root node of the state trie after all transactions are executed
      - transactionsRoot
        - 256-bit Keccak hash of the root node of the trie of block transactions
      - receiptsRoot
        - 256-bit Keccak hash of the root node of the trie of transactions receipts
      - logsBloom
        - The Bloom filter composed from indexable information (logger address and log topics) contained in each log entry from the receipt of each transaction in the transactions list
      - difficulty
        - Can be calculated from the previous block's difficulty and timestamp
          - difficulty of genesis block = 131072
          - x = floor(parent block difficulty / 2048)
          - before homestead: c = 1 if timestamp < parent timestamp + 13, c = -1 otherwise
          - homestead: c = max(1 - floor((timestamp - parent timestamp) / 10), -99)
          - byzantium: c = max(2 if parent has uncles else 1 - floor((timestamp - parent timestamp) / 9), -99)
            - This change makes difficulty adjustment proportional to ETH issued & hashpower spent on the block, instead of just proportional to timestamp change, which prevents attack vectors with manipulating uncle rate to game the system
          - epsilon = floor(2**(floor(block number / 1e5) - 2))
            - Muir Glacier: instead of block_number use block_number - 9_000_000
            - London: instead of block_number use block_number - 9_700_000
            - Arrow Glacier: instead of block_number use block_number - 10_700_000
          - difficulty = max(genesis difficulty, parent difficulty + x * c + epsilon)
        - This mechanism enforces a homeostasis in terms of the time between blocks; a smaller period between the last two blocks results in an increase in the difficulty level and thus additional computation required, lengthening the likely next period. Conversely, if the period is too large, the difficulty, and expected time to the next block, is reduced.
        - The expected time to find the nonce & mixHash is proportional to the difficulty
      - number
        - number of ancestor blocks
        - Genesis block has number 0
      - gasLimit
        - current limit of gas expenditure per block
        - parent gasLimit - floor(parent gasLimit / 1024) < gasLimit < parent gasLimit + floor(parent gasLimit / 1024)
        - gasLimit >= 125000
      - gasUsed
        - total gas used by transactions
      - timestamp
        - output of Unix's time() at the block inception
        - must be greater than parent timestamp
      - extraData
        - byte array of 32 bytes or fewer, arbitrary data relevant to the block
      - mixHash
        - 256-bit hash used as proof of work together with nonce
      - nonce
        - 64 bit hash used as proof of work together with mixHash
        - nonce <= 2**256 / difficulty
      - baseFeePerGas // since London `block_base_fee_per_gas`
        - adjusted up or down each block according to a formula which is a function of gas used in parent block and gas target (block gas limit divided by elasticity multiplier (2)) of parent block. 
	        - parentGasTarget = parent.gasLimit / 2
	        - if London fork block
		        - baseFee = 1000000000
		    - else if parent.gasUsed == parentGasTarget
			    - baseFee = parent.baseFee
			- else if parent.GasUsed > parentGasTarget
				- gasUsedDelta = parent.gasUsed - parentGasTarget
				- baseFeeDelta = max(parent.baseFee * gasUsedDelta / parentGasTarget // 8, 1)
				- baseFee = parent.baseFee + baseFeeDelta
			- else 
				- gasUsedDelta = parentGasTarget - parent.gasUsed
		        - baseFeeDelta = parent.baseFee * gasUsedDelta / parent.gasUsed / 8
		        - - baseFee = parent.baseFee - baseFeeDelta
        - The algorithm results in the base fee per gas increasing when blocks are above the gas target, and decreasing when blocks are below the gas target.
        - The base fee per gas is burned
        - https://eips.ethereum.org/EIPS/eip-1559
    - Transactions
      - RLP-encoded pairs of index and transaction
    - Transaction receipts
      - $R ≡ (R_x, R_z, R_u, R_b, R_l)$
      - $R$:  The transaction receipt is a tuple of five items 
        - $R_x$: the type of the transaction
        - $R_z$: the status code of the transaction
        - $R_u$: the cumulative gas used in the block containing the transaction receipt as of immediately after the transaction has happened
        - $R_l$: the set of logs created through execution of the transaction
        - $R_b$: the Bloomfilter composed from information in those logs 
      - Not a part of the body (transferred through network), but saved to DB after block execution
      - RLP-encoded pairs of index and receipt
      - Receipt
        - Post-transaction state root (before Byzantium); 0 or 1 number showing whether transaction was successfully finished (after Byzantium)
        - Cumulative gas used in the block after transaction has happened
        - Logs created during transaction
          - Series of log entries
            - Loggers' address (20 bytes)
            - A series of 32-bytes log topics (up to 4 topics)
            - Some bytes of data
        - Bloom filter of logs
          - 2048 bits (256 bytes)
          - Allow easy search log by topic
    - Ommer/uncle block headers (blocks with parent equal to current block grandparent)
      - each same format as header
  - Block header validity
    - nonce & mixHash are correct 
    - gasUsed <= gasLimit
    - gasLimit is correct
    - baseFee is correct // since London `block_base_fee_per_gas`
	- timestamp > parent timestamp
    - number = parent number + 1
    - extra data is at most 32 bytes
  - Block finalization
    - Validate ommers
      - Maximum of ommer headers is 2
      - Verify that header is valid
      - Ommer should be a sibling to one of 6 this block's ancestors (either parent or grandparent or grand-grandparent and so on up to 6th ancestor)
    - Validate transactions
      - gasUsed of block = accumulated gas used according to the last transaction
    - Apply rewards
      - Award block beneficiary
        - 5 Ether before Byzantium
        - 3 Ether after Byzantium
      - For each uncle header award block beneficiary with blockReward / 32
      - Award each uncle beneficiary with (1 + (Uncle block number - block number) / 8) * blockReward
    - Verify state and nonce
  - Genesis block
    - Parent hash = 0
    - Ommers list is empty
    - Beneficiary address = 0
    - stateRoot - determined by development premine (number the accounts with non-zero balance filled according to Ethereum presale)
    - transactions root = 0
    - Receipts root = 0
    - Log bloom = all 0s
    - Difficulty = 2**17
    - number = 0
    - gasUsed = 3141592
    - gasLimit = 0
    - time - initial timestamp
    - extraData = 0
    - mixHash = 0
    - nonce = KEC((42))



## Execution Environment: I

```
I = Execution Environment = {
  a: address(this) address of the account which owns the executing code
  o: tx.origin original sender of the tx that initialized this execution
  p: tx.gasPrice price of gas
  d: data aka byte array of method id & args
  s: sender of this tx or initiator of this execution
  v: value send along w this execution or transaction
  b: byte array of machine code to be executed
  H: header of the current block
  e: current stack depth
}
```

- Transaction execution
  - defines the state transition function $Υ$, with $T$ being a transaction and $σ$ the state
    - $σ^` = Υ(σ, T)$ [$σ^`$ is the post transactional state]
  - Intrinsic gas $g_0$: the amount of gas this transaction requires to be paid prior to execution
    - <img src="assets/intrinsic_gas.png"  width="40%" height="40%">
    - for input data/new contract init code G(txdatazero) for each zero byte + G(txdatanonzero) for each non-zero byte
    - G(txcreate) for contract creation after Homestead
    - G(transaction)
    - ACCESS_LIST_ADDRESS_COST * addresses_in_access_list + ACCESS_LIST_STORAGE_KEY_COST * storage_keys_in_access_list // since Berlin
  - Effective gas price
    - Legacy and Type 1 transactions: effective_gas_price = transaction.gasPrice
    - Type 2 transactions // since London
      - priority_fee_per_gas = min(transaction.max_priority_fee_per_gas, transaction.max_fee_per_gas - block.base_fee_per_gas) `priority_fee`
      - effective_gas_price = priority_fee_per_gas + block.base_fee_per_gas
  - Up-front cost = effectiveGasPrice * gasLimit + transferValue
    -  $v_0 ≡ T_gT_p + T_V$
  - Check for validity 
    - <img src="assets/validity.png"  width="50%" height="90%">
    - The transaction is well-formed RLP, with no additional trailing bytes
    - Signature is valid, sender can be calculated from signature
    - Sender exists and is not contract 
    - Transaction nonce = sender's current nonce
    - Intrinsic gas <= gasLimit
    - up-front cost <= sender balance
    - user is willing to at least pay the base fee // since London
      - transaction.max_fee_per_gas >= block.base_fee_per_gas
    - transaction.max_fee_per_gas < 2**256 // since London
    - transaction.max_priority_fee_per_gas < 2**256 // since London
    - transaction.max_fee_per_gas >= transaction.max_priority_fee_per_gas // since London
  - Accrued sub-state: A
    - The data accumulated during tx execution that needs to be remembered for later
    - $A ≡ (A_s, A_l, A_t, A_r, A_a, A_K)$
    - ```
      A = {
        s: suicide set (the accounts to delete at the end of this tx)
        l: logs
        t: touched accounts
        r: refunds (gas received when storage is freed)
        a: set of accessed account addresses
        K: set of accessed storage keys (each
      element is a tuple of a 20-byte account address and
      a 32-byte storage slot)
      }
      ```

    - Suicide set
      - set of accounts that will be discarded following the transaction's completion
    - Log series
      - a series of archived and indexable 'checkpoints' in VM code execution that allow for contract-calls to be easily tracked by onlookers external to the Ethereum world (such as decentralised application front-ends)
      - Append-only, not readable by contracts
      - ~10x cheaper  than storage
      - organized into Merkle trie which allows efficient light client access to event records
    - Touched accounts
      - Empty ones are deleted at the end of transaction
    - Refund balance
      - increased through using the SSTORE instruction in order to reset contract storage to zero from some non-zero value
      - increased through SELFDESTRUCT // till Berlin
  - Accessed lists // since Berlin
    - The list of addreses accessed in transaction
      - Initialized to having sender, receiver (or created contract) and all precompile addresses + all addresses from access list of the transaction
    - The list of (address, storage key) pairs accessed in transaction
      - Iinitialized to keys in access list of the transaction
    - Similar to substate in that they are scoped to entire transaction execution
    - Used to calculate gas cost of opcodes accessing the state (EXTCODESIZE, EXTCODECOPY, EXTCODEHASH, BALANCE, CALL, CALLCODE, DELEGATECALL, STATICCALL, SLOAD, SSTORE, SELFDESTRUCT): cold access cost if not yet accessed, warm access cost otherwise
    - https://eips.ethereum.org/EIPS/eip-2929
  - Execution
    - Validity
      - `transaction_validity`
      - Additionally: gasLimit + gas used already in this block <= block gasLimit
    - Execution
      - Increment nonce of sender
      - sender balance -= gasLimit * gasPrice
        - fail if resulting balance < 0
      - gasLeft = gasLimit - intrinsicGas
      - This moment is called checkpoint state
        - <img src="assets/checkpoint_state.png"  width="60%" height="80%">
      - we define the tuple of post-execution provisional state $σ_P$, remaining gas $g_0$, accrued substate $A$ and status code $z$
          <img src="assets/provisional_state.png"  width="60%" height="80%">

## Contract Creation
- Contract creation
    - New account
      - Address = rightmost 160 bits of Keccack-256 hash of RLP(sender, sender nonce - 1)
        - $a ≡ ADDR(s, σ[s]n − 1, ζ, i)$
        - $ADDR(s, n, ζ, i) ≡ B96..255(KEC(L_A(s, n, ζ, i)))$
        - $L_A(s, n, ζ, i) ≡ (RLP(s, n))$  if $ζ = ∅$
        - $L_A(s, n, ζ, i) ≡ (255) · s · ζ · KEC(i)$ otherwise
        - $ζ$ the salt for new account’s address 
      - initial account nonce = 1
      - balance = transferred value + previous balance if account already existed
      - Storage is empty
      - Code hash = Keccak256(empty string)
    - Reduce sender's balance by the value passed
    - Execute initialization code
      - If it runs out of gas, `Out Of Gas` exception occurs and the entire create operation should have no effect on the state, effectively leaving it as it was immediately prior to attempting the creation.
        - intrinsic cost is still paid, gasLeft = 0 after it
        - transferred value is not paid
      - Subtleties
        - During this execution newly created account exists but without code. So any message received by it doesn't execute any code.
        - If the initialisation execution ends with a SUICIDE instruction, the matter is moot since the account will be deleted before the transaction is completed.
        - For a normal STOP code, or if the code returned is otherwise empty, then the state is left with a zombie account, and any remaining balance will be locked into the account forever.
    - Final contract creation cost is paid = 2**256 - 1 if created contract's code size <= 24000, otherwise G(codedesposit) * code size 
      - (that is, subtracted from gasLeft)
      - This can also run out of gas resulting in OOG
      - Before Homestead in case of OOG here account is still created, along with initialization side-effects and the value is transferred, but no contract code is deployed. gasLeft stays the same then.
    - If code returned from initialization code starts with byte 0xEF creation aborts with failure // since London
    - Save code returned from initialization code as new contract's code
- If we send a transaction `tx` to create a contract, `tx.to` is set to 0 and we include a `tx.init` field that contains bytecode. This is NOT the bytecode run by the contract, rather it RETURNS the bytecode run by the contract ie the `tx.init` code is run ONCE at contract creation and never again.
  - If `T.to == 0` then this is a contract creation transaction and `T.init != null`, `T.data == null`

## Message Call
- Message call
    - Transfer value from sender to recipent
      - If recipient doesn't exist and transferred value is not zero, create it first with no code, no state, zero balance and zero nonce
    - Execute account's code
      - If exception occurs (OOG, stack underflow, invalid jump destination, invalid instruction), no gas is refunded to the caller and the state is reverted to the point immediately prior to balance transfer (so the gas fee still goes to the miner and value transfer is reverted)
      - Precompiled contracts
        - Four contracts which don't invoke EVM execution (i.e. implemented natively)
        - address = 1 - ECREC (elliptic curve public key recovery function)
        - address = 2 - SHA256 
        - address = 3 - RIP160 (RIPEMD 160-bit hash scheme)
        - address = 4 - ID (identity function)
          -  output equals input
        - address = 5 - MODEXP (modular exponentiation (base**exp) % mod) // since Byzantium
        - address = 6 - ECADD (elliptic curve point addition) // since Byzantium
        - address = 7 - ECMUL (elliptic curve point scalar multiplication)// since Byzantium
        - address = 8 - ECPAIR // since Byzantium
        - address = 9 - BLAKE2b // since Istanbul

## EVM state: μ
EVM is a $quasi$-Turingcomplete machine; the $quasi$ qualification comes from the fact that the computation is intrinsically bounded through a parameter, gas, which limits the total amount of computation done.

```
μ = {
  g: gas left
  pc: program counter ie index into which instruction of I.b to execute next
  m: memory contents, lazily initialized to 2^256 zeros
  i: number of words in memory
  s: stack contents
}
```

<img src="assets/evm.png"  width="60%" height="80%">

- EVM
  - stack-based architecture
  - Word size, stack item size = 256 bit (32 bytes)
  - Maximum stack size is 1024
  - Memory - word-addressed byte array. Volatile
  - Storage - word-addressable word array. Non-volatile, maintained as a part of the system state.
  - All locations in memory and storage are initially zero
  - Program code is not stored in memory, instead it is stored in a virtual ROM accessible only through special instruction
  - Integers are big-endian
  - 160-bit address is stored in rightwards (least significant) bits of 256-bit words
  - Gas paid for the operation (before operation execution)
    - Intrinsic operation cost
    - Payment for the subordinate message call or contract creation (in case of CREATE, CALL & CALLCODE instructions)
    - Payment for the usage of the memory
      - Over an account's execution, the total fee for memory usage payable is proportional to smallest multiple of 32 bytes that are required such that all memory indices (whether for read or write) are included in the range
      - When storage value is cleared, refund is given
  - Machine state
    - gas available
    - program counter PC - 256 bit
    - Memory contents 
    - Active number of words in memory
    - Stack contents
  - Exception happens when
    - There's insufficient gas for the next instruction
    - instruction is invalid
    - There's insufficient items in stack for instruction
    - JUMP/JUMPI destination is invalid
      - Destination should be any position in code occupied by JUMPDEST instruction
      - All such positions must be on valid instruction boundaries, rather than sitting in the data portion of PUSH operations and must appear within the explicitly defined portion of the code (rather than in the implicitly defined STOP operations that trail it)
    - New stack size is going to be more than 1024
  - Program halts when
    - after RETURN instruction with result given by return
    - after STOP, SUICIDE instructions with result ()
  - Execution cycle
    - Stack items are added or removed from the left-most, lower-indexed portion of the series
    - Gas is reduced by instruction cost
    - PC increments, unless it's JUMP or JUMPI
  - Operation cost
    - G<sub>memory</sub> paid for each word of memory accessed expansion
    - After 724 bytes of memory used it costs quadratically
  - Instructions
    - Gas costs https://ethgastable.info/
    - Stop and arithmetics
      - STOP - halts execution
      - ADD - pop two values from stack, push the sum
      - MUL - pop two values from stack, push the product
      - SUB - pop two values from stack, push the difference
      - DIV - pop two values from stack, push the integer divison, or 0 if denominator is 0
      - SDIV - signed integer division
        - 0 if denominator is 0
        - -2**255 if nominator = -2*255 & denominator = -1 (overflow)
        - integer division (truncating) with correct sign
        - All values are treated as two's complement signed 256-integers
      - MOD - pop two values from stack, modulo remainder or 0 if denominator is 0
      - SMOD - pop two values from stack, signed modulo remainder
        - 0 if denominator is 0
        - All values are treated as two's complement signed 256-integers
      - ADDMOD - modulo addition
        - pop three values from stack, push sum of two modulo third
        - addition is not subject to modulo 2**256
        - 0 if denominator is 0
      - MULMOD - modulo multiplication
        - pop three values from stack, push product of two modulo third
        - multiplication is not subject to modulo 2**256
        - 0 if denominator is 0
      - EXP - pop two values from stack, push the exponentiation
      - SIGNEXTEND - extend length of signed integer
        - pops two values
        - set the lowest t bits in first to value of bit t
        - t = 256 - 8(second + 1)
      - Bitwise shifting // since  Constantinople
        - SHL - shift left, pop 2 values from the stack, push arg2 << arg1
        - SHR - logical shift right, pop 2 values from the stack, push arg2 >> arg1 with zero fill
        - SAR - arithmetic shift right, pop 2 values from the stack, push arg2 >> arg1 with sign extension
    - Comparison & bitwise logic
      - LT - pop two values from stack, push 1 if less, 0 otherwise
      - GT - pop two values from stack, push 1 if greater, 0 otherwise
      - SLT - signed less-than, same as LT but values are treated as signed
      - SGT - signed greater-than, same as GT but values are treated as signed
      - EQ - pop two values from stack, push 1 if equal, 0 otherwise
      - ISZERO - pop value from stack, push 1 if 0, 0 otherwise
      - AND - pop two values from stack, push bitwise AND
      - OR - pop two values from stack, push bitwise OR
      - XOR - pop two values from stack, push bitwise XOR
      - NOT - pop value from stack, push bitwise NOT
      - BYTE - retrieve single byte from word
        - pop two values from stack
        - push byte number second value form first
        - 0 if second value >= 32
        - Counting bytes from the left, i.e. N = 0 is most significant
    - SHA3 - compute Keccak-256 hash
      - pop two values from stack
      - push hash of array in memory starting at first value and second value in length
    - Environmental info
      - ADDRESS - push address of currently executing account
      - BALANCE - pop address from stack, push balance of account or 0 if doesn't exist
      - ORIGIN - push execution origination address (sender of original transaction, never a contract)
      - CALLER - push address of the account directly responsible for this execution
      - CALLVALUE - push deposited value by the transaction responsible for this execution
      - CALLDATALOAD - pop offset, push input data passed with transaction (max 32 bytes starting with offset)
      - CALLDATASIZE - push size of input data
      - CALLDATACOPY - copy input data to memory
        - pops 3 values
        - first - dest address
        - second - source offset in input data
        - third - count in bytes
        - fills dest with zeroes if out of input data bounds
      - CODESIZE - get size of code running in current environment
      - CODECOPY - copy code to memory
        - pops 3 values
        - first - dest memory address
        - second - source offset in code
        - third - count in bytes
        - fills dest with STOP opcode if out of bounds
      - GASPRICE - get gas price specified by the originating transaction
        - `effective_gas_price` // since London
      - EXTCODESIZE - pop address (lowest 160 bits are read), push size of account's code
      - EXTCODECOPY - copy an account's code to memory
        - pops 4 values
        - first - account address (lowest 160 bits are read)
        - second - dest memory address
        - third - offset in source code
        - fourth - count in bytes
        - fills dest with STOP opcode if out of bounds
      - RETURNDATASIZE  - push size of data returned from call // since Byzantium
      - RETURNDATACOPY  - copy return data to memory// since Byzantium
      - EXTCODEHASH -  pop address (lowest 160 bits are read), push keccak256 hash of account's code // since Constantinople
        - keccak256 hash of empty data in case account has no code
    - Block info
      - BLOCKHASH - get the hash of one of the 256 most recent complete blocks
        - pops block number
        - pushes block hash
        - pushes 0 if block number is greater than current or older than 256 blocks back
      - COINBASE - get the block's beneficiary address
      - TIMESTAMP - get the block's timestamp
      - NUMBER - get current block number
      - DIFFICULTY - get current block difficlulty
      - GASLIMIT - get current block gas limit
      - CHAINID - get network's chainID // since Istanbul
      - SELFBALANCE - get balance of current account (cheaper than BALANCE) // since Istanbul
      - BASEFEE - value of the base fee of the current block transaction is executing in // since London
    - Stack, memory, storage and flow
      - POP - pop item from stack
      - MLOAD - pop address, push 32 byte-word from memory
      - MSTORE - pops memory address and value from stack, writes 32 bytes into memory
      - MSTORE8 - pops memory address and value from stack, writes one byte into memory with value mod 256
      - SLOAD - pop storage address, push value from storage
      - SSTORE - pop storage address and value, writes value to storage
        - Gas cost is different for setting the value that was 0 and otherwise
        - Gas cost is different for setting the value for the first time inside transaction and subsequent modification // for Constantinople and since Istanbul
        - Throws out of gas error in case remaining gas is less then stipend (2300) // since Istanbul
        - Setting the value to 0 when it was non-zero gets a refund
      - JUMP - pop value from stack, set PC to it
      - JUMPI - conditional jump
        - pop two values
        - set PC to first value if second != 0
      - PC - push program counter value prior to the increment corresponding to this instruction
      - MSIZE - push size of active memory in bytes
      - GAS - push the value of available gas prior to reduction for this instruction
      - JUMPDEST - mark a valid destination for jumps
    - Push
      - PUSH1 - push 1 byte from the code address next to current PC
        - push 0 if out of bounds
        - byte is put to the least significant position in stack word
      - PUSH2..PUSH32 - similar to PUSH1 but put several bytes to least significant position of stack word
    - Duplication
      - DUP1 - push value equal to topmost stack value
      - DUP2..DUP16 - push value equal to Nth value in stack
    - Exchange
      - SWAP1 - exchange two topmost values in stack
      - SWAP2..SWAP16 - exchange topmost with Nth value in stack
    - Logging
      - LOG0 - append log record with no topics
        - pop two values
        - first is src address of the message in memory
        - second is size in bytes
      - LOG1..LOG4 - append log record witn N topics
        - pop 2 + N values
        - first two are address and size of message
        - next N are topic values
    - System
      - CREATE - create a new account
        - pops 3 values
        - first is value to transfer
        - second and third are address in memory and size of the initialization code
        - This account nonce is incremented
        - pushes 0 if execution failed with exception, if balance is not enough to transfer value, or if current depth of contract creation / message calls reached 1024
        - pushes address of new account otherwise
      - CREATE2 - create a new account // since Constantinople
        - pops 4 values
        - first is value to transfer
        - second and third are address in memory and size of the initialization code
        - fourth is salt
        - Works similar to CREATE but address of new contract is rightmost 160 bits of Keccac hash of (0xff ++ msg.sender ++ salt ++ keccak(init_code))
      - CALL - message call into an account
        - pops 7 values
        - first - gas we provide to this execution
        - second - receiver account address
        - third - transfer value
        - fourth and fifth - memory address and size of input data
        - sixth and seventh -  memory address and size of output data
        - pushes 0 if execution failed with exception, if balance is not enough to transfer value, or if current depth of contract creation / message calls reached 1024
        - pushes 1 if success
      - CALLCODE - message-call into this account with alternative account's code
        - call code of another account but with this same account as recipient
        - parameters the same as for CALL
        - DELEGATECALL was added in Homestead to fix not preserving sender and value
          - CALLCODE sets sender to called account
          - DELEGATECALL sets sender to this account
          - http://ethereum.stackexchange.com/questions/3667/difference-between-call-callcode-and-delegatecall
      - RETURN - halt execution and return output data
        - pops 2 values - memory address and size of output data
      - DELEGATECALL - message-call into this account with alternative account's code, but persisting the current values for sender and value // since Homestead
        - pops 6 values
        - parameters the same as for CALL but transfer value is skipped
        - recipient is the same account as this, just the code is overwritten and context is almost identical (apart from gas and depth)
      - SUICIDE - halt the execution and register account for later deletion
        - pops account address to send remaining funds to
        - Refund is given to account if it's not yet in suicide list // till Berlin
      - REVERT - stop execution and return error without consuming all remaining gas // Since Byzantium
      - STATICCALL - call with a guarantee that the state is not modified, read-only call // since Byzantium





## Finalization
- Finalization
  - Refuned gas = gasLeft + min(substate refundBalance, floor(gasUsed / MAX_REFUND_QUOTIENT))
    - MAX_REFUND_QUOTIENT = 2 // till Berlin
    - MAX_REFUND_QUOTIENT = 5 // since London
  - Beneficiary (miner) reward
    - usedGas * transaction.gasPrice // till Berlin
    - usedGas * priority_fee_per_gas #priority_fee // since London
      - miner only receives the priority fee
      - note that the base fee is not given to anyone (it is burned) 
  - Delete all accounts that either appear in the suicide list or are touched and empty


## Relevant Links
- [Ethereum Yellow Paper Course](https://youtu.be/e84V1MxRlYs)