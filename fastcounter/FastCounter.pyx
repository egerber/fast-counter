import logging
from fastcounter.ShortTermMemory import ShortTermMemory
from collections import Counter

logging.basicConfig(filename='memory.log', level=logging.DEBUG)

DEFAULT_CONSOLIDATION_THRESHOLD = 5  # How often does the pattern need to be detected in order to be placed into Long Term Memory
DEFAULT_BUCKET_SIZE = 5
DEFAULT_CONSOLIDATION_FREQUENCY = 1000

DEBUG = False

# TODO set upper limit for number of items in long term memory

cdef class FastCounter:
    cdef object stm, counter
    cdef int _iterations
    cdef int _consolidation_frequency
    cdef int deletions
    cdef int threshold

    def __init__(self,
                 int consolidation_frequency=DEFAULT_CONSOLIDATION_FREQUENCY,
                 int consolidation_threshold=DEFAULT_CONSOLIDATION_THRESHOLD,
                 bucket_size=DEFAULT_BUCKET_SIZE):

        self.counter = Counter()
        self.stm = ShortTermMemory(threshold=consolidation_threshold,
                                   bucket_size=bucket_size)  #behaves like collections.Counter object
        self.deletions = 0

        self._consolidation_frequency = consolidation_frequency
        self._iterations = 0

    def update(self, elements):
        for element in elements:
            # check first if it is already consolidated
            if element in self.counter:
                self.counter.update([element])
            else:
                self.stm.update([element])
            self._iterations += 1
            if self._iterations % self._consolidation_frequency == 0:
                self._consolidate()

    #TODO derive from collections.counter
    def most_common(self, k):
        return self.counter.most_common(k)

    #TODO derive from collections.counter
    def elements(self):
        return self.counter.elements()

    def _remove_elements(self, count):
        self.deletions += count
        self.stm.remove_least_common(count)

    def _consolidate(self):
        threshold_elements = self.stm.get_threshold_elements()

        for element, count in threshold_elements:
            self.counter[element] = count
        self.stm.remove_threshold_elements()

    def __len__(self):
        return len(self.counter)
