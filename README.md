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

## Stage 1

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

## Stage 2

In this stage, you will abstract the operators of the PH type so that they can manipulate min-PHs, max-PHs, and generally PHs based on any ordering relation between the values stored in nodes.

* Since the ordering criterion is only used in the `merge` function, you will define a more general function `merge-f` that compares the roots of two PHs according to a criterion passed as a parameter. From this function, you will derive particular types of merge:
  * `merge-max` - for max-PHs
  * `merge-min` - for min-PHs
  * other variants of `merge` explicitly requested in the assignment or in helper functions for other functions

* Since the `merge` function is called directly or indirectly by other operators of the PH type, these will also need to be abstracted - modified to take the type of `merge` as a parameter.

In the following stages, you will use heaps for processing movies. Therefore, in the second part of this stage we define the `movie` structure, which stores information about a film in 5 fields titled `name`, `rating`, `genre`, `duration`, `others`. The file `tutorial.rkt` will provide examples of defining and manipulating structures.

You will then implement a series of functions dedicated to movies:

* `(lst->movie lst)` - constructor of the `movie` structure that takes as parameter a list with 5 values, not 5 separate values
* `(mark-as-seen m)` - adds the information 'seen' at the beginning of the (list) `others` field of the movie `m`
* `(mark-as-seen-from-list movies seen)` - in the list of movies `movies`, marks as seen the movies from the list of names `seen`
  * Example:
    ```racket
    (mark-as-seen-from-list
      (list (make-movie 'a 9.3 'drama '(2 12) '())
            (make-movie 'b 8.2 'comedy '(1 56) '(feel-good))
            (make-movie 'c 8.8 'drama '(1 44) '(old))
            (make-movie 'd 8.0 'thriller '(2 25) '())
            (make-movie 'e 8.1 'action '(2 19) '(sequel)))
      '(a c))
    ```
    * This adds the information 'seen' in the `others` field of movies 'a' and 'c' ⇒
    ```racket
    '((movie 'a 9.3 'drama '(2 12) '(seen))
      (movie 'b 8.2 'comedy '(1 56) '(feel-good))
      (movie 'c 8.8 'drama '(1 44) '(seen old))
      (movie 'd 8.0 'thriller '(2 25) '())
      (movie 'e 8.1 'action '(2 19) '(sequel)))
    ```

* `(extract-seen movies)` - extracts the names of seen movies from the list of movies `movies`
  * Example:
    ```racket
    (extract-seen
      (list (make-movie 'a 9.3 'drama '(2 12) '(seen))
            (make-movie 'b 8.2 'comedy '(1 56) '(feel-good))
            (make-movie 'c 8.8 'drama '(1 44) '(legal seen old))
            (make-movie 'd 8.0 'thriller '(2 25) '())
            (make-movie 'e 8.1 'action '(2 19) '(sequel))))
    ```
    * ⇒ '(a c) (note that it returns a list of names, not a list of movies)
    * Note that the 'seen' information can appear at any position in the `others` field

* `(rating-stats movies)` - calculates a pair with the average rating of seen movies and of unwatched movies (by convention, if there are no movies of a certain type, the average rating of those is 0)
  * Example:
    ```racket
    (rating-stats
      (list (make-movie 'a 9.3 'drama '(2 12) '(seen))
            (make-movie 'b 8.2 'comedy '(1 56) '(feel-good))
            (make-movie 'c 8.8 'drama '(1 44) '(legal seen old))
            (make-movie 'd 8.0 'thriller '(2 25) '())
            (make-movie 'e 8.1 'action '(2 19) '(sequel))))
    ```
    * ⇒ '(9.05 . 8.1) (note that the result is a pair with a dot, not a list)

* `(extract-name-rating movies)` - transforms a list of movies into a list of pairs between the name and rating of the movie, discarding the other information
  * Example:
    ```racket
    (extract-name-rating
      (list (make-movie 'a 9.3 'drama '(2 12) '(seen))
            (make-movie 'b 8.2 'comedy '(1 56) '(feel-good))
            (make-movie 'c 8.8 'drama '(1 44) '(legal seen old))
            (make-movie 'd 8.0 'thriller '(2 25) '())
            (make-movie 'e 8.1 'action '(2 19) '(sequel))))
    ```
    * ⇒ '((a . 9.3) (b . 8.2) (c . 8.8) (d . 8.0) (e . 8.1))

* `(make-rating-ph movies)` - constructs a max-PH containing name-rating pairs corresponding to the movies in the list `movies`, ordered by rating
  * The order of inserting values into the PH is from right to left
  * Example:
    ```racket
    (make-rating-ph
      (list (make-movie 'a 9.3 'drama '(2 12) '(seen))
            (make-movie 'b 8.2 'comedy '(1 56) '(feel-good))
            (make-movie 'c 8.8 'drama '(1 44) '(legal seen old))
            (make-movie 'd 8.0 'thriller '(2 25) '())
            (make-movie 'e 8.1 'action '(2 19) '(sequel))))
    ```
    * 'e is inserted ⇒ '((e . 8.1))
    * 'd is inserted, which becomes 'e's child because it has a lower rating ⇒ '((e . 8.1) ((d . 8.0)))
    * 'c is inserted, which becomes 'e's parent because it has a higher rating ⇒ '((c . 8.8) ((e . 8.1) ((d . 8.0))))
    * 'b is inserted, which becomes 'c's child because it has a lower rating ⇒ '((c . 8.8) ((b . 8.2)) ((e . 8.1) ((d . 8.0))))
    * 'a is inserted, which becomes 'c's parent because it has a higher rating ⇒ '((a . 9.3) ((c . 8.8) ((b . 8.2)) ((e . 8.1) ((d . 8.0)))))

* `(before? a b L)` - returns true if and only if a = b or a appears before b in list L
  * It is not necessary for a and b to appear in list L
  * If only a appears, the result is true
  * If only b appears or neither appears (and they are not equal), the result is false

* `(make-genre-ph movies genres)` - constructs a PH containing movies from the list `movies`, ordered by preferences expressed in the list of genres `genres` - the genre of a child node cannot appear before the genre of the parent node in the list `genres`
  * As usual, insertion is done from right to left
  * Example:
    ```racket
    (make-genre-ph
      (list (make-movie 'a 9.3 'drama '(2 12) '(seen))
            (make-movie 'b 8.2 'comedy '(1 56) '(feel-good))
            (make-movie 'c 8.8 'drama '(1 44) '(legal seen old))
            (make-movie 'd 8.0 'thriller '(2 25) '())
            (make-movie 'e 8.1 'action '(2 19) '(sequel)))
      '(drama comedy action))
    ```
    * 'e is inserted
    * 'd is inserted, which becomes 'e's child since 'action' appears in the preference list but 'thriller' does not
    * 'c is inserted, which becomes 'e's parent since 'drama' precedes 'action'
    * 'b is inserted, which becomes 'c's child since 'drama' precedes 'comedy'
    * 'a is inserted, which becomes 'c's child since the insertion is a merge between the previous result and the new value, and for equal values (both films have the genre 'drama'), the `before?` function returns true, preferring the first root (the same principle used by the `merge` function)
    * ⇒ 
    ```racket
    (list (movie 'c 8.8 'drama '(1 44) '(legal seen old))
          (list (movie 'a 9.3 'drama '(2 12) '(seen)))
          (list (movie 'b 8.2 'comedy '(1 56) '(feel-good)))
          (list (movie 'e 8.1 'action '(2 19) '(sequel))
                (list (movie 'd 8.0 'thriller '(2 25) '()))))
    ```

The exercises highlight the fact that, in functional programming, functions are first-class values. The purpose of this stage is to consolidate knowledge related to:

* functionals (some tasks require working with functionals instead of using explicit recursion)
* anonymous functions (although you have freedom regarding their use, we recommend using anonymous functions as parameters for functionals when those functions are not needed elsewhere)
* curry and uncurry functions (you will use the currying mechanism to easily derive various types of merge from a more general function)

### Point Deductions for Not Meeting Requirements

The scale of possible point deductions in stage 2 is:
* -5p*n: where n = the number of functions among `merge-max`, `merge-min`, `merge-max-rating` that are not defined point-free by partial application of `merge-f`
* -10p*n: where n = the number of functions among `lst->movie`, `mark-as-seen-from-list`, `extract-seen`, `rating-stats`, `extract-name-rating`, `before?` solved without using functionals (according to requirements) instead of explicit recursion

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
