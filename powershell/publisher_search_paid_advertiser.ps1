cd $pwd
1..10 | % { write "" }

#2531921
#$block = Read-Host "enter starting block to search from"
$block = 2531921

$start_block = [Convert]::ToInt32($block)

while($true)
{  
    $blockhash = (.\litecoin-cli.exe -datadir=dataV212 getblockhash $start_block)

    echo $start_block "blockhash" $blockhash
    if($blockhash.length -eq 0)
    {
        write-host "tip reached"
        exit
    }

    $tx_list = (.\litecoin-cli.exe -datadir=dataV212 getblock $blockhash)
    

    $tx_json=($tx_list | ConvertFrom-Json)

    for ($tx_id=0;  $tx_id -lt $tx_json.tx.length; $tx_id++) {
        $raw_tx=(.\litecoin-cli.exe -datadir=dataV212 getrawtransaction $tx_json.tx[$tx_id])
        $progress = $tx_id / ($tx_json.tx.length/100)
        Write-Progress  $tx_json.tx[$tx_id] $progress
    

        
        $tx=(.\litecoin-cli.exe -datadir=dataV212 decoderawtransaction $raw_tx)
        $tx_op_json=($tx | ConvertFrom-Json)
        $op_data = $tx_op_json.vout[1].scriptPubKey.asm
        if ($op_data -like "OP_RETURN*") 
        { 
            $op_data = $op_data.Replace('OP_RETURN ', '')

            $op_text = -join ($op_data -split '(..)' | ? { $_ } | % { [char][convert]::ToUInt32($_,16) })
            if ($op_text -like "place_link:*") 
            {
                write-host "txid" $tx_json.tx[$tx_id] "advertiser data found" $op_data
                write-host $op_text
                write-host "publisher address received " $tx_op_json.vout[0].scriptPubKey.addresses[0] $tx_op_json.vout[0].value
            }
        }
    }

    $start_block++

}

