class nexus (
  $source  = 'http://buildsources.delivery.puppetlabs.net/tools/',
  $dest    = '/var/www',
  $version = '2.12.1-01',
  $port    = '8081',
  $ssl     = false,
) {
  $source_url = "${source}/nexus-${version}-bundle.tar.gz"

  include apache
  include java

  apache::port { 'nexus-proxy': port => '80' }

  apache::vhost::proxy { 'nexus-proxy':
    serveraliases => 'nexus-proxy',
    port          => 80,
    dest          => 'http://localhost:8081',
  }

  if $ssl {
    apache::port { 'nexus-https': port => '443' }

    apache::vhost::proxy { 'nexus-https-proxy':
      serveraliases  => 'nexus-https-proxy',
      port           => 443,
      ssl            => true,
      dest           => 'http://localhost:8081',
      request_header => 'set X-Forwarded-Proto "https"'
    }
  }

  file { $dest:
    ensure  => 'directory'
  }

  exec { 'nexus-download':
    command => "curl -v -L --progress-bar -o '/tmp/nexus-${version}-bundle.tar.gz' '${source_url}'",
    cwd     => '/tmp',
    path    => [ '/bin', '/usr/bin' ],
    creates => "/tmp/nexus-${version}-bundle.tar.gz",
    unless  => "test -d ${dest}/nexus-${version}"
  }

  exec { 'nexus-extract':
    command   => "tar -C ${dest} -zxvf /tmp/nexus-${version}-bundle.tar.gz",
    cwd       => '/tmp',
    path      => [ '/bin', '/usr/bin' ],
    creates   => "${dest}/nexus-${version}",
    subscribe => Exec[ 'nexus-download' ],
    require   => Exec[ 'nexus-download' ]
  }

  file { '/etc/init.d/nexus':
    ensure => 'link',
    target => "${dest}/nexus-${version}/bin/nexus"
  }

  service { 'nexus':
    ensure => 'running',
    enable => 'true'
  }
}
