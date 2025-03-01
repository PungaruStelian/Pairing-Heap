# A Pairing Max-Heap in Racket

In this first assignment, you will implement a **pairing max-heap** in Racket, which is an efficient tree data structure.

## Objectives
* Becoming familiar with the structure and representation of pairing heaps (PH) in Racket
* Implementing a pairing max-heap and its common operations
* Practicing stack and tail recursion concepts in Racket

## Structure and Representation

A **pairing heap** (abbreviated PH) is an n-ary tree that respects the heap property and efficiently implements the following operations:
* insertion into the heap
* deletion of the root (causing heap restructuring)
* merging two heaps

The heap property refers to maintaining an ordering relation between any parent node and its children:
* in a min-heap, the parent's value is less than or equal to the values of its children
* in a max-heap, the parent's value is greater than or equal to the values of its children

We will represent a pairing heap as a list:
* empty, if the heap contains no elements
* `(root child_1 child_2 ... child_n)`, otherwise, where each child is also a PH

## Operations to Implement

### Constructors and Operators (15p)
* `empty-ph`: the empty PH
* `(val->ph val)`: creates a PH that is a single node with the value val
* `(ph-empty? ph)`: checks if a PH is empty
* `(ph-root ph)`: returns the value in the root or `false` if the PH is empty
* `(ph-subtrees ph)`: returns the list of children of the root or `false` if the PH is empty

### Merge (15p)
* `(merge ph1 ph2)`: merges the PHs ph1 and ph2
  * union(empty, anything) = anything
  * otherwise, the PH with the smaller root becomes the first child of the one with the larger root

Example:
```racket
(merge '(8 (2) (5) (7 (3)))
       '(12 (6) (11 (8) (10 (4) (1) (2)))))
```
Since 12 > 8, the first tree becomes the leftmost child of the second:
```racket
'(12 (8 (2) (5) (7 (3))) (6) (11 (8) (10 (4) (1) (2))))
```

### Insertion (10p)
* `(ph-insert val ph)`: inserts the value val into the PH ph
  * insertion is a merge between ph and a PH that contains only the value val

### Construction from List (10p)
* `(list->ph lst)`: inserts all values from the list lst, from right to left, into an empty PH
  * Use stack recursion

Example:
```racket
(list->ph '(2 5 8 7 3))
```
1. insert 3 into empty ⇒ '(3)
2. insert 7 into result ⇒ '(7 (3))
3. insert 8 into result ⇒ '(8 (7 (3)))
4. insert 5 into result ⇒ '(8 (5) (7 (3)))
5. insert 2 into result ⇒ '(8 (2) (5) (7 (3)))

### Two-pass Merge Left-to-Right (20p)
* `(two-pass-merge-LR phs)`: merges all PHs in the list phs, according to a 2-step protocol
  * Use tail recursion

Example:
```racket
(two-pass-merge-LR '((8 (2))   
                     (12)
                     (14 (11 (8)))   
                     (5 (4))   
                     (11 (10 (9)))))
```
1. Merge the PHs two by two, from left to right:
   * '(12 (8 (2)))
   * '(14 (5 (4)) (11 (8)))
   * '(11 (10 (9))) (the last value remains as is)
2. Merge the results, from left to right:
   * '(14 (12 (8 (2))) (5 (4)) (11 (8))) 
   * '(14 (11 (10 (9))) (12 (8 (2))) (5 (4)) (11 (8)))

### Two-pass Merge Right-to-Left (20p)
* `(two-pass-merge-RL phs)`: same as above, but both steps are performed from right to left
  * Use stack recursion

Example:
```racket
(two-pass-merge-RL '((8 (2))   
                     (12)   
                     (14 (11 (8)))   
                     (5 (4))   
                     (11 (10 (9)))))
```
1. Merge the PHs two by two, from right to left:
   * '(8 (2)) (the first value remains as is)
   * '(14 (12) (11 (8)))
   * '(11 (5 (4)) (10 (9)))
2. Merge the results, from right to left:
   * '(14 (11 (5 (4)) (10 (9))) (12) (11 (8))) 
   * '(14 (8 (2)) (11 (5 (4)) (10 (9))) (12) (11 (8)))

### Tournament Merge (20p)
* `(tournament-merge phs)`: "knock-out" type merge - the first step of two-pass-merge-LR is performed on the list phs, then again on the resulting list, and so on until only one PH remains

Example:
```racket
(tournament-merge '((8 (2))   
                    (12)   
                    (14 (11 (8)))   
                    (5 (4))   
                    (11 (10 (9)))))
```
1. Merge the PHs two by two, from left to right:
   * '(12 (8 (2)))
   * '(14 (5 (4)) (11 (8)))
   * '(11 (10 (9)))
2. Merge the results two by two, from left to right:
   * '(14 (12 (8 (2))) (5 (4)) (11 (8)))
   * '(11 (10 (9)))
3. Merge the results two by two, from left to right:
   * '(14 (11 (10 (9))) (12 (8 (2))) (5 (4)) (11 (8)))

### Deletion of the Root (10p)
* `(ph-del-root ph)`: returns the PH obtained after deleting the root of ph
  * the children of the deleted node are merged using two-pass-merge-LR
  * returns `false` if the PH is empty

## Notes

1. You must respect the recursion type requirements:
   * Stack recursion for `list->ph` and `two-pass-merge-RL`
   * Tail recursion for `two-pass-merge-LR`

2. Use the PH interface (constructors and operators), not equivalent list functions.

3. You can define helper functions if needed. The same recursion type restrictions apply to them.

## Testing

The `checker.rkt` file contains tests for each function. Run it to check the correctness of your implementation.
## Additional Resources

* [Racket Documentation](https://docs.racket-lang.org/)
* [Pairing Heaps - Description](https://en.wikipedia.org/wiki/Pairing_heap)
* [Racket Lab - Data Structures](https://ocw.cs.pub.ro/courses/pp/25/laboratoare/racket/structuri-de-date)
