## Test environments

* local OS X 10.12.6 install, R 3.4.4
* macOS 10.11 El Capitan, R-release (r-hub)
* Ubuntu 14.04 (on travis-ci), R 3.4.4
* Fedora Linux, R-devel, clang, gfortran (r-hub)
* Ubuntu Linux 16.04 LTS, R-release, GCC (r-hub)
* Windows Server 2008 R2 SP1, R-devel, 32/64 bit (r-hub)
* Windows Server 2008, R-oldrelease (win-builder)
* Windows Server 2008, R-release (win-builder)

## R CMD check results

0 errors | 0 warnings | 0 note

## Comments

This is a resubmission. Thank you for the swift response. I fixed the following
issue:

  check ERRORs on Solaris and macOS
  
  > add_citeproc_filter(NULL, error = FALSE)
  Error in if (file.exists(p)) p else bin : argument is of length zero 
