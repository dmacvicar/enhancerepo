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
