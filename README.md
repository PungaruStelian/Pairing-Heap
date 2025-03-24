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

### Notes

1. You must respect the recursion type requirements:
   * Stack recursion for `list->ph` and `two-pass-merge-RL`
   * Tail recursion for `two-pass-merge-LR`

2. Use the PH interface (constructors and operators), not equivalent list functions.

3. You can define helper functions if needed. The same recursion type restrictions apply to them.

## Stage 3

In this stage, you will implement two applications of priority heaps:
- Extracting the first k elements from a list according to a specific sorting criterion
- Merging values contained in multiple PHs

Specifically, you will implement specialized versions of these two applications dedicated to movies, as defined in stage 2. Note that at the beginning of the stage3.rkt file, there is a line (require "etapa2.rkt") indicating that it will be necessary to resolve stage 2 in the same folder where you solved stage 3, to benefit from previously implemented functions.

Important considerations for implementation and expression binding:
- Use `let` or `let*` to avoid duplicate calculations
- Use `named let` for ad-hoc implementation of recursive processes without helper functions

You need to implement the following functions:

### `best-k`
A function that takes a comparison criterion op, a list of movies, and a number k, in an order and grouping defined by you (the function's antetypes are not specified), and determines the first k movies from the movies list according to the op criterion.
- The result should be obtained using a PH built based on the movies list and op criterion
- Initialize an empty PH, insert the final result after k successive extractions
- The best-k function is not checked by the checker, but should provide the foundation for the best-k-rating and best-k-duration functions, which are checked

### `best-k-rating`
Determines the best k movies from a list, from the perspective of their rating.

Example:
```racket
(best-k-rating
 (list (make-movie 'a 9.3 'drama '(2 12) '(seen))
       (make-movie 'b 8.2 'comedy '(1 56) '(feel good))
       (make-movie 'c 8.8 'drama '(1 44) '(legal seen old))
       (make-movie 'd 8.0 'thriller '(2 25) '())
       (make-movie 'e 8.1 'action '(2 19) '(sequel)))
 4)
```
Returns:
```racket
(list
 (movie 'a 9.3 'drama '(2 12) '(seen))
 (movie 'c 8.8 'drama '(1 44) '(legal seen old))
 (movie 'b 8.2 'comedy '(1 56) '(feel good))
 (movie 'e 8.1 'action '(2 19) '(sequel)))
```

### `best-k-duration`
Determines the shortest k movies from a list.

Example:
```racket
(best-k-duration
 (list (make-movie 'a 9.3 'drama '(2 12) '(seen))
       (make-movie 'b 8.2 'comedy '(1 56) '(feel good))
       (make-movie 'c 8.8 'drama '(1 44) '(legal seen old))
       (make-movie 'd 8.0 'thriller '(2 25) '())
       (make-movie 'e 8.1 'action '(2 19) '(sequel)))
 3)
```

Returns:
```racket
(list
 (movie 'c 8.8 'drama '(1 44) '(legal seen old))
 (movie 'b 8.2 'comedy '(1 56) '(feel-good))
 (movie 'a 9.3 'drama '(2 12) '(seen)))
```
### `(update-pairs p pairs)`
Delete the pH root of the first pair that satisfies the predicate `

- Each pair of PAIRS contains a movie name and a max-fo rats to the film by various users
- If no ratings are stored for the movie in the targeted pair (the associated pH is VID), then the unchanged `pears list returns
- If no pair satisfies the predicate P, the unchanged PAIRS list returns

Example:
``` Racket
(update-pairs
 (λ (p) #t)
 '((a 10 (9) (10 (8) (9 (7) (9 (8)))))
   (b 10 (9) (6) (8) (9) (8) (7 (7)))
   (c 10 (8) (10 (8) (7) (9) (8) (6)))))
```
- All pairs satisfy the predicate, so the pH root of the first pair will be wiped
- As the pairs have a pH on the second position, ie a list, they do not display as pairs with a point, but as lists that have the first position of the film, and the rest of the list corresponds to the pH

Return:
``` Racket
'((a 10 (9) (8) (9 (7) (9 (8))))      ; here the root was deleted here
  (b 10 (9) (6) (8) (9) (8) (7 (7)))
  (c 10 (8) (10 (8) (7) (9) (8) (6))))
```
### `(Best-K-Iratings-Overall Pairs K)`
Determines the best k reviews (in pairs with the film to which they were awarded), based on a PAIRS list of the type above (pairs (name-film. pH-with-ranges))

- The result is a list of pairs (name-film.
rating) and is obtained by interclaining the pH corresponding to each movie, as follows:
- a new pH with pairs (name-philam. rating) corresponding to the roots of each pH in `peaches is initialized- we will call it the pH of roots
- invariant: the root of the pH of roots corresponds to the best review overall
- at each iteration,
This root is extracted and brought to the pH of roots the next best rating corresponding to the film that has just been extracted (to maintain the invariant)

Example:
``` Racket
(best-k-ratings-overall 
 '((a 10 (9) (10 (8) (9 (7) (9 (8)))))
   (b 10 (9) (6) (8) (9) (8) (7 (7)))
   (c 10 (8) (10 (8) (7) (9) (8) (6))))
 7)
```

-
The pH of roots with pairs' (a. 10), '(b. 10),' (c. 10) ⇒ is initialized
one of them becomes a root, for example '(c. 10)
- Following its extraction '(c. 10), another one is brought (c. 10) instead of it (as there is a rating 10 for the film c) ⇒
We have the same values ​​in the pH of roots, and the new root is, for example,
'(a. 10)
- is extracted '(a. 10), in its place being brought a new' (a. 10), and the new root is' (c. 10)
- is extracted '(c. 10), in its place being brought a' (c. 9), and the new root is' (a. 10)
- is extracted '(a. 10), in its place being brought a' (a. 9), and the new root is' (b. 10)
- is extracted '(b. 10),
in its place being brought a '(b. 9), and the new root is' (a. 9)
- is extracted '(a. 9), in its place being brought a new' (a. 9), and the new root is' (b. 9)
- Extraction of '(b. 9) is the seventh extraction ⇒
'((c. 10) (a. 10) (c. 10) (a. 10) (b. 10) (a. 9) (b. 9))
- Note: Checker-
UL also accepts other correct results (the same rats but in pairs with other movies, as long as the respective pairs match some input reviews)
### Deductions for Not Following Assignment Requirements

Possible point deductions in stage 3:
- `-5p*n`: where n = number of functions between best-k-rating, best-k-duration that are not defined as applications of best-k
- `-20p*n`: where n = number of functions between best-k, update-pairs, best-k-ratings-overall resolved without using named let as required
- `-0p`: We encourage using let and let* to avoid duplicate calculations, even if there are no deductions related to this aspect

## Stage 4

When interested in the `typical` perception of users on a film, the median of rating can be more relevant than the average, especially when the rating list contains extreme values, which can significantly distort the media. As the rating for a movie arrive in continuous flow as the film records new views,
and the value of the median must be updated frequently. Instead of recalculating this value every time the film receives a new review, it can be dynamically maintained, using two pairing heaps:

- a max -ph holding the half of the lowest rating
- a min -ph holding half with the highest rating
- The two pHs must remain balanced: In the most non-balanced case, Max -ph will contain more than Min-Ph
- Each new review involves the insertion of the new rating in the related pH (the one with higher or lower rats, as the case may be) and the rebalancing of the two PHs. To easily implement this process, at a certain time T will correspond to a quartet **(nume-film delta max-ph min-ph)**,
where Delta represents the difference between Max-Ph size and Min-Ph (0 or 1) size
- The median will be:
The average of the roots of the 2 pHs, for the number of reviews,
the root of Max-Ph, for the odd number of reviews

In stage 4 you will implement this algorithm for the Median's dynamic calculation, based on a flow of reviews as a racket flow.

The novelty of the stage consists of working with **flows**:
- Recenziile care intră în sistem sunt modelate ca flux
- The stages of evolution of the median are modeled as flow
- Each new review corresponds to a moment of time t, and for each time T time we will submit a `stage` in the resulting flow - the information about how much the medias were at the time t

You have to implement the following functions:
```racket
(add-rating quad rating) ; receives a type quartet (name-Film Delta Max-Uph Min-Ph) and a rating, and returns updated quartet by inserting the rating in the related pH and rebalancing the pH
```
Ex:
```racket
(Add-Stating '(A 0 (4) (7)) 5)
```
- whereas 5> 4 (rating> root (max -ph)), 4 is inserted in min -ph ⇒
'(A -1 (4) (5 (7)))

- As Delta <0, root (min -ph) is moved to Max-Ph ⇒
'(A 1 (5 (4)) (7))

* `(reviews->quads reviews)` - transforms a flow of reviews (review = pair (name-film. rating)) into a stages flow (stage = quartet list: a quartet for each movie that has received reviews so far)

Ex:
```racket
(reviews->quads (stream '(a . 4) '(b . 1) '(a . 2)))
```
- At first we have no information about any movie

- At time t = 1, we have to add rating 4 for the movie 'a ⇒
A quartet is created for the movie 'A, in which only Max-Ph contains the value 4 ⇒
**'((A (A 1 (4) ())** is the first stage of evolution (a list containing a single quartet)

- At time t = 2, we have to add the 1 rating for the movie 'B ⇒
a quartet is created for the 'B movie, in which only Max-Ph contains the value 1 ⇒
**'((B 1 (1) ()) (A 1 (4) ()))** is the second stage of evolution (a list of two quartets)

- At time t = 3, we have to add the 2 rating for the movie 'a ⇒
The quartet is updated for the movie 'A by adding the rating 2 ⇒
**'((B 1 (1) ()) (A 0 (2) (4)))** is the third stage of evolution

- The result of the call is a flow containing the 3 lists above (the 3 stages)

* `(quads->medians quads)` - transforms a stages flow represented using quartets into a stages flow represented using median

Ex:
```racket
(quads->medians (reviews->quads (stream '(a . 4) '(b . 1) '(a . 2))))
```
- Quartets list **'((A 1 (4) ()))** becomes the list of pairs' **((a. 4))**
(for the movie 'a, the median coincides with the only rating received)

- Quartets list **'((B 1 (1) ()) (A 1 (4) ()))** becomes the list of pairs **'((b. 1) (a. 4))**

- Quartets list **'((B 1 (1) ()) (A 0 (2) (4)))** becomes the list of pairs **'((b. 1) (a. 3))**
(For 'A, the median is the average of the 2 rats, according to the Formula for the HAP RING NUMBER)

- The result of the call is a flow containing the 3 lists of the above pairs

### Deposits generated by non -observance of the statement requirements

The Barem of Possible Deposits in Stage 4 is:

- -20p: If you make conversions from lists in flows or from lists, instead of operating directly with the flow interface (when creating/manipulating flows) and with the lists interface (when creating/manipulating lists)

- -20p: If the quads-> medias function uses explicit recursion or does not use a function on flows

## Testing

The `checker.rkt` file contains tests for each function. Run it to check the correctness of your implementation.
## Additional Resources

* [Racket Documentation](https://docs.racket-lang.org/)
* [Pairing Heaps - Description](https://en.wikipedia.org/wiki/Pairing_heap)
* [Racket Lab - Data Structures](https://ocw.cs.pub.ro/courses/pp/25/laboratoare/racket/structuri-de-date)
