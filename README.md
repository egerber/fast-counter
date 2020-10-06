# FastCounter

## Introdcution
FastCounter is a library that assimilates the behavior of <code>collections.Counter</code> but introduces 
features for counting very large sets of data, where only high frequent elements need to be kept in memory. FastCounter is comparatively fast, because it is implemented in Cython. FastCounter implements a specific datastructure
that allows keeping ordered frequency lists in a performant manner, especially for extreme distributions. It allows to count elements from large datasets by 
making use of the concept of short-term-memories, that forget infrequent items and consolidate only those items that reach
a certain threshold.

FastCounter behaves very similar to a Cache with a Least-Frequently-Used approach. It keeps/counts only those elements, which occur very frequently. The threshold for this minimum frequency can be specified
In terms of the interface, FastCounter works just like <code>collections.Counter</code>

## Features
#### Counting in Buckets
FastCounter keeps a map of all elements and their respective count. This map is ordered and must be thereby updated everytime a 
one element "overtakes" another element in the ordered list. This can be a bottleneck in many situations where we don't need the exact
frequency of an element but rather the "order of magnitude". FastCounter allows elements only to move between buckets of a specific size (e.g. </code>[0,100],[101,200],[201,300],...</code>). This results
in less re-ordering steps while counting.

#### Specifying threshold
You can customize the number of times an element has to occur over a period in order to consolidate it an keep counting it. At the same time, elements inside the shortterm memory compete against each other. This leads to less memoryuse.

#### Maximum Size for Shortterm memory
in order to avoid blowing up the memory for large datasets, you can specify the parameter <code>max_items_shortterm_memory</code> which limits the number of 
in memory items for the short-term memory without affecting the number of items in the global "long-term-memory".

## Examples
Counting the most frequent N-Grams can be very expensive in terms of memory use. This bottleneck becomes obvious when
trying to compute 5-Grams, 6-Grams,...Suddenly the amount of required memory explodes way beyond the capacity of our computer. 
FastCounter circumvents this problem by counting only those 5- or 6-Grams that occur more often than a fixed number of times (estimated). 
Therefore we can still extract all those meaningful 5-Grams and 6-Grams that occur relatively frequent.

## Installation
FastCounter can be installed by cloning this repository and running <code>pip install .</code> (relase as pip package is still in progress)

## Use
Inside your code, you can use fast-counter with the following line

<code>from fastcounter import FastCounter</code>

FastCounter is initialized with the arguments 

- <code>consolidation_frequency</code>
- <code>bucket_size</code>
- <code>consolidation_threshold</code>
- <code>max_items_shortterm_memory</code>

<pre>
from fastcounter import FastCounter

counter = FastCounter(consolidation_frequency=100,
                                   consolidation_threshold=10,
                                   bucket_size=50,
                                   max_items_shortterm_memory=100000)
elements=[1,2,3,4,5,1,1,2]

counter.update(elements)
counter.most_common(10)

...
</pre>

