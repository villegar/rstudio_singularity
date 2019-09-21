module load singularity
if [ ${1:-0} == 1 ]; then
        mkdir -p singularity && cd singularity
        singularity pull --name rstudio.simg docker://rocker/tidyverse:latest
fi;

#PASSWORD='rstudio'
PASSWORD=$(openssl rand -base64 8)

# User-installed R packages go into their home directory
if [ ! -e ${HOME}/.Renviron ]
then
  printf '\nNOTE: creating ~/.Renviron file\n\n'
  echo 'R_LIBS_USER=~/R/%p-library/%v' >> ${HOME}/.Renviron
fi

# Get tunneling info
port=$(shuf -i8000-9999 -n1)
node=$(hostname -s)
user=$(whoami)
server="iris.jacks.local"

# Verify if we are running on Roaring Thunder (double tunneling is needed)
if [[ $node = node* ]] || [[ $node = big* ]] || [[ $node = gpu* ]]
then
        server="rt.sdstate.edu"
fi

# print tunneling instructions jupyter-log
echo -e "
INSTRUCTIONS
1. (HPC) Run one of the following (required to access the GUI):
    - MacOS or Linux terminal command to create your ssh tunnel:
        ssh -N -L ${port}:${node}:${port} ${user}@${server}

    - MobaXterm (https://mobaxterm.mobatek.net) - Windows GUI:

        Forwarded port: ${port}
        Remote server: ${node}
        Remote port: ${port}
        SSH server: ${server}
        SSH login: $user
        SSH port: 22
"
if [[ $node = node* ]] || [[ $node = big* ]] || [[ $node = gpu* ]]
then
echo -e "
    - PuTTY (https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) on Windows CMD:
        plink -ssh -L ${port}:${node}:${port} ${user}@${server} ssh -L ${port}:${node}:${port} ${user}@${node}
"
else
echo -e "
    - PuTTY (https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) on Windows CMD:
        plink -ssh -L ${port}:${node}:${port} ${user}@${server}
"
fi
echo -e "
2. Use a Browser on your local machine to go to:
    localhost:${port}  (prefix w/ https:// if using password)

3. Use the following credentials:
        user: ${user}
        password: ${PASSWORD}
"

if [ ${1:-0} -ne "0" ]
then
        echo "Once you are done using RStudio, don't forget to terminate your job by running:

        scancel $1"
fi

PASSWORD=$PASSWORD singularity exec --bind=$HOME  rstudio.simg rserver --auth-none=0  --auth-pam-helper-path=pam-helper --www-port $port


# References
## https://www.rocker-project.org/use/singularity/
## https://divingintogeneticsandgenomics.rbind.io/post/run-rstudio-server-with-singularity-on-hpc/
