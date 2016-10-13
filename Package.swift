import PackageDescription

let package = Package(
    name: "Trip",
    dependencies: [
	    .Package(url: "https://github.com/tadija/AEXML.git", majorVersion: 4),
    ]
)
