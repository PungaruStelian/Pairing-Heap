#lang racket
(require racket/match)
(provide (all-defined-out))

; ++++ STAGE 1 ++++

;; A pairing heap is an n-ary tree that 
;; respects the heap property and efficiently implements
;; the following operations:
;; - insertion into the heap
;; - deletion of the root (causing heap restructuring)
;; - merging two heaps
;; The heap property refers to maintaining an ordering relation
;; between any parent node and its children:
;; - in a min-heap, the parent's value is less than or 
;;   equal to the values of its children
;; - in a max-heap, the parent's value is greater than or
;;   equal to the values of its children
;; - a heap can be based on other ordering relations as well
;;
;; We will represent a pairing heap (abbreviated PH)
;; as a list:
;; - empty, if the heap contains no elements
;; - (root child_1 child_2 ... child_n), otherwise
;;   - where each child is also a PH
;;
;; In this stage, we implement a max-heap of pairing.

; ++++ STAGE 2 ++++

;; In this stage, we abstract the operators of the PH type so that
;; we can easily derive operations for various variants
;; of PH, depending on the ordering relation on which
;; the heap property is based.
;;  - function directly affected: merge
;;  - indirectly affected functions: functions that call merge,
;;     which will need to receive the type of merge as a parameter
;;
;; Then, we use the PH type to process movies, where a movie
;; is represented as a structure with 5 fields: name, rating, genre, 
;; duration, others.
;; In Racket, there is a simple way to define and manipulate structures,
;; described in the "tutorial.rkt" file.
;;
;; The recommended workflow for stage 2 is:
;; - Copy from stage 1 the functions that remain unchanged
;; - Abstract by ordering relation:
;;  * define the more general merge-f operator which receives, in addition
;;    to merge, a comparator by which elements need to be ordered
;;  * derive from this operator the required merge variants
;;  * modify those functions from stage 1 that call merge, so that
;;    the merge function is a parameter of the function, not an identifier
;;    bound to an external value
;; - Read the tutorial on structures in Racket ("tutorial.rkt" file)
;; - Implement the functions that process movies 

; empty-ph : PH
; out: the empty PH
(define empty-ph '())

; val->ph : T -> PH
; in: a value of any type T
; out: the PH that contains only this value
(define (val->ph T)
    (list T))

; ph-empty? : PH -> Bool
; in: pairing heap ph
; out: true, if ph is empty
;      false, otherwise
(define (ph-empty? ph)
    (null? ph))

; ph-root : PH -> T | Bool
; in: pairing heap ph
; out: false, if ph is empty
;      root(ph), otherwise
(define (ph-root ph)
    (if (ph-empty? ph)
        #f
        (car ph)
    )
)

; ph-subtrees : PH -> [PH] | Bool
; in: pairing heap ph
; out: false, if ph is empty
;      children(ph), otherwise
(define (ph-subtrees ph)
    (if (ph-empty? ph)
        #f
        (cdr ph)
    )
)

; TODO 1 (15p)
; Define the merge-f function in curry form, 
; so that you can later define point-free
; the functions merge-min, merge-max, and 
; merge-max-rating, as partial applications
; of merge-f.
;  - point-free definition = a definition that 
;    does not explicitly state the function's argument
;   * ex: (define f add1) is a point-free definition
;   * ex: (define (f x) (add1 x)) or, equivalently,
;     (define f (λ (x) (add1 x))) are not point-free
; merge-f = merge with comparison criterion comp
; in: pairing heaps ph1, ph2, comparator comp
;     (the order and grouping of parameters
;     must be decided by you)
; out: union(ph1, ph2) such that:
;   - union(empty, anything) = anything
;   - otherwise, the PH with root "less comp" 
;     becomes the first child of the other
;     (when equal, ph2 becomes a child of ph1)
; Keep the original merge-f function
(define merge-f 
    (λ (comp) 
        (λ (ph1) 
            (λ (ph2) 
                (cond 
                    ((ph-empty? ph1) ph2)
                    ((ph-empty? ph2) ph1)
                    ((comp (car ph1) (car ph2)) (append (list (car ph2)) (list ph1) (cdr ph2)))
                    (else (append (list (car ph1)) (list ph2) (cdr ph1)))
                )
            )
        )
    )
)

; merge-max : PH x PH -> PH 
; in: pairing heaps ph1, ph2 
; preconditions: ph1, ph2 are max-PHs 
; out: max-PH resulting from union(ph1, ph2) 
; RESTRICTIONS (5p): 
; - The definition must be point-free.
(define merge-max
    (λ (ph1 ph2)
        (((merge-f (λ (a b) (< a b))) ph1) ph2)
    )
)

; merge-min : PH x PH -> PH 
; in: pairing heaps ph1, ph2 
; preconditions: ph1, ph2 are min-PHs 
; out: min-PH resulting from union(ph1, ph2) 
; RESTRICTIONS (5p): 
; - The definition must be point-free.
(define merge-min
    (λ (ph1 ph2)
        (((merge-f (λ (a b) (> a b))) ph1) ph2)
    )
)

; merge-max-rating : PH x PH -> PH 
; in: pairing heaps ph1, ph2 
; preconditions: ph1, ph2 contain pairs with dot
; (name . rating) and are max-PHs ordered 
; by rating 
; out: max-PH resulting from union(ph1, ph2) 
; RESTRICTIONS (5p): 
; - The definition must be point-free.
(define merge-max-rating
    (λ (ph1 ph2)
        (((merge-f (λ (a b) (< (cdr a) (cdr b)))) ph1) ph2)
    )
)

; TODO 2 (10p)
; Redefine the following functions from stage 1 that
; call (directly or indirectly) merge, so that
; the merge function is given as a parameter
; (in the first position, as in the calls from the checker):
;  - ph-insert
;  - list->ph
;  - two-pass-merge-LR
;  - ph-del-root

(define (ph-insert merge val ph)
    (merge ph (val->ph val))
)

(define (list->ph merge ph)
    (if (ph-empty? ph)
        empty-ph
        (ph-insert merge (car ph) (list->ph merge (cdr ph)))
    )
)

(define (two-pass-merge-LR merge phs)

    (define (pair-merge lst acc)
        (cond
            ((ph-empty? lst) acc)
            ((ph-empty? (cdr lst)) (append acc (list (car lst))))
            (else (pair-merge (cddr lst) (append acc (list (merge (car lst) (cadr lst))))))
        )
    )
  
    (define (merge-all lst acc)
        (if (ph-empty? lst)
            acc
            (merge-all (cdr lst) (merge acc (car lst)))
        )
    )
    
    (merge-all (pair-merge phs empty-ph) empty-ph)
)

(define (ph-del-root merge ph)
    (if (ph-empty? ph)
        #f
        (two-pass-merge-LR merge (cdr ph))
    )
)

;; We define a movie as a structure with 5 fields:
;; name, rating, genre, duration, others.
(define-struct movie (name rating genre duration others) #:transparent)

; TODO 3 (10p)
; lst->movie : [Symbol, Number, Symbol, [Int], [Symbol]] -> Movie
; in: list lst with 5 values, in this order:
;     - name represented as a symbol (ex: 'the-lives-of-others)
;     - rating represented as a number (ex: 8.4)
;     - genre represented as a symbol (ex: 'drama)
;     - duration represented as a list of hours and minutes (ex: '(2 17))
;     - others represented as a list of symbols (ex: '(german))
; out: movie object instantiated with these 5 values
; RESTRICTIONS (10p):
;  - Don't identify the elements of the list, use a functional.
(define (lst->movie lst)
  (apply make-movie lst))

; TODO 4 (10p)
; mark-as-seen : Movie -> Movie
; in: movie m
; out: m updated so that the symbol 'seen is
;      added to the beginning of the (list) others field
(define (mark-as-seen m)
    (define mov2 (struct-copy movie m (others (append '(seen) (movie-others m)))))
    mov2
)

; TODO 5 (10p)
; mark-as-seen-from-list : [Movie] x [Symbol] -> [Movie]
; in: list of movies movies, list of names seen
; out: the movies list updated so that movies
;      with names in the seen list are marked as seen
; RESTRICTIONS (10p):
;  - Don't use explicit recursion.
;  - Use at least one functional.
(define (mark-as-seen-from-list movies seen)
    (map (λ (movie)
            (if (member (movie-name movie) seen)
               (mark-as-seen movie)
               movie
            )
         )
         movies
    )
)

; TODO 6 (10p)
; extract-seen : [Movie] -> [Symbol]
; in: list of movies movies
; out: the list of names of seen movies from the movies list
;      (seen = the others list contains 'seen)
; RESTRICTIONS (10p):
;  - Don't use explicit recursion.
;  - Don't use fold-type functionals.
;  - Use at least one functional.
(define (extract-seen movies)
    (apply append (map (λ (movie)
                            (if (member 'seen (movie-others movie)) ; it doesn't matter where seen appears
                                (list (movie-name movie))
                                empty-ph
                            )
                        )
                        movies
                  )
    )
)

; TODO 7 (15p)
; rating-stats : [Movie] -> (Number, Number)
; in: list of movies movies
; out: pair (average-rating-seen . average-rating-unseen)
;  - average-rating-seen = the average of ratings of seen movies
;  - similarly for unseen and unwatched movies
; (if there are no movies of a certain type, the average is 0)
; RESTRICTIONS
;  - Don't use explicit recursion.
;  - Use at least one functional.
;  - Don't traverse the movies in the list (or parts of the list)
;    more than once.
(define (rating-stats movies)
    (define totals
        (foldl
            (λ (m acc)
                (if (member 'seen (movie-others m))
                    (list (+ (car acc) (movie-rating m))
                          (+ (cadr acc) 1)
                          (caddr acc)
                          (cadddr acc)
                    )
                    (list (car acc)
                          (cadr acc)
                          (+ (caddr acc) (movie-rating m))
                          (+ (cadddr acc) 1)
                    )
                )
            )
            (list 0 0 0 0) movies
        )
    )

    (cons (if (= (cadr totals) 0)
            0
            (/ (car totals) (cadr totals))
          )
        (if (= (cadddr totals) 0)
            0
            (/ (caddr totals) (cadddr totals))
        )
    )
)

; TODO 8 (10p)
; extract-name-rating : [Movie] -> [(Symbol, Number)]
; in: list of movies movies
; out: list of pairs (name . rating) 
;      (one pair for each movie in movies)
; RESTRICTIONS (10p):
;  - Don't use explicit recursion.
;  - Use at least one functional.
(define (extract-name-rating movies)
    (map (λ (m)
            (cons (movie-name m) (movie-rating m))
         )
         movies
    )
)

; TODO 9 (10p)
; make-rating-ph : [Movie] -> PH
; in: list of movies movies
; out: max-PH containing the pairs (name . rating)
;      corresponding to the movies in the movies list
;      (ordered by rating)
;  - the last pair is inserted into the empty PH
;  - ...
;  - the first pair is inserted into the PH so far
(define (make-rating-ph movies)
    (foldr (λ (m ph)
            (ph-insert merge-max-rating (cons (movie-name m) (movie-rating m)) ph)
            )
            empty-ph
            movies
    )
)

; TODO 10 (10p)
; before? : T1 x T2 x List
;           (List is a heterogeneous list)
; in: arbitrary values a, b, arbitrary list List
; out: true, if a = b or a appears before b in List
;      false, otherwise
; RESTRICTIONS (10p):
;  - Don't use explicit recursion.
;  - Identify in Help Desk the findf functional
;    and use it.
(define (before? a b L)
    (or (equal? a b)
        (equal? (findf (λ (x) (or (equal? x a) (equal? x b))) L) a)
    )
)

; TODO 11 (10p)
; make-genre-ph : [Movie] x [Symbol] -> PH
; in: list of movies movies, list of genres genres
; out: PH containing movies, such that the genre
;      of a parent node appears in the genres list
;      before the genre of its children
;      (according to the definition from the before? function)
;  - the last movie is inserted into the empty PH
;  - ...
;  - the first movie is inserted into the PH so far
; note: when a movie of the same genre as the current
; root is inserted, the new movie becomes a child
; of the root 
(define (make-genre-ph movies genres)
  (foldr (λ (m ph)
           (ph-insert 
            (lambda (ph1 ph2)
              (cond
                ((null? ph1) ph2)
                ((null? ph2) ph1)
                (else
                 (cond
                   ((equal? (movie-genre (car ph1)) (movie-genre (car ph2)))
                    (append (list (car ph1)) (list ph2) (cdr ph1)))
                   ((and (member (movie-genre (car ph1)) genres) 
                         (member (movie-genre (car ph2)) genres))
                    (if (before? (movie-genre (car ph1)) (movie-genre (car ph2)) genres)
                        (append (list (car ph1)) (list ph2) (cdr ph1))
                        (append (list (car ph2)) (list ph1) (cdr ph2))))
                   ((member (movie-genre (car ph1)) genres)
                    (append (list (car ph1)) (list ph2) (cdr ph1)))
                   ((member (movie-genre (car ph2)) genres)
                    (append (list (car ph2)) (list ph1) (cdr ph2)))
                   (else
                    (append (list (car ph2)) (list ph1) (cdr ph2)))))))
            m 
            ph))
         empty-ph
         movies))