include wget

# Installs RStudio (user shiny, password shiny) and Shiny
# Change these if the version changes
# See http://www.rstudio.com/ide/download/server
# This is the standard installation (update it when a new release comes out)
# https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.5042-amd64.deb
# $rstudioserver = 'rstudio-server-0.98.1091-amd64.deb'
# $urlrstudio = 'https://s3.amazonaws.com/rstudio-dailybuilds/'
$rstudioserver = 'rstudio-server-1.2.5042-amd64.deb'              # updated
$urlrstudio = 'https://download2.rstudio.org/server/trusty/amd64/'

# See http://www.rstudio.com/shiny/server/install-opensource
# https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.16.958-amd64.deb
# $shinyserver = 'shiny-server-1.2.3.368-amd64.deb'
# $urlshiny = 'http://download3.rstudio.org/ubuntu-12.04/x86_64/'
$shinyserver = 'shiny-server-1.5.16.958-amd64.deb'
$urlshiny = 'http://download3.rstudio.org/ubuntu-14.04/x86_64/'


#http://projects.puppetlabs.com/projects/puppet/wiki/Simple_Text_Patterns/7
define line($file, $line, $ensure = 'present') {
    case $ensure {
        default : { err ( "unknown ensure value ${ensure}" ) }
        present: {
            exec { "/bin/echo '${line}' >> '${file}'":
                unless => "/bin/grep -qFx '${line}' '${file}'"
            }
        }
        absent: {
            exec { "/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${file}'":
                onlyif => "/bin/grep -qFx '${line}' '${file}'"
            }
        }
    }
}

# Update system for r install
class update_system {   
    exec {'apt_update':
        provider => shell,
        command  => 'apt-get update;',
    }
    ->
    exec {'openjdk8-repository':
      provider => shell,
      command  =>
      'add-apt-repository ppa:openjdk-r/ppa -y;
      apt-get update;',
    }
    ->
    package {['software-properties-common','libapparmor1',
              #'freetds-dev', 'freetds-bin','sqsh','tdsodbc','r-cran-rodbc', 
              'libdbd-mysql', 'libmysqlclient-dev','libssl-dev',
              'python-software-properties', 
              'upstart', 'psmisc',
              #'dbus-x11', # required for init-checkconf
              'libxml2-dev',
              'libprotobuf-dev',
              #'libssh2-1-dev', 'libgit2-dev',
              'python', 'g++', 'make','vim', 'whois','mc','libcairo2-dev',
              'openjdk-8-jdk', 'openjdk-11-jdk', 'gdebi-core', 'libcurl4-gnutls-dev']:
      ensure  => present,
    }
    ->
    exec {'alternative-openjdk8':
      provider => shell,
      command  =>
      'update-java-alternatives --set  /usr/lib/jvm/java-1.8.0-openjdk-amd64;',
    }
    ->
    exec {'update-gitlib2':
      provider => shell,
      command  =>
      'add-apt-repository ppa:cran/libgit2 -y;
      apt-get update;',
    }    
    ->
    package {['libssh2-1-dev', 'libgit2-dev']:
      ensure => present,
    }
    ->
    exec {'add-cran-repository':
      provider => shell,
      command  =>
      'add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/";
      add-apt-repository ppa:cran/libgit2 -y;
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9;
      apt-get update;',
    }
    ->
    exec {'upgrade-system':
      provider => shell,
	    timeout => 2000, # On slow machines, this needs some time
      command  =>'apt-get -y upgrade;apt-get -y autoremove;',
    }
    ->
    # Install host additions (following https://www.virtualbox.org/manual/ch04.html
    # this must be done after upgrading.
    package {'dkms':
        ensure => present,
    }    
}

class install_opencpu {
    exec {'add-opencpu-repository':
      provider => shell,
      command  =>
        'add-apt-repository ppa:opencpu/opencpu-1.6 -y;
         apt-get update;
         apt-get upgrade -y;',
     }
    ->
    package { 'opencpu' :
      ensure => installed,
    }
}


# Install r base and packages
class install_r {
    package {['r-base', 'r-base-dev']:
      ensure  => present,
      require => Package['dkms'],
    }    
    ->
    exec {'install-r-packages':
        provider => shell,
        timeout  => 3000,
        command  => 'Rscript /vagrant/usefulpackages.R'
    }
}

# Download and install shiny server and add users
class install_shiny_server {
    # Download shiny server
    wget::fetch {'shiny-server-download':
        require  => [Exec['install-r-packages'],
                    Package['software-properties-common',
                    'python-software-properties', 'g++']],
        destination => "${shinyserver}",
        timeout  => 300,
        source   => "${urlshiny}${shinyserver}",
    }
    ->    
    # Create rstudio_users group
    group {'rstudio_users':
        ensure => present,
    }
    ->
    # http://www.pindi.us/blog/getting-started-puppet
    user {'shiny':
        ensure  => present,
        groups   => ['rstudio_users', 'vagrant'], # adding to vagrant required for startup
        shell   => '/bin/bash',
        managehome => true,
        name    => 'shiny',
        home    => '/srv/shiny-server',
    }   
    ->
    # Install shiny server
    exec {'shiny-server-install':
        provider => shell,
        command  => "gdebi -n ${shinyserver}",
    }
    # Copy example shiny files
    file {'/srv/shiny-server/01_hello':
        source  => '/usr/local/lib/R/site-library/shiny/examples/01_hello',
        owner   => 'shiny',
        ensure  => 'directory',
        recurse => true,
    }   
    ->
   # Setting password during user creation does not work    
   # Password shiny is public; this is for local use only
   exec {'shinypassword':
        provider => shell,
        command => 'usermod -p `mkpasswd -H md5 shiny` shiny',
     }
    ->
    # Remove standard app
    file {'/srv/shiny-server/index.html':
        ensure => absent,
    } 
}

# install rstudio and start service
class install_rstudio_server {
    # Download rstudio server
    wget::fetch {'rstudio-server-download':
        require  => Package['r-base'],
        timeout  => 0,
        destination => "${rstudioserver}",
        source  => "${urlrstudio}${rstudioserver}",
    }
    ->
    exec {'rstudio-server-install':
        provider => shell,
        command  => "gdebi -n ${rstudioserver}",
    }
}

# Make sure that both services are running
class check_services{
    service {'shiny-server':
        ensure    => running,
        require   => [User['shiny'], Exec['shiny-server-install']],
        hasstatus => true,
    }
    service {'rstudio-server':
        ensure    => running,
        require   => [User['shiny'], Exec['rstudio-server-install']],
        hasstatus => true,
    }
}

class startupscript{
    file { '/etc/init/makeshinylinks.conf':
       require   => [Service['shiny-server'], Exec['shinypassword']],
       ensure => 'link',
       target => '/vagrant/makeshinylinks.conf',
    }
 ->
    exec{ 'reboot-makeshiny-links':
    #    require   => File['/vagrant/makeshinylinks.sh'],
       provider  => shell,
       command   => 
       'chmod +x /vagrant/makeshinylinks.sh;
       /vagrant/makeshinylinks.sh',
    }
}

class webmin {
    $base = "webmin_1.970_all.deb"
    $url = "http://prdownloads.sourceforge.net/webadmin/"
    $archive = "/root/$base"
    $installed = "/etc/webmin/version"

    $dependencies = [
        "libapt-pkg-perl",
        "libnet-ssleay-perl",
        "libauthen-pam-perl",
        "libio-pty-perl",
        "apt-show-versions",
    ]

    package{$dependencies: ensure => installed}->
    exec { "DownloadWebmin":
        cwd     => "/root",
        command => "/usr/bin/wget $url$base",
        creates => $archive,
    }

    exec { "InstallWebmin":
        cwd     => "/root",
        command => "/usr/bin/dpkg -i $archive",
        creates => $installed,
        require => Exec["DownloadWebmin"],
        notify  => Service[webmin],
    }

    service { webmin:
        ensure   => running,
        require  => Exec["InstallWebmin"],
        provider => init;
    }
}

include webmin
include update_system
include install_r
include install_opencpu
include install_shiny_server
include install_rstudio_server
include check_services
include startupscript

