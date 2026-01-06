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
		require => File[ "/etc/nginx/sites-available/${facts['networking']['fqdn']}.d" ],
		notify  => Service['nginx'],
	}

	openssl::certificate::x509 { $facts['networking']['fqdn']:
		country      => 'CH',
		organization => 'Example.com',
		commonname   => $facts['networking']['fqdn'],
		altnames     => $::config[hosts],
		extkeyusage  => [ 'serverAuth', 'clientAuth' ],
		cnf_tpl      => 'chassis_openssl/cert.cnf.erb',
		days         => 3650,
		owner        => 'www-data',
		group        => 'www-data',
	}
	-> file { "/vagrant/${facts['networking']['fqdn']}.cert":
		ensure  => present,
		replace => $config['chassis_openssl']['cert']['replace'],
		source  => "/etc/ssl/certs/${facts['networking']['fqdn']}.crt",
		mode    => '0644',
	}
	-> file { "/vagrant/${facts['networking']['fqdn']}.key":
		ensure  => present,
		replace => $config['chassis_openssl']['key']['replace'],
		source  => "/etc/ssl/certs/${facts['networking']['fqdn']}.key",
		mode    => '0644',
	}
}
