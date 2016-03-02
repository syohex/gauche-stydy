#!/usr/bin/env gosh

;; Reference
;;  - http://oneshotlife-python.hatenablog.com/entry/2016/02/22/101642

(use rfc.http)
(use rfc.uri)
(use rfc.json)
(use srfi-13)
(use gauche.parseopt)

(define base-uri "https://app.rakuten.co.jp/services/api/BooksBook/Search/20130522?")

(define (bookapi-uri author hits how-sort)
  (let* ((developer-id (sys-getenv "DEVELOPER_ID"))
         (affiliate-id (sys-getenv "AFFILIATE_ID")))
    (string-concatenate (list base-uri
                              "applicationId=" developer-id
                              "&affiliateId=" affiliate-id
                              "&author=" author
                              "&hits=" (number->string hits)
                              "&sort=" how-sort))))
(define (main args)
  (let-args (cdr args)
      ((hits "hits=i" 10)
       (how-sort "s|sorts=s" "sales")
       . restargs)
    (when (null? restargs)
      (format #t "Usage: rakuten-book-api.scm [--hits hits] [--sorts how-sort] author\n")
      (exit 1))
    (let* ((author (car restargs))
           (uri (bookapi-uri author hits how-sort)))
      (receive (_ _ hostname _ path query _) (uri-parse uri)
        (receive (code headers body) (http-get hostname
                                               (string-concatenate (list path "?" query))
                                               :secure #t)
          (unless (string=? code "200")
            (error "Can't download " url))
          (let* ((res (parse-json-string body))
                 (items (cdr (assoc "Items" res equal?)))
                 (index 1))
            (vector-map
             (lambda (item-info)
               (let* ((item (cdr (assoc "Item" item-info equal?)))
                      (title (cdr (assoc "title" item equal?))))
                 (format #t "[~2@a] ~a\n" index title)
                 (inc! index)))
             items)))))))
