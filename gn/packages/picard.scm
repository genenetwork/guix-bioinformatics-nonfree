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

(define-module (gn packages picard)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages java)
  #:use-module (gnu packages zip))

(define-public picard-bin
  (package
   (name "picard")
   (version "2.1.1")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://github.com/broadinstitute/picard/releases/download/"
                  version "/picard-tools-" version ".zip"))
            (sha256
             (base32 "0xm524q9sfhnbhknkia683zhwxha7mfh1bzg0lj4ssnzmrxa4ql8"))))
   (build-system gnu-build-system)
   (propagated-inputs
    `(("icedtea" ,icedtea-7)))
   (native-inputs
    `(("unzip" ,unzip)))
   (arguments
    `(#:tests? #f ; This is a binary package only, so no tests.
      #:phases
      (modify-phases %standard-phases
        (delete 'configure) ; Nothing to configure.
        (delete 'build) ; This is a binary package only.
        (replace 'unpack
          (lambda _
            (zero? (system* "unzip" (assoc-ref %build-inputs "source")))))
        (replace 'install
          (lambda _
            (let ((out (string-append (assoc-ref %outputs "out")
                                      "/share/java/picard/")))
              (chdir "picard-tools-2.1.1")
              (install-file "htsjdk-2.1.1.jar" out)
              (install-file "libIntelDeflater.so" out)
              (install-file "picard-lib.jar" out)
              (install-file "picard.jar" out)))))))
   (home-page "http://broadinstitute.github.io/picard/")
    (synopsis "A set of Java command line tools for manipulating high-throughput
sequencing data (HTS) data and formats")
    (description "Picard comprises Java-based command-line utilities that
manipulate SAM files, and a Java API (HTSJDK) for creating new programs that
read and write SAM files. Both SAM text format and SAM binary (BAM) format are
supported.")
    (license license:expat)))
