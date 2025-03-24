#lang racket
(require racket/match)
(require "etapa2.rkt")
(provide (all-defined-out))

;; Această etapă continuă seria aplicațiilor heap-urilor  
;; de împerechere, pe care le vom folosi pentru a calcula
;; în mod dinamic mediana recenziilor unui film, simulând
;; condițiile din realitate - în care apar în permanență
;; noi recenzii pentru diverse filme.
;;    
;; Pentru a modela această dinamică folosim un flux de
;; perechi (nume-film . rating), pe baza căruia calculăm
;; un flux de stadii evolutive astfel:
;;  - fiecare stadiu este reprezentat ca listă de perechi
;;    * o pereche pentru fiecare film cu minim o recenzie
;;    * fiecare pereche este de forma
;;      (nume-film . mediană-rating-uri-primite-până-acum)
;;  - fiecare nouă recenzie determină actualizarea unei
;;    mediane, adică trecerea într-un alt stadiu,
;;    generând un nou element în fluxul rezultat
;;
;; Algoritmul folosit este următorul:
;;  Fluxul de perechi este transformat într-un flux de
;;  liste de cvartete (nume-film delta max-ph min-ph)
;;   - fiecare element din flux conține câte un cvartet 
;;     pentru fiecare film care are minim o recenzie
;;   - dacă filmul are un număr par de recenzii:
;;     - max-ph și min-ph au aceeași dimensiune
;;     - delta = size(max-ph) - size(min-ph) = 0
;;     - max-ph = max-PH cu cele mai mici rating-uri
;;     - min-ph = min-PH cu cele mai mari rating-uri
;;     - mediana este media rădăcinilor celor 2 PH-uri
;;   - dacă filmul are un număr impar de recenzii:
;;     - max-ph are un element în plus față de min-ph
;;     - delta = size(max-ph) - size(min-ph) = 1
;;     - max-ph = max-PH cu cele mai mici rating-uri
;;     - min-ph = min-PH cu cele mai mari rating-uri
;;     - mediana este rădăcina lui max-ph
;;
;; Pentru completarea cu succes a etapei este necesar să
;; calculați medianele cu algoritmul descris în enunț.
;; În caz contrar, punctajul acordat de checker va fi retras.


; TODO 1 (45p)
; add-rating : (Symbol, Int, PH, PH) x Number
;              -> (Symbol, Int, PH, PH)
; in: cvartet (nume delta max-ph min-ph),
;     rating de adăugat
; out: cvartet actualizat prin adăugarea 
;      rating-ului, astfel:
;  - dacă rating <= root(max-ph)
;    inserează rating în max-ph, actualizând delta
;  - altfel
;    inserează rating în min-ph, actualizând delta
;  - dacă delta > 1
;    mută root(max-ph) în min-ph
;  - dacă delta < 0
;    mută root(min-ph) în max-ph
(define (add-rating quad rating)
  (match quad
    [(list name delta max-ph min-ph)
     (cond
       ; Cazul 1: Ambele heap-uri sunt goale - inițializăm max-ph
       [(and (ph-empty? max-ph) (ph-empty? min-ph))
        (list name 1 (val->ph rating) empty-ph)]
       
       ; Cazul 2: Doar max-ph este gol (caz excepțional)
       [(ph-empty? max-ph)
        (list name 1 (val->ph rating) min-ph)]
       
       ; Cazul 3: Doar min-ph este gol
       [(ph-empty? min-ph)
        (if (<= rating (ph-root max-ph))
            ; Adăugăm în max-ph și verificăm echilibrarea
            (let* ([new-max-ph (ph-insert merge-max rating max-ph)]
                   [new-delta (+ delta 1)])
              (if (> new-delta 1)
                  ; Echilibrăm mutând rădăcina din max-ph în min-ph
                  (list name 0 
                        (ph-del-root merge-max new-max-ph)
                        (val->ph (ph-root new-max-ph)))
                  ; Nu trebuie să echilibrăm
                  (list name new-delta new-max-ph min-ph)))
            ; Adăugăm în min-ph
            (list name (- delta 1) max-ph (val->ph rating)))]
       
       ; Cazul 4: Rating <= rădăcina max-ph, adăugăm în max-ph
       [(<= rating (ph-root max-ph))
        (let* ([new-max-ph (ph-insert merge-max rating max-ph)]
               [new-delta (+ delta 1)])
          (if (> new-delta 1)
              ; Echilibrăm mutând rădăcina din max-ph în min-ph
              (list name 0 
                    (ph-del-root merge-max new-max-ph)
                    (ph-insert merge-min (ph-root new-max-ph) min-ph))
              ; Nu trebuie să echilibrăm
              (list name new-delta new-max-ph min-ph)))]
       
       ; Cazul 5: Rating > rădăcina max-ph, adăugăm în min-ph
       [else
        (let* ([new-min-ph (ph-insert merge-min rating min-ph)]
               [new-delta (- delta 1)])
          (if (< new-delta 0)
              ; Echilibrăm mutând rădăcina din min-ph în max-ph
              ; CORECȚIE: delta trebuie să fie 1, nu 0, după echilibrare
              (list name 1
                    (ph-insert merge-max (ph-root new-min-ph) max-ph)
                    (ph-del-root merge-min new-min-ph))
              ; Nu trebuie să echilibrăm
              (list name new-delta max-ph new-min-ph)))])])
)


; TODO 2 (45p)
; reviews->quads : Stream<(Symbol, Number)> ->
;                  Stream<[(Symbol, Int, PH, PH)]>
; in: stream de perechi (nume . rating)
; out: stream de liste de cvartete
;      (nume delta max-ph min-ph)
;  - elementul k din rezultat corespunde primelor
;    k recenzii din input (ex: dacă primele 10
;    recenzii sunt pentru 3 filme distincte, al
;    10-lea element din fluxul rezultat conține o
;    listă de 3 cvartete - unul pentru fiecare film)
; RESTRICȚII (20p):
;  - Lucrați cu operatorii pe fluxuri, fără a
;    converti liste în fluxuri sau fluxuri în liste.
(define (reviews->quads reviews)
  ; Implementăm un echivalent al lui stream-scan
  (define (my-stream-scan f init strm)
    (if (stream-empty? strm)
        empty-stream
        (let loop ([acc init] [s strm])
          (if (stream-empty? s)
              empty-stream
              (let ([new-acc (f acc (stream-first s))])
                (stream-cons new-acc 
                            (loop new-acc (stream-rest s))))))))
  
  (my-stream-scan
   (lambda (quads review)
     (define name (car review))
     (define rating (cdr review))
     
     ; Verificăm dacă filmul există deja
     (define existing-quad (findf (lambda (q) (equal? (car q) name)) quads))
     
     (if existing-quad
         ; Actualizăm cvartetul existent
         (map (lambda (q)
                (if (equal? (car q) name)
                    (add-rating q rating)
                    q))
              quads)
         ; Adăugăm un cvartet nou cu film care nu are încă recenzii
         (append quads (list (add-rating (list name 0 empty-ph empty-ph) rating)))))
   '()
   reviews))


; TODO 3 (30p)
; quads->medians : Stream<[(Symbol, Int, PH, PH)]> ->
;                  Stream<[(Symbol, Number)]>  
; in: stream de liste de cvartete (ca mai sus)
; out: stream de liste de perechi (nume-film . mediană)
;  - mediana se calculează pe baza PH-urilor din
;    fiecare cvartet, conform algoritmului de mai sus
; RESTRICȚII (20p):
;  - Nu folosiți recursivitate explicită. Folosiți cel
;    puțin o funcțională pe fluxuri.
(define (quads->medians quads)
  (stream-map
   (lambda (quad-list)
     (map (lambda (q)
            (match q
              [(list name delta max-ph min-ph)
               (cons name
                     (if (= delta 0)
                         ; Număr par de ratinguri: media rădăcinilor
                         (/ (+ (ph-root max-ph) (ph-root min-ph)) 2)
                         ; Număr impar de ratinguri: rădăcina lui max-ph
                         (ph-root max-ph)))]))
          quad-list))
   quads))