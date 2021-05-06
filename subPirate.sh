#!/bin/bash

RED='\033[1;31m'

if [ $# = 0 ]; then
	printf "\n"
	printf "${RED} You must have these following tools setup and ready in Kali linux in order for this script to fully work!
	1- Sublist3r2 (An improved version of original sublist3r which allows virustotal subdomain finding): https://github.com/RoninNakomoto/Sublist3r2.git (Put script folder in /opt)
	2- Assetfinder (Go subdomain discovery tool): https://github.com/tomnomnom/assetfinder.git (Install GO to make an alias of the package via 'go get')
	3- Subfinder (Another tool for domain discovery, can be installed with apt-get)
	4- github-subdomains (A script by Gwendel to find domains by github-dorking): https://github.com/gwen001/github-search (/opt)
	5- Subjack (Checks for possible subdomain takeover, can be installed with apt-get)
	6- Httprobe (GO tool for probing found domains to check if they are alive): https://github.com/tomnomnom/httprobe
	7- Gowitness (GO tool for taking screenshots of all alive domains identified): https://github.com/sensepost/gowitness
	8- Nmap (Network scanning tool comes pre-installed with kali)
	9- SubDomainizer (Checks for potential sensitive information in JS files): https://github.com/nsonaniya2010/SubDomainizer (/opt)
	10- Github-secrets.py (A script by Gwendel to check for secrets in github repos): https://github.com/gwen001/github-search (/opt)"
	printf "\n"
	printf "\n ${RED} Tool Usage: ./subPirate.sh <domain> \n"
	exit;

elif [ $# -gt 1 ]; then
	printf "\n ${RED}ERROR: Only one argument needed!"
	printf "\n"
	printf "${RED}Usage: ./subPirate.sh <domain>"
	exit;

elif [ $# == 1 ]; then
	printf "\n"
	printf "${RED} --------------------------------------------------------------------------- \n"
	printf "\n"
	printf "${RED}[X] Creating the 'Domains' and 'Tests' directory..... ('Tests' is where you can ensure every tool has worked successfully by browsing its files, Domains directory is where the loot is. [X]"
	mkdir Domains && mkdir Tests
	printf "\n"
	printf "${RED}[+] Extracting domains using Sublist3r2...... \n
	NOTE: Make sure you've provided the correct Virustotal API key within the subPirate script!"
	printf "\n ${RED} -------------------------------------------------------------------------"
	
	if [ -e /opt/Sublist3r2/sublist3r2.py ]; then
		printf "VIRUSTOTAL TOKEN" | python3 /opt/Sublist3r2/sublist3r2.py -d $1 -o Tests/sublist3r.txt; else
		printf "\n \n ${RED} ERROR: sublist3r2.py not located, consider editing its destination within the script if you set it up, otherwise put the sublist3r2 project folder in /opt"
		exit
		fi
		
		
	printf "\n"
	printf "${RED}[+] Scanning with sublist3r has finished!"
	printf " ${RED}\n -----------------------------------------\n"
	printf "\n"
	printf "${RED}[+] Now extracting subdomains with assetfinder tool........"
	printf "\n"
	assetfinder --subs-only $1 >> Tests/assetfinder.txt
	
	printf "\n ${RED}Assetfinder scanning finished! Now onto subfinder...\n"
	printf "\n ${RED}[+] Starting.... \n \n"
	subfinder -d $1 -silent >> Tests/subfinder.txt
	printf "\n ${RED}[+] Scanning with subfinder has finished! \n"
	printf "\n ${RED}[+] Finding even MORE subdomains using github dorking (MAKE SURE YOUR GITHUB'S TOKEN IS PUT WITHIN THE SCRIPT)...... [+] \n ..............."
	python3 /opt/github-search/github-subdomains.py -t "GITHUB TOKEN" -d $1 >> Tests/github.txt
	printf "............... \n Finished! \n"
	printf "\n ${RED}[XXX] Grouping all found domains into one all.txt file.... [XXX] \n"
	cat Tests/sublist3r.txt >> Tests/all.txt
	cat Tests/assetfinder.txt >> Tests/all.txt
	cat Tests/subfinder.txt >> Tests/all.txt
	cat Tests/github.txt >> Tests/all.txt
	printf "\n ${RED}[XXX] Removing duplicates and merging results to a finalized all.txt inside 'Domains'...... [XXX] \n"
	cat -n Tests/all.txt | sort -k2 -k1n  | uniq -f1 | sort -nk1,1 | cut -f2- >> Domains/all.txt
	printf "\n ${RED}[X] all.txt has been created! [X] \n"
	printf "\n ${RED}[x_x] Now checking for possible domain takeovers...\n"
	subjack -w Domains/all.txt -t 100 -timeout 30 -ssl -c /usr/share/subjack/fingerprints.json -v 3 -o Domains/takeover.txt
	printf "\n ${RED}[x_x] Domain takeover check finished! now probing for all alive domains that give a response... \n"
	cat Domains/all.txt | httprobe -s -p https:443 | sed 's/.443//' >> Domains/alive.txt
	printf "\n ${RED}[+] Done probing! Now onto taking screenshots of alive subdomains.... \n"
	timeout 5m gowitness file -f Domains/alive.txt -F
	mv screenshots Domains
	# printf "\n ${RED}[+] Done! Now scanning for open ports against the alive domains using nmap... \n"
	# mkdir Domains/Nmap
	# cat Domains/alive.txt | cut -c9- >> Domains/Tests/edited4Nmap.txt
	# nmap -iL Domains/Tests/edited4Nmap.txt -T4 -p- -oA Domains/Nmap/scan.txt
	# (I advise using masscan instead of nmap if your target scope is large as nmap might take too long, otherwise remove the comments and let it run or edit it)
	printf "\n ${RED}[+] Done! Now onto looking for sensitive information using SubDomainizer.... \n"
	python3 /opt/SubDomainizer/SubDomainizer.py -l Domains/alive.txt | tee -a Domains/subdomainizer.txt
	printf "\n ${RED}[+] Done! Now onto looking for sensitive information within Github repos (THIS ONE WON'T BE SAVED, VIEW RESULTS FROM TERMINAL).... \n"
	python3 /opt/github-search/github-secrets.py -t "GITHUB TOKEN" -s $1
	printf "\n ${RED}[X] All done! navigate inside Domains for potential loot! [X] \n"
	printf "\n ${RED}[XXXXX] Exiting...[XXXXX] \n"
	exit
fi
