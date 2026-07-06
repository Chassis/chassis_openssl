# A Chassis extension to install and configure OpenSSL
class chassis_openssl (
	$config,
) {
	if ( ! defined( File["/etc/nginx/sites-available/${facts['networking']['fqdn']}.d"] ) ) {
		file { "/etc/nginx/sites-available/${facts['networking']['fqdn']}.d":
			ensure  => directory,
			require => Package['nginx']
		}
	}

	file { "/etc/nginx/sites-available/${facts['networking']['fqdn']}.d/ssl":
		content => template('chassis_openssl/site.nginx.conf.ssl.erb'),
		require => [
			File[ "/etc/nginx/sites-available/${facts['networking']['fqdn']}.d" ],
			Openssl::Certificate::X509[ $config['hosts'][0] ],
		],
		notify  => Service['nginx'],
	}

	# Generate a certificate for every host, each with all hosts (and their
	# wildcard variants) as subject alternative names.
	$config['hosts'].each | String $host | {
		openssl::certificate::x509 { $host:
			country      => 'CH',
			organization => 'Example.com',
			commonname   => $host,
			altnames     => $config['hosts'],
			extkeyusage  => [ 'serverAuth', 'clientAuth' ],
			cnf_tpl      => 'chassis_openssl/cert.cnf.erb',
			days         => 3650,
			owner        => 'www-data',
			group        => 'www-data',
		}
		-> file { "/vagrant/${host}.cert":
			ensure  => present,
			replace => $config['chassis_openssl']['cert']['replace'],
			source  => "/etc/ssl/certs/${host}.crt",
			mode    => '0644',
		}
		-> file { "/vagrant/${host}.key":
			ensure  => present,
			replace => $config['chassis_openssl']['key']['replace'],
			source  => "/etc/ssl/certs/${host}.key",
			mode    => '0644',
		}
	}
}
