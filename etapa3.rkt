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
  ; Create custom merge function for this comparison operation
  (define merge-custom 
    (lambda (ph1 ph2)
      (cond
        [(ph-empty? ph1) ph2]
        [(ph-empty? ph2) ph1]
        [(op (ph-root ph1) (ph-root ph2)) (append (list (ph-root ph1)) (list ph2) (ph-subtrees ph1))]
        [else (append (list (ph-root ph2)) (list ph1) (ph-subtrees ph2))])))
  
  ; Build initial heap using fold-right
  (define movies-heap
    (foldr (lambda (movie ph) (merge-custom (val->ph movie) ph)) empty-ph movies))
  
  ; Extract k elements or until heap is empty
  (let extract-k ([heap movies-heap]
                 [result '()]
                 [count 0])
    (cond
      [(or (ph-empty? heap) (= count k)) result]
      [else (extract-k (ph-del-root merge-custom heap)
                      (append result (list (ph-root heap)))
                      (+ count 1))])))

; best-k-rating : [Movie] x Int -> [Movie]
; in: list of movies movies, number k
; out: the best k movies from movies (by rating)
; RESTRICTIONS (5p):
;  - Obtain best-k-rating as an application of best-k.
(define (best-k-rating movies k)
  (best-k (lambda (m1 m2) (>= (movie-rating m1) (movie-rating m2))) movies k))

; best-k-duration : [Movie] x Int -> [Movie]
; in: list of movies movies, number k
; out: the shortest k movies from movies 
; RESTRICTIONS (5p):
;  - Obtain best-k-duration as an application of best-k.
(define (best-k-duration movies k)
  (best-k 
   (lambda (m1 m2)
     (let ([duration1 (+ (* 60 (car (movie-duration m1))) (cadr (movie-duration m1)))]
           [duration2 (+ (* 60 (car (movie-duration m2))) (cadr (movie-duration m2)))])
       (<= duration1 duration2)))
   movies k))


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
  (let loop ([current pairs]
             [processed '()])
    (cond
      ; End of list, no match found
      [(null? current) pairs]
      ; Test current pair
      [(p (car current))
       (let* ([pair (car current)]
              [name (car pair)]
              [ratings (cdr pair)]
              [updated-ratings (ph-del-root merge-max ratings)])
         (if updated-ratings
             ; Found valid pair to update - reconstruct the list with updated pair
             (append (reverse processed) 
                     (cons (cons name updated-ratings) (cdr current)))
             ; If PH is empty after deleting root, return unchanged list
             pairs))]
      ; Continue with next pair
      [else (loop (cdr current) (cons (car current) processed))])))
                  

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
  ; Skip empty pairs or pairs with empty PH
  (define valid-pairs 
    (filter (lambda (p) (and (not (null? p)) (not (ph-empty? (cdr p))))) pairs))
  
  ; Build initial heap of best ratings
  (define initial-ph
    (foldl (lambda (pair ph)
             (let* ([name (car pair)]
                    [ratings-ph (cdr pair)]
                    [best-rating (ph-root ratings-ph)]
                    [name-rating (cons name best-rating)])
               (merge-max-rating ph (val->ph name-rating))))
           empty-ph
           valid-pairs))
  
  ; Build lookup table for quick access to ratings by film name
  (define ratings-table
    (foldl (lambda (pair table)
             (hash-set table (car pair) (cdr pair)))
           (hash)
           valid-pairs))
  
  ; Extract k best ratings
  (let extract-k ([ph initial-ph]
                  [result '()]
                  [count 0]
                  [pairs-map ratings-table])
    (cond
      ; We have k results or the heap is empty
      [(or (= count k) (ph-empty? ph)) result]
      [else
       (let* ([best-pair (ph-root ph)]
              [name (car best-pair)]
              [rating (cdr best-pair)]
              [remaining-ph (ph-del-root merge-max-rating ph)]
              [film-ratings (hash-ref pairs-map name #f)]
              [updated-film-ratings (and film-ratings (ph-del-root merge-max film-ratings))]
              [next-ph (if (and updated-film-ratings (not (ph-empty? updated-film-ratings)))
                           (merge-max-rating 
                            remaining-ph 
                            (val->ph (cons name (ph-root updated-film-ratings))))
                           remaining-ph)]
              [next-map (if updated-film-ratings
                            (hash-set pairs-map name updated-film-ratings)
                            pairs-map)])
         (extract-k next-ph
                    (append result (list best-pair)) 
                    (+ count 1)
                    next-map))]))
)

