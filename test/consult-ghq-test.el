;;; consult-ghq-test.el --- Tests for consult-ghq -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'consult-ghq)

(defmacro consult-ghq-test--with-ghq (roots paths &rest body)
  "Run BODY with ghq mocked to report ROOTS and full PATHS."
  (declare (indent 2))
  `(cl-letf (((symbol-function 'consult-ghq--call)
              (lambda (&rest args)
                (pcase args
                  (`("root" "--all") ,roots)
                  (`("list" "--full-path") ,paths)
                  (_ (error "Unexpected ghq args: %S" args))))))
     ,@body))

(defun consult-ghq-test--alist (candidates)
  "Return CANDIDATES as (NAME . DIRECTORY)."
  (mapcar (lambda (c)
            (cons (substring-no-properties c)
                  (get-text-property 0 'consult-ghq-directory c)))
          candidates))

(ert-deftest consult-ghq-test-multiple-roots ()
  (consult-ghq-test--with-ghq '("/r/a" "/r/b")
      '("/r/b/github.com/x/one" "/r/a/github.com/x/two")
    (should (equal (consult-ghq-test--alist (consult-ghq--candidates))
                   '(("github.com/x/one" . "/r/b/github.com/x/one/")
                     ("github.com/x/two" . "/r/a/github.com/x/two/"))))))

(ert-deftest consult-ghq-test-duplicate-names ()
  (consult-ghq-test--with-ghq '("/r/a" "/r/b")
      '("/r/a/github.com/x/same" "/r/b/github.com/x/same" "/r/b/github.com/x/solo")
    (let ((cands (consult-ghq--candidates)))
      (should (equal (consult-ghq-test--alist cands)
                     '(("github.com/x/same [/r/a]" . "/r/a/github.com/x/same/")
                       ("github.com/x/same [/r/b]" . "/r/b/github.com/x/same/")
                       ("github.com/x/solo" . "/r/b/github.com/x/solo/"))))
      (should (equal (consult-ghq--lookup "github.com/x/same [/r/b]" cands)
                     "/r/b/github.com/x/same/")))))

(ert-deftest consult-ghq-test-nested-roots ()
  (consult-ghq-test--with-ghq '("/r" "/r/nested")
      '("/r/nested/github.com/x/one" "/r/github.com/x/two")
    (should (equal (mapcar #'car (consult-ghq-test--alist (consult-ghq--candidates)))
                   '("github.com/x/one" "github.com/x/two")))))

(ert-deftest consult-ghq-test-path-outside-roots ()
  (consult-ghq-test--with-ghq '("/r/a") '("/elsewhere/repo")
    (should (equal (consult-ghq-test--alist (consult-ghq--candidates))
                   '(("/elsewhere/repo" . "/elsewhere/repo/"))))))

;;; consult-ghq-test.el ends here
