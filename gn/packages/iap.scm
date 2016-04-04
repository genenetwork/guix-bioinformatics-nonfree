;; PROGRAM             IAP        GUIX      !EQ   FIXED
;; BWA                 0.7.5a     0.7.12    X     X
;; Sambamba            0.5.9      0.5.9             (crashes, has to do with LLVM)
;; FastQ               0.11.4     0.11.5    X     X
;; Picard              1.141      2.1.0     X     X
;; bamMetrics          -          -         X
;; GATK                3.4-46     3.5       X     X
;; snpEff              4.1        4.2       X     X
;; vcftools            0.1.14     0.1.12b   X     X
;; strelka             1.0.14     1.0.14
;; VarScan             2.4.0      2.4.1     X     X
;; FreeBayes           0.1.14     1.0.2     X
;; mutect              1.1.7      -         X     N (crashes, has to do with GATK)
;; freec               7.2        8.7       X     P (version not available, contacted author)
;; delly               0.7.2      0.7.2
;; IGVTools            2.3.60     2.3.60
;; Samtools            1.2        1.3       X     X
;; Tabix               0.2.6      -         X     ?
;; PLink               1.9b3      1.90b3    X     X (same)
;; King                1.4        1.9       X     X
;; BioVCF              0.9.2      
;; VCFLib              -          -

(define-module (gnu packages iap)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix build-system ant)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages java)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages statistics)
  #:use-module (gnu packages zip))

(define-public bwa
  (package
    (name "bwa")
    (version "0.7.5a")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/bio-bwa/bwa-"
                                  version ".tar.bz2"))
              (sha256
               (base32
                "1pfpzxnmz9m5fgfh3r5cnzg6d5hkx74jycn9fmc24f5r22bxfmyi"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ;no "check" target
       #:phases
       (alist-replace
        'install
        (lambda* (#:key outputs #:allow-other-keys)
          (let ((bin (string-append
                      (assoc-ref outputs "out") "/bin"))
                (doc (string-append
                      (assoc-ref outputs "out") "/share/doc/bwa"))
                (man (string-append
                      (assoc-ref outputs "out") "/share/man/man1")))
            (mkdir-p bin)
            (mkdir-p doc)
            (mkdir-p man)
            (install-file "bwa" bin)
            (install-file "README.md" doc)
            (install-file "bwa.1" man)))
        ;; no "configure" script
        (alist-delete 'configure %standard-phases))))
    (inputs `(("zlib" ,zlib)))
    ;; Non-portable SSE instructions are used so building fails on platforms
    ;; other than x86_64.
    (supported-systems '("x86_64-linux"))
    (home-page "http://bio-bwa.sourceforge.net/")
    (synopsis "Burrows-Wheeler sequence aligner")
    (description
     "BWA is a software package for mapping low-divergent sequences against a
large reference genome, such as the human genome.  It consists of three
algorithms: BWA-backtrack, BWA-SW and BWA-MEM.  The first algorithm is
designed for Illumina sequence reads up to 100bp, while the rest two for
longer sequences ranged from 70bp to 1Mbp.  BWA-MEM and BWA-SW share similar
features such as long-read support and split alignment, but BWA-MEM, which is
the latest, is generally recommended for high-quality queries as it is faster
and more accurate.  BWA-MEM also has better performance than BWA-backtrack for
70-100bp Illumina reads.")
    (license license:gpl3+)))

(define-public fastqc-bin
  (package
    (name "fastqc")
    (version "0.11.4")
    (source (origin
      (method url-fetch)
      (uri (string-append
            "http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v"
            version ".zip"))
      (sha256
       (base32 "1rqz7p9xc8ki97afx15v7yd1pv6z59868rkikvljzc77zbwk7cmd"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ; No tests for binary release.
       #:phases
       (modify-phases %standard-phases
         (delete 'configure) ; No configure phase for binary release.
         (delete 'build) ; No build phase for binary release.
         (replace 'install
           (lambda _
             (let* ((out (assoc-ref %outputs "out"))
                    (bin (string-append out "/bin"))
                    (create-and-copy
                     (lambda (dir)
                       (mkdir (string-append bin "/" dir))
                       (copy-recursively dir (string-append bin "/" dir)))))
               (install-file "cisd-jhdf5.jar" bin)
               (install-file "jbzip2-0.9.jar" bin)
               (install-file "sam-1.103.jar" bin)
               (map create-and-copy '("net" "org" "uk" "Templates" "Help"
                                      "Configuration"))
               (install-file "fastqc" bin)
               ;; Make the script executable.
               (chmod (string-append bin "/fastqc") #o555)))))))
    (propagated-inputs
     `(("perl" ,perl) ; Used for a runner script for the Java program.
       ("jdk" ,icedtea-7)))
    (native-inputs
     `(("unzip" ,unzip)))
    (home-page "http://www.bioinformatics.babraham.ac.uk/projects/fastqc/")
    (synopsis "A quality control tool for high throughput sequence data")
    (description
     "FastQC aims to provide a QC report which can spot problems which originate
either in the sequencer or in the starting library material.  It can either run
as a stand alone interactive application for the immediate analysis of small
numbers of FastQ files, or it can be run in a non-interactive mode where it
would be suitable for integrating into a larger analysis pipeline for the
systematic processing of large numbers of files.")
    ;; FastQC is licensed GPLv3+, but one of its dependencies (JHDF5) is
    ;; licensed ASL2.0.
    (license (list license:gpl3+ license:asl2.0))))

(define-public picard-bin
  (package
   (name "picard")
   (version "1.141")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "https://github.com/broadinstitute/picard/releases/download/"
                  version "/picard-tools-" version ".zip"))
            (sha256
             (base32 "1ari9j37a0v8bm03c77pw729bqwbqqn6h15rw028jhl1iz4rgd5g"))))
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
              (chdir (string-append "picard-tools-" ,version))
              (install-file (string-append "htsjdk-" ,version ".jar") out)
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

(define-public gatk-bin
  (package
   (name "gatk")
   (version "3.4")
   (source (origin
             (method url-fetch)
             ;; TODO: You need to be logged in on a web page to download
             ;; this release.
            (uri (string-append
                  "file:///hpc/local/CentOS7/cog_bioinf/GenomeAnalysisTK-"
                  version ".tar.bz2"))
            (sha256
             (base32 "022wi4d64myp8nb4chpypb3pi8vnx1gsjhkncpjyd8pdks0p72sv"))))
   (build-system gnu-build-system)
   (propagated-inputs
    `(("icedtea" ,icedtea-7)
      ("gatk-queue" ,gatk-queue-bin)))
   (arguments
    `(#:tests? #f ; This is a binary package only, so no tests.
      #:phases
      (modify-phases %standard-phases
        (delete 'configure) ; Nothing to configure.
        (delete 'build) ; This is a binary package only.
        (add-before 'install 'debug-current-working-directory
          (lambda _
            (chdir "..")
            (display (format #f "~s~%" (getcwd)))))
        (replace 'install
          (lambda _
            (display (format #f "~s~%" (getcwd)))
            (let ((out (string-append (assoc-ref %outputs "out")
                                      "/share/java/" ,name "/")))
              (install-file "GenomeAnalysisTK.jar" out)))))))
   (home-page "https://www.broadinstitute.org/gatk/")
   (synopsis "Package for analysis of high-throughput sequencing")
   (description "The Genome Analysis Toolkit or GATK is a software package for
analysis of high-throughput sequencing data, developed by the Data Science and
Data Engineering group at the Broad Institute.  The toolkit offers a wide
variety of tools, with a primary focus on variant discovery and genotyping as
well as strong emphasis on data quality assurance.  Its robust architecture,
powerful processing engine and high-performance computing features make it
capable of taking on projects of any size.")
   ;; There are additional restrictions, so it's nonfree.
   (license license:expat)))

(define-public gatk-queue-bin
  (package
   (name "gatk-queue")
   (version "3.4")
   (source (origin
             (method url-fetch)
             ;; TODO: You need to be logged in on a web page to download
             ;; this release.
            (uri (string-append
                  "file:///hpc/local/CentOS7/cog_bioinf/Queue-"
                  version ".tar.bz2"))
            (sha256
             (base32 "103gns8f427h0b944d7v6aci7lzq1c8g3pngjn271m3p0j5cd7mj"))))
   (build-system gnu-build-system)
   (propagated-inputs
    `(("icedtea" ,icedtea-7)))
   (arguments
    `(#:tests? #f ; This is a binary package only, so no tests.
      #:phases
      (modify-phases %standard-phases
        (delete 'configure) ; Nothing to configure.
        (delete 'build) ; This is a binary package only.
        (replace 'install
          (lambda _
            (chdir "..") ; The build system moves into the "resources" folder.
            (let ((out (string-append (assoc-ref %outputs "out")
                                      "/share/java/gatk/")))
              (install-file "Queue.jar" out)))))))
   (home-page "https://www.broadinstitute.org/gatk/")
   (synopsis "Package for analysis of high-throughput sequencing")
   (description "The Genome Analysis Toolkit or GATK is a software package for
analysis of high-throughput sequencing data, developed by the Data Science and
Data Engineering group at the Broad Institute.  The toolkit offers a wide
variety of tools, with a primary focus on variant discovery and genotyping as
well as strong emphasis on data quality assurance.  Its robust architecture,
powerful processing engine and high-performance computing features make it
capable of taking on projects of any size.")
   ;; There are additional restrictions, so it's nonfree.
   (license license:expat)))

(define-public snpeff-bin
  (package
   (name "snpeff")
   (version "4.1")
   (source (origin
             (method url-fetch)
            (uri "mirror://sourceforge/snpeff/snpEff_v4_1_core.zip")
            (sha256
             (base32 "1vjgj6aacjsw6iczy09h18q5kx8ppxrrcq8w38g159zq7y3732kb"))))
           ;;(base32 "011cmnv67qjpf28njg243sf8bbagh9gjp9vh9ck0zi9xwbydkijg"))))
   (build-system gnu-build-system)
   (propagated-inputs
    `(("icedtea" ,icedtea-7)
      ("perl" ,perl)
      ("python" ,python)
      ("bash" ,bash)
      ("r" ,r)))
   (native-inputs
    `(("unzip" ,unzip)
      ("perl" ,perl)
      ("python" ,python-2)
      ("bash" ,bash)
      ("r" ,r)))
   (arguments
    `(#:tests? #f ; This is a binary package only, so no tests.
      #:phases
      (modify-phases %standard-phases
        (delete 'configure) ; Nothing to configure.
        (delete 'build) ; This is a binary package only.
         (replace 'install
           (lambda _
             (let* ((out (assoc-ref %outputs "out"))
                    (bin (string-append out "/share/java/" ,name))
                    (create-and-copy
                     (lambda (dir)
                       (mkdir (string-append bin "/" dir))
                       (copy-recursively dir (string-append bin "/" dir)))))
               (install-file "snpEff.config" bin)
               (install-file "snpEff.jar" bin)
               (install-file "SnpSift.jar" bin)
               (map create-and-copy '("scripts" "galaxy"))))))))
   (home-page "http://snpeff.sourceforge.net/")
   (synopsis "Genetic variant annotation and effect prediction toolbox.")
   (description "Genetic variant annotation and effect prediction toolbox.
It annotates and predicts the effects of variants on genes (such as amino
acid changes).")
   ;; No license specified.
   (license license:non-copyleft)))

(define-public vcftools
  (package
    (name "vcftools")
    (version "0.1.14")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/vcftools/vcftools/archive/v"
                     version ".tar.gz"))
              (sha256
               (base32
                "1pvgv9vzlgny5h3ljcy7fl2iyn98v366kdxnxv0h36aycj20ai5s"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ; no "check" target
       #:make-flags (list
                     "CFLAGS=-O2" ; override "-m64" flag
                     (string-append "PREFIX=" (assoc-ref %outputs "out"))
                     (string-append "MANDIR=" (assoc-ref %outputs "out")
                                    "/share/man/man1"))
       #:phases
       (modify-phases %standard-phases
         (add-after 'configure 'patch-manpage-install
           (lambda _
             (substitute* "Makefile"
               (("cp \\$\\{PREFIX\\}/cpp/vcftools.1") "cp ./cpp/vcftools.1"))))
         (add-before 'configure 'run-autogen
           (lambda _
             (zero? (system* "sh" "autogen.sh")))))))
    (native-inputs
     `(("autoconf" ,(autoconf-wrapper))
       ("automake" ,automake)
       ("libtool" ,libtool)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("perl" ,perl)
       ("zlib" ,zlib)))
    (home-page "http://vcftools.sourceforge.net/")
    (synopsis "Tools for working with VCF files")
    (description
     "VCFtools is a program package designed for working with VCF files, such
as those generated by the 1000 Genomes Project.  The aim of VCFtools is to
provide easily accessible methods for working with complex genetic variation
data in the form of VCF files.")
    ;; The license is declared as LGPLv3 in the README and
    ;; at http://vcftools.sourceforge.net/license.html
    (license license:lgpl3)))

(define-public varscan
  (let ((commit "91f116629b2addce523a2eabe118b1cd7a538444"))
    (package
      (name "varscan")
      (version "2.4.0")
      (source (origin
        (method url-fetch)
        (uri (string-append
              "https://github.com/dkoboldt/varscan/raw/" commit "/VarScan.v"
              version ".source.jar"))
        (sha256
         (base32 "1qyl93awj31qg4pbwaicm5vgq4zv5b9aqa10dpna9qrvbcqfdz90"))))
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
                  (let ((params (append '("jar" "cfm" "varscan-2.4.0.jar") out-files)))
                    (zero? (apply system* params)))))))
           (replace 'install
             (lambda _
               (let ((out (string-append (assoc-ref %outputs "out")
                                         "/share/java/varscan/")))
                 (install-file "varscan-2.4.0.jar" out)))))))
      (home-page "http://dkoboldt.github.io/varscan/")
      (synopsis "Variant detection in massively parallel sequencing data")
      (description "")
      ;; Free for non-commercial use by academic, government, and
      ;; non-profit/not-for-profit institutions
      (license license:non-copyleft))))

(define-public plink2
  (package
    (name "plink2")
    (version "1.90b3")
    (source
     (origin
      (method url-fetch)
      ;; https://github.com/chrchang/plink-ng/archive/v1.90b3.tar.gz
       (uri (string-append
             "https://github.com/chrchang/plink-ng/archive/v"
             version ".tar.gz"))
       (sha256
        (base32 "03fzib1al5qkr9vxv63wxmv6y2pfb1rmir0h8jpi72r87hczqjig"))
       (patches (list (search-patch "plink-ng-Makefile-zlib.patch")))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ;no "check" target
       #:phases
       (modify-phases %standard-phases
        (delete 'configure)
        (replace 'build
                 (lambda _
                   (zero? (system* "make" "-f" "Makefile.std"))
                   ))                 
        (replace 'install
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let ((bin (string-append (assoc-ref outputs "out")
                                              "/bin/")))
                      (install-file "plink2" bin)
                      #t))))))
    (inputs
     `(("zlib" ,zlib)
       ("openblas" ,openblas)
       ("atlas" ,atlas)
       ("lapack" ,lapack)
       ("gfortran" ,gfortran)
       ))
    (native-inputs
     `(("unzip" ,unzip)))
    (home-page "https://www.cog-genomics.org/plink2")
    (synopsis "Whole genome association analysis toolset")
    (description
     "PLINK is a whole genome association analysis toolset, designed to
perform a range of basic, large-scale analyses in a computationally efficient
manner.  The focus of PLINK is purely on analysis of genotype/phenotype data,
so there is no support for steps prior to this (e.g. study design and
planning, generating genotype or CNV calls from raw data).  Through
integration with gPLINK and Haploview, there is some support for the
subsequent visualization, annotation and storage of results.")
    ;; Code is released under GPLv2, except for fisher.h, which is under
    ;; LGPLv2.1+
    (license (list license:gpl2 license:lgpl2.1+))))

(define-public samtools
  (package
    (name "samtools")
    (version "1.2")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "mirror://sourceforge/samtools/"
                       version "/samtools-" version ".tar.bz2"))
       (sha256
        (base32
         "1akdqb685pk9xk1nb6sa9aq8xssjjhvvc06kp4cpdqvz2157l3j2"))))
    (build-system gnu-build-system)
    (arguments
     `(;; There are 87 test failures when building on non-64-bit architectures
       ;; due to invalid test data.  This has since been fixed upstream (see
       ;; <https://github.com/samtools/samtools/pull/307>), but as there has
       ;; not been a new release we disable the tests for all non-64-bit
       ;; systems.
       #:tests? ,(string=? (or (%current-system) (%current-target-system))
                           "x86_64-linux")
       #:modules ((ice-9 ftw)
                  (ice-9 regex)
                  (guix build gnu-build-system)
                  (guix build utils))
       #:make-flags (list "LIBCURSES=-lncurses"
                          (string-append "prefix=" (assoc-ref %outputs "out")))
       #:phases
       (alist-cons-after
        'unpack
        'patch-tests
        (lambda* (#:key inputs #:allow-other-keys)
          (let ((bash (assoc-ref inputs "bash")))
            (substitute* "test/test.pl"
              ;; The test script calls out to /bin/bash
              (("/bin/bash")
               (string-append bash "/bin/bash"))
              ;; There are two failing tests upstream relating to the "stats"
              ;; subcommand in test_usage_subcommand ("did not have Usage"
              ;; and "usage did not mention samtools stats"), so we disable
              ;; them.
              (("(test_usage_subcommand\\(.*\\);)" cmd)
               (string-append "unless ($subcommand eq 'stats') {" cmd "};")))))
        (alist-cons-after
         'install 'install-library
         (lambda* (#:key outputs #:allow-other-keys)
           (let ((lib (string-append (assoc-ref outputs "out") "/lib")))
             (install-file "libbam.a" lib)))
         (alist-cons-after
          'install 'install-headers
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((include (string-append (assoc-ref outputs "out")
                                          "/include/samtools/")))
              (for-each (lambda (file)
                          (install-file file include))
                        (scandir "." (lambda (name) (string-match "\\.h$" name))))
              #t))
          (alist-delete 'configure %standard-phases))))))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (inputs `(("ncurses" ,ncurses)
              ("perl" ,perl)
              ("python" ,python)
              ("zlib" ,zlib)))
    (home-page "http://samtools.sourceforge.net")
    (synopsis "Utilities to efficiently manipulate nucleotide sequence alignments")
    (description
     "Samtools implements various utilities for post-processing nucleotide
sequence alignments in the SAM, BAM, and CRAM formats, including indexing,
variant calling (in conjunction with bcftools), and a simple alignment
viewer.")
    (license license:expat)))



;; WARNING: This is non-free software. It will NEVER and SHOULD NEVER be
;; mainlined in GNU Guix.  You should avoid using this package, and if you
;; can, please write a free replacement for it.
(define-public king-bin
  (package
    (name "king")
    (version "1.4")
    ;; WARNING: There's no source code.  This downloads a tarball with the
    ;; executable.
    (source (origin
      (method url-fetch)
      (uri "http://people.virginia.edu/~wc9c/KING/Linux-king.tar.gz")
      (file-name (string-append name "-" version "-bin.tar.gz"))
      (sha256
       (base32 "0y5ghnkxirhdbi12csj7kqxz60ci206lfpr5ynwwjcw5l7pzbn8j"))))
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
