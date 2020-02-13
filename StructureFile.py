# StructureFile.py
# greifm
# 
# this class is made to easily edit .gro structure files
#
# use:
#   create object using an input .gro file
#   can be used as a class or directly using user input
#
#   edit files with .removelines([[pattern, column, argument]])
#       removelines takes a list input of a list containing a pattern (str), column (int), and argument (str)
#           lots of pca lists can be given
#           the argument can either be "include" or "exclude"
#               include is essentially an AND statement with other pca(include)'s for deletion
#               exclude will exclude that line from deletion, despite include statements
#               use includes before excludes, order is otherwise not important
#   examples in main()
#
# todo:
#   make _createAtomArray more efficient

class StructureFile:
    # class variables           # all are strings to make file writing easier
    # string self.title                 # string
    # string self.numAtoms              # int
    # list(string) self.atoms           # whitespace separated values
    # string self.box                   # whitespace separated floats
    # list(list(string)) self.atomArray # strings, floats

    def __init__(self, fileName):
        try:
            readFile = open(fileName, "r")

            self.atoms = []
            for line in readFile:               # read all lines into atom list
                self.atoms.append(line)         
            self.title = self.atoms.pop(0)      # move first line into title
            self.numAtoms= self.atoms.pop(0)    # move second line into numAtoms
            self.box = self.atoms.pop(-1)       # move last line into box
            
        except Exception as e1:
            print("error in initiation of structureFile object: \n", e1)
        finally:
            readFile.close()
     
    def __str__(self):
        atomString = ""
        for line in self.atoms:
            atomString += line
        return self.title + self.numAtoms + atomString + self.box

    def write(self, fileOut):
        try:
            self.numAtoms = str(len(self.atoms)) + "\n" # recalculate numAtoms before writing
                                        # this could have been done during deletion but was unnecessary and inefficient
            string = self.title
            string += self.numAtoms
            for ii in self.atoms:
                string += ii
            string += self.box      # large string of everything to be written

            writeFile = open(fileOut, "w")
            writeFile.write(string)
        except Exception as e1:
            print("error in write of structureFile object: \n", e1)
        finally:
            writeFile.close()

    def _createAtomArray(self): # created every time removelines() is used; resource inefficient
                                # however, deleting lines would also be inefficient, see "todo:"
        self.atomArray = []
        for ii in range(0,len(self.atoms)):
            self.atomArray.append(self.atoms[ii].split())   # a list of lists mirroring self.atoms

    def removelines(self, pca): # pca is list(list(pattern, column, include/exclude))
        try:
            self._createAtomArray()     # create an easily searchable array
            index = []                  # store index of lines to be deleted from self.atoms
            for ii in range(0,len(self.atomArray)): # look through array, matching 
                addindex = True
                for jj in range(0, len(pca)):   # go through each pca
                    pattern = pca[jj][0]    # prettier variables
                    column = pca[jj][1]
                    argument = pca[jj][2]

                    if pattern in self.atomArray[ii][column]:   # if search terms are found
                        if argument == "include":           # and include flag
                            addindex = addindex and True     # and not previously excluded, flag for deletion
                        elif argument == "exclude":         # and exclude flag
                            addindex = False                 # then do not delete
                        else:
                            raise "error, invalid input" + argument
                    else:
                        if argument == "include":
                            addindex = False    # if not found, don't delete
                        elif argument == "exclude":
                            pass                # does not need to be excluded
                if addindex == True:
                    index.append(ii)
            for jj in range(len(index)-1,-1,-1):    # go backwards as pop would alter index
                self.atoms.pop(index[jj])
        except Exception as e1:
            print ("error in removelines of structureFile object:\n", e1)

def testfile():     # test file
    test = StructureFile("testfilein.gro")  # create object and load data into it
    carbonNotPept = [["C", 1, "include"],["ALA", 0, "exclude"], ["TRP", 0, "exclude"]]
    test.removelines( carbonNotPept )    # delete carbon atoms except for those in ALA and TRP
    test.removelines( [["TRP", 0, "include"], ["2", 0, "include"]] )    # delete tpr if it is 2tpr
    test.removelines( [["162FA24", 0, "include"], ["O", 1, "include"]] ) # delete all oxygens from res 1672FA24
    test.write("testfileout.gro")   # save to file

def menu():
    print( "\nWelcome to StructureFile's .gro line management system\n" )
    gro = fileinput()
    print( "\ninstruction:\t you will be asked for a search term, which column it can be found in, and if you wish for the term to be inclusive or exclusive.\n\t - the search term can be / is a subset of the search string.\n\t - the column can either be the first (0) or the second (1) column of the gro file; (res name, atom)\n\t - if the inclusive flag is used multiple search's can be made, lines will only be deleted if they meet both search's\n\t - if the exclusive flag is used the line will not be deleted, even if it meets the inclusive search's. \n\t - use inclusive search(s) first, then exclusive(s); or the results will be unexpected\n")

    cont = contTwo = contThree = True
    while cont:
        array = []
        ii = 0
        while contTwo:
            array.append( inputspa() )
            contTwo = inputanother("do you wish to add another search term to this?")
            ii += 1
        print("deleting line(s)")
        gro.removelines(array)
        cont = inputanother("do you wish to delete more lines from the file?")
    while contThree:
        try:
            gro.write(input( "what is the file name you wish to save this file as?: " ))
            contThree = False
        except Exception:
            print("error, please try again")
    print("done")

def fileinput():
    try:
        gro = StructureFile( input( "what is the file name you wish to input? " ) )
    except Exception as e1:
        print( "error in file input: ", e1, "\nprogram will now close; please enter a real file name next time")
        exit()
    return gro

def inputspa():
    pattern = column = arg = None
    pattern = input( "enter search term: ")
    while column is None:
        column = input( "enter column number: ")
        try:
            column = int(column)
        except Exception:
            print ( "Invalid choice", column, "must be int" )
            column = None
    while arg is None:
        arg = input( "enter (i)nclusive or (e)xclusive: ")
        if arg == 'i':
            argument = "include"
        elif arg == 'e':
            argument = "exclude"
        else:
            print( "Invalid choice", arg, "must be i or e" )
            arg = None
    array = [pattern, column, argument]
    return array

def inputanother(x):
    while True:
        another = input( x + " (y) (n): ")
        if another == 'y':
            return True
        elif another == 'n':
            return False
        else:
            print( "Invalid choice", another, "must be y or n" )

    
if __name__ == "__main__":
    menu()
