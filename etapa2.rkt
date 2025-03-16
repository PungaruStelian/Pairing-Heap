#lang racket
(require racket/match)
(provide (all-defined-out))

; ++++ ETAPA 1 ++++

;; Un heap de împerechere (pairing heap) este un arbore n-ar care
;; respectă proprietatea de heap și implementează eficient
;; următoarele operații:
;; - inserție în heap
;; - ștergerea rădăcinii (determinând restructurarea heap-ului)
;; - reuniunea a două heap-uri
;; Proprietatea de heap se referă la menținerea unei relații de
;; ordine între orice nod părinte și copiii acestuia:
;; - într-un min-heap, valoarea părintelui este mai mică sau 
;;   egală decât valorile copiilor săi
;; - într-un max-heap, valoarea părintelui este mai mare sau
;;   egală decât valorile copiilor săi
;; - un heap se poate baza și pe alte relații de ordine
;;
;; Vom reprezenta un heap de împerechere (prescurtat PH - de la
;; "pairing heap") ca pe o listă:
;; - vidă, în cazul în care heap-ul nu conține elemente
;; - (rădăcină fiu_1 fiu_2 ... fiu_n), altfel
;;   - unde fiecare fiu este de asemenea un PH
;;
;; În această etapă implementăm un max-heap de împerechere.


; TODO 1 (15p)
; Definiți, conform indicațiilor, următorii constructori și 
; operatori ai tipului PH.
; Ulterior, manipulați PH-ul prin intermediul acestei interfețe
; (nu utilizați funcții dedicate listelor atunci când există
; funcții echivalente dedicate tipului PH).

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

; TODO 2 (15p)
; merge: PH x PH -> PH
; in: pairing heaps ph1, ph2
; out: union(ph1, ph2) astfel:
;  - union(vid, orice) = orice
;  - altfel, PH-ul cu root mai mic devine
;    primul fiu al celui cu root mai mare
;    (prin convenție, dacă rădăcinile sunt
;    egale, ph2 devine fiul lui ph1)
; ATENȚIE!
; Rezultă că, doar atunci când se aplică 
; pe PH-uri cu rădăcini egale, operația
; merge nu este comutativă.
; Pentru a trece testele, dați mereu  
; argumentele lui merge în ordinea
; specificată în enunț!
; (define (merge ph1 ph2)
;     (cond
;         ((ph-empty? ph1) ph2)
;         ((ph-empty? ph2) ph1)
;         ((< (ph-root ph1) (ph-root ph2))(append (list (ph-root ph2)) (list ph1) (ph-subtrees ph2)))
;         (else (append (list (ph-root ph1)) (list ph2) (ph-subtrees ph1)))
;     )
; )

; TODO 3 (10p)
; ph-insert : T x PH -> PH
; in: valoare val, pairing heap ph
; out: ph' rezultat după inserția lui val în ph
;  - inserția este un merge între ph și 
;    PH-ul creat doar din valoarea val
;    (în această ordine)
; (define (ph-insert val ph)
;     (merge ph (val->ph val))
; )

; TODO 4 (10p)
; list->ph : [T] -> PH
; in: listă de valori lst
; out: ph' rezultat din inserții repetate
;  - se inserează ultimul element din lst în PH-ul vid
;  - ...
;  - se inserează primul element din lst în PH-ul de până acum
; RESTRICȚII (10p):
;  - Folosiți recursivitate pe stivă.
; (define (list->ph lst)
;     (if (ph-empty? lst)
;         empty-ph
;         (ph-insert (car lst) (list->ph (cdr lst)))
;     )
; )

; TODO 5 (20p)
; two-pass-merge-LR : [PH] -> PH
; in: listă de PH-uri phs
; out: ph' rezultat din merge stânga-dreapta:
;  - merge de primele două PH-uri
;  - merge de rezultat cu merge de următoarele două
;  ...
;  - merge de rezultat cu:
;    - merge de ultimele două PH-uri, dacă nr_par(phs)
;    - ultimul PH, dacă nr_impar(phs)
; RESTRICȚII (10p):
;  - Folosiți recursivitate pe coadă.
; (define (two-pass-merge-LR phs)

;     (define (pair-merge lst acc)
;         (cond
;             ((ph-empty? lst) acc)
;             ((ph-empty? (cdr lst)) (append acc (list (car lst))))
;             (else (pair-merge (cddr lst) (append acc (list (merge (car lst) (cadr lst))))))
;         )
;     )
  
;     (define (merge-all lst acc)
;         (if (ph-empty? lst)
;             acc
;             (merge-all (cdr lst) (merge acc (car lst)))
;         )
;     )
    
;     (merge-all (pair-merge phs empty-ph) empty-ph)
; )

; TODO 6 (20p)
; two-pass-merge-RL : [PH] -> PH
; in: listă de PH-uri phs
; out: ph' rezultat din merge dreapta-stânga
; (ca mai sus, dar se începe cu ultimele două PH-uri:
;  - merge de penultimul cu ultimul
;  - merge de rezultat cu merge de anterioarele două etc.)
; RESTRICȚII (10p):
;  - Folosiți recursivitate pe stivă.
; (define (two-pass-merge-RL phs)
;     (define (remove-last-one lst)
;         (reverse (cdr (reverse lst)))
;     )
  
;     (define (remove-last-two lst)
;         (reverse (cddr (reverse lst)))
;     )

;     (define (get-last lst)
;         (car (reverse lst))
;     )

;     (define (group-merge lst)
;         (cond
;             ((ph-empty? lst) empty-ph)
;             ((ph-empty? (cdr lst)) lst)
;             (else (append (group-merge (remove-last-two lst))
;                     (list (merge (get-last (remove-last-one lst)) (get-last lst)))))
;         )
;     )
  
;     (define (fold-all lst)
;         (if (ph-empty? lst)
;             lst
;             (merge (fold-all (cdr lst)) (car lst))
;         )
;     )
  
;     (fold-all (group-merge phs))
; )

; TODO 7 (20p)
; tournament-merge : [PH] -> PH
; in: listă de PH-uri phs
; out: ph' rezultat din merge tip "knock-out"
;  - listele de ph-uri sunt parcurse stânga-dreapta
;  - merge două câte două (pentru număr impar, ultimul rămâne ca atare)
;  - merge două câte două între PH-urile rezultate anterior
;  ...
;  - până rămâne un singur PH
; (define (tournament-merge phs)
;     (define (merge-pairs lst)
;         (cond
;             ((ph-empty? lst) empty-ph)
;             ((ph-empty? (cdr lst)) lst)
;             (else (append (list (merge (car lst) (cadr lst))) (merge-pairs (cddr lst))))
;         )
;     )

;     (define (merge-until-one lst)
;         (cond
;             ((ph-empty? lst) empty-ph)
;             ((ph-empty? (cdr lst)) (car lst))
;             (else (merge-until-one (merge-pairs lst)))
;         )
;     )

;   (merge-until-one phs)
; )

; TODO 8 (10p)
; ph-del-root : PH -> PH | Bool
; in: pairing heap ph
; out: false, dacă ph e vid
;      ph' rezultat în urma ștergerii root(ph), altfel
;      - fiii root(ph) sunt uniți prin two-pass-merge-LR
; (define (ph-del-root ph)
;     (if (ph-empty? ph)
;         #f
;         (two-pass-merge-LR (cdr ph))
;     )
; )

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
(define merge-f
  (lambda (comp)
    (lambda (ph1 ph2)
      (cond
        [(null? ph1) ph2]
        [(null? ph2) ph1]
        [else
         (let ([a (car ph1)]
               [b (car ph2)])
           (if (comp a b)
               (cons b (cons (list a) (append (cdr ph1) (cdr ph2))))
               (cons a (cons (list b) (append (cdr ph2) (cdr ph1))))))]))))

(define merge-max (merge-f (lambda (a b) (< a b))))
(define merge-min (merge-f (lambda (a b) (> a b))))
(define merge-max-rating (merge-f (lambda (a b) (< (cdr a) (cdr b)))))

; merge-max : PH x PH -> PH
; in: pairing heaps ph1, ph2
; precondiții: ph1, ph2 sunt max-PH-uri
; out: max-PH rezultat din union(ph1, ph2)
; RESTRICȚII (5p):
;  - Definiția trebuie să fie point-free.
; (define merge-max (merge-f (lambda (a b) (< a b))))

; merge-min : PH x PH -> PH
; in: pairing heaps ph1, ph2
; precondiții: ph1, ph2 sunt min-PH-uri
; out: min-PH rezultat din union(ph1, ph2)
; RESTRICȚII (5p):
;  - Definiția trebuie să fie point-free.
; (define merge-min (merge-f (lambda (a b) (> a b))))

; merge-max-rating : PH x PH -> PH
; in: pairing heaps ph1, ph2
; precondiții: ph1, ph2 conțin perechi cu punct
; (nume . rating) și sunt max-PH-uri ordonate
; după rating
; out: max-PH rezultat din union(ph1, ph2)
; RESTRICȚII (5p):
;  - Definiția trebuie să fie point-free.
; (define merge-max-rating (merge-f (lambda (a b) (< (cdr a) (cdr b)))))


; TODO 2 (10p)
; Redefiniți următoarele funcții din etapa 1 care
; apelează (direct sau indirect) merge, astfel
; încât funcția merge să fie dată ca parametru
; (pe prima poziție, ca în apelurile din checker):
;  - ph-insert
;  - list->ph
;  - two-pass-merge-LR
;  - ph-del-root

(define (ph-insert merge elem ph)
  (merge (list elem) ph))

(define (list->ph merge lst)
  (foldl (lambda (elem ph) (ph-insert merge elem ph) '() lst)))

(define (two-pass-merge-LR merge heaps)
  (if (null? heaps)
      '()
      (let ([merged (merge-pairs-LR merge heaps)])
        (two-pass-merge-RL merge merged))))

(define (merge-pairs-LR merge heaps)
  (cond
    [(null? heaps) '()]
    [(null? (cdr heaps)) heaps]
    [else (cons (merge (car heaps) (cadr heaps)) (merge-pairs-LR merge (cddr heaps)))]))

(define (two-pass-merge-RL merge heaps)
  (if (null? heaps)
      '()
      (let loop ([h (car heaps)] [rest (cdr heaps)])
        (if (null? rest)
            h
            (loop (merge h (car rest)) (cdr rest))))))

(define (ph-del-root merge ph)
  (if (null? ph)
      '()
      (two-pass-merge-LR merge (cdr ph))))

;; PARTEA A DOUA (cea în care prelucrăm filme)

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
  'your-code-here)


; TODO 4 (10p)
; mark-as-seen : Movie -> Movie
; in: film m
; out: m actualizat astfel încât symbolul 'seen este
;      adăugat la începutul câmpului (listei) others
(define (mark-as-seen m)
  'your-code-here)


; TODO 5 (10p)
; mark-as-seen-from-list : [Movie] x [Symbol] -> [Movie]
; in: listă de filme movies, listă de nume seen
; out: lista movies actualizată astfel încât filmele
;      cu numele în lista seen sunt marcate ca văzute
; RESTRICȚII (10p):
;  - Nu folosiți recursivitate explicită.
;  - Folosiți cel puțin o funcțională.
(define (mark-as-seen-from-list movies seen)
  'your-code-here)

 
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
  'your-code-here)


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
  'your-code-here)


; TODO 8 (10p)
; extract-name-rating : [Movie] -> [(Symbol, Number)]
; in: listă de filme movies
; out: listă de perechi (nume . rating) 
;      (o pereche pentru fiecare film din movies)
; RESTRICȚII (10p):
;  - Nu folosiți recursivitate explicită.
;  - Folosiți cel puțin o funcțională.
(define (extract-name-rating movies)
  'your-code-here)


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
  'your-code-here)


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
  'your-code-here)


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
  'your-code-here)

