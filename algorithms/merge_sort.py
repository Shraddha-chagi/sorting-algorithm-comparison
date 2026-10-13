def merge_sort(arr):
    """Sort a list using the Merge Sort algorithm."""
    if len(arr) <= 1:
        return arr.copy()
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    return merge(left, right)
def merge(left, right):
    """Merge two sorted lists into one sorted list."""
    result = []
    i = 0
    j = 0
    while i < len(left) and j < len(right):
        if left[i] <= right[j]:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result.extend(left[i:])
    result.extend(right[j:])
    return result
if __name__ == "__main__":
    test_data = [5, 2, 8, 1, 3]
    print("Original:", test_data)
    print("Sorted:", merge_sort(test_data))