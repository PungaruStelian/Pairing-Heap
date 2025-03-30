#lang racket
(require racket/match)
(require "etapa2.rkt")
(provide (all-defined-out))

;; This stage continues the series of applications of pairing heaps,
;; which we will use to dynamically calculate the median of movie reviews,
;; simulating real-world conditions - in which new reviews continuously
;; appear for various movies.
;;    
;; To model this dynamic, we use a stream of pairs (movie-name . rating),
;; based on which we calculate a stream of evolutionary stages as follows:
;;  - each stage is represented as a list of pairs
;;    * one pair for each movie with at least one review
;;    * each pair has the form
;;      (movie-name . median-of-ratings-received-so-far)
;;  - each new review determines the update of a median, meaning
;;    the transition to another stage, generating a new element
;;    in the resulting stream
;;
;; The algorithm used is as follows:
;;  The stream of pairs is transformed into a stream of lists
;;  of quartets (movie-name delta max-ph min-ph)
;;   - each element in the stream contains one quartet
;;     for each movie that has at least one review
;;   - if the movie has an even number of reviews:
;;     - max-ph and min-ph have the same size
;;     - delta = size(max-ph) - size(min-ph) = 0
;;     - max-ph = max-PH with the smallest ratings
;;     - min-ph = min-PH with the largest ratings
;;     - the median is the average of the roots of the 2 PHs
;;   - if the movie has an odd number of reviews:
;;     - max-ph has one more element than min-ph
;;     - delta = size(max-ph) - size(min-ph) = 1
;;     - max-ph = max-PH with the smallest ratings
;;     - min-ph = min-PH with the largest ratings
;;     - the median is the root of max-ph
;;
;; For successful completion of this stage, it is necessary to
;; calculate the medians using the algorithm described above.
;; Otherwise, the points awarded by the checker will be withdrawn.


; TODO 1 (45p)
; add-rating : (Symbol, Int, PH, PH) x Number
;              -> (Symbol, Int, PH, PH)
; in: quartet (name delta max-ph min-ph),
;     rating to add
; out: updated quartet by adding the rating, as follows:
;  - if rating <= root(max-ph)
;    insert rating into max-ph, updating delta
;  - else
;    insert rating into min-ph, updating delta
;  - if delta > 1
;    move root(max-ph) to min-ph
;  - if delta < 0
;    move root(min-ph) to max-ph

(define (balance-ph name max-ph min-ph delta)
    (cond
        ; max-ph has too many elements
        ((> delta 1)
            (let ((max-root (ph-root max-ph)))
                (list name 0
                    (ph-del-root merge-max max-ph)
                    (if (ph-empty? min-ph)
                        (val->ph max-root)
                        (ph-insert merge-min max-root min-ph)
                    )
                )
            )
        )
        ; min-ph has too many elements
        ((< delta 0)
            (let ((min-root (ph-root min-ph)))
                (list name 1
                    (ph-insert merge-max min-root max-ph)
                    (ph-del-root merge-min min-ph)
                )
            )
        )
        ; Heaps are already balanced
        (else (list name delta max-ph min-ph))
    )
)

(define (add-rating quad rating)
    (let (
            (name (car quad))
            (delta (cadr quad))
            (max-ph (caddr quad))
            (min-ph (cadddr quad))
        )
        (if (ph-empty? max-ph)
            ; if max-ph is empty, it means min-ph is also empty
            (list name 1 (val->ph rating) empty-ph)
            ; regardless of whether min-ph is empty, we insert based on max-ph's root
            (if (<= rating (ph-root max-ph))
                ; max-ph contains the lower half of ratings
                (let ((new-max-ph (ph-insert merge-max rating max-ph)))
                    (balance-ph name new-max-ph min-ph (+ delta 1))
                )
                ; min-ph contains the upper half of ratings
                (let ((new-min-ph (ph-insert merge-min rating min-ph)))
                        (balance-ph name max-ph new-min-ph (- delta 1))
                )
            )
        )
    )
)

; TODO 2 (45p)
; reviews->quads : Stream<(Symbol, Number)> ->
;                  Stream<[(Symbol, Int, PH, PH)]>
; in: stream of pairs (name . rating)
; out: stream of lists of quartets
;      (name delta max-ph min-ph)
;  - element k in the result corresponds to the first
;    k reviews from input (ex: if the first 10
;    reviews are for 3 distinct movies, the
;    10th element of the resulting stream contains a
;    list of 3 quartets - one for each movie)
; RESTRICTIONS (20p):
;  - Work with stream operators, without
;    converting lists to streams or streams to lists.
(define (reviews->quads reviews)
    (define (my-fold f acc s)
        (if (stream-empty? s)
            s
            (let* (
                    (head (stream-first s))
                    (tail (stream-rest s))
                    (new-acc (f acc head))
                )
                (stream-cons new-acc (my-fold f new-acc tail))
            )
        )
    )
  
    (my-fold
        (lambda (quads review)
            (define name (car review))
            (define rating (cdr review))
            ; check if the movie already exists
            (define existing-quad (findf (lambda (q) (equal? (car q) name)) quads))
     
            (if existing-quad
                ; update the existing quad with the new rating
                (map 
                    (lambda (q)
                        (if (equal? (car q) name)
                            (add-rating q rating)
                            q
                        )
                    )
                    quads
                )
                ; add a new quad for the movie
                (append quads (list (add-rating (list name 0 empty-ph empty-ph) rating)))
            )
        )
        empty-ph
        reviews
   )
)


; TODO 3 (30p)
; quads->medians : Stream<[(Symbol, Int, PH, PH)]> ->
;                  Stream<[(Symbol, Number)]>  
; in: stream of lists of quartets (as above)
; out: stream of lists of pairs (movie-name . median)
;  - the median is calculated based on the PHs from
;    each quartet, according to the algorithm above
; RESTRICTIONS (20p):
;  - Do not use explicit recursion. Use at least
;    one functional on streams.
(define (quads->medians quad-list-stream)
    (stream-map
        (lambda (quad-list)
            (map 
                (lambda (quad)
                    (let (
                        (name (car quad))
                        (delta (cadr quad))
                        (max-ph (caddr quad))
                        (min-ph (cadddr quad))
                        )
                        (cons name
                              (if (= delta 0)
                                  (/ (+ (ph-root max-ph) (ph-root min-ph)) 2)
                                  (ph-root max-ph)
                              )
                        )
                    )
                )
                quad-list
            )
        )
        quad-list-stream
    )
)