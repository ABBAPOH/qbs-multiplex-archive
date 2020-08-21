import qbs
import qbs.FileInfo
import qbs.ModUtils
import qbs.TextFile

Project {
    DynamicLibrary {
        Profile {
            name: "mygcc"
            qbs.toolchainType: "gcc" // auto-detected gcc
        }
        Profile {
            name: "myclang"
            qbs.toolchainType: "clang"  // auto-detected clang
        }

        name: "mylib"
        files: [
            "lib.cpp",
            "lib.h",
        ]
        Depends { name: 'cpp' }
        cpp.defines: ['CRUCIAL_DEFINE']

        Export {
            Depends { name: "cpp" }
            cpp.includePaths: [product.sourceDirectory]
        }
        qbs.profiles: ["mygcc", "myclang"]

        install: true
        installDir: "lib-" + qbs.toolchainType
    }

    Product {
        Depends { name: "mylib"; profiles: ["mygcc", "myclang"] }
        Depends { name: "archiver" }

        property bool includeTopLevelDir: false

        builtByDefault: false
        name: "archive"
        type: ["archiver.archive"]
        targetName: "archive"
        destinationDirectory: project.buildDirectory

        archiver.type: qbs.targetOS.contains("windows") ? "zip" : "tar"
        Properties {
            condition: includeTopLevelDir
            archiver.workingDirectory: qbs.installRoot + "/.."
        }
        archiver.workingDirectory: qbs.installRoot

        Rule {
            multiplex: true
            inputs: ["installable"]
            inputsFromDependencies: ["installable"]

            Artifact {
                filePath: "list.txt"
                fileTags: ["archiver.input-list"]
            }

            prepare: {
                var cmd = new JavaScriptCommand();
                cmd.silent = true;
                cmd.excludedPathPrefixes = product.excludedPathPrefixes;
                cmd.inputFilePaths = inputs.installable.map(function(a) {
                    return ModUtils.artifactInstalledFilePath(a);
                });
                cmd.outputFilePath = output.filePath;
                cmd.baseDirectory = product.moduleProperty("archiver", "workingDirectory");
                cmd.sourceCode = function() {
                    inputFilePaths.sort();
                    var tf;
                    try {
                        tf = new TextFile(outputFilePath, TextFile.WriteOnly);
                        for (var i = 0; i < inputFilePaths.length; ++i) {
                            var relativePath = FileInfo.relativePath(baseDirectory, inputFilePaths[i]);
                            tf.writeLine(relativePath);
                        }
                    } finally {
                        if (tf)
                            tf.close();
                    }
                };

                return [cmd];
            }
        }
    }

}

