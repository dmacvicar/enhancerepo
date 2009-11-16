Name: a
Summary: a package
License: Public Domain
Version: 1.0
Release: 0
%description
a simple package

%build

%install
echo "Hello friends!" > %{buildroot}/hello.txt

%files
/hello.txt
