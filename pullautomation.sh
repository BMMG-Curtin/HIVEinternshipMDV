#!/bin/bash/

# runmethesequal.sh
# by greifm

# an automated scrypt for pull sim
# adapted from runme.sh by greifm

function processunphysical()
{
    testing=false
    keepfiles=false

    traj=../tempallcomb.xtc
    top=../finalpull250x5_long/221_AlaTrp_pull_250x5_long.tpr
    index=../finalpull250x5_long/index5.ndx
    gro=../221_AlaTrp_US_3.7_in.gro

    if [ $# == 9 ]
    then            # needs updating, (never used, nice idea) # add file locations?
        echo "Using function input arguments\nUsing \"" $@ "\" for variables"; sleep 1s 
        filterearly=$1      # if true, will filter before other changes are made
        lowpassFE=$2        # choose between low pass and high pass
        nfFE=$3             # choose filter level
        centre=$4           # choose center group
        filter=$5           # if true, will filter
        lowpass=$6          # choose between low pass and high pass
        nf=$7               # choose filter level
        b=$8; e=$9
    else
        echo "Using default input arguments"; sleep 1s
        filterearly=false    # if true, will filter before other changes are made
        lowpassFE=true     # choose between low pass and high pass          # can not fit as tpr will hold pept at start
        nfFE=5              # choose filter level

        centre=19           # choose center group

        filter=true        # if true, will filter
        lowpass=true       # choose between low pass and high pass
        nf=2                # choose filter level
        fit=true
        fitin=19
        all=true

        b=0
        e=1750
    fi

    # cut up file
    outfile=221_AlaTrp_push250x5long_raw_b${b}e${e}
    dir=$outfile
    mkdir $dir; cd $dir
    echo 0 | gmx trjconv -f $traj -o ${outfile}.xtc -s $top -b $b -e $e
    if [ $testing == true ]; then read nothing; fi


    #filterearly
    if [ $filterearly == true ]
    then
        if [ $lowpassFE == true ]
        then
            pass="ol"
        else
            pass="oh"
        fi

        infile=$outfile
        outfile=${outfile}_fe${pass}${nfFE}
        gmx filter -f ${infile}.xtc -${pass} ${outfile}.xtc -s $top -nf $nfFE
        if [ $testing == true ]; then read nothing; fi
    fi

    # nojump
    infile=$outfile
    outfile=${outfile}_nojump
    echo 0 | gmx trjconv -f ${infile}.xtc -o ${outfile}.xtc -s $top -pbc nojump
    if [ $testing == true ]; then read nothing; fi

    # center on lipids and pbc mol
    infile=$outfile
    outfile=${outfile}_c${centre}_mol
    echo $centre 0 | gmx trjconv -f ${infile}.xtc -o ${outfile}.xtc -s $top -n $index -pbc mol -center
    if [ $testing == true ]; then read nothing; fi

    # filter
    if [ $filter == true ]
    then
        if [ $lowpass == true ]
        then pass="ol"
        else pass="oh"
        fi

        if [ $fit == true ]
        then
            if [ $all == true ]; then all="-all"; else all=""; fi
            infile=$outfile
            outfile=${outfile}_f${pass}${nf}fit${fitin}${all}
            echo $fitin | gmx filter -f ${infile}.xtc -${pass} ${outfile}.xtc -s $top -nf $nf -fit $firin -n $index $all
        else
            infile=$outfile
            outfile=${outfile}_f${pass}${nf}
            gmx filter -f ${infile}.xtc -${pass} ${outfile}.xtc -s $top -nf $nf
        fi
        if [ $testing == true ]; then read nothing; fi
    fi

    # remove things
    infile=$outfile
    outfile=AHHH_${outfile}_remnosol
    createinfile   # creates index, not automated, see createinfile()
    gmx make_ndx -n $index -o index_now.ndx -f $gro <infile
    echo 24 | gmx trjconv -f ${infile}.xtc -o ${outfile}.xtc -n index_now.ndx

    # clean up
    if [ -e ${outfile}.xtc ]
    then
        cp ${outfile}.xtc ../created/.
        cd ..
        if [ $keepfiles == false ]; then rm -r $dir; fi
        echo "successfully created " $outfile
    else
        echo "error, final file does not exist. please check output for details"
    fi
    echo "done"
    exit
}

function createinfile() 
{    
    >infile
    echo "r 113 | r 46 | r 117 | r 103">>infile
    # if editing this, remember to edit echo 24 | gmx trjconv -f ${infile}.xtc  etc
    echo "7 & ! 23">>infile
    echo "q">>infile
}

processunphysical
