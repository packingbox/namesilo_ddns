#!/bin/bash

# change the domain name and api key with yours.
# get api key from https://www.namesilo.com/account_api.php

domain_name="yours.com"
sub_domain="test"
api_key="454544323434434"

# define domain_name and temp xml file
domain_xml="/tmp/namesilo_response.xml"
domain_txt="/tmp/namesilo_response.txt"

## define variables 
host_type=""
host_name=""
host_ip=""
host_rrid=""

# get dnsListRecords
# https://www.namesilo.com/api_reference.php#dnsListRecords
dns_list_url="https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$api_key&domain=$domain_name"
#echo $dnslist_url

# get xml from namesilo
curl -s "$dns_list_url" > $domain_xml
#cat $domain_name.xml

# split xml file into bash readable txt format
read_dom ()
{
    local IFS=\>
    read -d \< ENTITY CONTENT
}

while read_dom; do

    if [[ $ENTITY = "record_id" ]]; then
        host_rrid="$CONTENT"
    
    elif [[ $ENTITY = "type" ]]; then
        host_type=$CONTENT
    
    elif [[ $ENTITY = "host" ]]; then
        host_name=$CONTENT
        
    elif [[ $host_type = "A" ]] && [[ $host_name = "$sub_domain.$domain_name" ]] && [[ $ENTITY = "value" ]]; then
        host_ip="$CONTENT"
        echo "$host_ip" 
    fi
done < $domain_xml

# check ip status

# get current ip address
check_ip=http://api.ipify.org
current_ip=$(curl -s $check_ip)
#echo "$current_ip $host_ip"

# get history ip address
history_ip=$host_ip

# update records
# https://www.namesilo.com/api_reference.php#dnsUpdateRecord
dns_update_url="https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$api_key&domain=$domain_name&rrid=$host_rrid&rrhost=$sub_domain&rrvalue=$current_ip&rrttl=3600"
#echo $dns_update_url

if [[ $current_ip = $history_ip ]]; then
    echo "same ip record, no need to update"
elif [[ $(curl -s "$dns_update_url" | grep -c "<code>300</code>") > 0 ]]; then
    echo $(curl -s "$dns_update_url")
    echo "ip changed and update to $current_ip"
fi
exit 0
