#!/usr/bin/php
<?php

function usage() {
    global $argv;
    echo "Usage: " . $argv[0] . " [-d <domain name>] [-b <keybits>] [-i <digest>] [-s <days>] [-cnh]
       " . $argv[0] . " --domain=<\"domain name\"> [--bits=<keybits>] [--digest=<digest>] [--self-sign=<days>] [--custom] [--no-write] [--help]

\t   -d --domain | Specify the domain to be secured
\t     -b --bits | Specify the length of the privkey in bits
\t   -c --custom | Use a custom CSR
\t -n --no-write | Don't write key and CSR - just print them to stdout
\t   -i --digest | Specify digest for CSR. Default SHA256
\t-s --self-sign | Generate a self-signed certificate
\t     -h --help | Print this help message\n";
    exit(0);
}

class newCert {
    function __construct() {
	$this->digestAvailable = openssl_get_md_methods(TRUE);
	$this->digestAvailableShort = openssl_get_md_methods(FALSE);
        $this->digestString = implode("\n\t",$this->digestAvailableShort);
    }
    private $keyConfig = array(
	"private_key_type" => OPENSSL_KEYTYPE_RSA,
	"digest_alg" => "sha256",
    );
    private $certDays = 0;

    public $dn = array(
        "countryName" => "US",
        "stateOrProvinceName" => "Virginia",
        "localityName" => "Ashburn",
        "organizationName" => "BlackMesh",
        "organizationalUnitName" => "Network Operations",
        "emailAddress" => "noc@blackmesh.com"
    );
    public function setDigest($digest = 'sha256') {
	while ((!in_array($digest,$this->digestAvailable)) || ($digest == '')) {
	    echo "\033[31mProvided digest algorithm '${digest}' not recognized. Pick one of \033[33m\n\t" . $this->digestString . "\033[0m\nDigest algorithm: ";
	    $digest = trim(fgets(STDIN));
	}
	$this->keyConfig['digest_alg'] = $digest;
	echo "Set digest algorithm to \033[36m${digest}\033[0m\n";
    }
    public function setDays($days = 365) {
	while ((!is_int($days)) || ($days <= 0)) {
	    echo "\033[31mProvided days $days is not a whole number. I need an integer larger than zero.\033[0m\nDays to sign: ";
	    $days = intval(trim(fgets(STDIN)));
	}
	echo "Signing cert for \033[36m${days}\033[0m days.\n";
	$this->certDays = $days;
    }
    public function pukeConfig() {
	print_r($this->keyConfig);
    }
    public function setBits($bits = 2048) {
	while (!in_array($bits,array(1024,2048,4096))) {
	    echo "Pick the length of your key. Must be one of:\n1024\n2048\n4096\n\nKey Length: ";
	    $bits = trim(fgets(STDIN));
	}
	$this->keyConfig['private_key_bits'] = intval($bits);
	echo "Set private key length to \033[36m$bits\033[0m bits\n";
    }

    public function setDomain($domain = NULL) {
	while (!$domain) {
	    echo "You didn't give me a domain name.\n\nDomain name: ";
	    $domain = trim(fgets(STDIN));
	}
	$this->dn['commonName'] = $domain;
	echo "Set domain to \033[36m$domain\033[0m\n";
    }

    public function setDn() {
        foreach (array_keys($this->dn) as $dnProperty) {
	    if ($dnProperty != 'commonName') {
		echo "${dnProperty}: ";
		$this->dn[$dnProperty] = trim(fgets(STDIN));
	    }
	}
    }

    public function genKey() {
	$this->newKey = openssl_pkey_new($this->keyConfig);
	openssl_pkey_export($this->newKey, $this->newKeyText);
    }

    public function genCsr() {
	$this->newCsr = openssl_csr_new($this->dn, $this->newKey, $this->keyConfig);
	openssl_csr_export($this->newCsr, $this->newCsrText);
    }
    public function saveKey($file) {
	openssl_pkey_export_to_file($this->newKey,$file);
    }
    public function saveCsr($file) {
	openssl_csr_export_to_file($this->newCsr,$file);
    }
    public function signKey() {
	$this->certificate = openssl_csr_sign($this->newCsr, NULL, $this->newKey,$this->certDays,$this->keyConfig);
	openssl_x509_export($this->certificate, $this->newCertificateText);
    }
    public function saveCertificate($file) {
	openssl_x509_export_to_file($this->certificate,$file);
    }
}
$shortOptions = "d:b:i:s:cnh";
$longOptions = array(
    "domain:",
    "bits:",
    "custom",
    "no-write",
    "self-sign:",
    "digest:",
    "help"
);
$options = getopt($shortOptions, $longOptions);

if ((isset($options['h'])) || (isset($options['help']))) {
    usage();
}

if ((isset($options['i'])) || (isset($options['digest']))) {
    $digest = $options['i'] or $digest = $options['digest'];
} else {
    $digest = 'sha256';
}

$cert = new newCert();
$cert->setDigest($digest);
$domain = $options['d'] or $domain = $options['domain'];
$cert->setDomain($domain);

if ((isset($options['s'])) || (isset($options['self-sign']))) {
    $certDays = $options['s'] or $certDays = $options['self-signed'];
    $certDays = intval($certDays);
    $cert->setDays($certDays);
}

if ((isset($options['b'])) || (isset($options['bits']))) {
    $keyBits = $options['b'] or $keyBits = $options['bits'];
} else {
    $keyBits = 2048;
}
$cert->setBits($keyBits);


if ((isset($options['c'])) || (isset($options['custom']))) {
    $cert->setDn();
}
echo "Setting CSR to:\n";
foreach($cert->dn as $dnField => $dnValue) {
    echo "    ${dnField}: \033[36m${dnValue}\033[0m\n";
}

$cert->genKey();
$cert->genCsr();
echo $cert->newKeyText;
echo $cert->newCsrText;
if (isset($certDays)) {
    $cert->signKey($certDays);
    echo $cert->newCertificateText;
}

$baseFileName = preg_replace('/\*/','wildcard',$cert->dn['commonName']) . '_' . date('Y-m-d');

if ((isset($options['n'])) || (isset($options['no-write']))) {
    echo "\nNot writing anything per user request.\n\033[33mYou must manually save the private key and document its\nlocation in a ticket comment\033[0m\n";
} else {
    $keyFile = $baseFileName . '.key';
    $csrFile = $baseFileName . '.csr';
    $crtFile = $baseFileName . '.crt';
    if(file_exists($keyFile)) {
	echo "\033[31m". realpath($keyFile) . " already exists. Not overwriting\033[0m\n";
        echo "\033[33mYou must manually save the private key and document its\nlocation in a ticket comment\033[0m\n";
    } else {
	$cert->saveKey($keyFile);
	echo "Private key saved to \033[32m" . realpath($keyFile) . "\033[0m\n";
    }
    if(file_exists($csrFile)) {
	echo "\033[31m" . realpath($csrFile) . " already exists. Not overwriting\033[0m\n";
        echo "\033[33mYou don't need to save the CSR, but you should probably\nput it in a ticket comment\033[0m\n";
    } else {
	$cert->saveCsr($csrFile);
	echo "Signing request saved to \033[32m" . realpath($csrFile) . "\033[0m\n";
    }
    if (isset($certDays)) {
	if(file_exists($crtFile)) {
	    echo "\033[31m" . realpath($crtFile) . " already exists. Not overwriting\033[0m\n";
            echo "\033[33mYou must manually save the certificate and document its\nlocation in a ticket comment\033[0m\n";
	} else {
	    $cert->saveCertificate($crtFile);
	    echo "Certificate saved to \033[32m" . realpath($crtFile) . "\033[0m\n";
	}
    }
}

?>