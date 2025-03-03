#!/usr/bin/env python3
#********************************************************************************
# scripts/build-loader.py
# Copyright (c) 2013-2025, Richard Goedeken
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#********************************************************************************

import sys

BASICPROG = """
10 PRINT "HOW MANY DIGITS TO CALCULATE";:INPUT D
20 N=INT(D*3.321928)+1:IF N*2+1 > &HFB00 THEN PRINT "ERROR: NOT ENOUGH MEMORY":END
30 D1=INT(D/256):D0=D-D1*256:POKE &H400,D1:POKE &H401,D0
40 N1=INT(N/256):N0=N-N1*256:POKE &H402,N1:POKE &H403,N0
50 A=&H404:READ N1:FOR X = 0 TO N1-1:READ B:POKE A+X,B:NEXT
60 EXEC &H404
"""

def GenerateLoader(loaderin, loaderout):
    # read the input binary file
    inBytes = open(loaderin, "rb").read()
    # generate the output data lines
    outLines = [ ]
    progsize = len(inBytes)
    for idx in range(progsize):
        if idx % 16 == 0:
            outLines.append("%d" % inBytes[idx])
        else:
            outLines[idx//16] += ",%d" % inBytes[idx]
    # write the output basic program
    f = open(loaderout, "w")
    f.write(chr(13))
    f.write(BASICPROG.replace("\n","\r"))
    f.write(f"100 DATA {progsize}\r")
    for idx in range(len(outLines)):
        f.write(f'{int(110 + idx * 10)} DATA {outLines[idx]}\r')
    f.close()

#******************************************************************************
# main function call for standard script execution
#

if __name__ == "__main__":
    print("LOADER.BAS Builder script")
    # get input paths
    if len(sys.argv) != 3:
        print(f"****Usage: {sys.argv[0]} <in_loader_bin> <out_loader_bas>")
        sys.exit(1)
    loaderin = sys.argv[1]
    loaderout = sys.argv[2]
    GenerateLoader(loaderin, loaderout)

