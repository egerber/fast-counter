import unittest
from fastcounter.FastCounter import FastCounter
import random
from collections import Counter

NUM_ITERATIONS_COMPARISON = 5


class TestShortTermMemory(unittest.TestCase):

    def test_init_len(self):
        counter = FastCounter()
        self.assertEqual(len(counter), 0)

    # check if fastcounter behaves the same as collections.counter with threshold 1
    # TODO allow threshold 1 and try identity with most_common(MAX_RANDOM)
    def test_identitiy_counter(self):
        random.seed(2)
        for iteration in range(NUM_ITERATIONS_COMPARISON):
            counter1 = FastCounter(consolidation_frequency=1,
                                   consolidation_threshold=2,
                                   bucket_size=1)
            counter2 = Counter()
            MAX_RANDOM = 100
            random_list = [random.randint(1, MAX_RANDOM) for i in range(1000)]

            counter1.update(random_list)
            counter2.update(random_list)

            self.assertCountEqual(counter1.most_common(1), counter2.most_common(1))

    def test_correct_counting1(self):
        counter = FastCounter(consolidation_frequency=1,
                              consolidation_threshold=2,
                              bucket_size=20)

        counter.update([1, 1, 1, 1, 1, 2, 2, 2, 2, 2])
        self.assertEqual(counter.most_common(2), [(1, 5), (2, 5)])

    def test_correct_counting2(self):
        counter = FastCounter(consolidation_frequency=1,
                              consolidation_threshold=6,
                              bucket_size=20)

        counter.update([1, 1, 1, 1, 1, 2, 2, 2, 2, 2])
        self.assertEqual(counter.most_common(2), [])

    def test_max_items_shortterm_memory(self):
        counter = FastCounter(consolidation_frequency=1,
                              consolidation_threshold=1000000,
                              bucket_size=1,
                              max_items_shortterm_memory=5)

        counter.update([1, 2, 3, 4, 5])
        self.assertEqual(counter.get_size_shortterm_memory(), 5)
        counter.update([6, 7, 8, 9, 10])
        self.assertEqual(counter.get_size_shortterm_memory(), 5)
