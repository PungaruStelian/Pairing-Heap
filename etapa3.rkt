#lang racket
(require "etapa2.rkt")
(require racket/match)
(provide (all-defined-out))

;; This stage is dedicated to applications of pairing heaps, 
;; which we will use for:
;;  - extracting the best films from a list, according
;;    to a certain criterion
;;  - extracting the best reviews from a collection
;;    of reviews for various films (a good review
;;    corresponds to a good rating given to the respective film)
;;
;; For the successful completion of the stage, it is necessary to
;; solve the tasks with the dedicated PH algorithms 
;; (described in the assignment). The score given by the checker will be 
;; withdrawn if the tasks are solved with other algorithms.


; TODO 1 (40p)
; Define the best-k function in a form that
; facilitates the subsequent derivation of the functions
; best-k-rating and best-k-duration.
; in: comparison criterion op (which compares 2 movies),
;     list of movies movies, number k
; out: the sorted list of the "best" movies
;      according to the criterion (the "best" first)
; Algorithm:
;  1. build a PH of movies based on the movies list 
;     and the op criterion
;  2. repeatedly extract the root of this PH until
;     the result contains k movies (or the PH becomes empty)
; RESTRICTIONS (20p):
;  - Use named let to perform step 2 of the
;    algorithm.
(define (best-k op movies k)
    ; start from the empty list and at every step combine a movie with the accumulator using the OP function
    (define make-sorted-ph-of-movies
        (foldl (λ (movie ph) 
                (ph-insert (merge-f op) movie ph)
                )
                empty-ph
                movies
        )
    )
    ; only solution for named let
    (let extract-k ((ph make-sorted-ph-of-movies)
                    (result '()))
        (if (or (ph-empty? ph) (= (length result) k))
            result
            (extract-k (ph-del-root (merge-f op) ph)
                    (append result (list (ph-root ph))))
        )
    )
)

; best-k-rating : [Movie] x Int -> [Movie]
; in: list of movies movies, number k
; out: the best k movies from movies (by rating)
; RESTRICTIONS (5p):
;  - Obtain best-k-rating as an application of best-k.
(define (best-k-rating movies k)
    (best-k (λ (m1 m2) 
               (< (movie-rating m1) (movie-rating m2)))
            movies
            k
    )
)

; best-k-duration : [Movie] x Int -> [Movie]
; in: list of movies movies, number k
; out: the shortest k movies from movies 
; RESTRICTIONS (5p):
;  - Obtain best-k-duration as an application of best-k.
(define (best-k-duration movies k)
    (define (seconds m) 
        (+ (* 60 (car (movie-duration m))) (cadr (movie-duration m)))
    )
    
    (best-k (λ (m1 m2)
                (> (seconds m1) (seconds m2))
            )
            movies
            k
    )
)

; TODO 2 (30p)
; update-pairs : ((Symbol, PH) -> Bool) x [(Symbol, PH)]
;                -> [(Symbol, PH)]
; in: predicate p, list of pairs (movie-name . PH)
;     (PH is a max-PH that contains ratings given
;      to the movie in various reviews - so a PH
;      of numbers)
; out: the pairs list updated as follows:
;      - for the first pair that satisfies the predicate 
;        p, the root of the pair's PH is deleted
;      - if the pair's PH is empty or if no pair
;        satisfies p, return the pairs list unchanged
; RESTRICTIONS (20p):
;  - Use named let to iterate through pairs.
(define (update-pairs p pairs)
    ; initialization
    (let loop ((curr pairs)
                (acc '()))
        (cond
            ; finished
            ((null? curr) acc)
            ((p (car curr))
                (define pair (car curr)) ; name . PH of ratings
                (define ratings (cdr pair)) ; PH
                (if (ph-empty? ratings)
                    ; return unchanged list
                    (append acc curr)
                    ; build the updated list and finish recursion
                    (append acc (list (append (list (car pair))
                        (ph-del-root merge-max ratings))) (cdr curr))
                )
            )
            ; cdr curr is the rest of the pairs
            (else (loop (cdr curr) (append acc (list (car curr)))))
        )
    )
)

; TODO 3 (50p)
; best-k-ratings-overall : [(Symbol, PH)] x Int
;                          -> [(Symbol, Number)]
; in: list of pairs (movie-name . PH)
;     (as above, PH is a max-PH of ratings)
;     number k 
; out: the sorted list of the best k pairs
;      (movie-name . rating), corresponding to the best
;      ratings from all PHs
; Algorithm:
;  1. Initialize a PH of pairs (name . rating), 
;     corresponding to the best rating of each movie
;     (i.e., extract the root of each PH of ratings,
;      paired with the name of the associated movie)
;  2. Repeat k times:
;     - extract the root of the roots PH
;       (name-root . rating-root)
;       (i.e., extract the best pair overall)
;     - bring into the roots PH the next best 
;       rating of the movie name-root (if any)
; RESTRICTIONS (20p):
;  - Use named let to perform step 2 of the
;    algorithm.
(define (best-k-ratings-overall pairs k)
    ; from input: the ratings from each movie are sorted
    ; from pairs of name - heap of ratings, it becomes a sorted heap with all names and best ratings
    (define initial-ph
        (foldl (λ (pair ph)
            (ph-insert merge-max-rating (append (list (car pair)) (ph-root (cdr pair))) ph)
                )
                empty-ph ; acc
                pairs
        )
    )

    (let extract-k ((ph initial-ph)
                    (result '())
                    (current-pairs pairs))
        (cond
            ((or (= (length result) k) (ph-empty? ph)) result)
            (else
                (define best-pair (ph-root ph))
                (define name (car best-pair))
                (define remaining-ph (ph-del-root merge-max-rating ph))
                ; remove the best pair with the best rating from the list
                (define updated-pairs 
                    (update-pairs (λ (p) (equal? (car p) name)) current-pairs)
                )
                ; find the updated pair for the movie
                (define updated-movie-pair 
                    (findf (λ (p) (equal? (car p) name)) updated-pairs)
                )
                ; extract the updated ph without the best rating
                (define next-rating-ph 
                    (and updated-movie-pair (cdr updated-movie-pair))
                )

                (extract-k
                    (if (not (ph-empty? next-rating-ph))
                        ; if there is a next rating for the same name, add it to the heap and sort it
                        (ph-insert merge-max-rating 
                            (append (list name) (ph-root next-rating-ph))
                                remaining-ph)
                        ; if there is no next rating, the heap remains the same
                        remaining-ph)
                    (append result (list best-pair))
                    updated-pairs
                )
            )
        )
    )
)
