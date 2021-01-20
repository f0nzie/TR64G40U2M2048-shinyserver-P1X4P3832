## SOURCE

*   https://github.com/dkilfoyle/vagrant-rstudio

![image-20210118101405520](assets/BUILD/image-20210118101405520.png)



-----

## RUNNING

*   Webmin at https://127.0.0.1:10000/

![image-20210118115719910](assets/BUILD/image-20210118115719910.png)







-----

## TESTING

### Activating and deactivating puppet services



![image-20210118120025123](assets/BUILD/image-20210118120025123.png)



## PROBLEMS

### Fixed lack of file makeshinylinks.sh

Sync project folder with VM folder `/vagrant`:

```
config.vm.synced_folder ".", "/vagrant", disabled: false
```



![image-20210119183121590](assets/BUILD/image-20210119183121590.png)



Add folder R under `shiny-server`  folder

![image-20210119183246561](assets/BUILD/image-20210119183246561.png)

Put here any Shiny projects that want to share. It will need to reboot Shiny server.



### Problem starting shiny-server

But the server starts the same.

![image-20210119161218645](assets/BUILD/image-20210119161218645.png)

This is `makeshinylinks.sh` script:

![image-20210119161302287](assets/BUILD/image-20210119161302287.png)

### opencpu update repo failing

![image-20210119154700981](assets/BUILD/image-20210119154700981.png)

### RStudio too old

Update to a newer version of rstudio-server for `trusty64`

![image-20210119152549717](assets/BUILD/image-20210119152549717.png)



![image-20210118211428952](assets/BUILD/image-20210118211428952.png)

![image-20210118211352165](assets/BUILD/image-20210118211352165.png)

![image-20210118211325715](assets/BUILD/image-20210118211325715.png)

![image-20210118211238338](assets/BUILD/image-20210118211238338.png)



### update and install newer version of libgit2 and libssh2

![image-20210119154858412](assets/BUILD/image-20210119154858412.png)



### update Java alternatives to Java 1.8 JDK

![image-20210119155016494](assets/BUILD/image-20210119155016494.png)

![image-20210119154956794](assets/BUILD/image-20210119154956794.png)



### Install java8 and java11 for more Java options

![image-20210119155245068](assets/BUILD/image-20210119155245068.png)

### opencpu

![image-20210119155139344](assets/BUILD/image-20210119155139344.png)

Fix to this error:

![image-20210118205929724](assets/BUILD/image-20210118205929724.png)

Puppet script:

```
class install_opencpu {
    exec {'add-opencpu-repository':`
      provider => shell,
      command  =>
        'add-apt-repository ppa:opencpu/opencpu-1.6;
         apt-get update;
         apt-get upgrade;
         ',
     }
    ->
    package { 'opencpu' :
      ensure => installed,
    }
}
```



### Install javajdk8

```
'default-jdk', 'gdebi-core', 'libcurl4-gnutls-dev']:
```



### Fixed problem with opencpu

https://www.opencpu.org/download.html

![image-20210118205455180](assets/BUILD/image-20210118205455180.png)

```
class install_opencpu {
    exec {'add-opencpu-repository':
      provider => shell,
      command  =>
        'add-apt-repository ppa:opencpu/opencpu-1.6;
         apt-get update;
         apt-get upgrade;
         ',
     }
    ->
    package { 'opencpu' :
      ensure => installed,
    }
}
```



```
options("repos"="http://cran.rstudio.com") # set the cran mirror

packages = c("BH", "devtools", "ggplot2", "dplyr", "tidyr", "RcppEigen", "stringr", "gridExtra",
             "RCurl", "RJSONIO", "RJDBC", "knitr", "lme4", "latticeExtra", "RMySQL",
             "XLConnect", "Cairo", "opencpu", "rstudio")
packages = setdiff(packages, installed.packages()[, "Package"])
if (length(packages) != 0) {
  (install.packages(packages, dep = c("Depends", "Imports")))
}

# Packages from github are installed unconditionally
ghpackages = c("rstudio/htmltools", "trestletech/shinyTable", "rstudio/rmarkdown", "rstudio/shiny")
devtools::install_github(ghpackages)
#ghFrame = do.call(rbind, strsplit(ghpackages,"/"))

#reqPackages = setdiff(ghFrame[,2], installed.packages()[,"Package"])
#ghPack = ghFrame[ghFrame[,2]==reqPackages,,drop=FALSE]
#
#if (nrow(ghPack) != 0){
#  (devtools::install_github(apply(ghPack,1,paste,collapse="/")))
#}
update.packages(ask = FALSE)
```





```
 sudo add-apt-repository ppa:cran/libgit2
 sudo apt-get update
 sudo apt-get install libssh2-1-dev libgit2-dev
```



*   With Bionic there seems to be a problem with puppet:
    ![image-20210118125031364](assets/BUILD/image-20210118125031364.png)

Trying to install R repository for `trusty64`:
```
Ign http://archive.ubuntu.com trusty/universe Translation-en_US                
Fetched 488 B in 8s (60 B/s)                                                   
Reading package lists... Done
W: GPG error: http://cran.rstudio.com trusty/ Release: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 51716619E084DAB9
```


![image-20210118115814158](assets/BUILD/image-20210118115814158.png)



![image-20210118101655305](assets/BUILD/image-20210118101655305.png)

![image-20210118101614383](assets/BUILD/image-20210118101614383.png)

### hiera.yaml

`Warning: Config file /etc/puppet/hiera.yaml not found, using Hiera defaults`

![image-20210118100820047](assets/BUILD/image-20210118100820047.png)



### puppet maestrodev-get

`    default: Error: Could not install module 'maestrodev-wget' (latest)`

![image-20210118100853956](assets/BUILD/image-20210118100853956.png)

Add `--force` parameter. Change the puppet command to:

![image-20210118100916982](assets/BUILD/image-20210118100916982.png)



### Do not run opencpu

Because cannot find repository.

![image-20210118101050606](assets/BUILD/image-20210118101050606.png)