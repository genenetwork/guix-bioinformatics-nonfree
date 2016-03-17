;;; Copyright © 2016 Roel Janssen <roel@gnu.org>
;;;
;;; This file is NOT part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (gn packages strelka)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages check)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages python))

;; WARNING: This is non-free software. It will NEVER and SHOULD NEVER be
;; mainlined in GNU Guix.  You should avoid using this package, and if you
;; can, please write a free replacement for it.
(define-public strelka
  (package
    (name "strelka")
    (version "1.0.14")
    (source (origin
      (method url-fetch)
      (uri (string-append
            ;;"ftp://strelka:''@ftp.illumina.com/v1-branch/v"
            ;;version "/strelka_workflow-" version ".tar.gz"))
            "https://sites.google.com/site/strelkasomaticvariantcaller/home/"
            "download/" name "_workflow-" version ".tar.gz"))
      (sha256
       (base32 "0f9g2pkr1f7s4r8sxl53jxr2cjpyx53zf3va0jj8fxzavxiwmbmk"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'check)
         (replace
          'build
          (lambda* (#:key inputs #:allow-other-keys)
            ;; Disable tests explicitely.
            (substitute* "src/Makefile"
              (("^test.*") "test:"))
            ;; Fix for running tests.
            ;;(substitute* "strelka/src/run_cppcheck.py"
            ;;  (("/usr/bin/env python") "python"))
            (zero? (system* "make" "build")))))))
    ;;(inputs
    ;; `(("python" ,python)))
    (native-inputs
     `(("bash" ,bash) ; TODO: Find the package definition..
       ("boost" ,boost)
       ("python" ,python-2)
       ("cppcheck" ,cppcheck)
       ("zlib" ,zlib)))
    (home-page "https://sites.google.com/site/strelkasomaticvariantcaller/")
    (synopsis "Somatic variant calling workflow for matched tumor-normal samples")
    (description "Analysis package designed to detect somatic SNVs and small
indels from the aligned sequencing reads of matched tumor-normal samples")
    ;; WARNING: The license is "Illumina Open Source Software License 1".
    (license license:non-copyleft)))
