#!/bin/bash/

# replexautomation.sh
# to process files for visualisation in stereo
# greifm

# the following is edited from doathing.sh by greifm
# the following is edited from dosomething.sh by greifm
# the following is edited from dothings.sh by greifm
# the following is edited from ash.sh by greifm
# a script automate postprocessing on replex data

function combine()
{
    # variables
    testing=false   # for testing, if true the program will ask for user input to continue at each stage
    keepfiles=false # if you wish to keep intermediate files make it true
    pept=false      # for centering on peptide
    filter=false    # for filtering
    nf=5
    filearly=false  # for filering before concat
    fenf=5
    # output, leave all false if only wish to remove solvent
    heavy=false     # for removing all lipids except heavy atoms
    terminal=false  # like heavy but with terminal carbons
    float=true     # like terminal but with a couple of lipids of each type
    # other variables
    b=20000         # begining frame
    e=20050         # end frame
    index=../index.ndx # index
                    # xtc and top file names can be changed at  lines 38,39,and84
                    # further changes will be needed for naming conventions starting at concatination

    array=( "$@" )  # argument input placed into array
    dir=${array[0]}_${array[-1]}_${#array[*]} # naming convention
    
    # make and cd to directory of naming convention dir
    mkdir $dir; cd $dir
    if [ $testing == true ]; then echo $dir; read nothing; fi

    # run changes on individual files
    tempOne=( $( echo {001..100}) ) # will break if array exceeds 99
    for ii in ${!array[*]}
    do
        traj=../../US${array[$ii]}_s1.00_rawTraj.xtc 
        top=../../top${array[$ii]}.tpr
        outn=traj_${array[$ii]}.xtc
        filename=a${tempOne[ii]}traj${array[$ii]}_rawTraj_cm

        # cut
        gmx trjconv -f $traj -o $outn -b $b -e $e 
        traj=$outn

        # filter before center? - no need
        if [ $filearly == true ]
        then
            echo 19 | gmx filter -f $traj -ol ${filename}.xtc -s $top -n $index -nf $fenf -all -fit
            traj=${filename}.xtc
        fi
    
        if [ $pept == true ]
        then
            # center on protein, cut, pbc. Nojump does not work, lipid layers separate
            echo 8 0 | gmx trjconv -f $traj -o ${filename}.xtc -s $top -n $index -center -pbc mol
        else
            echo 19 0 | gmx trjconv -f $traj -o ${filename}.xtc -s $top -n $index -center -pbc mol
        fi
        if [ $testing == true ]; then read nothing; fi
    done

    # create file for concationation input
    # this is done because trjcat for some reason does not accept echo input
    touch timefile
    numFrames=$(( e - b ))  # number of frames
    for ii in ${!array[*]}
    do
        echo $((b + numFrames * ii)).00 >> timefile
    done
    if [ $testing == true ]; then head -n ${#array[*]} timefile; read nothing; fi

    # concatonate
    if [ $pept == true ]; then cen=_pept; else cen=_lipid; fi           # variables used for naming
    if [ $filearly == true ]; then fil=olea${fenf}allfit19_; else fil=""; fi
    outfile=traj_comb${dir}_rawTraj_b${b}e${e}_${fil}cm${cen}      # file name for output

    gmx trjcat -f a???traj?.?_rawTraj_cm.xtc -o ${outfile}.xtc -settime<timefile
    if [ $testing == true ]; then read nothing; fi

    # filter
    if [ $filter == true ]
    then
        top=../../top${array[0]}.tpr
        filterfile=${outfile}_fil${nf}
        gmx filter -f ${outfile}.xtc -ol ${filterfile}.xtc -s $top -n $index -nf $nf
        outfile=${filterfile}
        if [ $testing == true ]; then read nothing; fi
    fi

    # what atoms will be output
    if [ $heavy == true ]
    then
        # remove all atoms except protein, O and N of lipids
        heavyfile=../${outfile}_heavy.xtc
        echo 24| gmx trjconv -f $outfile -o $heavyfile -n $index
        if [ $testing == true ]; then read nothing; fi
    elif [ $float == true ]
    then
        # like heavy but with 4 x 4 molecules added back in
        floatfile=../${outfile}_float.xtc
        echo 30 | gmx trjconv -f $outfile -o $floatfile -n $index
        if [ $testing == true ]; then read nothing; fi
    elif [ $terminal == true ]
    then 
        # like heavy but with terminal carbons
        terminalfile=../${outfile}_terminal.xtc
        echo 29 | gmx trjconv -f $outfile -o $terminalfile -n $index
    else
        # remove solvent
        solvremoved=../${outfile}_nonwater.xtc
        echo 7| gmx trjconv -f $outfile -o $solvremoved -n $index
        if [ $testing == true ]; then read nothing; fi
    fi

    # clean up
    cd ..
    if [ $keepfiles == false ]; then rm -r ${dir}; fi
    echo "combine ${dir} done"
} 

# run command, change arguments at will.
combine 3.8 3.6 3.4 3.2 3.0 2.8 2.6 2.4 2.2 2.0 1.8 1.6 1.5 1.4 1.2 1.0 0.9 0.8 0.6 0.4 0.2 0.0 0.0 0.2 0.4 0.6 0.8 0.9 1.0 1.1 1.2 1.4 1.5 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 

rm \#*
echo "done"
exit
