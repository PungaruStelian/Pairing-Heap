; ++++ ETAPA 2 ++++

;; În această etapă abstractizăm operatorii tipului PH astfel
;; încât să putem deriva ușor operațiile pentru diverse variante
;; de PH, în funcție de relația de ordine pe care se bazează
;; proprietatea de heap.
;;  - funcție afectată direct: merge
;;  - funcții afectate indirect: funcțiile care apelează merge,
;;     care vor avea nevoie să primească tipul de merge ca parametru
;;
;; Apoi, folosim tipul PH pentru a prelucra filme, unde un film
;; este reprezentat ca o structură cu 5 câmpuri: nume, rating, gen, 
;; durată, altele.
;; În Racket, există un mod simplu de a defini și manipula structuri,
;; descris în fișierul "tutorial.rkt".
;;
;; Fluxul de lucru recomandat pentru etapa 2 este:
;; - Copiați din etapa 1 funcțiile care rămân neschimbate
;; - Abstractizați după relația de ordine:
;;  * definiți operatorul mai general merge-f care primește, în plus
;;    față de merge, un comparator după care trebuie ordonate elementele
;;  * derivați din acest operator variantele cerute de merge
;;  * modificați acele funcții din etapa 1 care apelează merge, astfel
;;    încât funcția merge să fie parametru al funcției, nu un identificator
;;    legat la o valoare externă
;; - Citiți tutorialul despre structuri în Racket (fișierul "tutorial.rkt")
;; - Implementați funcțiile care prelucrează filme 

; empty-ph : PH
; out: PH-ul vid
(define empty-ph '())

; val->ph : T -> PH
; in: o valoare de un tip oarecare T
; out: PH-ul care conține doar această valoare
(define (val->ph T)
    (list T))

; ph-empty? : PH -> Bool
; in: pairing heap ph
; out: true, dacă ph este vid
;      false, altfel
(define (ph-empty? ph)
    (null? ph))

; ph-root : PH -> T | Bool
; in: pairing heap ph
; out: false, dacă ph e vid
;      root(ph), altfel
(define (ph-root ph)
    (if (ph-empty? ph)
        #f
        (car ph)
    )
)

; ph-subtrees : PH -> [PH] | Bool
; in: pairing heap ph
; out: false, dacă ph e vid
;      copii(ph), altfel
(define (ph-subtrees ph)
    (if (ph-empty? ph)
        #f
        (cdr ph)
    )
)

; TODO 1 (15p)
; Definiți funcția merge-f în formă curry, 
; astfel încât ulterior să definiți point-free
; funcțiile merge-min, merge-max și 
; merge-max-rating, ca aplicații parțiale
; ale lui merge-f.
;  - definiție point-free = o definiție care 
;    nu explicitează argumentul funcției
;   * ex: (define f add1) este o definiție point-free
;   * ex: (define (f x) (add1 x)) sau, echivalent,
;     (define f (λ (x) (add1 x))) nu sunt point-free
; merge-f = merge cu criteriul de comparație comp
; in: pairing heaps ph1, ph2, comparator comp
;     (ordinea și gruparea parametrilor
;     trebuie decisă de voi)
; out: union(ph1, ph2) astfel:
;   - union(vid, orice) = orice
;   - altfel, PH-ul cu root "mai puțin comp" 
;     devine primul fiu al celuilalt
;     (la egalitate, ph2 devine fiul lui ph1)
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
; precondiții: ph1, ph2 sunt max-PH-uri 
; out: max-PH rezultat din union(ph1, ph2) 
; RESTRICȚII (5p): 
; - Definiția trebuie să fie point-free.
(define merge-max
    (λ (ph1 ph2)
        (((merge-f (λ (a b) (< a b))) ph1) ph2)
    )
)

; merge-min : PH x PH -> PH 
; in: pairing heaps ph1, ph2 
; precondiții: ph1, ph2 sunt min-PH-uri 
; out: min-PH rezultat din union(ph1, ph2) 
; RESTRICȚII (5p): 
; - Definiția trebuie să fie point-free.
(define merge-min
    (λ (ph1 ph2)
        (((merge-f (λ (a b) (> a b))) ph1) ph2)
    )
)

; merge-max-rating : PH x PH -> PH 
; in: pairing heaps ph1, ph2 
; precondiții: ph1, ph2 conțin perechi cu punct 
; (nume . rating) și sunt max-PH-uri ordonate 
; după rating 
; out: max-PH rezultat din union(ph1, ph2) 
; RESTRICȚII (5p): 
; - Definiția trebuie să fie point-free.
(define merge-max-rating
    (λ (ph1 ph2)
        (((merge-f (λ (a b) (< (cdr a) (cdr b)))) ph1) ph2)
    )
)

; TODO 2 (10p)
; Redefiniți următoarele funcții din etapa 1 care
; apelează (direct sau indirect) merge, astfel
; încât funcția merge să fie dată ca parametru
; (pe prima poziție, ca în apelurile din checker):
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

;; Definim un film (movie) ca pe o structură cu 5 câmpuri:   
;; nume, rating, gen, durată, altele.
(define-struct movie (name rating genre duration others) #:transparent)

; TODO 3 (10p)
; lst->movie : [Symbol, Number, Symbol, [Int], [Symbol]] -> Movie
; in: listă lst cu 5 valori, în această ordine:
;     - numele reprezentat ca simbol (ex: 'the-lives-of-others)
;     - ratingul reprezentat ca număr (ex: 8.4)
;     - genul reprezentat ca simbol (ex: 'drama)
;     - durata reprezentată ca listă de ore și minute (ex: '(2 17))
;     - altele reprezentate ca listă de simboluri (ex: '(german))
; out: obiect de tip movie instanțiat cu cele 5 valori
; RESTRICȚII (10p):
;  - Nu identificați elementele listei, ci folosiți o funcțională.
(define (lst->movie lst)
  (apply make-movie lst))

; TODO 4 (10p)
; mark-as-seen : Movie -> Movie
; in: film m
; out: m actualizat astfel încât symbolul 'seen este
;      adăugat la începutul câmpului (listei) others
(define (mark-as-seen m)
    (define mov2 (struct-copy movie m (others (append '(seen) (movie-others m)))))
    mov2
)

; TODO 5 (10p)
; mark-as-seen-from-list : [Movie] x [Symbol] -> [Movie]
; in: listă de filme movies, listă de nume seen
; out: lista movies actualizată astfel încât filmele
;      cu numele în lista seen sunt marcate ca văzute
; RESTRICȚII (10p):
;  - Nu folosiți recursivitate explicită.
;  - Folosiți cel puțin o funcțională.
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
; in: listă de filme movies
; out: lista numelor filmelor văzute din lista movies
;      (văzut = lista others conține 'seen)
; RESTRICȚII (10p):
;  - Nu folosiți recursivitate explicită.
;  - Nu folosiți funcționale de tip fold.
;  - Folosiți cel puțin o funcțională.
(define (extract-seen movies)
    (apply append (map (λ (movie)
                            (if (member 'seen (movie-others movie)) ; nu conteaza unde apare seen
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
; in: listă de filme movies
; out: pereche (rating-mediu-seen . rating-mediu-unseen)
;  - rating-mediu-seen = media rating-urilor filmelor văzute
;  - analog pentru unseen și filmele nevăzute
; (dacă nu există filme de un anumit fel, media este 0)
; RESTRICȚII
;  - Nu folosiți recursivitate explicită.
;  - Folosiți cel puțin o funcțională.
;  - Nu parcurgeți filmele din listă (sau părți ale listei)
;    mai mult decât o dată.
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
; in: listă de filme movies
; out: listă de perechi (nume . rating) 
;      (o pereche pentru fiecare film din movies)
; RESTRICȚII (10p):
;  - Nu folosiți recursivitate explicită.
;  - Folosiți cel puțin o funcțională.
(define (extract-name-rating movies)
    (map (λ (m)
            (cons (movie-name m) (movie-rating m))
         )
         movies
    )
)

; TODO 9 (10p)
; make-rating-ph : [Movie] -> PH
; in: listă de filme movies
; out: max-PH care conține perechile (nume . rating)
;      corespunzătoare filmelor din movies
;      (cu ordonare după rating)
;  - se inserează ultima pereche în PH-ul vid
;  - ...
;  - se inserează prima pereche în PH-ul de până acum
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
;           (List este o listă eterogenă)
; in: valori oarecare a, b, listă oarecare List
; out: true, dacă a = b sau a apare înaintea lui b în List
;      false, altfel
; RESTRICȚII (10p):
;  - Nu folosiți recursivitate explicită.
;  - Identificați în Help Desk funcționala findf
;    și folosiți-o.
(define (before? a b L)
    (or (equal? a b)
        (equal? (findf (λ (x) (or (equal? x a) (equal? x b))) L) a)
    )
)

; TODO 11 (10p)
; make-genre-ph : [Movie] x [Symbol] -> PH
; in: listă de filme movies, listă de genuri genres
; out: PH care conține filme, astfel încât genul
;      unui nod părinte să apară în lista genres
;      înaintea genului fiilor săi      
;      (conform definiției din funcția before?)
;  - se inserează ultimul film în PH-ul vid
;  - ...
;  - se inserează primul film în PH-ul de până acum
; observație: când se inserează un film de același
; gen cu root-ul curent, noul film devine fiul
; root-ului 
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