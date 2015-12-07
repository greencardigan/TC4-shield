
# bvwelch 6 mar '11

import sys
import csv
from pylab import *
from numpy import *

f = open('variacinput.txt', 'r') 
variacdata = [ ( row[0], row[1] ) for row in csv.reader(f) ]
f.close

volts = [ int( p[0] ) for p in variacdata ]
adc = [ int( p[1] ) for p in variacdata ]

for i in range(len(volts) - 2):
    m, b = polyfit(adc[i:i+2], volts[i:i+2], 1)
    print "%d,%g,%g" % (adc[i], m, b)
    x = range(adc[i], adc[i+1])
    y = [ m*i + b for i in x ]
    plot(x,y)

plot(adc, volts)
show()

