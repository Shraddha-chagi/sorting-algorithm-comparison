def insertion_sort(arr):
    """Sort a list using the Insertion Sort algorithm."""
    arr = arr.copy()
    for i in range(1, len(arr)):
        key = arr[i]
        j = i - 1
        while j >= 0 and arr[j] > key:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key
    return arr
if __name__ == "__main__":
    test_data = [5, 2, 8, 1, 3]
    print("Original:", test_data)
    print("Sorted:", insertion_sort(test_data))