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

(define-module (gn packages king)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression))

;; WARNING: This is non-free software. It will NEVER and SHOULD NEVER be
;; mainlined in GNU Guix.  You should avoid using this package, and if you
;; can, please write a free replacement for it.
(define-public king
  (package
    (name "king")
    (version "1.9")
    ;; WARNING: There's no source code.  This downloads a tarball with the
    ;; executable.
    (source (origin
      (method url-fetch)
      (uri "http://people.virginia.edu/~wc9c/KING/executables/Linux-king19.tar.gz")
      (file-name (string-append name "-" version "-bin.tar.gz"))
      (sha256
       (base32 "10i6mhpvn3j992riy0gch2gr519iq4cxw6x2d9x4gmdjlamd0m00"))))
    (build-system gnu-build-system)
    ;; The executable is linked to 64-bit libraries.
    (supported-systems '("x86_64-linux"))
    ;; WARNING: The host system's libz.so.1 is used because we only have an
    ;; executable that is linked already.
    (native-inputs
     `(("zlib" ,zlib)))
    (arguments
     `(#:tests? #f ; There are no tests to run.
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (delete 'build)
         (delete 'validate-runpath) ; It uses the host's libraries anyway.
         (replace 'unpack
          (lambda _
            (mkdir-p "king")
            (chdir "king")
            (zero? (system* "tar" "xvf" (assoc-ref %build-inputs "source")))))
         (replace 'install
           (lambda _
             (let ((out (string-append (assoc-ref %outputs "out") "/bin")))
               (mkdir-p out)
               (copy-file "king" (string-append out "/king"))))))))
    (home-page "http://people.virginia.edu/~wc9c/KING/")
    (synopsis "Program making use of high-throughput SNP data")
    (description "KING is a toolset making use of high-throughput SNP data
typically seen in a genome-wide association study (GWAS) or a sequencing
project.  Applications of KING include family relationship inference and
pedigree error checking, population substructure identification, forensics,
gene mapping, etc.")
    ;; WARNING: There's no license specified.  This is non-free software.
    (license license:non-copyleft)))
