#!/bin/bash

#Usage: ./parse_voyager.sh <filename>

# create a reverse file that is easier to parse
tac $1 > $1.reversed

# we will use the filename variable to store the actual filename, for readability
# this filename will actually be something like Scheduler.Archive.reversed
filename=$1.reversed
outfile=$1.xml

#initialize the output file (we will be appending to it in the script)
echo "" > $outfile

# tag - setting this to something that will not be matched
# this is an array we will use for storing the tags based on depth
tag=( )

# depth - this will tell us how many tags deep we are
# it will be used for feeding to the array
# starts with a depth of 0
depth=0

# itemnum - this is a value that we will put in a tag for easier searchability in the xml
# it will show up in the final product like this:
# <0> </0>
# <1> </1>
# <2> </2> #etc...
itemnum=0

# this section is where the document is read and parsed
# the $filename is specified after the "done" line at the end of the block
# in the while loop, the variable $line is used for the current line of the file
while read line
do
   #strip the newline character off (^M)
//g')ne=$(echo $line | sed 's/
   # we are looking for specifically lines that start with "<<-"
   # it is structured in a hierarchical way because of that
   if [[ $(echo $line | grep "^<<-" | wc -l) == 1 ]]; then
      # check if the tag[depth] is not null
      if [[ ! -z "${tag[$depth]}" ]]; then
         echo "Current tag: ${tag[$depth]}"
         echo "Depth: $depth"
         depth=$((depth + 1))
         echo "Current tag is not null, increasing depth to $depth"
         #set itemnum back to 0
         itemnum=0
      fi
      # strip off the "<<-" and just get the tag name
      # we will store this in the tag variable for later
      tag[$depth]=$(echo $line | awk -F"<<- " '{print $2}' )
      
      #add tab formatting to the xml file
      for (( i=0; i<$depth; i++ ))
      do
         printf "	" >> $outfile
      done
      echo "<${tag[$depth]}>" >> $outfile
      echo ${tag[$depth]}
       
   elif [[ $(echo $line | grep "^>>>" | wc -l) == 1 ]]; then
      #do nothing, this is the Version line and screws up our XML
      foo="bar"

   #This is not a line that opens with "<<-"
   else
      if [[ $(echo $line) != ${tag[$depth]} ]]; then
         echo "Line: $line"
         echo "Looking for ${tag[$depth]}"
         
         #add tab formatting to the xml file
         for (( i=0; i<$(($depth + 1)); i++ ))
         do
            printf "	" >> $outfile
         done
         
         echo "<$itemnum>$line</$itemnum>" >> $outfile

         #itemnum++
         itemnum=$((itemnum + 1))
      else
         # this is how we close the tag
	 echo "Tag Closed: ${tag[$depth]}"
         
         #add tab formatting to the xml file
         for (( i=0; i<$depth; i++ ))
         do
            printf "	" >> $outfile
         done
         
         printf "</" >> $outfile
         printf "${tag[$depth]}" >> $outfile
         printf ">\n" >> $outfile

         #delete the tag from the array
         unset -v tag[$depth]
         #reduce the depth
         depth=$((depth - 1))
         
         # set itemnum back to 0
         itemnum=0
      fi
   fi
done < "$filename"
