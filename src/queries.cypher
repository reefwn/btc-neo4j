// block information
MATCH (block :block)<-[:inc]-(tx :tx)
WHERE block.hash='' // REPLACE WITH block_hash
RETURN block, tx LIMIT 100


// tx information
MATCH (inputs)-[:in]->(tx:tx)-[:out]->(outputs)
WHERE tx.txid='' // REPLACE WITH tx_id
OPTIONAL MATCH (inputsaddresses)-[:located]->(inputs)
OPTIONAL MATCH (outputs)-[:locked]->(outputsaddresses)
OPTIONAL MATCH (tx)-[:inc]->(block)
RETURN inputs, tx, outputs, block, inputsaddresses, outputsaddresses


// address information
MATCH (address:address)<-[:locked]-(output:output)
WHERE address.address='' // REPLACE WITH address
RETURN address, output