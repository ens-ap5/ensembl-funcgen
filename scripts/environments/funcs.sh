#!/usr/local/bin/bash


#echo ":::: Sourcing funcs.sh"
export PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'

#To do
#Add more error echos when exiting
#Document error codes
#rename funcs lcfirst or _ first to enable us to filter public and 'private' methods in help functions

#We should add these to an array and then use the array values in ReportExit to list a nice error rather than a number
# File : funcs.sh
# Error Codes: #restrict these to 100s so we can use 200s in any environment which sources these?
# 205 - Incorrect user
# 100 - Variable not defined
# 201 - Binary not found
# 101 - Variable not valid
# 255 - Execution of script failed


# LIST OF RESERVED VARIABLES
# These may be set in one function to be used in the caller
# i.e. do not use/set these unless using the function which sets them
# Also check func.sh and efg.env for similar reserved variables e.g REPLY
# JOB_ID



_TRUE=1;
_FALSE=!$_




_setOptArgArray(){

	#Set var in sub
	#Subshelling would cause problems with setting OPTIND 
	array_var=$1
	shift
	  #Should this be $@ to avoid spliting 'words with' with spaces?
	args=($*)   
	OptArgArray=
	nextarg=0


	#Need to check args here!
	#can I ever be less than 0?

	CheckVariables array_var
	#This is largely pointless as if it is not passed we just suck in the args
	#$i will be -1 if called outside of getopts?
	#Actaully Could be anything dependant on the last value of OPTIND
	#Is also susceptible of polluting of OPTIND if not reset to 0 before calling getopts

	i=$(($OPTIND - 2))

	while [[ $nextarg = 0 ]]; do
	
		#echo "i is $i"

		#echo "arg is ${args[$i]}"

		
		if [[ "${args[$i]}" = -* ]] || [[ -z "${args[$i]}" ]]; then
			nextarg=1
			OPTIND=$(($i + 1))
			#echo "next arg is at $OPTIND"
				#do we need to set this to -1?
		else
			#echo "using arg ${args[$i]}"
			OptArgArray="$OptArgArray ${args[$i]}"
			
		fi
		

		i=$(($i + 1))

	done


	eval "$array_var=($OptArgArray)"
	
}



### Trapping

#Do we want to trap any other signals?
#We probably want to capture CTRL-C (and CTRL-D?)
#as we are exiting from scripts/cmds, but the env is then carrying on with the next step
#Shouldn't we just Execute everything?

#if [ $trap_exit -eq 1 ]
#then
#	trap TrapExit EXIT
#fi

#alias exit="ding_bell"

#ding_bell() {
#	echo -e "tra la la \a"
#}

################################################################################
# Func      : _trapExt
# Desc      : Reports exit status but calls bash before exit, so we don't exit the environment
# Args [1]  : 
# Return    : 
# Exception : 
################################################################################

_trapExit(){
	es=$?
	echo "Exiting with status:$es"

	#Need to move this to funcs.sh and define exit codes and error messages

	#POOP POOP! This works, and about time too.
	#Well not quite, we aren't exiting the native shell, but we don't inherit the previosu history
	#So not quite sure what we're doing

	#This is only required if we do not initialise with a subshell and want to maintain native shell(ltcsh in our case)
	#i.e. we don't want to exit the calling shell just because this script has exited
	#This happens when a one time run script is shebanged without launching a subshell
	#Or when an environment is sourced and issues consecutive EXIT signals.

	#Can we call this dependant on an env var? MAINTAIN_SUBSHELL=1

	#No no no, this is not working, we are still exiting the env
	#We're just calling bash, so it looks like we're not exiting to ltcsh. GRRR!!!!
	#This is resulting in multiple instances of bash running!
	
	#And still not maintain env for some exits e.g. Execute
	#Is this because we are calling it from another script?
	#This was working when we had it in arrays.env, but then funcs in this script couldn't rely on it and had to use exit directly.

	bash



}



################################################################################
# Func      : CheckUser()
# Desc      : checks the a user user name against the current user
# Args [1]  : user name
# Return    : none 
# Exception : exits if user names dont match 
################################################################################

Checkuser()
{
    current_user=$(whoami)

    if [ $1 != $current_user ]
    then
        echo "error : script must be run by '$1' not '$current_user'"
		exit 205
    fi
}

################################################################################
# Func      : jobWait()
# Desc      : Waits for lsf job
# Arg  [1]  : Job ID
# Arg  [2]  : Amount of time to wait before polling in seconds. Default is 280(5mins)
#             Remove this and allow a list of Job IDs?
# Return    : Exit code from lsf job
# Exception : Exits if JobID not defined
################################################################################

jobWait()
{
	job_id=$1
	secs=$2
	secs=${secs:=280}
	
	
	CheckVariables job_id

	complete=
	exited=

	#Test for valid job first?
	

	while [ ! $complete ]; do

		job_info=($(bjobs $job_id))
		status=${job_info[10]}
		#We probably need to catch lsf daemon not responding here
		#as well as bjobs failure

		if [[ $status = 'EXIT' ]]; then
			
			#Get exit code
			complete=$(bjobs -l $job_id | grep 'Exited with exit code')
			complete=$(echo $complete | sed 's/.*code //')
			complete=$(echo $complete | sed 's/\. The CPU.*//')

			
		elif [[ $status = 'DONE' ]]; then
			complete=0
		else
			echo sleeping for $secs secs
			sleep $secs
		fi
	done

	echo -e "Finished waiting for job:\t$job_id"

	return $complete

}


# private method i.e. lcfirst
# therefore do not need -h opt
#Need to split this into checkJob

checkJob(){
	job_name=$1
	CheckVariables job_name

	#This does not catch Job <gallus_gallus_transcripts.55_2m.fasta> is not found
	JOB_ID=$(bjobs -J $job_name | grep -e "^[0-9]" | sed -r 's/([0-9]+)[[:space:]].*/\1/')

	if [ $? -ne 0 ]; then
		echo "Failed to access job information"
		exit 1
	fi


}

submitJob(){

	#Change this to take opts so we can wait for jobs?

	job_name=$1
	shift
	bsub_job=$*

	CheckVariables job_name bsub_job
	checkJob $job_name

	#We should test for more than one job here?
	#jid will currently catch all ids
	#altho retu
	
	if [ $JOB_ID ]; then
		echo "Job($JOB_ID) $job_name already exists"
	else
		#echo through bash to avoid wierd resources parameter truncation

		echo bsub -J $job_name $bsub_job
		

		JOB_ID=$(echo bsub -J $job_name $bsub_job | bash)

		if [ $? -ne 0 ]; then
			echo $JOB_ID
			echo "Failed to submit job $job_name"
			exit 1
		fi

		echo $JOB_ID

		JOB_ID=$(echo $JOB_ID | sed 's/Job <//')
		JOB_ID=$(echo $JOB_ID | sed 's/>.*//')

	fi

	#To let LSF process the job
	sleep 5
	echo "To monitor job: bjobs -lJ $job_name"
	bjobs -w $JOB_ID

}




################################################################################
# Func      : CheckVariables()
# Desc      : check that all passed environment variables have been assigned 
#             values
# Args [n]  : list of variables to check 
# Return    : #list of variables that cannot be found
# Exception : Exits if string evaluated variable is of length zero
################################################################################

CheckVariables()
{
	line=

	if [ ! "$*" ]; then
		echo 'Must pass variable name(s) to check'
		exit 100
	fi


    for var in $*
    do
        val=$(eval "echo \$$var")

        if [ -z "$val" ]
		then 
			line="$line \$$var"
		fi
    done

    if [ ! -z "$line" ]
    then
        echo "Environment variable(s) :$line are not set"
		#This is not exiting if it is called from another environment
		exit 100
    fi
}


CheckVariablesOrUsage(){
	usage=$1
	shift
	variable_names="$*"

	#Could CheckVariabl

	tmp=$(CheckVariables $variable_names)

	if [ $? != 0 ]; then
		echo "$tmp."
		echo "  $usage"
		#This get's flattened into one line if we capture the output for returning rather than exit
		exit 1;
	fi
}

ValidateVariableOrUsage(){
	usage=$1
	shift

	CheckVariables usage

	tmp=$(ValidateVariable $*)

	if [ $? != 0 ]; then
		echo "$tmp"
		echo "$usage"
		exit 1;
	fi
}


################################################################################
# Func      : ValidateVariable()
# Desc      : Check that the passed variable is contained in pass valid variable
#             array
# Arg [1]   : Variable to validate 
# Arg [n+1] : List of valid variable values 
# Return    : 
# Exception : Exits if variable is not present in valid variable list
################################################################################

ValidateVariable(){
	var_name=$1
	valid_vars_name=$2
	valid=

	CheckVariables $var_name $valid_vars_name

	var_value=$(eval "echo \$$var_name")
	valid_var_values=$(eval "echo \$$valid_vars_name")


	#Could we grep here instead?

    for valid_var_value in $valid_var_values
    do
        if [ $valid_var_value = $var_value ]
		then 
			valid=1
		fi
    done

    if [ ! $valid ]
    then
        echo "$var_value is not a valid $var e.g. $valid_var_values"
		exit 101
    fi
}


################################################################################
# Func      : CheckBinaries() 
# Desc      : checks that binary files exist
# Args [n]  : list of binaries to check 
# Return    : list of binaries that cannot be found
# Exception : none
################################################################################

CheckBinaries()
{
    for var in $*
    do
        which $var | grep ^no > /dev/null
        
        if [ $? -eq 0 ]; 
		then 
			#where is $line coming from?
			line="$line '$var'"
		fi
    done
    
    if [ ! -z "$line" ]
    then 
        echo "Binary(s) : $line cannot be found"
		exit 201
    fi
}

################################################################################
# Func      : CheckDirs()
# Desc      : checks to see whether passed parameter is a directory
# Arg [1]   : list of directory paths
# Return    : returns true if it is a directory
# Exception : exists if not a directory
################################################################################

CheckDirs()
{

	for dir_name in $*
    do
		if [ ! -d $dir_name ]
		then
			echo "error : directory $dir_name does not exist"
			exit 203
		fi
	done
}



################################################################################
# Func      : MakeDirs() 
# Desc      : if a given directory does not exist then it will make it 
# Args [n]  : list of directory(s) to make 
# Return    : none
# Exception : exits if 'mkdir' fails 
################################################################################

MakeDirs()
{
     for dir_name in $*
     do
         if [ ! -d $dir_name ]
         then
			mkdir -p $dir_name;
			rtn=$?; 

			if [ $rtn -ne 0 ]; 
			then 
				exit $rtn; 
			fi;
         fi
     done
}


################################################################################
# Func      : BackUpFile() 
# Desc      : Backs up file to $BACKUP_DIR if set
# Args [n]  : File name(not path, so have to back up from file directory)
# Return    : none
# Exception : 
################################################################################

BackUpFile(){

	#Can we add some file path parsing here to enable back up of file paths

	file=$(GetFilename $1)
	file_dir=$(GetDir $1)

	backup_dir=${BACKUP_DIR:=$file_dir}
	MakeDirs $backup_dir

	if [[ -f $1 ]]; 
	then 
		Execute cp $1 ${backup_dir}/${file}.$$
	fi
}

################################################################################
# Func      : ArchiveFile() 
# Desc      : 
# Args [n]  : 
# Return    : 
# Exception : 
################################################################################


#This needs to change to accomodate warehouse
#rsync -essh -Wav /source /destination
#We still need to back up tho
#But archive is now defunct no?

ArchiveFile()
{

	backup_dir=${BACKUP_DIR:=.}
	backup_dir="${backup_dir}/"
	MakeDirs $backup_dir

	file=$(echo $1 | sed 's/.*\///')

	if [[ -f $1 ]]; 
	then 
		Execute mv $1 ${backup_dir}/${file}.$$
	fi
}



################################################################################
# Func      : ChangeDir() 
# Desc      : if a given directory exists then it moves into it else exit 
# Args [1]  : path of directory to move into 
# Return    : none
# Exception : exits if 'cd' fails 
################################################################################

ChangeDir()
{

	Execute cd $1

}

################################################################################
# Func      : ChangeMakeDir() 
# Desc      : if a given directory exists then it moves into it, else it creates
#             the directory and then moves into it 
# Args [1]  : path of directory to move into 
# Return    : none
# Exception : exits if 'cd' fails or MakeDir fails
################################################################################

ChangeMakeDir()
{
    MakeDirs $1
	ChangeDir $1
}


################################################################################
# Func      : CheckFile() 
# Desc      : checks to see whether passed parameter is a file or a link to an 
#             existing file
# Arg [1]   : file name 
# Return    : none 
# Exception : exists if not a file 
################################################################################

CheckFile()
{
    if [ ! -f $1 ]
    then
        echo "error : file $1 does not exist"
		exit 204
    fi
}

#Could change this to CheckFilesOrUsage?
#And just pass variable names like CheckVariables

CheckFilesOrUsage(){
	usage_string=$1
	shift
	file_variables=$*
	
	usage='usage: CheckFilesOrUsage "usage string" [/file/path]+ '
 	CheckVariablesOrUsage "$usage" usage_string $file_variables


	for file_var in $file_variables; do
		file=$(eval "echo \$$file_var")

		if [ ! -f $file ]; then
			echo "error : $file does not exist.
$usage_string"
			exit 204
		fi
	done
}




################################################################################
# Func      : Execute() 
# Desc      : executes unix command and tests return status 
# Arg [n]   : command
# Return    : none
# Exception : exits if command fails
################################################################################

Execute()
{

	#echo "Executing $*"
	#We're having problems with perl -e, mysql -e and mysql < file!
	#Also haveing probles with cmd="echo 'sql statement' | mysql"
	#Execute $cmd
	#This just echos the whole of cmd and doesn't pipe!
	#This works if we don't use $cmd and Execute directly. 


    $*


	rtn=$? 


	if [ $rtn -ne 0 ]
	then 
		exit $rtn 
	fi

	#Can we trap errors here somehow?

}




################################################################################
# Func      : SedFile()
# Desc      : executes a  given (simple) sed command on a given file 
# Args [1]  : sed command 
# Args [2]  : file name 
# Return    : none
# Exception : exits if MoveFile fails 
################################################################################

SedFile()
{
    _SED_CMD=$1
    _FILE=$2

    _TMP_FILE=/tmp/$(GetFilename $_FILE).$$
  
    sed "$_SED_CMD" $_FILE > $_TMP_FILE; _RTN=$?;

    if [ $_RTN -eq 0 ]
    then 
        MoveFile -f $_TMP_FILE $_FILE;
    else
        exit $_RTN
    fi
}

################################################################################
# Func      : GetDir() 
# Desc      : extracts the directory path from a path that includes a file name 
# Args [1]  : file name including path
# Return    : returns directory without file name  
# Exception : none 
################################################################################

GetDir()
{
    echo ${1%/*}
}

################################################################################
# Func      : GetFilename() 
# Desc      : extracts the file name from a path that includes the directory 
# Args [1]  : file name including path
# Return    : returns file name without directory info 
# Exception : none 
################################################################################

GetFilename()
{ 
    echo ${1##*/}
}


SetFileSize(){
	file=$1
	shift
	
	CheckFile $file
		
   	#Need to follow links here to get real size!
	file_size=($(ls -lLk $file))
	export file_size=${file_size[4]} 
}


################################################################################
# Func      : AskQuestion()
# Desc      : adds the appropriate switch (for Mac or OSF1) to prevent a new line
#             being added after a question.
# Args [1]  : question string
# Return    : #returns the given question with the appropriate switch ???
#             Return REPLY value. This is prevent having to access REPLY, which 
#             may persist from previous AskQuestion, hence preventing while [ $READ != $answer ]
#             Actually, this makes no difference as the caller still has to clean the reply var, but
#             it is more obvious what is going on.
# Exception : none 
################################################################################

#This causes a hang
#REPLY=$(AskQuestion "Would you like to use the following $seq_type file? [y|n] $file")


AskQuestion()
{
   _QUESTION=$1


	#Do we need this no trailing new line switch? 
   #if [ $(isMac) -eq $_TRUE ]
   #then
   #    echo -n "$_QUESTION"
   #else
  #     echo -n "$_QUESTION" 
   #fi


    echo -n "$_QUESTION?  " 
    read REPLY


	#Value of return always have to be an int
	#Hence we can't return $REPLY

	#We should return 1 or undef to signify if response is valid given list of possible answers

	#return $REPLY
}


################################################################################
# Func      : ContinueOverride()
# Desc      : Executes AskQuestion unless a force flag has been specified in 
#             which case continues.  Probably need to set REPLY to Y here??????
# Args [1]  : question string
# Args [2]  : override flag
# Return    : 
# Exception : none 
################################################################################

ContinueOverride(){
    CheckVariables 1

    if [ ! $2 ]
    then
		AskQuestion "$1 [y|n]"

		if [[ $REPLY != [yY]* ]]; then
			echo "Exiting"
			exit
		fi
    else
		echo "Auto Continue"
    fi

}




################################################################################
# Func      : CheckCompressedFile()
# Desc      : checks whether a file is of a compressed format or not
# Args [1]  : file name
# Return    : none
# Exception : exits if not a compressed file and prints error msg
################################################################################

CheckCompressedFile()
{
    _FILE=$1

    if [ $(isCompressedFile $_FILE) -eq $_FALSE ] 
    then 
        echo "Error: '$_FILE' is not a compressed file"
        exit 202 
    fi
}

################################################################################
# Func      : isCompressedFile()
# Desc      : tests whether a file is of a compressed format or not
# Args [1]  : file name 
# Return    : returns true if file is compressed else false  
# Exception : none
################################################################################

isCompressedFile()
{
    _FILE2=$1

    file $_FILE2 | grep "compressed data" > /dev/null

    if [ $? -eq 1 ]
    then 
        echo $_FALSE
    else
        echo $_TRUE
    fi
}

################################################################################
# Func      : getDay()
# Desc      : gets the current day
# Args [0]  : none
# Return    : returns the current day in the format "1"
# Exception : none
################################################################################

getDay()
{
    echo $(date '+%d') 
}

################################################################################
# Func      : getMonth()
# Desc      : gets the current month
# Args [0]  : none
# Return    : returns the current month in the format "1" 
# Exception : none
################################################################################

getMonth()
{
    echo $(date '+%m') 
}

################################################################################
# Func      : getPreviousMonth()
# Desc      : gets the month previous to the current month
# Args [0]  : none
# Return    : returns the previous month in the format "1"
# Exception : none
################################################################################

getPreviousMonth()
{
    if [ $(getMonth) -eq "01" ]
    then
        _PREV_MNTH=12
    else
        _PREV_MNTH=$(expr $(getMonth) - 1)
    fi
    echo $_PREV_MNTH
}

################################################################################
# Func      : getDaysInMonth()
# Desc      : gets the number of days in a given month
# Args [1]  : month
# Args [2]  : year
# Return    : returns the number of days in a month
# Exception : none
################################################################################

getDaysInMonth()
{
    _MNTH=$1
    _YEAR=$2
    
    _DAYS=$(for i in `cal $_MNTH $_YEAR`; do echo; done; echo $i); _DAYS=$(expr $_DAYS);
    echo $_DAYS
}

################################################################################
# Func      : getYear()
# Desc      : gets the current day
# Args [0]  : none
# Return    : returns the current year in the format "2003"
# Exception : none
################################################################################

getYear()
{
    echo $(date '+%Y')
}

################################################################################
# Func      : getPreviousYear()
# Desc      : gets the year previous to the current year
# Args [0]  : none
# Return    : returns the previous year in the format "2003"
# Exception : none
################################################################################

getPreviousYear()
{
    echo $(expr $(getYear) - 1) 
}

################################################################################
# Func      : getPreviousRelativeYear()
# Desc      : gets the year relative to the previous month
#             eg  if the previous month was in the previous year it returns the
#             the previous year else it returns the current year.
# Args [0]  : none
# Return    : returns the and relevant year in the string format
#             "01 2003"
# Exception : none
################################################################################

getPreviousRelativeYear()
{
    if [ $(getPreviousMonth) -eq "12" ]
    then
        _PREV_YEAR=$(getPreviousYear)
    else
        _PREV_YEAR=$(getYear)
    fi
    echo $_PREV_YEAR
}

################################################################################
# Func      : PadNumber()
# Desc      : reformats a number from "1" to "01"
# Args [1]  : number
# Return    : returns the given number in the format "01"
# Exception : none
################################################################################

padNumber()
{
    _NUM=$1

    _PAD_NUM=$(echo $_NUM | awk '{printf("%02d",$1)}')
    echo $_PAD_NUM
}


#Distribute()
#{
#   CheckBinaries scp
   
#   _LOCAL_DIR=$1
#   _REMOTE_HOST=$2
#   _REMOTE_USER=$3
#   _REMOTE_DIR=$4

#   _REMOTE_LOGIN="$_REMOTE_USER@$_REMOTE_HOST"
#   scp -r  $_LOCAL_DIR $_REMOTE_LOGIN:$_REMOTE_DIR
#}


isMac(){

	if [[ $(uname -s) = 'Darwin' ]]; then
		echo $_TRUE
	fi
}

