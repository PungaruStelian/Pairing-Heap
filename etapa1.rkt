#lang racket
(provide (all-defined-out))

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
(define (merge ph1 ph2)
    (cond
        ((ph-empty? ph1) ph2)
        ((ph-empty? ph2) ph1)
        ((< (ph-root ph1) (ph-root ph2))(append (list (ph-root ph2)) (list ph1) (ph-subtrees ph2)))
        (else (append (list (ph-root ph1)) (list ph2) (ph-subtrees ph1)))
    )
)

; TODO 3 (10p)
; ph-insert : T x PH -> PH
; in: valoare val, pairing heap ph
; out: ph' rezultat după inserția lui val în ph
;  - inserția este un merge între ph și 
;    PH-ul creat doar din valoarea val
;    (în această ordine)
(define (ph-insert val ph)
    (merge ph (val->ph val))
)

; TODO 4 (10p)
; list->ph : [T] -> PH
; in: listă de valori lst
; out: ph' rezultat din inserții repetate
;  - se inserează ultimul element din lst în PH-ul vid
;  - ...
;  - se inserează primul element din lst în PH-ul de până acum
; RESTRICȚII (10p):
;  - Folosiți recursivitate pe stivă.
(define (list->ph lst)
    (if (ph-empty? lst)
        empty-ph
        (ph-insert (car lst) (list->ph (cdr lst)))
    )
)

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
(define (two-pass-merge-LR phs)

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

; TODO 6 (20p)
; two-pass-merge-RL : [PH] -> PH
; in: listă de PH-uri phs
; out: ph' rezultat din merge dreapta-stânga
; (ca mai sus, dar se începe cu ultimele două PH-uri:
;  - merge de penultimul cu ultimul
;  - merge de rezultat cu merge de anterioarele două etc.)
; RESTRICȚII (10p):
;  - Folosiți recursivitate pe stivă.
(define (two-pass-merge-RL phs)
    (define (remove-last-one lst)
        (reverse (cdr (reverse lst)))
    )
  
    (define (remove-last-two lst)
        (reverse (cddr (reverse lst)))
    )

    (define (get-last lst)
        (car (reverse lst))
    )

    (define (group-merge lst)
        (cond
            ((ph-empty? lst) empty-ph)
            ((ph-empty? (cdr lst)) lst)
            (else (append (group-merge (remove-last-two lst))
                    (list (merge (get-last (remove-last-one lst)) (get-last lst)))))
        )
    )
  
    (define (fold-all lst)
        (if (ph-empty? lst)
            lst
            (merge (fold-all (cdr lst)) (car lst))
        )
    )
  
    (fold-all (group-merge phs))
)

; TODO 7 (20p)
; tournament-merge : [PH] -> PH
; in: listă de PH-uri phs
; out: ph' rezultat din merge tip "knock-out"
;  - listele de ph-uri sunt parcurse stânga-dreapta
;  - merge două câte două (pentru număr impar, ultimul rămâne ca atare)
;  - merge două câte două între PH-urile rezultate anterior
;  ...
;  - până rămâne un singur PH
(define (tournament-merge phs)
    (define (merge-pairs lst)
        (cond
            ((ph-empty? lst) empty-ph)
            ((ph-empty? (cdr lst)) lst)
            (else (append (list (merge (car lst) (cadr lst))) (merge-pairs (cddr lst))))
        )
    )

    (define (merge-until-one lst)
        (cond
            ((ph-empty? lst) empty-ph)
            ((ph-empty? (cdr lst)) (car lst))
            (else (merge-until-one (merge-pairs lst)))
        )
    )

  (merge-until-one phs)
)

; TODO 8 (10p)
; ph-del-root : PH -> PH | Bool
; in: pairing heap ph
; out: false, dacă ph e vid
;      ph' rezultat în urma ștergerii root(ph), altfel
;      - fiii root(ph) sunt uniți prin two-pass-merge-LR
(define (ph-del-root ph)
    (if (ph-empty? ph)
        #f
        (two-pass-merge-LR (cdr ph))
    )
)
