#!/usr/bin/env gosh

(use rfc.http)
(use rfc.uri)
(use scheme.base)

(define (retrieve-images regex body images)
  (if-let1 match (rxmatch regex body)
    (begin
      (set! body (rxmatch-after match))
      (retrieve-images regex body (cons (rxmatch-substring match 2) images)))
    (filter-images images)))

(define (filter-images images)
  (let ((re (string->regexp "\\.(jpe?g|png)$")))
    (filter (cut rxmatch re <>) images)))

(define (download-file url)
  (let ((output-file (sys-basename url)))
    (receive (scheme user-info hostname port path query fragment) (uri-parse url)
      (when hostname
        (call-with-output-file output-file
          (lambda (out-port)
            (receive (code headers body) (http-get hostname (or path "/"))
              (format #t "Download ~a -> ~a\n" url output-file)
              (write-string body out-port))))))))

(define (main args)
  (when (zero? (length (cdr args)))
    (error "Usage: image-downloader.scm url"))
  (let ((url (cadr args)))
    (receive (scheme user-info hostname port path query frament) (uri-parse url)
      (receive (code headers body) (http-get hostname (or path "/"))
        (let ((re (string->regexp "(src|href)=\"([^\"]+)\"")))
          (map download-file (retrieve-images re body '())))))))
