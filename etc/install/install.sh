#!/bin/bash
#
# Read the README file before executing this script.
#
# This script recreates an OpenACS server from scratch by:
#
# - dropping and creating the database
# - Re-checking out the source code from CVS (optional)
# - Doing necessary installation and configuration of OpenACS and
#   .LRN over HTTP that is normally done manually in a browser.
#
# @author Peter Marklund (peter@collaboraid.biz)

# DEBUG: If any command fails - exit
#set -e

# Set the script directory to the current dir for convenience
script_path=$(dirname $(which $0))
cd $script_path

source functions.sh

# TODO: add config variables for service owner and group
# we should check for the existence of the specified user
#   if the user doesn't exist, 
#     if the user was specified in the command line
#       create the user
#     fi
#     interactive prompt to create user or terminate script
#   fi
#
# Meanwhile, however, we're just going to assume that service user
# is the same as servername and that the user exists.  Documented
# in README


# Parse options
export config_file="config.tcl"
interactive="no"
usage="$0 [OPTIONS]
    --config-file Sets up information about the server and database used (see config.tcl.in). Defaults to config.tcl
    --no-checkout Do not checkout new source code
    --oacs-only   Do not install .LRN, only OpenACS
    --no-install  Do not install .LRN or OpenACS. Useful if you only want to recreate the db user and then install manually
    --postgresql  Install on PostgreSQL. Overrides database setting in install config file.
    --interactive Gives you the possibility to exit at certain points during installation
"

# Check that script is executed as root
if [ $(whoami) != "root" ]; then
    echo "$0: You must execute this script as root, exiting"
    exit -1
fi

# Check that the config file exists
if [ ! -r ${config_file} ]; then
    echo "$0: Aborting installation. The config file \"$config_file\" does not exist or is not readable."
    exit -1
fi

# Set important configuration parameters
serverroot=`get_config_param serverroot`
svscanroot=`get_config_param svscanroot`
database=`get_config_param database`
server_url=`get_config_param server_url`
error_log_file=`get_config_param error_log_file`
tclwebtest_dir=`get_config_param tclwebtest_dir`
stop_server_command=`get_config_param stop_server_command`
start_server_command=`get_config_param start_server_command`
restart_server_command=`get_config_param restart_server_command`
startup_seconds=`get_config_param startup_seconds`
shutdown_seconds=`get_config_param shutdown_seconds`
restart_seconds=$(expr $startup_seconds + $shutdown_seconds)
dotlrn_demo_data=`get_config_param dotlrn_demo_data`
dotlrn=`get_config_param dotlrn`
crawl_links=`get_config_param crawl_links`
do_checkout=`get_config_param do_checkout`
use_daemontools=`get_config_param use_daemontools`
do_install="yes"

# command-line settings override config file settings
while [ -n "$1" ] ; do
   case "$1" in
      "--config-file")        
        shift
        export config_file=$1
      ;;
      "--no-checkout")
        do_checkout="no"
      ;;
      "--oacs-only")
        dotlrn="no"
      ;;
      "--postgresql")
        database="postgres"
      ;;
      "--interactive")
        interactive="yes"
      ;;
      "--help"|"-h")
        echo "${usage}"
        exit 0
      ;;
      "--no-install")
        do_install="no"
      ;;
      *)
        echo "$0: option not recognized: ${i}"
        echo "${usage}"
        exit 1
      ;;
   esac

   shift
done

# If pre/post checkout scripts have been provided - check that they can
# be executed
pre_checkout_script=`get_config_param pre_checkout_script`
post_checkout_script=`get_config_param post_checkout_script`
if [ -n "$pre_checkout_script" ] && [ ! -x $pre_checkout_script ]; then
    echo "The pre checkout script $pre_checkout_script does not exist or is not executable"
    exit -1
fi
if [ -n "$post_checkout_script" ] && [ ! -x $post_checkout_script ]; then
    echo "The post checkout script $post_checkout_script does not exist or is not executable"
    exit -1
fi

# Log some important parameters for the installation
echo "$0: Starting installation with config_file $config_file. Using serverroot=$serverroot, server_url=$server_url, do_checkout=$do_checkout, do_install=${do_install}, dotlrn=$dotlrn, and database=$database."
prompt_continue $interactive

# stop the server
echo "$0: Taking down $serverroot at $(date) with command ${stop_server_command}"
$stop_server_command
# Wait for the server to come down
# TODO - this prints an error message in a default install because the 
# symlink exists but the target directory won't be created until the
# cvs checkout later
# maybe we should do the daemontools check here and not run the stop command
# if daemontools is true and directory is missing

echo "$0: Waiting $shutdown_seconds seconds for server to shut down at $(date)"
sleep $shutdown_seconds

# Recreate the database user
echo "$0: Recreating database user at $(date)"
if [ $database == "postgres" ]; then
    # Postgres
    pg_bindir=`get_config_param pg_bindir`
    pg_port=`get_config_param pg_port`
    pg_db_name=`get_config_param pg_db_name`
    su  `get_config_param pg_db_user` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/dropdb -p $pg_port $pg_db_name; ${pg_bindir}/createdb -p $pg_port $pg_db_name; ${pg_bindir}/createlang -p $pg_port plpgsql $pg_db_name";

else
    #Oracle
    su oracle -c "cd $script_path; config_file=$config_file ./oracle/recreate-user.sh";
fi

# The idea of this script is to move away any files or changes
# to the source tree that we want to keep (for example an
# edited AOLServer config file, see README)
if [ -n "$pre_checkout_script" ]; then
    source $pre_checkout_script
fi

# Move away the old sources and checkout new ones check do_checkout
if [ $do_checkout == "yes" ]; then
    echo "$0: Checking out OpenACS at $(date)"
    config_file=$config_file dotlrn=$dotlrn ./checkout.sh
    
    # If we are using daemontools, set up the supervise directory
    if parameter_true $use_daemontools; then
	
    # Create a daemontools directory if needed
    	if ! [ -L "${svscanroot}" ] && ! [ -d "${svscanroot}" ] ; then
            # if we are supposed to use daemontools but there is no control
            # directory, link the default directory from the cvs tree
	    # TODO: currently this leaves us with a stranded supervise
	    # because it was using control files that we moved away.
	    # The new supervise works fine, but the old one is still
	    # floating around.  We should either kill the old one directly
	    # as part of shutdown, or preserve the control files so we can 
	    # continue using any previous supervise command
	    echo "$0: Creating daemontools directory"
	    ln -s $serverroot/etc/daemontools $svscanroot
            # allow svscan to start
	    echo "$0: Waiting for $startup_seconds seconds for svscan to come up at $(date)"
	    sleep $startup_seconds
	    echo "$0: Giving group 'web' control over the server: svgroup web ${svscanroot}"
        # svgroup may not be on the system, check the PATH
	    if which svgroup &> /dev/null; then
		svgroup web ${svscanroot}
	    fi
	fi
    fi
fi

# The idea of this script is to copy in any files (AOLServer config files,
# log files etc.) under the new source tree, and apply any patches
# that should be applied (see README).
if [ -n "$post_checkout_script" ]; then
    source $post_checkout_script
fi

# Bring up the server again
echo "$0: Bringing the server $serverroot back up at $date with command $command"

# TODO - if we did checkout, we may have created and linked a 
# daemontools directory, in which case we already started the 
# server and this next command is redundant.  Should see if there's
# an easy way to create a disabled supervise directory that doesn't
# complicate later startup

$start_server_command

# Give the server some time to come up
echo "$0: Waiting for $startup_seconds seconds for server to come up at $(date)"
sleep $startup_seconds

if parameter_true $do_install; then
  # Save the time we started installation
  installation_start_time=$(date +%s)
    
  # Install OpenACS
  echo "$0: Starting installation of OpenACS at $(date)"
  ${tclwebtest_dir}/tclwebtest -config_file $config_file openacs-install.test
  
  # Restart the server
  echo "$0: Restarting server at $(date)"
  $restart_server_command
  echo "$0: Waiting for $restart_seconds seconds for server to come up at $(date)"
  sleep $restart_seconds
  
  if [ $database == "postgres" ]; then
      # Run vacuum analyze
      echo "$0: Beginning 'vacuum analyze' at $(date)"
      su  `get_config_param pg_db_user` -c "export LD_LIBRARY_PATH=${pg_bindir}/../lib; ${pg_bindir}/vacuumdb -p $pg_port -z `get_config_param pg_db_name`"
  fi
  
  if [ $dotlrn == "yes" ]; then
      # Install .LRN
      echo "$0: Starting install of .LRN at $(date)"
      ${tclwebtest_dir}/tclwebtest -config_file $config_file dotlrn-install.test
  
      # Restart the server
      echo "$0: Restarting server at $(date)"
      $restart_server_command
      echo "$0: Waiting for $restart_seconds seconds for server to come up at $(date)"
      sleep $restart_seconds
      extra_seconds_wait=300
      echo "$0: Waiting an extra $extra_seconds_wait seconds here as much initialization of dotLRN and message catalog usually happens at this point"
      sleep $extra_seconds_wait
  
      if parameter_true "$dotlrn_demo_data"; then
          # Do .LRN demo data setup
          echo "$0: Starting basic setup of .LRN at $(date)"
          ${tclwebtest_dir}/tclwebtest -config_file $config_file dotlrn-basic-setup.test
      fi
  fi
  
  if parameter_true $crawl_links; then
      # Search for broken pages
      echo "$0: Starting to crawl links to search for broken pages at $(date)"
      ${tclwebtest_dir}/tclwebtest -config_file $config_file dotlrn-links-check.test
  fi
  
  # Report the time at which we were done
  echo "$0: Finished (re)installing $serverroot at $(date)"
  
  # Check errors in the log file
  if [ -r ${error_log_file} ]; then
      seconds_since_installation_start=$(expr $(date +%s) - $installation_start_time)
      minutes_since_installation_start=$(expr $seconds_since_installation_start / 60 + 1)
      log_error_file=${serverroot}/log/error.log
      ./aolserver-errors.pl -${minutes_since_installation_start}m ${error_log_file} > $log_error_file
      error_line_count=$(wc -l $log_error_file | awk '{print $1}')
      if expr $error_line_count \> 1 &> /dev/null; then
         alert_keyword=`get_config_param alert_keyword`
         echo "$0: ${alert_keyword} - There are error messages in the log file, they are stored in $log_error_file"
      fi
  else
      echo "$0: Log file ${error_log_file} not readable - cannot check for errors"
  fi
  
  # Warn about errors in the HTML returned from the server
  ./warn-if-installation-errors.sh `get_config_param openacs_output_file`
  ./warn-if-installation-errors.sh `get_config_param openacs_packages_output_file`
  if [ $dotlrn == "yes" ]; then
      ./warn-if-installation-errors.sh `get_config_param apm_output_file`
  fi
fi
