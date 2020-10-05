#FastCounter

## Introdcution
FastCounter is a library that assimilates the behavior of <code>collections.Counter</code> but introduces features for counting very large sets of data, where only high frequent elements need to be received. FastCounter is comparatively fast, because it is implemented in Cython. FastCounter implements a specific datastructure
that allows keeping ordered frequency lists in a performant manner, especially for extreme distributions. 

FastCounter behaves very similar to a Cache with a Least-Frequently-Used approach. It keeps/counts only those elements, which occur very frequently. The threshold for this minimum frequency can be specified
In terms of the interface, FastCounter works just like <code>collections.Counter</code>
## Features
#### Counting in Buckets
FastCounter keeps a map of all elements and their respective count. This map is ordered and must be thereby updated everytime a 
one element "overtakes" another element in the ordered list. This can be a bottleneck in many situations where we don't need the exact
frequency of an element but rather the "order of magnitude". FastCounter allows elements only to move between buckets of a specific size (e.g. </code>[0,100],[101,200],[201,300],...</code>). This results
in less re-ordering steps while counting.

#### Maximum Capacity
We can limit the total number if items that are kept in the "cache" while counting. Thereby we can drastically limit
the memory space that is used.

## Examples
FastCounter is initialized with the arguments <code>threshold</code> and <code>bucket_size</code>. The former specifies, 
### Example 1: N-Grams
Counting the most frequent N-Grams can be very expensive in terms of memory use. This bottleneck becomes obvious when
trying to compute 5-Grams, 6-Grams,...Suddenly the amount of required memory explodes way beyond the capacity of our computer. 
FastCounter circumvents this problem by counting only those 5- or 6-Grams that occur more often than a fixed number of times (estimated). 
Therefore we can still extract all those meaningful 5-Grams and 6-Grams that occur relatively frequent.

## Installation
FastCounter can be installed by running <code>pip install fast-counter</code>

Inside your code, you can use fast-counter with the following line: <code>from fastcounter.FastCounter import FastCounter</code>

afterwards we can initialize the Counter by

## TODO
-[ ] create interface for fastCounter instance
-[ ] mention short-term memory
-[ ] Make non-consolidated items available for most_common call


<pre>
<code>from fastcounter.FastCounter import FastCounter</code>

memory=Memory()
memory(elements)

#returns collections.Counter
counter=memory.getCounter()

#retrieves the frequencies of 100 most frequent elements
counter.most_common(100)

for element in list:
    memory.update[element]    
</pre>


