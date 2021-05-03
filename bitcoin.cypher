CALL apoc.load.json(
    // REPLACE WITH FILE PATH OR URL
)
YIELD value AS json

// CREATE BLOCK
MERGE (curblock:block {hash: json.hash}) 
SET 
    curblock.size = json.size, 
    curblock.prevblock = json.prev_block, 
    curblock.merkleroot = json.mrkl_root, 
    curblock.time = json.time, 
    curblock.bits = json.bits, 
    curblock.nonce = json.nonce, 
    curblock.txcount = json.n_tx, 
    curblock.version = json.ver 
MERGE (prevblock:block {hash: json.prev_block}) 
MERGE (curblock)-[:chain]->(prevblock)

// CREATE TX
FOREACH (
    t IN json.tx |
    MERGE (tx:tx {txid: t.hash})
    MERGE (tx)-[:inc {i: t.tx_index}]->(curblock)
    SET
        tx.version = t.ver,
        tx.locktime = t.lock_time,
        tx.size = t.size,
        tx.weight = t.weight,
        tx.fee = t.fee

    // CREATE OUTINPUT (TYPE INPUT)
    FOREACH (input IN t.inputs |
        MERGE (inpt:output {seq: input.sequence})
        SET inpt.index = CASE input.prev_out
        WHEN NULL THEN
            toString(t.tx_index) + toString(input.index)
        ELSE
            toString(input.prev_out.tx_index) + toString(input.prev_out.n)
        END
        SET inpt.value = CASE input.prev_out
        WHEN NULL THEN
            NULL
        ELSE
            input.prev_out.value
        END
        MERGE (inpt)-[:in {vin: input.index, script: input.script, witness: input.witness}]->(tx) 
        
        // CREATE ADDRESS IF EXISTS
        FOREACH (_ IN CASE WHEN input.prev_out <> '' THEN [1] ELSE [] END |
            MERGE (add:address {address: input.prev_out.addr})
            MERGE (add)-[:located]->(inpt)
        )
    )

    // CREATE OUTPUT (TYPE OUTPUT)
    FOREACH (output IN t.out |
        MERGE (outpt:output {index: toString(output.tx_index) + toString(output.n)})
        MERGE (tx)-[:out {vout: output.n}]->(outpt)
        SET
            outpt.value = output.value,
            outpt.script = output.script
        
        // CREATE ADDRESS IF EXISTS
        FOREACH (_ IN CASE WHEN output.addr <> '' THEN [1] ELSE [] END |
            MERGE (add:address {address: output.addr}) 
            MERGE (outpt)-[:locked]->(add)
        )
    )
)