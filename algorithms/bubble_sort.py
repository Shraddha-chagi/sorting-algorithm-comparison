def bubble_sort(arr):
    """Sort a list using the Bubble Sort algorithm."""
    arr = arr.copy()
    n = len(arr)
    for i in range(n):
        swapped = False
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                swapped = True
        if not swapped:
            break
    return arr
if __name__ == "__main__":
    test_data = [5, 2, 8, 1, 3]
    print("Original:", test_data)
    print("Sorted:", bubble_sort(test_data))