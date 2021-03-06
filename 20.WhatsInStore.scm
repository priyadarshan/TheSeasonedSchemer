;; The Seasoned Schemer
;; chapter 20
;; What's in Store ?

(define abort '())

(define global-table '())

(define (add1 n)
  (+ n 1))

(define (sub1 n)
  (- n 1))

(define (atom? a)
  (and (not (pair? a))
       (not (null? a))))

(define (text-of x)
  (cadr x))

(define (formals-of x)
  (cadr x))

(define (body-of x)
  (cddr x))

(define (ccbody-of x)
  (cddr x))

(define (name-of x)
  (cadr x))

(define (right-side-of x)
  (if (null? (cddr x))
      0
      (caddr x)))

(define (cond-lines-of x)
  (cdr x))

(define (else? x)
  (if (atom? x)
      (eq? x 'else)
      #f))

(define (question-of x)
  (car x))

(define (answer-of x)
  (cadr x))
�����̂�
(define (function-of x)
  (car x))

(define (arguments-of x)
  (cdr x))


(define (lookup table name)
  (table name))

(define (extend name1 val table)
  (lambda (name2)
    (if (eq? name1 name2)
        val
        (table name2))))

(define (define? e)
  (eq? (and (pair? e)
            (car e)) 'def))

(define (*define e)
  (set! global-table
        (extend (name-of e)
                (box (the-meaning (right-side-of e)))
                global-table)))

(define (box it)
  (lambda (sel)
    (sel it (lambda (new)
              (set! it new)))))

(define (setbox box new)
  (box (lambda (it set)
         (set new))))

(define (unbox box)
  (box (lambda (it set)
         it)))

(define (the-meaning e)
  (meaning e lookup-in-global-table))

(define (lookup-in-global-table name)
  (lookup global-table name))

(define (meaning e table)
  ((expression-to-action e) e table))

(define (*quote e table)
  (text-of e))

(define (*identifier e table)
  (unbox (lookup table e)))

(define (*set e table)
  (setbox
   (lookup table (name-of e))
   (meaning (right-side-of e) table)))

(define (*lambda e table)
  (lambda (args)
    (beglis (body-of e)
            (multi-extend (formals-of e)
                          (box-all args)
                          table))))

;; (define (beglis es table)
;;   (cond
;;    ((null? (cdr es))
;;     (meaning (car es) table))
;;    (else ((lambda (val)
;;             (beglis (cdr es) table))
;;           (meaning (car es) table)))))

;; (define (beglis es table)
;;   (let ((m (meaning (car es) table)))
;;     (if (null? (cdr es))
;;         m
;;         ((lambda (val)
;;            (beglis (cdr es) table)) m))))

;; (define (beglis es table)
;;   (let ((m (meaning (car es) table)))
;;     (if (null? (cdr es))
;;         m
;;         (let ((val m))
;;           (beglis (cdr es) table)))))

(define (beglis es table)
  (let ((m (meaning (car es) table))
        (d (cdr es)))
    (if (null? d)
        m
        (beglis d table))))

;; (define (box-all vals)
;;   (if (null? vals)
;;       '()
;;       (cons (box (car vals))
;;                (box-all (cdr vals)))))

;; (define (box-all vals)
;;   (letrec
;;       ((rec
;;         (lambda (vals acc)
;;           (if (null? vals)
;;               acc
;;               (rec (cdr vals)
;;                    (cons (box (car vals)) acc))))))
;;     (rec (reverse vals) '())))

(define (box-all vals)
  (let loop ((vals (reverse vals))
             (acc '()))
    (if (null? vals)
        acc
        (loop (cdr vals)
              (cons (box (car vals)) acc)))))

(define (multi-extend names vals table)
  (if (null? names)
      table
      (extend (car names)(car vals)
              (multi-extend (cdr names)(cdr vals)
                            table))))

(define (*application e table)
  ((meaning (function-of e) table)
   (evlis (arguments-of e) table)))

;; (define (evlis args table)
;;   (if (null? args)
;;       '()
;;       ((lambda (val)
;;          (cons val
;;                (evlis (cdr args) table)))
;;        (meaning (car args) table))))

;; (define (evlis args table)
;;   (if (null? args)
;;       '()
;;       (cons (meaning (car args) table)
;;             (evlis (cdr args) table))))

;; (define (evlis args table)
;;   (letrec
;;       ((rec
;;         (lambda (args table acc)
;;           (if (null? args)
;;               acc
;;               (rec (cdr args)
;;                    table
;;                    (cons (meaning (car args) table)
;;                          acc))))))
;;     (rec (reverse args) table '())))

(define (evlis args table)
  (let loop ((args (reverse args))
             (table table)
             (acc '()))
    (if (null? args)
        acc
        (loop (cdr args) table
              (cons (meaning (car args) table)
                    acc)))))

(define (a-prim p)
  (lambda (args-in-a-list)
    (p (car args-in-a-list))))

(define (b-prim p)
  (lambda (args-in-a-list)
    (p (car args-in-a-list)
       (cadr args-in-a-list))))

(define (*const e table)
  (cond
   ((number? e) e)
   ((eq? e #t) #t)
   ((eq? e #f) #f)
   ((eq? e 'cons)(b-prim cons))
   ((eq? e 'car )(a-prim car))
   ((eq? e 'cdr)(a-prim cdr))
   ((eq? e 'eq?)(b-prim eq?))
   ((eq? e 'atom?)(a-prim atom?))
   ((eq? e 'null?)(a-prim null?))
   ((eq? e 'zero?)(a-prim zero?))
   ((eq? e 'add1)(a-prim add1))
   ((eq? e 'sub1)(a-prim sub1))
   ((eq? e 'number)(a-prim number?))))

(define (*cond e table)
  (evcon (cond-lines-of e) table))

(define (evcon lines table)
  (cond
   ((else? (question-of (car lines)))
    (meaning (answer-of (car lines)) table))
   ((meaning (question-of (car lines)) table)
    (meaning (answer-of (car lines)) table))
   (else (evcon (cdr lines) table))))

(define (*letcc e table)
  (let/cc skip
    (beglis (ccbody-of e)
            (extend (name-of e)
                    (box (a-prim skip) table)))))

(define (value e)
  (let/cc the-end
    (set! abort the-end)
    (if (define? e)
        (*define e)
        (the-meaning e))))

(define (the-empty-table name)
  (abort
   (cons 'no-answer
         (cons name '()))))

(define (expression-to-action e)
  (if (atom? e)
      (atom-to-action e)
      (list-to-action e)))

(define (atom-to-action e)
  (cond
   ((number? e) *const)
   ((eq? e #t) *const)
   ((eq? e #f) *const)
   ((eq? e 'cons) *const)
   ((eq? e 'car) *const)
   ((eq? e 'cdr) *const)
   ((eq? e 'null?) *const)
   ((eq? e 'eq?) *const)
   ((eq? e 'atom?) *const)
   ((eq? e 'zero?) *const)
   ((eq? e 'add1) *const)
   ((eq? e 'sub1) *const)
   ((eq? e 'number?) *const)
   (else *identifier)))

(define (list-to-action e)
  (let ((a (car e)))
    (if (atom? a)
        (let ((prim-of? (cut eq? a <>)))
          (cond 
           ((prim-of? 'quote) *quote)
           ((prim-of? 'lambda) *lambda)
           ((prim-of? 'letcc) *letcc)
           ((prim-of? 'set!) *set)
           ((prim-of? 'cond) *cond)
           (else *application)))
        *application)))


(set! global-table (lambda (name)
                     (the-empty-table name)))
