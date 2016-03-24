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

(define-module (gn packages varscan)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix build-system ant))

(define-public varscan
  (package
    (name "varscan")
    (version "2.4.1")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "https://github.com/dkoboldt/varscan/releases/download/v"
            version "/VarScan.v" version ".source.jar"))
      (sha256
       (base32 "0y45ympkza7qwcbcisg006286pwjbr5978n03hx5nvl09f0mapk8"))))
    (build-system ant-build-system)
    (arguments
     `(#:tests? #f ; No test target.
       #:phases
       (modify-phases %standard-phases
         (replace 'unpack
           (lambda _
             (mkdir "source")
             (chdir "source")
             (and
              ;; Unpack the Java archive containing the source files.
              (zero? (system* "jar" "xf" (assoc-ref %build-inputs "source")))
              ;; Remove existing compiled output.
              (with-directory-excursion "net/sf/varscan/"
                (for-each (lambda (file)
                            (unless (string= (string-take-right file 5) ".java")
                              (zero? (system* "rm" file))))
                          (find-files "." #:directories? #f))))))
         (replace 'build
           (lambda _
             ;; Keep a list of files to be included in the JAR.
             (let ((out-files '("META-INF/MANIFEST.MF"))
                   (sources-dir "net/sf/varscan/"))
               (and
                (with-directory-excursion sources-dir
                  (for-each
                   (lambda (file)
                     (when (string= (string-take-right file 5) ".java")
                       ;; Compile the source files.
                       (zero? (system* "javac" file))
                       ;; Add to list of files to be included in the JAR.
                       (set! out-files
                             (append
                              out-files
                              (list (string-append sources-dir
                                (string-drop-right (string-drop file 2) 5)
                                ".class"))))))
                   (find-files "." #:directories? #f)))
                ;; Construct the Java archive.
                (let ((params (append '("jar" "cfm" "varscan-2.4.1.jar") out-files)))
                  (zero? (apply system* params)))))))
         (replace 'install
          (lambda _
            (let ((out (string-append (assoc-ref %outputs "out")
                                      "/share/java/varscan/")))
              (install-file "varscan-2.4.1.jar" out)))))))
    (home-page "http://dkoboldt.github.io/varscan/")
    (synopsis "Variant detection in massively parallel sequencing data")
    (description "")
    ;; Free for non-commercial use by academic, government, and
    ;; non-profit/not-for-profit institutions
    (license license:non-copyleft)))
