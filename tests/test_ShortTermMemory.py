import unittest
from fastcounter.ShortTermMemory import ShortTermMemory


class TestShortTermMemory(unittest.TestCase):

    def test_init_len(self):
        counter = ShortTermMemory(2, 1)
        self.assertEqual(len(counter), 0)

    def test_threshold_elements(self):
        counter = ShortTermMemory(2, 1)

        counter.update([1, 2, 2, 2, 3, 3, 3, 3])
        self.assertEqual(counter.get_threshold_elements(), [(2, 3), (3, 4)])

    def test_leastCommonElements(self):
        counter = ShortTermMemory(2, 1)
        counter.update([1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 4, 4, 4])
        self.assertEqual(counter.least_common(1), [(3, 1)])
        self.assertEqual(counter.least_common(2), [(4, 3), (3, 1)])

    def test_sortedElemens(self):
        counter = ShortTermMemory(2, 1)

        counter.update([1, 2, 3, 4])
        self.assertEqual(counter._get_sorted_elements(), [1, 2, 3, 4])
        counter.update([3, 3, 3])
        self.assertEqual(counter._get_sorted_elements(), [3, 2, 1, 4])

        counter.update([4, 4])
        self.assertEqual(counter._get_sorted_elements(), [3, 4, 1, 2])

        counter.update([4])
        self.assertEqual(counter._get_sorted_elements(), [3, 4, 1, 2])

    def test_sortedelements2(self):
        counter = ShortTermMemory(2, 1)

        counter.update([1, 1, 1, 1, 1])
        counter.update([2, 3, 2])

        self.assertEqual(counter._get_sorted_elements(), [1, 2, 3])

    def test_bucketSizes(self):
        counter = ShortTermMemory(2, 1)

        counter.update([1, 2])
        self.assertEqual(counter.get_bucketsize(0), 0)
        self.assertEqual(counter.get_bucketsize(1), 2)
        self.assertEqual(counter.get_bucketsize(2), 0)

        counter.update([1])
        self.assertEqual(counter.get_bucketsize(1), 1)
        self.assertEqual(counter.get_bucketsize(2), 1)
        counter.update([2])
        self.assertEqual(counter.get_bucketsize(1), 0)
        self.assertEqual(counter.get_bucketsize(2), 2)
        counter.update([3])
        self.assertEqual(counter.get_bucketsize(1), 1)
        self.assertEqual(counter.get_bucketsize(2), 2)

    def test_removeThreshold_elements(self):
        counter = ShortTermMemory(2, 1)

        counter.update([1, 2, 3])
        counter.update([1])

        self.assertEqual(counter.get_threshold_elements(), [(1, 2)])
        counter.remove_threshold_elements()
        self.assertEqual(counter._get_sorted_elements(), [2, 3])
        self.assertEqual(counter.get_index_for_key(2), 0)
        self.assertEqual(counter.get_index_for_key(3), 1)

        counter.update([3, 3, 3, 3, 3, 3])
        self.assertEqual(counter._get_key_to_index(), {3: 1, 2: 2})
        counter.update([10, 10, 10, 10, 12, 12, 12, 13, 13, 1, 13, 13, 13])

    def test_bucketSize2(self):
        counter = ShortTermMemory(2, 2)

        counter.update([1, 2, 3])
        self.assertEqual(counter._get_sorted_elements(), [1, 2, 3])
        self.assertEqual(counter.get_elements_in_bucket(0), [])
        self.assertEqual(counter.get_elements_in_bucket(1), [1, 2, 3])

        counter.update([1, 2, 3])
        self.assertEqual(counter._get_sorted_elements(), [1, 2, 3])
        self.assertEqual(counter.get_elements_in_bucket(0), [])
        self.assertEqual(counter.get_elements_in_bucket(1), [])
        self.assertEqual(counter.get_elements_in_bucket(2), [1, 2, 3])
        counter.update([1, 1, 1, 1])
        self.assertEqual(counter._get_sorted_elements(), [1, 2, 3])
        self.assertEqual(counter.get_elements_in_bucket(0), [])
        self.assertEqual(counter.get_elements_in_bucket(1), [])
        self.assertEqual(counter.get_elements_in_bucket(2), [2, 3])
        self.assertEqual(counter.get_elements_in_bucket(4), [1])

        self.assertEqual(counter._get_sorted_elements(), [1, 2, 3])

    def test_updateSortingWithBucketSize2(self):
        counter = ShortTermMemory(2, 2)
        counter.update([1, 2, 2, 2, 2, 2])
        self.assertEqual(counter.get_elements_in_bucket(1), [1])
        self.assertEqual(counter.get_elements_in_bucket(3), [2])
        counter.remove_threshold_elements()
        self.assertEqual(len(counter), 1)
        self.assertEqual(counter.get_elements_in_bucket(1), [1])
        self.assertEqual(counter.get_elements_in_bucket(2), [])

        counter.remove_least_common(1)
        self.assertEqual(counter.get_elements_in_bucket(1), [])
        self.assertEqual(counter.get_elements_in_bucket(2), [])

        counter.update([1, 2, 2, 2, 2, 2])
        self.assertEqual(counter.get_elements_in_bucket(1), [1])
        self.assertEqual(counter.get_elements_in_bucket(3), [2])
