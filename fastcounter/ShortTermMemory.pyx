cdef int DEFAULT_BUCKET_SIZE = 5

cdef class ShortTermMemory:
    cdef dict counts, key_to_index
    cdef int count_elements, \
        threshold, \
        max_count, \
        _index_offset, \
        bucket_size
    cdef list threshold_elements, sorted_elements, bucket_offsets

    def __init__(self, threshold=2, bucket_size=DEFAULT_BUCKET_SIZE):
        if threshold <= 1:
            raise ValueError("threshold must be bigger than zero")
        self.counts = {}
        self.count_elements = 0
        self.threshold = threshold
        self.threshold_elements = []

        self._index_offset = 0  # serves as dynamic index for key_to_index array that adapts for the index mappings when threshold elements are removed

        self.bucket_size = bucket_size
        self.key_to_index = {}
        self.sorted_elements = []

        self.bucket_offsets = [0, 0]

        self.max_count = 1

    cpdef get_bucket_offset(self, index):
        return self.bucket_offsets[index]

    cpdef shift_bucket_offsets(self, offset):
        for i in range(len(self.bucket_offsets)):
            self.bucket_offsets[i] += offset

    cpdef update(self, keys):
        for key in keys:
            if key in self.counts:
                self.update_sorted_element(key)
            else:
                self.append_sorted_element(key)

    cpdef set_count(self, key, value):
        # TODO make more efficient
        self.update([key] * value)

    cpdef update_sorted_element(self, key):
        self.counts[key] += 1
        current_count = self.counts[key]

        if current_count == self.threshold:
            self.threshold_elements.append(key)

        bucket_id = self.get_bucket_for_count(current_count)
        if self.is_new_bucket(current_count):
            self.update_sorting_index(key, bucket_id)  # current_count)

        if bucket_id > self.max_count:
            self.max_count = bucket_id

    cpdef is_new_bucket(self, count):
        div, mod = divmod(count, self.bucket_size)
        return mod == 0

    cpdef get_bucket_for_count(self, count):
        div, mod = divmod(count, self.bucket_size)
        if self.bucket_size == 1:
            return div
        else:
            return div + 1

    def _get_sorted_elements(self):
        return [el for el in self.sorted_elements]

    def _get_key_to_index(self):
        return self.key_to_index

    cpdef set_bucket_offset(self, index, offset):
        if offset < 0:
            raise ValueError("offset cannot be negative")
        self.bucket_offsets[index] = offset

    cpdef append_sorted_element(self, key):
        self.count_elements += 1
        self.counts[key] = 1

        self.sorted_elements.append(key)

        self.key_to_index[key] = self.count_elements - 1 + self._index_offset
        self.set_bucket_offset(0, self.count_elements - 1)
        self.set_bucket_offset(1, self.count_elements - 1)

    cpdef add_bucket(self, key):
        self.bucket_offsets.append(0)

        index = self.get_index_for_key(key)
        # move element to new position
        swap_index = 0
        swap_key = self.sorted_elements[swap_index]

        self.swap_elements(index, swap_index, key, swap_key)

    # TODO replace count with bucket_id
    cpdef update_sorting_index(self, key, bucket_id):
        if bucket_id > self.max_count:
            self.add_bucket(key)
        else:
            index = self.get_index_for_key(key)
            swap_index = self.get_bucket_offset(bucket_id) + 1  # last index in current bucket
            swap_key = self.sorted_elements[swap_index]  # element before next bucket

            if swap_index < 0 or index < 0:
                raise ValueError("index cannot be negative")
            self.swap_elements(index, swap_index, key, swap_key)

            self.set_bucket_offset(bucket_id, max(0, self.get_bucket_offset(bucket_id) + 1))

    cpdef swap_elements(self, index, swap_index, key, swap_key):
        self.sorted_elements[index], self.sorted_elements[swap_index] = self.sorted_elements[swap_index], \
                                                                        self.sorted_elements[index]
        self.key_to_index[key] = swap_index + self._index_offset
        self.key_to_index[swap_key] = index + self._index_offset

    cpdef get_threshold_elements(self):
        return [(key, self.counts[key]) for key in self.threshold_elements]

    cpdef most_common(self, k):
        return [(key, self.counts[key]) for key in self.sorted_elements[:k]]

    cpdef least_common(self, k):
        return [(key, self.counts[key]) for key in self.sorted_elements[-k:]]

    cpdef set_max_bucket_offset(self, max_offset):
        if max_offset < 0:
            raise ValueError("offset cannot be negative")
        for index, offset in enumerate(self.bucket_offsets):
            if offset > max_offset:
                self.bucket_offsets[index] = max_offset
            else:
                break

    cpdef remove_least_common(self, k):
        elements = self.least_common(k)
        for el, count in elements:
            del self.counts[el]
            del self.key_to_index[el]

        k = len(elements)
        self.count_elements -= k

        self.sorted_elements = self.sorted_elements[:-k]
        self.set_max_bucket_offset(max(self.count_elements - 1, 0))

    cpdef get_elements_in_bucket(self, bucket_id):
        bucket_size = self.get_bucketsize(bucket_id)
        if bucket_size > 0:
            offset = self.get_bucket_offset(bucket_id)
            return self.sorted_elements[offset - bucket_size + 1:offset + 1]
        else:
            return []

    cpdef get_index_for_key(self, key):
        return self.key_to_index[key] - self._index_offset

    cpdef remove_bucket(self, bucket_id):
        self.bucket_offsets.pop(bucket_id)

    cpdef get_bucketsize(self, bucket_id):
        if bucket_id >= len(self.bucket_offsets):
            return 0

        if bucket_id == len(self.bucket_offsets) - 1:
            return self.get_bucket_offset(bucket_id) + 1

        next_bucket = bucket_id + 1
        return self.get_bucket_offset(bucket_id) - self.get_bucket_offset(next_bucket)

    cpdef invalidate_bucket(self, bucket_id):
        self.bucket_offsets[bucket_id] = -100

    cpdef remove_threshold_elements(self):
        elements = self.threshold_elements

        k = len(elements)
        self.remove_most_common(k)
        self.threshold_elements = []

    cpdef delete_negative_buckets(self):
        count_delete_indices = 0
        for i in range(len(self.bucket_offsets)):
            index = len(self.bucket_offsets) - i - 1
            offset = self.bucket_offsets[index]

            if offset < 0:
                count_delete_indices += 1
            else:
                break
        if count_delete_indices > 0:
            self.bucket_offsets = self.bucket_offsets[:- count_delete_indices]

        if len(self.bucket_offsets) < 2:
            self.bucket_offsets = [0, 0]

    cpdef remove_most_common(self, k):
        for i in range(k):
            element = self.sorted_elements[i]
            del self.counts[element]
            del self.key_to_index[element]

        self.count_elements -= k
        self.sorted_elements = self.sorted_elements[k:]
        self.shift_bucket_offsets(-k)
        self.delete_negative_buckets()

        self._index_offset += k
        if len(self.sorted_elements):
            self.max_count = self.get_bucket_for_count(self.counts[self.sorted_elements[0]])
        else:
            self.max_count = 1

    def __len__(self):
        return self.count_elements
