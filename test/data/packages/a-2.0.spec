Name: a
Summary: a package
License: Public Domain
Version: 2.0
Release: 0
%description
a simple package

%build

%install
echo "Hello friends friend friends friends!" > %{buildroot}/hello.txt

%files
/hello.txt

%changelog
* Fri Dec 4 2009 xxxx@yyyy.com
- second change fixes bnc#1111 and
  kde #3444 and CVE-3333
* Thu Dec 3 2009 xxxx@yyyy.com
- first change
* Mon May 11 2009 xxxx@yyyy.com
- initial package
